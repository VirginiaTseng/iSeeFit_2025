import os
from dotenv import load_dotenv, find_dotenv, dotenv_values

load_dotenv(find_dotenv())
HUGGINGFACE_API_TOKEN = os.getenv("HUGGINGFACEHUB_API_TOKEN")
# print(HUGGINGFACE_API_TOKEN)
# print(dotenv_values('.env'))  os.getenv("HUGGINGFACEHUB_API_TOKEN")

# Use a pipeline as a high-level helper
from transformers import pipeline

# img2text
def img2text(url):    
    image_to_text = pipeline("image-to-text", model="Salesforce/blip-image-captioning-base")
    text = image_to_text(url)[0]['generated_text']

    print(text)
    return text





#from langchain import PromptTemplate, LLMChain, OpenAI

from langchain_core.prompts import PromptTemplate
from langchain.chains import LLMChain
#from langchain_openai import OpenAI
from langchain_openai import ChatOpenAI 


# llm
def generate_story(scenario):
    template = """
    You are a story teller;
    You can generate a story based on a simple narrative, the story should be at least 40 words but no more than 100 words;
    
    CONTEXT: {scenario}
    STORY:
    """

    prompt = PromptTemplate(template=template, input_varables=["scenario"])

    # LLMChain is now deprecated
    # story_llm = LLMChain(llm=OpenAI(
    #     model_name="gpt-3.5-turbo",
    #     temperature=1,
    # ), prompt=prompt, verbose=True)

    # story= story_llm.predict(scenario=scenario)

    llm = ChatOpenAI(model_name="gpt-3.5-turbo", temperature=1)
    story_generator = prompt | llm  # ✅ This replaces `LLMChain`
    story = story_generator.invoke({"scenario": scenario}) 

    print(story.content)
    return story.content




import requests



# text to speech
def text2speech(message):
    #API_URL = "https://router.huggingface.co/hf-inference/v1"  #
    API_URL = "https://api-inference.huggingface.co/models/espnet/kan-bayashi_ljspeech_vits"
    headers = {"Authorization": "Bearer {HUGGINGFACEHUB_API_TOKEN}}"}
    payload = {
        "inputs": message,
    }
    response = requests.post(API_URL, headers=headers, json=payload)
    with open("audio.flac", "wb") as file:
        file.write(response.content)



from transformers import SpeechT5Processor, SpeechT5ForTextToSpeech, SpeechT5HifiGan
from datasets import load_dataset
import torch
import soundfile as sf
from datasets import load_dataset

def text2speech2(message):
    processor = SpeechT5Processor.from_pretrained("microsoft/speecht5_tts")
    model = SpeechT5ForTextToSpeech.from_pretrained("microsoft/speecht5_tts")
    vocoder = SpeechT5HifiGan.from_pretrained("microsoft/speecht5_hifigan")

    inputs = processor(text=message, return_tensors="pt")

    # load xvector containing speaker's voice characteristics from a dataset
    embeddings_dataset = load_dataset("Matthijs/cmu-arctic-xvectors", split="validation")
    speaker_embeddings = torch.tensor(embeddings_dataset[7306]["xvector"]).unsqueeze(0)

    speech = model.generate_speech(inputs["input_ids"], speaker_embeddings, vocoder=vocoder)

    sf.write("speech3.wav", speech.numpy(), samplerate=16000)


scenario = img2text('visit.jpg')
story=generate_story(scenario)
# text2speech(story)
text2speech2(story)

import streamlit as st
def main():
    st.set_page_config(page_title="Moodie - img audio story", page_icon="📚")
    st.header("Turn img into audio story")
    st.subheader("A simple AI tool that generates stories based on images")

    uploaded_file = st.file_uploader("Choose an image...", type=["jpg", "jpeg", "png"])
    if uploaded_file is not None:
        print(uploaded_file)

        bytes_data = uploaded_file.getvalue()
        with open(uploaded_file.name, "wb") as file:
            file.write(bytes_data)
        st.image(uploaded_file, caption="Uploaded Image", use_column_width=True)

        scenario = img2text(uploaded_file.name)
        story = generate_story(scenario)
        text2speech2(story)

        with st.expander("scenario"):
            st.write(scenario)
        with st.expander("story"):
            st.write(story)

        #st.audio("audio.flac")
        st.audio("speech3.wav")

# streamlit run yourscript.py
if __name__ == "__main__":
    main()


# reference:
# hf.co/tasks 
# relevance AI