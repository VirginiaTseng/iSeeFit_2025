
import requests
import os
from dotenv import load_dotenv, find_dotenv, dotenv_values

load_dotenv(find_dotenv())
HUGGINGFACE_API_TOKEN = os.getenv("HUGGINGFACEHUB_API_TOKEN")

API_URL = "https://router.huggingface.co/hf-inference/v1"
headers = {"Authorization": "Bearer {HUGGINGFACE_API_TOKEN}}"}

def query(payload):
	response = requests.post(API_URL, headers=headers, json=payload)
	return response.content

audio_bytes = query({
	"inputs": "The answer to the universe is 42",
})
# # You can access the audio with IPython.display for example
# from IPython.display import Audio
# Audio(audio_bytes)

# from scipy.io.wavfile import write as write_wav

# sampling_rate = model.config.sample_rate
# write_wav("audio2.wav", sampling_rate, audio_bytes)




from transformers import pipeline
import scipy

synthesiser = pipeline("text-to-speech", "suno/bark")

speech = synthesiser("Hello, my dog is cooler than you!", forward_params={"do_sample": True})

scipy.io.wavfile.write("bark_out2.wav", rate=speech["sampling_rate"], data=speech["audio"])
