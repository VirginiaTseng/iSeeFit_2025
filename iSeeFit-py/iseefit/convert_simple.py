#!/usr/bin/env python3
"""
简化的 PyTorch 到 Core ML 转换脚本
专门处理模型结构不匹配的问题
"""

import torch
import coremltools as ct
import torchvision.models as M
import torch.nn as nn
import os
from pathlib import Path

def load_model_safely(model_path, num_classes=101):
    """安全加载模型，处理各种可能的保存格式"""
    print(f"Loading model from: {model_path}")
    
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")
    
    # 创建基础模型
    model = M.vit_b_16(weights=None)
    model.heads.head = nn.Linear(model.heads.head.in_features, num_classes)
    
    # 加载权重
    checkpoint = torch.load(model_path, map_location="cpu")
    print(f"Checkpoint keys: {list(checkpoint.keys())}")
    
    # 尝试不同的加载方式
    if isinstance(checkpoint, dict):
        if 'model_state_dict' in checkpoint:
            state_dict = checkpoint['model_state_dict']
        elif 'state_dict' in checkpoint:
            state_dict = checkpoint['state_dict']
        elif 'model' in checkpoint:
            state_dict = checkpoint['model']
        else:
            state_dict = checkpoint
    else:
        state_dict = checkpoint
    
    # 加载状态字典，允许部分匹配
    missing_keys, unexpected_keys = model.load_state_dict(state_dict, strict=False)
    
    if missing_keys:
        print(f"Missing keys: {missing_keys[:5]}...")  # 只显示前5个
    if unexpected_keys:
        print(f"Unexpected keys: {unexpected_keys[:5]}...")  # 只显示前5个
    
    model.eval()
    return model

def convert_to_coreml(model, output_path="Food101_ViT.mlmodel"):
    """转换为 Core ML 格式"""
    print("Converting to Core ML...")
    
    # 创建示例输入
    example_input = torch.randn(1, 3, 224, 224)
    
    # 尝试不同的转换方法
    try:
        # 方法1: JIT trace
        print("Trying JIT trace...")
        traced_model = torch.jit.trace(model, example_input)
        
        # 转换为 Core ML
        mlmodel = ct.convert(
            traced_model,
            inputs=[ct.ImageType(
                name="input_image",
                shape=example_input.shape,
                scale=1/255.0,
                bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225]
            )],
            convert_to="mlprogram"
        )
        
    except Exception as e1:
        print(f"JIT trace failed: {e1}")
        try:
            # 方法2: JIT script
            print("Trying JIT script...")
            scripted_model = torch.jit.script(model)
            
            mlmodel = ct.convert(
                scripted_model,
                inputs=[ct.ImageType(
                    name="input_image",
                    shape=example_input.shape,
                    scale=1/255.0,
                    bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225]
                )],
                convert_to="neuralnetwork"  # 使用更兼容的格式
            )
            
        except Exception as e2:
            print(f"JIT script failed: {e2}")
            try:
                # 方法3: 直接转换（不推荐，但有时有效）
                print("Trying direct conversion...")
                mlmodel = ct.convert(
                    model,
                    inputs=[ct.ImageType(
                        name="input_image",
                        shape=example_input.shape
                    )],
                    convert_to="neuralnetwork"
                )
            except Exception as e3:
                raise Exception(f"All conversion methods failed: {e1}, {e2}, {e3}")
    
    # 保存模型
    print(f"Saving to {output_path}...")
    mlmodel.save(output_path)
    
    # 显示模型信息
    file_size = os.path.getsize(output_path) / (1024 * 1024)
    print(f"✅ Model saved successfully!")
    print(f"📁 File: {output_path}")
    print(f"📏 Size: {file_size:.2f} MB")
    
    return mlmodel

def main():
    """主函数"""
    print("🚀 Starting PyTorch to Core ML conversion...")
    
    # 设置路径
    model_path = "checkpoints/best_model.pt"
    output_path = "Food101_ViT.mlmodel"
    
    try:
        # 加载模型
        model = load_model_safely(model_path)
        print("✅ Model loaded successfully!")
        
        # 测试模型
        print("Testing model...")
        test_input = torch.randn(1, 3, 224, 224)
        with torch.no_grad():
            output = model(test_input)
        print(f"Model output shape: {output.shape}")
        
        # 转换为 Core ML
        mlmodel = convert_to_coreml(model, output_path)
        
        print("🎉 Conversion completed successfully!")
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
