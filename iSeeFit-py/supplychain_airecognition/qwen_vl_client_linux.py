from openai import OpenAI
import os
import base64
from PIL import Image
import io
import tempfile
import subprocess
import shutil
from pdf2image import convert_from_path
import argparse


client_deepseek = OpenAI(api_key="sk-715bfb35cf1642d799033d54db48a4d1", base_url="https://api.deepseek.com")
client_qwen = OpenAI(api_key="sk-4d572220edf14c70a1a999f1c67d5720", base_url="https://dashscope.aliyuncs.com/compatible-mode/v1")


class DocumentProcessor:
    """文档处理器类，用于处理不同类型的文档并转换为base64编码，支持Linux和Windows平台"""
    
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
    
    def process(self):
        """
        处理文档并返回处理结果
        
        返回:
            处理成功返回True，否则返回False和错误消息
        """
        if self.file_path.lower().endswith(('.doc', '.docx')):
            image_paths = self._convert_doc_to_jpg()
            if not image_paths:
                return False, "DOC/DOCX转换为JPG失败"
            self.file_path = image_paths
        
        elif self.file_path.lower().endswith('.pdf'):
            image_paths = self._convert_pdf_to_jpg()
            if not image_paths:
                return False, "PDF转换失败"
            self.file_path = image_paths
        
        return self._encode_to_base64()
    
    def _convert_doc_to_docx_secure(self, doc_path):
        """
        安全地将DOC文件转换为DOCX文件
        
        参数:
            doc_path: DOC文件路径
            
        返回:
            转换后的DOCX文件路径，失败返回None
        """
        try:
            # 标准化路径
            input_path = os.path.abspath(doc_path).replace('\\', '/')
            output_dir = os.path.dirname(input_path)
            file_name = os.path.splitext(os.path.basename(input_path))[0]
            
            # 创建临时目录
            with tempfile.TemporaryDirectory() as tmpdir:
                # 设置环境变量
                os.environ['TMP'] = tmpdir
                os.environ['TEMP'] = tmpdir
                
                # 构建命令
                cmd = [
                    'soffice',
                    '--headless',
                    '--nologo',
                    '--nodefault',
                    '--norestore',
                    '--convert-to', 'docx:MS Word 2007 XML',
                    '--outdir', output_dir,
                    input_path
                ]
                
                # 执行转换
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    check=True,
                    timeout=30  # 设置超时防止卡死
                )
                
                # 返回转换后的文件路径
                return os.path.join(output_dir, f"{file_name}.docx")
                
        except subprocess.CalledProcessError as e:
            print(f"DOC转DOCX错误：\nSTDOUT: {e.stdout}\nSTDERR: {e.stderr}")
            return None
        except Exception as e:
            print(f"DOC转DOCX失败: {str(e)}")
            return None
    
    def _convert_doc_to_jpg(self):
        """
        将DOC或DOCX转为JPG
        
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
        使用pdf2image将PDF文件转换为JPG图像，输出到output目录
        
        参数:
            pdf_path: PDF文件路径，默认为self.file_path
            
        返回:
            转换后的JPG图片路径列表
        """
        try:
            # 如果未指定参数，使用默认值
            if pdf_path is None:
                pdf_path = self.file_path
            
            # 确保output目录存在
            output_dir = "output"
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                
            # 获取PDF文件名作为输出图像的基本名称
            base_name = os.path.splitext(os.path.basename(pdf_path))[0]
            
            # 使用pdf2image库将PDF转换为图像
            images = convert_from_path(pdf_path)
            
            image_paths = []
            
            for i, image in enumerate(images):
                image_path = os.path.join(output_dir, f'{base_name}_page_{i+1}.jpg')
                image.save(image_path, "JPEG")
                image_paths.append(image_path)
            
            return image_paths
        except Exception as e:
            print(f"PDF转换为JPG失败: {str(e)}")
            return None
    
    def _encode_to_base64(self):
        """
        将文件内容编码为base64
        
        返回:
            处理成功返回True，否则返回False和错误消息
        """
        try:
            if isinstance(self.file_path, list):
                if len(self.file_path) < 4:
                    self.base64_image = self._merge_images_to_base64(self.file_path)
                else:
                    for image_path in self.file_path:
                        with open(image_path, "rb") as image_file:
                            self.base64_images.append(base64.b64encode(image_file.read()).decode('utf-8'))
            else:
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
        images = [Image.open(img_path) for img_path in image_paths]
        
        if len(images) == 1:
            merged_img = images[0]
        else:
            max_width = max(img.width for img in images)
            total_height = sum(img.height for img in images)
            
            merged_img = Image.new('RGB', (max_width, total_height), (255, 255, 255))
            
            y_offset = 0
            for img in images:
                x_offset = (max_width - img.width) // 2
                merged_img.paste(img, (x_offset, y_offset))
                y_offset += img.height
        
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
    processor = DocumentProcessor(file_path, task_id)
    success, error_message = processor.process()
    
    if not success:
        return error_message
    
    base64_image = processor.get_base64_image()
    base64_images = processor.get_base64_images()
    
    system_prompt = f"""你是一个专业的文档分析助手。你的任务是分析文档图像并生成结构化的中文JSON总结。
    重要提示：
    1. 必须严格遵守JSON格式
    2. 所有内容必须是有效的JSON字符串
    3. 所有内容必须使用中文
    4. 你将直接从图像中提取信息，不需要中间转换步骤
    5. 合同类型的文档必定包含表格用于存储合同明细，表格内可能包含3个或以上数据明细，请直接从表格中提取多个数据明细，不要遗漏

    具体格式要求如下：\n{json_content}
    """
    
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
    
    return response.choices[0].message.content


if __name__ == "__main__":
    print("Linux文档处理程序已启动") 
    
    # 测试文档处理和多模态分析
    def test_document_processing():
        """测试文档处理功能"""
        test_file = input("请输入要处理的文件路径: ")
        processor = DocumentProcessor(test_file)
        success, error_message = processor.process()
        
        if success:
            print("文档处理成功!")
            if processor.get_base64_image():
                print(f"生成单张base64图像，长度: {len(processor.get_base64_image())}")
            if processor.get_base64_images():
                print(f"生成多张base64图像，数量: {len(processor.get_base64_images())}")
        else:
            print(f"文档处理失败: {error_message}")
    
    def test_multimodal_analysis():
        """测试多模态分析功能"""
        test_file = input("请输入要分析的文件路径: ")
        
        # 简单的JSON模板示例
        json_template = '''{
            "文档类型": "请识别这是什么类型的文档",
            "标题": "文档的主标题",
            "日期": "文档上的日期",
            "内容摘要": "简要总结文档的主要内容",
            "关键信息": {
                "字段1": "从文档中提取的重要信息1",
                "字段2": "从文档中提取的重要信息2"
            }
        }'''
        
        print("开始分析文档...")
        result = get_multimodal_analysis(test_file, json_template)
        print("\n分析结果:")
        print(result)
    
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(description="文档处理和多模态分析测试工具")
    parser.add_argument("--process", action="store_true", help="测试文档处理")
    parser.add_argument("--analyze", action="store_true", help="测试多模态分析")
    
    args = parser.parse_args()
    
    # 根据命令行参数执行相应的测试
    if args.process:
        test_document_processing()
    elif args.analyze:
        test_multimodal_analysis()
    else:
        print("请使用--process或--analyze参数指定测试类型")
        print("例如: python qwen_vl_client_linux.py --process")
        print("或者: python qwen_vl_client_linux.py --analyze") 
    