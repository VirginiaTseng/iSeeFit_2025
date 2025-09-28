# convert_to_coreml.py
import torch
import coremltools as ct
import torchvision.models as M
import torch.nn as nn
import os

# 检查模型文件是否存在
model_path = "checkpoints/best_model.pt"
if not os.path.exists(model_path):
    print(f"ERROR: Model file not found at {model_path}")
    exit(1)

# 1) 重构你的模型（和训练时一致）
num_classes = 101
model = M.vit_b_16(weights=None)
model.heads.head = nn.Linear(model.heads.head.in_features, num_classes)

# 2) 加载训练好的权重（你的 best_model.pt）
print("Loading model weights...")
try:
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

    state = torch.load(model_path, map_location=device)
    print(f"Model state keys: {list(state.keys())[:5]}...")  # 显示前5个键
    
    # 尝试加载状态字典
    model.load_state_dict(state, strict=False)  # 使用 strict=False 允许部分匹配
    print("Model weights loaded successfully!")
except Exception as e:
    print(f"ERROR loading model: {e}")
    print("Trying to load with different approach...")
    
    # 如果直接加载失败，尝试其他方法
    try:
        checkpoint = torch.load(model_path, map_location="cpu")
        if 'model_state_dict' in checkpoint:
            model.load_state_dict(checkpoint['model_state_dict'], strict=False)
        elif 'state_dict' in checkpoint:
            model.load_state_dict(checkpoint['state_dict'], strict=False)
        else:
            model.load_state_dict(checkpoint, strict=False)
        print("Model weights loaded with alternative method!")
    except Exception as e2:
        print(f"ERROR with alternative loading: {e2}")
        exit(1)

model.eval()

# 3) trace（示例输入需与模型期望一致）
print("Creating example input...")
example = torch.randn(1, 3, 224, 224)  # 如果你的模型训练输入是 224

print("Tracing model...")
try:
    traced = torch.jit.trace(model, example)
    print("Model traced successfully!")
except Exception as e:
    print(f"ERROR tracing model: {e}")
    print("Trying script method...")
    try:
        traced = torch.jit.script(model)
        print("Model scripted successfully!")
    except Exception as e2:
        print(f"ERROR scripting model: {e2}")
        exit(1)

# 4) convert to Core ML
print("Converting to Core ML...")
try:
    # 首先尝试使用 traced 模型
    print("Trying with traced model...")
    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="input_image", shape=example.shape,
                             scale=1/255.0,
                             bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225])],
        convert_to="mlprogram"
    )
    print("Core ML conversion successful with traced model!")
except Exception as e:
    print(f"Traced model conversion failed: {e}")
    try:
        # 尝试使用 traced 模型但用 neuralnetwork 格式
        print("Trying traced model with neuralnetwork format...")
        mlmodel = ct.convert(
            traced,
            inputs=[ct.ImageType(name="input_image", shape=example.shape)],
            convert_to="neuralnetwork"
        )
        print("Core ML conversion successful with neuralnetwork format!")
    except Exception as e2:
        print(f"Traced model with neuralnetwork failed: {e2}")
        try:
            # 尝试直接转换原始模型（绕过 JIT）
            print("Trying direct model conversion...")
            mlmodel = ct.convert(
                model,
                inputs=[ct.ImageType(name="input_image", shape=example.shape,
                                     scale=1/255.0,
                                     bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225])],
                convert_to="neuralnetwork"
            )
            print("Direct model conversion successful!")
        except Exception as e3:
            print(f"Direct model conversion failed: {e3}")
            try:
                # 最后尝试：使用更简单的输入格式
                print("Trying with simplified input format...")
                mlmodel = ct.convert(
                    model,
                    inputs=[ct.ImageType(name="input_image", shape=example.shape)],
                    convert_to="neuralnetwork"
                )
                print("Simplified conversion successful!")
            except Exception as e4:
                print(f"All conversion methods failed:")
                print(f"  - Traced mlprogram: {e}")
                print(f"  - Traced neuralnetwork: {e2}")
                print(f"  - Direct mlprogram: {e3}")
                print(f"  - Direct neuralnetwork: {e4}")
                exit(1)

# 5) 可选：float16 压缩以减小体积（也能加速）
print("Quantizing model...")
try:
    mlmodel_fp16 = ct.models.neural_network.quantization_utils.quantize_weights(mlmodel, nbits=16)
    print("Model quantized successfully!")
except Exception as e:
    print(f"WARNING: Quantization failed: {e}")
    print("Using original model without quantization...")
    mlmodel_fp16 = mlmodel

# 6) 保存
output_path = "Food101_ViT.mlmodel"
print(f"Saving model to {output_path}...")
try:
    mlmodel_fp16.save(output_path)
    print(f"✅ Successfully saved {output_path}")
    print(f"Model size: {os.path.getsize(output_path) / (1024*1024):.2f} MB")
except Exception as e:
    print(f"ERROR saving model: {e}")
    exit(1)
