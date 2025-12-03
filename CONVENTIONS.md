Everything should be through backend (e.g. data service, LLM chatbot service)
Frontend should not have direct communication with Supabase
Supabase on frontend is purely just for session management
Frontend should utilise Riverpod where appropriate