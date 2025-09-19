from openai import OpenAI
import os
import base64
from PIL import Image
import io
import platform
import sys
from pdf2image import convert_from_path

# Windows特有模块
if platform.system() == 'Windows':
    import pythoncom
    import win32com.client
# Linux特有模块
else:
    import subprocess


# for backward compatibility, you can still use `https://api.deepseek.com/v1` as `base_url`.
client_deepseek = OpenAI(api_key="sk-715bfb35cf1642d799033d54db48a4d1", base_url="https://api.deepseek.com")
client_qwen = OpenAI(api_key="sk-4d572220edf14c70a1a999f1c67d5720", base_url="https://dashscope.aliyuncs.com/compatible-mode/v1")


class DocumentProcessor:
    """文档处理器类，用于处理不同类型的文档并转换为base64编码"""
    
    def __init__(self, file_path, task_id=None):
        """
        初始化文档处理器
        
        参数:
            file_path: 文件路径
            task_id: 任务ID，用于更新任务状态
        """
        self.file_path = file_path
        self.task_id = task_id
        self.base64_image = None
        self.base64_images = []
        self.processed_file_path = None
        self.is_windows = platform.system() == 'Windows'
    
    def process(self):
        """
        处理文档并返回处理结果
        
        返回:
            处理成功返回True，否则返回False和错误消息
        """
        # 检查是否为DOC或DOCX文件
        if self.file_path.lower().endswith(('.doc', '.docx')):
            if self.is_windows:
                pdf_path = self._convert_doc_to_pdf_windows()
            else:
                # Linux系统下直接转为JPG
                image_paths = self._convert_doc_to_jpg_linux()
                if not image_paths:
                    return False, "DOC/DOCX转换失败"
                self.file_path = image_paths
                return self._encode_to_base64()
                
            if not pdf_path:
                return False, "DOC/DOCX转换为PDF失败"
            self.file_path = pdf_path
        
        # 检查是否为PDF文件
        if self.file_path.lower().endswith('.pdf'):
            image_paths = self._convert_pdf_to_jpg()
            if not image_paths:
                return False, "PDF转换失败"
            self.file_path = image_paths
        
        # 将文件转换为base64编码
        return self._encode_to_base64()
    
    def _convert_doc_to_pdf_windows(self):
        """
        在Windows上将DOC或DOCX文件转换为PDF
        
        返回:
            转换后的PDF文件路径
        """
        pythoncom.CoInitialize()
        try:
            # 获取文件所在目录和文件名（不含扩展名）
            doc_dir = os.path.dirname(self.file_path)
            doc_name = os.path.splitext(os.path.basename(self.file_path))[0]
            
            # 设置输出PDF文件路径
            pdf_path = os.path.join(doc_dir, f'{doc_name}.pdf')
            
            word = win32com.client.Dispatch('Word.Application')
            doc = word.Documents.Open(self.file_path)
            doc.SaveAs(pdf_path, FileFormat=17)
            doc.Close()
            word.Quit()
            
            print(f"文件已转换为PDF: {pdf_path}")
            return pdf_path
        except Exception as e:
            print(f"DOC/DOCX转换失败: {str(e)}")
            return None
            
    def _convert_doc_to_jpg_linux(self):
        """
        在Linux上将DOC或DOCX转为JPG
        
        返回:
            转换后的JPG图片路径列表
        """
        try:
            # 获取文件所在目录和文件名（不含扩展名）
            doc_dir = os.path.dirname(self.file_path)
            doc_name = os.path.splitext(os.path.basename(self.file_path))[0]
            
            # 转换为PDF
            pdf_path = os.path.join(doc_dir, f'{doc_name}.pdf')
            subprocess.run(['soffice', '--headless', '--convert-to', 'pdf', self.file_path, '--outdir', os.path.dirname(pdf_path)])
            
            # 使用PDF转JPG功能将PDF转为图像
            image_paths = self._convert_pdf_to_jpg(pdf_path)
            
            # 清理临时文件
            if os.path.exists(pdf_path):
                os.remove(pdf_path)
                
            return image_paths
            
        except Exception as e:
            print(f"DOC/DOCX转换为JPG失败: {str(e)}")
            return None
    
    def _convert_pdf_to_jpg(self, pdf_path=None):
        """
        将PDF转换为JPG图片
        
        参数:
            pdf_path: 可选的PDF路径，如果为None则使用self.file_path
            
        返回:
            转换后的JPG图片路径列表
        """
        try:
            # 使用传入的pdf_path或默认的self.file_path
            pdf_file = pdf_path if pdf_path else self.file_path
            
            # 获取PDF文件所在目录和文件名（不含扩展名）
            pdf_dir = os.path.dirname(pdf_file)
            pdf_name = os.path.splitext(os.path.basename(pdf_file))[0]
            
            # 将PDF转换为图片
            images = convert_from_path(pdf_file)
            image_paths = []
            
            # 保存每一页为JPG格式
            for i, image in enumerate(images):
                image_path = os.path.join(pdf_dir, f'{pdf_name}_page_{i+1}.jpg')
                image.save(image_path, 'JPEG')
                image_paths.append(image_path)
            
            return image_paths
        except Exception as e:
            print(f"PDF转换失败: {str(e)}")
            return None
    
    def _encode_to_base64(self):
        """
        将文件内容编码为base64
        
        返回:
            处理成功返回True，否则返回False和错误消息
        """
        try:
            # 判断file_path是否为列表
            if isinstance(self.file_path, list):
                # 多页PDF的情况
                if len(self.file_path) < 4:
                    # 少于4张图片时，将它们合并成一张
                    self.base64_image = self._merge_images_to_base64(self.file_path)
                else:
                    # 多页PDF的情况，生成base64编码的图片列表
                    for image_path in self.file_path:
                        with open(image_path, "rb") as image_file:
                            self.base64_images.append(base64.b64encode(image_file.read()).decode('utf-8'))
            else:
                # 单个图片文件的情况
                with open(self.file_path, "rb") as image_file:
                    self.base64_image = base64.b64encode(image_file.read()).decode('utf-8')
            
            return True, None
        except Exception as e:
            return False, f"文件编码失败: {str(e)}"
    
    def _merge_images_to_base64(self, image_paths):
        """
        将多张图片垂直合并成一张图片，并返回base64编码
        
        参数:
            image_paths: 图片路径列表
        
        返回:
            合并后图片的base64编码字符串
        """
        # 读取所有图片
        images = [Image.open(img_path) for img_path in image_paths]
        
        # 计算合并后的尺寸
        if len(images) == 1:
            # 只有一张图片时，不需要合并
            merged_img = images[0]
        else:
            # 垂直合并所有图片
            max_width = max(img.width for img in images)
            total_height = sum(img.height for img in images)
            
            merged_img = Image.new('RGB', (max_width, total_height), (255, 255, 255))
            
            # 垂直排列所有图片
            y_offset = 0
            for img in images:
                # 水平居中放置每张图片
                x_offset = (max_width - img.width) // 2
                merged_img.paste(img, (x_offset, y_offset))
                y_offset += img.height
        
        # 将合并后的图片转换为base64编码
        buffered = io.BytesIO()
        merged_img.save(buffered, format="JPEG")
        return base64.b64encode(buffered.getvalue()).decode('utf-8')
    
    def get_base64_image(self):
        """获取base64编码的图像"""
        return self.base64_image
    
    def get_base64_images(self):
        """获取base64编码的图像列表"""
        return self.base64_images


