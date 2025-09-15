#pip install huggingface_hub
#export HUGGINGFACE_TOKEN=api_xxx

from huggingface_hub import InferenceClient
import json
repo_id = "microsoft/Phi-3-mini-4k-instruct"

# llm_client = InferenceClient(
#     model=repo_id,
#     timeout=120,)

# def call_llm(inference_client: InferenceClient, prompt: str):
#     response = inference_client.post(
#         json={
#             "input": prompt,
#             "parameters": {"max_new_tokens": 200},
#             "task": "text-generation",
#         }
#     )
#     return json.loads(response.decode())[0]["generated_text"]

# response= call_llm(llm_client, "what is happiness?")
# print(response)



from huggingface_hub import InferenceClient

from dotenv import load_dotenv, find_dotenv, dotenv_values
import os

load_dotenv(find_dotenv())
HUGGINGFACE_API_TOKEN = os.getenv("HUGGINGFACEHUB_API_TOKEN")


client = InferenceClient(
	provider="nebius",
	api_key="hf_{HUGGINGFACE_API_TOKEN}}"
)

messages = [
	{
		"role": "user",
		"content": "What is the capital of France?"
	}
]

completion = client.chat.completions.create(
    model="microsoft/Phi-3-mini-4k-instruct", 
	messages=messages, 
	max_tokens=500,
)

print(completion.choices[0].message.content)