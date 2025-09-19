from flask import Flask, request, jsonify, send_from_directory, render_template, Response
import os
import uuid
import threading
import time
from flask_cors import CORS  # 添加CORS支持，处理跨域请求
import json
from .json_templates import TEMPLATES, DEFAULT_TEMPLATE

# 导入处理逻辑和辅助函数
from .document_processor import (
    secure_filename_cn, allowed_file, create_empty_template,
    process_multimodal_task, process_multimodal_stream_task,
    active_tasks, task_lock
)

# 创建应用实例
app = Flask(__name__, static_folder='static', template_folder='templates')
CORS(app)  # 启用CORS

# 配置
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB限制
app.config['ALLOWED_EXTENSIONS'] = {'jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'}

# 确保上传文件夹存在
if not os.path.exists(app.config['UPLOAD_FOLDER']):
    os.makedirs(app.config['UPLOAD_FOLDER'])

# @app.route('/')
# def index():
#     """渲染首页"""
#     return render_template('index.html')

@app.route('/tasks/stream/<task_id>', methods=['GET'])
def stream_task(task_id):
    """使用SSE实时获取任务处理状态和结果"""
    # 检查该任务是否已经有活跃的SSE连接
    with task_lock:
        if task_id not in active_tasks:
            return jsonify({
                'error': '找不到指定的任务或任务已完成'
            }), 404
        
        
        # 如果已经有连接，则拒绝新的连接请求
        if active_tasks[task_id]['sse_connected']:
            return jsonify({
                'error': '该任务已有活跃的SSE连接，不允许建立多个连接'
            }), 403
        
        # 标记该任务现在有一个活跃的SSE连接
        active_tasks[task_id]['sse_connected'] = True
    
    def generate():
        last_result = None
        # 发送SSE头部
        yield "event: connected\ndata: 已连接到任务流\n\n"
        
        # 持续检查任务状态和结果变化
        while True:
            # 在锁中获取任务信息，但不在整个处理过程中持有锁
            task_status = None
            current_result = None
            process_time = 0
            start_time = time.time()
            
            with task_lock:
                # 仅获取需要的数据，然后立即释放锁
                task_info = active_tasks[task_id]
                task_status = task_info['status']
                current_result = task_info.get('result', {})
                start_time = task_info.get('start_time', time.time())
                
            
            # 计算处理时间
            process_time = round(time.time() - start_time, 2)
            
            # 任务完成或出错处理
            if task_status in ['completed', 'error']:
                if task_status == 'error':
                    yield f"event: error\ndata: {json.dumps({'error': f'处理文件时出错: {current_result}', 'process_time': f'{process_time}秒'})}\n\n"
                else:
                    if isinstance(current_result, str):
                        try:
                            result_obj = json.loads(current_result)
                        except json.JSONDecodeError:
                            result_obj = {"raw_result": current_result}
                    else:
                        result_obj = current_result or {}
                    
                    yield f"event: completed\ndata: {json.dumps({'status': 'completed', 'result': result_obj, 'process_time': f'{process_time}秒'})}\n\n"
                
                # 任务已在锁内移除，现在跳出循环
                del active_tasks[task_id]
                break
            
            # 检查结果是否有变化
            if current_result != last_result:
                # 发送更新的结果
                yield f"event: update\ndata: {json.dumps({'status': 'processing', 'result': current_result, 'task_id': task_id, 'process_time': f'{process_time}秒'})}\n\n"
                last_result = current_result
            
            # 等待一小段时间再次检查，降低CPU使用率
            time.sleep(5)
    # 返回SSE响应
    return Response(generate(), mimetype='text/event-stream')


@app.route('/analyses', methods=['POST'])
def create_analysis():
    """
    接收文件并进行多模态分析的API接口
    接收：
        - document：一个文件（JPG、PNG、PDF、DOC、DOCX）
        - template_type：模板类型（可选，默认为purchase）
        - is_streaming：是否使用流式处理（可选，布尔值，默认为false）
    返回：任务ID，用于后续通过SSE获取结果
    """
    # 检查是否有文件部分
    if 'document' not in request.files:
        return jsonify({
            'error': '没有提供文件'
        }), 400
    
    file = request.files['document']
    
    # 检查文件名是否为空
    if file.filename == '':
        return jsonify({
            'error': '没有选择文件'
        }), 400
    
    # 检查文件类型是否允许
    if not allowed_file(file.filename, app.config['ALLOWED_EXTENSIONS']):
        return jsonify({
            'error': '不支持的文件类型'
        }), 400
    
    # 获取模板类型参数，如果没有提供则使用默认模板
    template_type = request.form.get('template_type', 'purchase')
    
    # 判断是否使用流式处理
    is_streaming = request.form.get('is_streaming', 'false').lower() == 'true'
    
    # 根据模板类型获取相应的JSON模板
    json_format = TEMPLATES.get(template_type, DEFAULT_TEMPLATE)
    
    try:
        # 生成唯一文件名并保存
        unique_id = str(uuid.uuid4())
        # 使用自定义的支持中文的安全文件名函数
        filename = secure_filename_cn(file.filename)
        # 保留原始文件名但添加唯一ID
        saved_filename = f"{unique_id}_{filename}"
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], saved_filename)
        file.save(file_path)
        
        # 注册任务到活动任务列表
        task_id = unique_id
        
        
        if is_streaming:
            # 创建一个空值模板，用于流式填充
            empty_template = create_empty_template(template_type, TEMPLATES, DEFAULT_TEMPLATE)
            with task_lock:
                active_tasks[task_id] = {
                    'status': 'processing',
                    'file_path': file_path,
                    'result': empty_template,  # 使用result字段存储当前模板状态
                    'start_time': time.time(),
                    'event': threading.Event(),
                    'sse_connected': False
                }
            
            # 启动后台线程处理任务
            thread = threading.Thread(
                target=process_multimodal_stream_task,
                args=(task_id, file_path, json_format)
            )
        else:
            with task_lock:
                active_tasks[task_id] = {
                    'status': 'processing',
                    'file_path': file_path,
                    'result': None,
                    'event': threading.Event(),
                    'start_time': time.time(),  # 记录开始时间
                    'sse_connected': False
                }
            # 启动后台线程处理任务
            thread = threading.Thread(
                target=process_multimodal_task,
                args=(task_id, file_path, json_format)
            )
        
        thread.start()
        
        # 立即返回任务ID，不等待处理完成
        return jsonify({
            'task_id': task_id,
            'message': f'文件已上传，正在进行多模态{"流式" if is_streaming else ""}分析处理',
            'stream_url': f'/tasks/stream/{task_id}'  # 返回SSE流URL
        }), 202
    
    except Exception as e:
        return jsonify({
            'error': f'处理文件时出错: {str(e)}'
        }), 500


# 主程序入口
def run(host='0.0.0.0', port=7777,debug=True):
    app.run(debug=debug, host=host, port=port) 