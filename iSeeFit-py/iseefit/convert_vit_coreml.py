#!/usr/bin/env python3
"""
专门用于 Vision Transformer 模型转换为 Core ML 的脚本
处理 ViT 模型在 Core ML 转换中的常见问题
"""

import torch
import coremltools as ct
import torchvision.models as M
import torch.nn as nn
import os
import warnings

# 忽略警告
warnings.filterwarnings("ignore")

def create_vit_model(num_classes=101):
    """创建 ViT 模型"""
    model = M.vit_b_16(weights=None)
    model.heads.head = nn.Linear(model.heads.head.in_features, num_classes)
    return model

def load_model_weights(model, model_path):
    """加载模型权重"""
    print(f"Loading weights from: {model_path}")
    
    checkpoint = torch.load(model_path, map_location="cpu")
    print(f"Checkpoint type: {type(checkpoint)}")
    
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
    
    # 加载权重，允许部分匹配
    missing_keys, unexpected_keys = model.load_state_dict(state_dict, strict=False)
    
    if missing_keys:
        print(f"Missing keys: {len(missing_keys)}")
    if unexpected_keys:
        print(f"Unexpected keys: {len(unexpected_keys)}")
    
    model.eval()
    return model

def test_model(model):
    """测试模型"""
    print("Testing model...")
    test_input = torch.randn(1, 3, 224, 224)
    
    with torch.no_grad():
        output = model(test_input)
    
    print(f"Input shape: {test_input.shape}")
    print(f"Output shape: {output.shape}")
    print(f"Output range: [{output.min():.3f}, {output.max():.3f}]")
    
    return True

def convert_with_torchscript(model, output_path):
    """使用 TorchScript 转换"""
    print("Converting with TorchScript...")
    
    # 创建示例输入
    example_input = torch.randn(1, 3, 224, 224)
    
    try:
        # 尝试 script（比 trace 更稳定）
        print("Trying JIT script...")
        scripted_model = torch.jit.script(model)
        
        # 转换为 Core ML
        mlmodel = ct.convert(
            scripted_model,
            inputs=[ct.ImageType(
                name="input_image",
                shape=example_input.shape,
                scale=1/255.0,
                bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225]
            )],
            convert_to="neuralnetwork",
            source="pytorch"  # 明确指定源框架
        )
        
        print("✅ TorchScript conversion successful!")
        return mlmodel
        
    except Exception as e:
        print(f"❌ TorchScript conversion failed: {e}")
        return None

def convert_direct(model, output_path):
    """直接转换（绕过 TorchScript）"""
    print("Converting directly...")
    
    try:
        # 直接转换模型
        mlmodel = ct.convert(
            model,
            inputs=[ct.ImageType(
                name="input_image",
                shape=(1, 3, 224, 224),
                scale=1/255.0,
                bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225]
            )],
            convert_to="neuralnetwork",
            source="pytorch"  # 明确指定源框架
        )
        
        print("✅ Direct conversion successful!")
        return mlmodel
        
    except Exception as e:
        print(f"❌ Direct conversion failed: {e}")
        return None

def convert_simplified(model, output_path):
    """简化转换（最小配置）"""
    print("Converting with simplified settings...")
    
    try:
        # 使用最简单的配置
        mlmodel = ct.convert(
            model,
            inputs=[ct.ImageType(
                name="input_image",
                shape=(1, 3, 224, 224)
            )],
            convert_to="neuralnetwork",
            source="pytorch"  # 明确指定源框架
        )
        
        print("✅ Simplified conversion successful!")
        return mlmodel
        
    except Exception as e:
        print(f"❌ Simplified conversion failed: {e}")
        return None

def save_model(mlmodel, output_path):
    """保存模型"""
    print(f"Saving model to: {output_path}")
    
    try:
        mlmodel.save(output_path)
        
        # 显示模型信息
        file_size = os.path.getsize(output_path) / (1024 * 1024)
        print(f"✅ Model saved successfully!")
        print(f"📁 File: {output_path}")
        print(f"📏 Size: {file_size:.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to save model: {e}")
        return False

def main():
    """主函数"""
    print("🚀 Starting ViT to Core ML conversion...")
    
    # 配置
    model_path = "checkpoints/best_model.pt"
    output_path = "Food101_ViT.mlmodel"
    num_classes = 101
    
    try:
        # 1. 创建模型
        print("Creating ViT model...")
        model = create_vit_model(num_classes)
        
        # 2. 加载权重
        model = load_model_weights(model, model_path)
        
        # 3. 测试模型
        test_model(model)
        
        # 4. 尝试不同的转换方法
        mlmodel = None
        
        # 方法1: TorchScript
        mlmodel = convert_with_torchscript(model, output_path)
        
        # 方法2: 直接转换
        if mlmodel is None:
            mlmodel = convert_direct(model, output_path)
        
        # 方法3: 简化转换
        if mlmodel is None:
            mlmodel = convert_simplified(model, output_path)
        
        # 5. 保存模型
        if mlmodel is not None:
            success = save_model(mlmodel, output_path)
            if success:
                print("🎉 Conversion completed successfully!")
                return 0
            else:
                print("❌ Failed to save model")
                return 1
        else:
            print("❌ All conversion methods failed")
            return 1
            
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