def get_multimodal_analysis(file_path, json_content, task_id=None):
    """
    使用多模态模型直接分析文件并返回JSON结果
    
    参数:
        file_path: 文件路径
        json_content: JSON格式模板
        task_id: 任务ID，用于更新任务状态
        
    返回:
        JSON字符串结果
    """
    # 使用DocumentProcessor处理文件
    processor = DocumentProcessor(file_path, task_id)
    success, error_message = processor.process()
    
    if not success:
        return error_message
    
    base64_image = processor.get_base64_image()
    base64_images = processor.get_base64_images()
    
    system_prompt = f"""你是一个专业的文档分析助手。你的任务是分析文档图像并生成结构化的中文JSON总结。
    重要提示：
    1. 你将直接从图像中提取信息，不需要中间转换步骤
    2. 图片中的表格包含多种详细信息，不要提取其他部分的内容，作为详细信息的部分
    3. 所有的重量单位都是吨，不要转换为千克，但重量值是千克时，请转换为吨
    具体格式要求如下：\n{json_content}
    """
    
    # 调用多模态API
    if base64_image is not None:
        response = client_qwen.chat.completions.create(
            model="qwen-vl-max-latest",
            messages=[
            {
                "role": "system", 
                "content": system_prompt
            },
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "请分析这个文档图像并生成JSON格式的总结："},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]
            }
        ],
        response_format={"type": "json_object"},
        max_tokens=8192,
        temperature=0.3,
        stream=False
    )
    else:
        # 为多页PDF创建图片URL列表
        image_urls = []
        for base64_img in base64_images:
            image_urls.append(f"data:image/jpeg;base64,{base64_img}")
        
        response = client_qwen.chat.completions.create(
            model="qwen-vl-max-latest",
            messages=[
                {
                    "role": "system", 
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "请分析这些文档图像并生成JSON格式的总结："},
                        {"type": "video", "video": image_urls}
                    ]
                }
            ],
            response_format={"type": "json_object"},
            max_tokens=8192,
            temperature=0.3,
            stream=False
        )
    
    # 直接返回模型生成的内容
    return response.choices[0].message.content


