Everything should be through backend (e.g. data service, LLM chatbot service)

Frontend should not have direct communication with Supabase

Supabase on frontend is purely just for session management

Frontend should utilise Riverpod where appropriate

Anything that a user can do in the context of adding data to the database, ensure that the process is 
foolproof (e.g. user cannot log in a non-sensical manner) and crashproof

Make sure to keep scalability and maintainability in mind

Keep hardcoding to a minimum, hardcode only when strictly neccessary

Remember to account for race conditions

Anything to do with AI, make sure to take LangChain into account, essentially to utilise LangChain 
where appropriate