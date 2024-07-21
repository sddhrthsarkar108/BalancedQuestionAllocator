import json

from langchain_core.messages import HumanMessage
from langchain.output_parsers import PydanticOutputParser
from langchain_core.prompts.chat import ChatPromptTemplate, HumanMessagePromptTemplate

from langchain_aws import ChatBedrock


from constants import (
    default_instructions,
)
from util import (
    FinalResponse,
    print_in_debug_mode,
    unwrap_payload,
    unwrap_query_params,
)


def lambda_handler(event, context):
    try:
        llm_model_id, llm_model_version, debug = unwrap_query_params(event)

        llm = ChatBedrock(
            model_id=f"{llm_model_id}.{llm_model_version}",
            model_kwargs={"temperature": 0},
        )
        print_in_debug_mode(
            debug, f"initialized llm; model id - {llm_model_id}.{llm_model_version}"
        )

        path = event["requestContext"]["path"]
        if "/invoke/raw" in path:
            return handle_raw_call(llm, event.get("body"))

        questions, subject, stream, chapters, instructions, prompt_template = (
            unwrap_payload(event)
        )

        output_parser = PydanticOutputParser(pydantic_object=FinalResponse)
        response_format = output_parser.get_format_instructions()
       
        prompt = ChatPromptTemplate(
            messages=[HumanMessagePromptTemplate.from_template(prompt_template)],
            partial_variables={"response_format": response_format},
        )
        print_in_debug_mode(
            debug,
            f"initialized LLM Prompt; format:\n{prompt.format(
                questions=questions,
                subject=subject,
                stream=stream,
                chapters=chapters,
                instructions=default_instructions
            )}",
        )

        llm_output: FinalResponse = (prompt | llm | output_parser).invoke(
            {
                "questions": questions,
                "subject": subject,
                "stream": stream,
                "chapters": chapters,
                "instructions": instructions,
            }
        )
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
            },
            "body": llm_output.model_dump_json(),
        }
    except Exception as e:
        error_message = str(e)
        print(f"error occurred: {error_message}")
        return {"statusCode": 500, "body": f"error occurred: {error_message}"}


def handle_raw_call(llm: ChatBedrock, prompt: str):
    messages = [HumanMessage(content=prompt)]
    llm_output = llm.invoke(messages)
    print(llm_output.content)
    return {
        "statusCode": 200,
        "body": llm_output.content,
    }


# uncomment to debug code locally
# if __name__ == "__main__":
    # TO DEBUG RAW CALL
    # queryParams = {"debug": "true"}
    # event = {
    #     "queryStringParameters": queryParams,
    #     "body": "Please introduce yourself.",
    #     "requestContext": {"path": "/invoke/raw"},
    # }
    # print(lambda_handler(event, None))

    #  TO DEBUG NON RWA CALL
    # body = {
    #     "questions": [
    #         "what is wildcard ?",
    #         "what is concurrent hash map ?"
    #     ],
    #     "subject": "Java Programming",
    #     "stream": "Computer Science",
    #     "chapters": [
    #         "Generics",
    #         "Collections"
    #     ]
    # }
    # queryParams = {"debug": "false"}

    # event = {
    #     "queryStringParameters": queryParams,
    #     "body": json.dumps(body),
    #     "requestContext": {"path": ""},
    # }
    # print(lambda_handler(event, None))
