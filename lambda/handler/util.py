import json

from pydantic import BaseModel
from typing import List

from pydantic import BaseModel
from typing import List

from constants import (
    default_instructions,
    default_prompt_template,
)


class RelatedChapter(BaseModel):
    chapter: str
    relevancy: float


class QuestionResponse(BaseModel):
    question: str
    related_chapters: List[RelatedChapter]

class FinalResponse(BaseModel):
    response: List[QuestionResponse]

def print_in_debug_mode(debug: str, msg: str):
    if debug == "true":
        print(msg)

def unwrap_query_params(event):
    query_params = event.get("queryStringParameters", {})

    if query_params is None:
        query_params = {}

    llm_model_id = query_params.get("llm_model_id", "anthropic")
    llm_model_version = query_params.get("llm_model_version", "claude-3-sonnet-20240229-v1:0")
    debug = query_params.get("debug", "false")

    return (llm_model_id, llm_model_version, debug)


def unwrap_payload(event):
    request_body = event.get("body")

    if request_body is None:
        payload = {}
    else:
        payload = json.loads(request_body)

    questions = payload.get("questions", [])
    if questions is []:
        raise Exception("pass questions in payload")
    numbered_questions = "\n".join([f"{i+1}. {item}" for i, item in enumerate(questions)])

    subject = payload.get("subject")
    if subject is None:
        raise Exception("pass subject in payload")
    
    stream = payload.get("stream")
    if stream is None:
        raise Exception("pass stream in payload")
    
    chapters = payload.get("chapters", [])
    if chapters is []:
        raise Exception("pass chapters in payload")
    numbered_chapters = "\n".join([f"{i+1}. {item}" for i, item in enumerate(chapters)])
    
    instructions = payload.get("instructions", default_instructions)
    prompt_template = payload.get("prompt_template", default_prompt_template)

    return (numbered_questions, subject, stream, numbered_chapters, instructions, prompt_template)

