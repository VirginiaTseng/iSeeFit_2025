import os
import re
import json
import copy
import threading
import time
from werkzeug.utils import secure_filename

# 全局变量，用于跟踪任务状态
active_tasks = {}
task_lock = threading.Lock()

# 自定义支持中文的安全文件名函数
def secure_filename_cn(filename):
    # 替换路径分隔符为下划线
    for sep in os.path.sep, os.path.altsep:
        if sep:
            filename = filename.replace(sep, '_')
    
    # 过滤掉不安全字符，但保留中文字符
    filename = re.sub(r'[^\w\u4e00-\u9fa5.-]', '_', filename)
    filename = filename.strip('._')  # 删除开头和结尾的点和下划线
    
    # 确保文件名不为空
    if not filename:
        filename = 'unnamed_file'
    
    return filename

# 检查文件扩展名是否允许
def allowed_file(filename, allowed_extensions):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in allowed_extensions

def create_empty_template(template_type, templates, default_template):
    """
    根据模板类型创建一个空值模板对象
    
    参数:
        template_type: 模板类型名称
        templates: 模板字典
        default_template: 默认模板
        
    返回:
        初始化的模板对象，所有字段为空值
    """
    template_str = templates.get(template_type, default_template)
    
    # 清理模板字符串中的注释和多余空格
    template_str = re.sub(r'//.*', '', template_str)  # 移除注释
    template_str = re.sub(r'\s+', ' ', template_str)  # 压缩空格
    
    try:
        # 尝试将模板转换为JSON对象
        template_obj = json.loads(template_str)
        
        # 递归初始化所有字段为空值
        def init_empty_fields(obj):
            if isinstance(obj, dict):
                for key in obj:
                    if isinstance(obj[key], (dict, list)):
                        obj[key] = init_empty_fields(obj[key])
                    else:
                        obj[key] = ""
                return obj
            elif isinstance(obj, list):
                if len(obj) > 0:
                    # 保留数组的第一个元素作为模板，并清空其内容
                    template_item = init_empty_fields(obj[0])
                    return [template_item]
                return []
            return obj
        
        return init_empty_fields(template_obj)
    
    except json.JSONDecodeError:
        # 如果模板字符串无法解析为JSON，返回空对象
        return {}

def process_multimodal_task(task_id, file_path, json_format):
    """后台处理多模态分析的任务函数"""
    try:
        # 导入多模态模型处理函数
        from .qwen_vl_client import get_multimodal_analysis
        
        # 直接调用多模态模型进行分析
        try:
            json_result = get_multimodal_analysis(file_path, json_format, task_id)
        except Exception as e:
            # 如果多模态模型失败，直接报错
            error_message = f"多模态分析失败: {str(e)}"
            with task_lock:
                if task_id in active_tasks:
                    active_tasks[task_id]['status'] = 'error'
                    active_tasks[task_id]['result'] = error_message
                    active_tasks[task_id]['event'].set()
            return
        
        # 更新任务状态
        with task_lock:
            if task_id in active_tasks:
                active_tasks[task_id]['status'] = 'completed'
                active_tasks[task_id]['result'] = json_result
                active_tasks[task_id]['event'].set()
    
    except Exception as e:
        # 更新任务状态为错误
        with task_lock:
            if task_id in active_tasks:
                active_tasks[task_id]['status'] = 'error'
                active_tasks[task_id]['result'] = str(e)
                active_tasks[task_id]['event'].set()

def process_multimodal_stream_task(task_id, file_path, json_format):
    """使用流式处理的方式处理多模态分析任务，逐步更新结果"""
    try:
        # 导入多模态流式处理函数
        from .qwen_vl_client import get_multimodal_analysis_stream
        
        # 获取当前任务信息
        with task_lock:
            if task_id not in active_tasks:
                return
            
            current_result = active_tasks[task_id]['result']
        
        # 使用流式处理函数处理文件
        accumulated_json = ""
        
        for chunk_data in get_multimodal_analysis_stream(file_path, json_format, task_id):
            if "error" in chunk_data:
                # 发生错误
                with task_lock:
                    if task_id in active_tasks:
                        active_tasks[task_id]['status'] = 'error'
                        active_tasks[task_id]['result'] = chunk_data["error"]
                        active_tasks[task_id]['event'].set()
                return
            
            # 累积JSON内容
            if "chunk" in chunk_data:  # 确保chunk不为空
                accumulated_json += chunk_data["chunk"]
                
                # 尝试从当前累积内容中提取字段值
                updated_result = update_template_from_json(current_result, accumulated_json)
                
                # 更新任务的当前结果
                with task_lock:
                    if task_id in active_tasks:
                        active_tasks[task_id]['result'] = updated_result
        
        # 流式处理完成后，保存最终结果并标记为完成
        with task_lock:
            if task_id in active_tasks:
                active_tasks[task_id]['status'] = 'completed'
                # result字段已经在上面的循环中持续更新，不需要再次赋值
                active_tasks[task_id]['event'].set()
    
    except Exception as e:
        # 更新任务状态为错误
        with task_lock:
            if task_id in active_tasks:
                active_tasks[task_id]['status'] = 'error'
                active_tasks[task_id]['result'] = str(e)
                active_tasks[task_id]['event'].set()

