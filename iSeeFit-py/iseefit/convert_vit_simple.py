#!/usr/bin/env python3
"""
最简单的 ViT 到 Core ML 转换脚本
专门处理 ViT 模型的转换问题
"""

import torch
import coremltools as ct
import torchvision.models as M
import torch.nn as nn
import os

def main():
    print("🚀 Starting simple ViT to Core ML conversion...")
    
    # 配置
    model_path = "checkpoints/best_model.pt"
    output_path = "Food101_ViT.mlmodel"
    num_classes = 101
    
    try:
        # 1. 创建模型
        print("Creating ViT model...")
        model = M.vit_b_16(weights=None)
        model.heads.head = nn.Linear(model.heads.head.in_features, num_classes)
        
        # 2. 加载权重
        print("Loading model weights...")
        checkpoint = torch.load(model_path, map_location="cpu")
        
        if isinstance(checkpoint, dict):
            if 'model_state_dict' in checkpoint:
                state_dict = checkpoint['model_state_dict']
            elif 'state_dict' in checkpoint:
                state_dict = checkpoint['state_dict']
            else:
                state_dict = checkpoint
        else:
            state_dict = checkpoint
        
        # 加载权重，允许部分匹配
        model.load_state_dict(state_dict, strict=False)
        model.eval()
        print("✅ Model loaded successfully!")
        
        # 3. 测试模型
        print("Testing model...")
        test_input = torch.randn(1, 3, 224, 224)
        with torch.no_grad():
            output = model(test_input)
        print(f"Model output shape: {output.shape}")
        
        # 4. 尝试最简单的转换方法
        print("Converting to Core ML...")
        
        # 方法1: 使用 TensorType 而不是 ImageType
        try:
            print("Trying with TensorType...")
            mlmodel = ct.convert(
                model,
                inputs=[ct.TensorType(
                    name="input_image",
                    shape=(1, 3, 224, 224)
                )],
                convert_to="neuralnetwork",
                source="pytorch"
            )
            print("✅ TensorType conversion successful!")
            
        except Exception as e1:
            print(f"❌ TensorType conversion failed: {e1}")
            
            # 方法2: 使用更简单的 ImageType
            try:
                print("Trying with simple ImageType...")
                mlmodel = ct.convert(
                    model,
                    inputs=[ct.ImageType(
                        name="input_image",
                        shape=(1, 3, 224, 224)
                    )],
                    convert_to="neuralnetwork",
                    source="pytorch"
                )
                print("✅ Simple ImageType conversion successful!")
                
            except Exception as e2:
                print(f"❌ Simple ImageType conversion failed: {e2}")
                
                # 方法3: 使用 mlprogram 格式
                try:
                    print("Trying with mlprogram format...")
                    mlmodel = ct.convert(
                        model,
                        inputs=[ct.TensorType(
                            name="input_image",
                            shape=(1, 3, 224, 224)
                        )],
                        convert_to="mlprogram",
                        source="pytorch"
                    )
                    print("✅ mlprogram conversion successful!")
                    
                except Exception as e3:
                    print(f"❌ All conversion methods failed:")
                    print(f"  - TensorType: {e1}")
                    print(f"  - Simple ImageType: {e2}")
                    print(f"  - mlprogram: {e3}")
                    return 1
        
        # 5. 保存模型
        print(f"Saving model to: {output_path}")
        mlmodel.save(output_path)
        
        # 显示模型信息
        file_size = os.path.getsize(output_path) / (1024 * 1024)
        print(f"✅ Model saved successfully!")
        print(f"📁 File: {output_path}")
        print(f"📏 Size: {file_size:.2f} MB")
        
        print("🎉 Conversion completed successfully!")
        return 0
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())

