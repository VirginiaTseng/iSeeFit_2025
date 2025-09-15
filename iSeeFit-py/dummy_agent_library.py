# !pip install -q huggingface_hub

import os
from huggingface_hub import InferenceClient

os.environ["HF_TOKEN"]='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'

client = InferenceClient("meta-llama/Llama-3.3-70B-Instruct")
# if the outputs for next cells are wrong, the free model may be overloaded. You can also use this public endpoint that contains Llama-3.2-3B-Instruct
# client = InferenceClient("https://jc26mwg228mkj8dw.us-east-1.aws.endpoints.huggingface.cloud")

# As seen in the LLM section, if we just do decoding, **the model will only stop when it predicts an EOS token**, 
# and this does not happen here because this is a conversational (chat) model and we didn't apply the chat template it expects.
# output = client.text_generation(
#     "The capital of france is",
#     max_new_tokens=100,
# )

# print(output)




# prompt="""<|begin_of_text|><|start_header_id|>user<|end_header_id|>
# The capital of France is<|eot_id|><|start_header_id|>assistant<|end_header_id|>"""
# output = client.text_generation(
#     prompt,
#     max_new_tokens=100,
# )

# print(output)



output = client.chat.completions.create(
    messages=[
        {"role": "user", "content": "The capital of France is"},
    ],
    stream=False,
    max_tokens=1024,
)
print(output.choices[0].message.content)








# This system prompt is a bit more complex and actually contains the function description already appended.
# Here we suppose that the textual description of the tools has already been appended.

SYSTEM_PROMPT = """Answer the following questions as best you can. You have access to the following tools:

get_weather: Get the current weather in a given location

The way you use the tools is by specifying a json blob.
Specifically, this json should have an `action` key (with the name of the tool to use) and an `action_input` key (with the input to the tool going here).

The only values that should be in the "action" field are:
get_weather: Get the current weather in a given location, args: {"location": {"type": "string"}}
example use :

{{
  "action": "get_weather",
  "action_input": {"location": "New York"}
}}


ALWAYS use the following format:

Question: the input question you must answer
Thought: you should always think about one action to take. Only one action at a time in this format:
Action:

$JSON_BLOB (inside markdown cell)

Observation: the result of the action. This Observation is unique, complete, and the source of truth.
... (this Thought/Action/Observation can repeat N times, you should take several steps when needed. The $JSON_BLOB must be formatted as markdown and only use a SINGLE action at a time.)

You must always end your output with the following format:

Thought: I now know the final answer
Final Answer: the final answer to the original input question

Now begin! Reminder to ALWAYS use the exact characters `Final Answer:` when you provide a definitive answer. """



prompt=f"""<|begin_of_text|><|start_header_id|>system<|end_header_id|>
{SYSTEM_PROMPT}
<|eot_id|><|start_header_id|>user<|end_header_id|>
What's the weather in London ?
<|eot_id|><|start_header_id|>assistant<|end_header_id|>
"""

print(prompt)

# messages=[
#     {"role": "system", "content": SYSTEM_PROMPT},
#     {"role": "user", "content": "What's the weather in London ?"},
#     ]
# from transformers import AutoTokenizer
# tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3.3-70B-Instruct")

# tokenizer.apply_chat_template(messages, tokenize=False,add_generation_prompt=True)




# # Do you see the problem?
# output = client.text_generation(
#     prompt,
#     max_new_tokens=200,
# )

# print(output)



# # The answer was hallucinated by the model. We need to stop to actually execute the function!
# output = client.text_generation(
#     prompt,
#     max_new_tokens=200,
#     stop=["Observation:"] # Let's stop before any actual function is called
# )

# print(output)





# # Dummy function
# def get_weather(location):
#     return f"the weather in {location} is sunny with low temperatures. \n"

# get_weather('London')


# # Let's concatenate the base prompt, the completion until function execution and the result of the function as an Observation
# new_prompt=prompt+output+get_weather('London')
# print(new_prompt)