def update_template_from_json(template, json_str):
    """
    从JSON字符串中提取字段值并更新模板
    
    参数:
        template: 当前模板对象
        json_str: JSON字符串（可能是不完整的JSON）
        
    返回:
        更新后的模板对象
    """
    # 尝试将字符串解析为JSON，如果成功则直接返回解析结果
    try:
        # 尝试完整解析
        data = json.loads(json_str)
        # 如果解析成功，直接返回解析结果
        return data
    
    except json.JSONDecodeError:
        # JSON解析失败，使用正则表达式提取键值对和数组
        # 创建模板的深拷贝，避免修改原始对象
        result = copy.deepcopy(template)
        
        # 提取普通键值对: "key": "value"
        kv_pattern = r'"([^"]+)"\s*:\s*"([^"]*)"'
        extracted_pairs = {}
        matches = re.finditer(kv_pattern, json_str)
        for match in matches:
            key = match.group(1)
            value = match.group(2)
            extracted_pairs[key] = value
        
        # 提取数组对象 - 使用更精确的方式匹配数组
        array_data = {}
        
        # 先尝试匹配完整的数组 "key": [ ... ]
        complete_array_pattern = r'"([^"]+)"\s*:\s*\[([\s\S]*?)\]'
        complete_array_matches = re.finditer(complete_array_pattern, json_str, re.DOTALL)
        
        # 处理所有完整的数组
        for array_match in complete_array_matches:
            array_key = array_match.group(1)
            array_content = array_match.group(2)
            
            # 提取数组中的每个对象
            objects = []
            obj_pattern = r'\{([\s\S]*?)\}'
            obj_matches = re.finditer(obj_pattern, array_content, re.DOTALL)
            
            for obj_match in obj_matches:
                obj_content = obj_match.group(1)
                obj_data = {}
                
                # 从对象内容中提取键值对
                obj_kv_matches = re.finditer(kv_pattern, '{' + obj_content + '}')
                for obj_kv_match in obj_kv_matches:
                    obj_key = obj_kv_match.group(1)
                    obj_value = obj_kv_match.group(2)
                    obj_data[obj_key] = obj_value
                
                if obj_data:  # 只添加非空对象
                    objects.append(obj_data)
            
            if objects:  # 只添加非空数组
                array_data[array_key] = objects
        
        # 然后处理不完整的数组（可能是最后一个数组）
        # 查找所有数组的开始位置
        array_starts = re.finditer(r'"([^"]+)"\s*:\s*\[', json_str)
        for array_start in array_starts:
            array_key = array_start.group(1)
            
            # 如果此键已在完整数组中处理过，则跳过
            if array_key in array_data:
                continue
            
            # 找到这个数组的起始位置
            start_pos = array_start.end()
            
            # 提取从起始位置到字符串结束的所有内容
            rest_content = json_str[start_pos:]
            
            # 从这个内容中提取可能的对象
            objects = []
            obj_pattern = r'\{([\s\S]*?)\}'
            obj_matches = re.finditer(obj_pattern, rest_content, re.DOTALL)
            
            for obj_match in obj_matches:
                obj_content = obj_match.group(1)
                obj_data = {}
                
                # 从对象内容中提取键值对
                obj_kv_matches = re.finditer(kv_pattern, '{' + obj_content + '}')
                for obj_kv_match in obj_kv_matches:
                    obj_key = obj_kv_match.group(1)
                    obj_value = obj_kv_match.group(2)
                    obj_data[obj_key] = obj_value
                
                if obj_data:  # 只添加非空对象
                    objects.append(obj_data)
                
                # 找到这个对象的结束位置
                end_pos = obj_match.end()
                
                # 检查这个对象后面是否有右括号或逗号，表示数组还在继续
                after_obj = rest_content[end_pos:].lstrip()
                if not after_obj or after_obj[0] not in [',', ']']:
                    # 如果没有逗号或右括号，说明已经到达了不完整数组的末尾
                    break
            
            # 检查是否存在最后一个不完整的对象
            last_obj_start = rest_content.rfind('{')
            last_obj_end = rest_content.rfind('}')
            
            if last_obj_start > last_obj_end:  # 说明存在一个没有右括号的不完整对象
                last_obj_content = rest_content[last_obj_start+1:]
                last_obj_data = {}
                
                # 从不完整对象中提取键值对
                last_obj_kv_matches = re.finditer(kv_pattern, '{' + last_obj_content)
                for last_obj_kv_match in last_obj_kv_matches:
                    last_obj_key = last_obj_kv_match.group(1)
                    last_obj_value = last_obj_kv_match.group(2)
                    last_obj_data[last_obj_key] = last_obj_value
                
                if last_obj_data:  # 只添加非空对象
                    objects.append(last_obj_data)
            
            if objects:  # 只添加非空数组
                array_data[array_key] = objects
        
        # 更新模板
        def update_template(obj):
            if isinstance(obj, dict):
                for key in obj:
                    # 更新普通键值对
                    if key in extracted_pairs and not isinstance(obj[key], (dict, list)):
                        obj[key] = extracted_pairs[key]
                    
                    # 更新数组
                    elif key in array_data and isinstance(obj[key], list) and len(obj[key]) > 0:
                        template_item = obj[key][0]  # 使用第一个元素作为模板
                        new_items = []
                        
                        for data_item in array_data[key]:
                            item_copy = copy.deepcopy(template_item)
                            if isinstance(item_copy, dict):
                                # 更新数组项中的字段
                                for field_key in item_copy:
                                    if field_key in data_item:
                                        item_copy[field_key] = data_item[field_key]
                            new_items.append(item_copy)
                        
                        obj[key] = new_items
                    
                    # 递归处理嵌套对象
                    elif isinstance(obj[key], dict):
                        update_template(obj[key])
                    
                    # 递归处理未匹配的数组
                    elif isinstance(obj[key], list) and len(obj[key]) > 0:
                        for item in obj[key]:
                            if isinstance(item, dict):
                                update_template(item)
            
            return obj
        
        return update_template(result)
   