default_prompt_template = """Act as an Examiner setting questions for an exam on {subject} for {stream} students.
    You will be provided with a set of questions as a question bank.
    Assign each question from the question bank to one or more chapters from the list provided below, following the given instructions:

    ### QUESTIONS:
    {questions}
    
    ### CHAPTERS:
    {chapters}

    ### INSTRUCTIONS:
    {instructions}

    ### RESPONSE FORMAT:
    {response_format}
        
    Your Response:
    """

default_instructions = """1. Output format:
        ```json
        {
            "response": [
                {
                    "question": "Explain the importance of the determinant of a matrix and its implications in linear algebra, particularly in solving systems of linear equations and determining matrix invertibility?",
                    "related_chapters": [
                        {
                            "chapter": "Matrix Operations",
                            "relevancy": "0.4"
                        },
                        {
                            "chapter": "Determinants and Inverses",
                            "relevancy": "0.6"
                        }
                    ]
                }
            ]
        }
        ```
    2. A question can be related to multiple chapters.
    3. Determine the relevancy of the given questions to the assigned chapters from the provided list of chapters on a scale of 0 to 1, where 0 represents not relevant and 1 represents strongly relevant.
    4. If a question is not directly related to any chapter but still somewhat relevant, assign it to the most closely related chapter with a low relevancy score.
    5. If you fail to assign a question to any chapter from the given list, assign the chapter as "uncategorized" and set relevancy to "1".
    6. Assign chapters and relevancy scores to all questions provided in the question bank.
    """