def get_multimodal_analysis_stream(file_path, json_content, task_id=None):
    """
    使用多模态模型直接分析文件并以流式方式返回JSON结果
    
    参数:
        file_path: 文件路径
        json_content: JSON格式模板
        task_id: 任务ID，用于更新任务状态
        
    返回:
        流式响应生成器
    """
    # 使用DocumentProcessor处理文件
    processor = DocumentProcessor(file_path, task_id)
    success, error_message = processor.process()
    
    if not success:
        yield {"error": error_message}
        return
    
    base64_image = processor.get_base64_image()
    base64_images = processor.get_base64_images()
    
    system_prompt = f"""你是一个专业的文档分析助手。你的任务是分析文档图像并生成结构化的中文JSON总结。
    重要提示：
    1. 你将直接从图像中提取信息，不需要中间转换步骤
    2. 图片中的表格包含多种详细信息，不要提取其他部分的内容，作为详细信息的部分
    3. 所有的重量单位都是吨，不要转换为千克，但重量值是千克时，请转换为吨
    
    具体格式要求如下：\n{json_content}
    """
    
    # 调用多模态API，启用流式传输
    if base64_image is not None:
        response = client_qwen.chat.completions.create(
            model="qwen-vl-max-latest",
            messages=[
            {
                "role": "system", 
                "content": system_prompt
            },
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "请分析这个文档图像并生成JSON格式的总结："},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]
            }
        ],
        response_format={"type": "json_object"},
        max_tokens=8192,
        temperature=0.3,
        stream=True  # 启用流式传输
    )
    else:
        # 为多页PDF创建图片URL列表
        image_urls = []
        for base64_img in base64_images:
            image_urls.append(f"data:image/jpeg;base64,{base64_img}")
        
        response = client_qwen.chat.completions.create(
            model="qwen-vl-max-latest",
            messages=[
                {
                    "role": "system", 
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "请分析这些文档图像并生成JSON格式的总结："},
                        {"type": "video", "video": image_urls}
                    ]
                }
            ],
            response_format={"type": "json_object"},
            max_tokens=8192,
            temperature=0.3,
            stream=True  # 启用流式传输
        )
    
    # 流式返回结果
    accumulated_content = ""
    for chunk in response:
        if hasattr(chunk.choices[0], 'delta') and hasattr(chunk.choices[0].delta, 'content') and chunk.choices[0].delta.content is not None:
            content_chunk = chunk.choices[0].delta.content
            accumulated_content += content_chunk
            yield {
                "chunk": content_chunk,
                "accumulated": accumulated_content
            }


   

