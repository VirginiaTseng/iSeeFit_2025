import pyttsx3

import tensorflow as tf
print(tf.__version__)

def text_to_speech():
    # 初始化 pyttsx3 引擎
    engine = pyttsx3.init()

    # 获取并列出所有可用的语音
    voices = engine.getProperty('voices')
    print("Available voices:")
    for i, voice in enumerate(voices):
        print(f"{i}: {voice.name} - {voice.languages}")

    # 选择语音（可以修改索引 0/1 切换不同的发音）
    engine.setProperty('voice', voices[0].id)  # 更换为 voices[1].id 可能是不同性别

    # 设置语速（默认值 200，可调整快慢）
    engine.setProperty('rate', 150)

    # 设置音量（范围 0.0 - 1.0）
    engine.setProperty('volume', 1.0)

    # 让用户输入文本
    text = input("Enter the text you want to convert to speech: ")

    # 开始朗读
    engine.say(text)

    # 运行并等待朗读完成
    engine.runAndWait()

if __name__ == "__main__":
    text_to_speech()
