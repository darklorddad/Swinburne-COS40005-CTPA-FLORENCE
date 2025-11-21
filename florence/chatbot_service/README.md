# Florence Chatbot Microservice

A dedicated multi-tenant Python microservice for AI-powered health chatbot functionality, decoupled from the Flutter frontend.

## Overview

This service provides AI-powered conversational assistance for diabetes management by:
- Managing chat logic and conversation history
- Integrating with DeepSeek LLM for intelligent responses
- Fetching and aggregating patient health data
- Ensuring strict user data isolation and security

## Architecture

```
Flutter App → JWT Auth → Chatbot Service → Supabase Database
                                      ↓
                                 DeepSeek API
```

### Key Principles

1. **Multi-Tenant**: Handles multiple users concurrently with strict data isolation
2. **Stateless**: All conversation history stored in database
3. **Secure**: JWT authentication on every request
4. **Scalable**: Independent deployment and horizontal scaling

## Project Structure

```
chatbot_service/
├── main.py                    # FastAPI application entry point
├── config.py                  # Environment configuration
├── requirements.txt           # Python dependencies
├── database_schema.sql        # Supabase table schema and RLS policies
├── README.md                  # This file
├── routers/
│   ├── __init__.py
│   └── chat.py               # Chat API endpoints
├── services/
│   ├── __init__.py
│   ├── deepseek.py           # DeepSeek API integration
│   ├── health_data.py        # Health data aggregation
│   └── conversation.py       # Chat history management
├── models/
│   ├── __init__.py
│   ├── chat.py               # Chat data models
│   └── health.py             # Health data models
└── utils/
    ├── __init__.py
    └── auth.py               # JWT authentication middleware
```

## Installation

### Prerequisites

- Python 3.10 or higher
- Supabase account with configured database
- DeepSeek API key

### Setup Steps

1. **Navigate to the chatbot service directory:**
   ```bash
   cd florence/chatbot_service
   ```

2. **Create a virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment:**
   - Windows:
     ```bash
     venv\Scripts\activate
     ```
   - macOS/Linux:
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Configure environment variables:**

   Ensure the `.env` file in the project root contains:
   ```env
   # Supabase Configuration
   SUPABASE_URL="https://your-project.supabase.co"
   SUPABASE_SERVICE_KEY="your-service-role-key"
   SUPABASE_ANON_KEY="your-anon-key"

   # DeepSeek AI Configuration
   DEEPSEEK_API_KEY="your-deepseek-api-key"
   DEEPSEEK_BASE_URL="https://api.deepseek.com/v1"
   DEEPSEEK_MODEL="deepseek-chat"
   DEEPSEEK_TEMPERATURE=0.8
   DEEPSEEK_MAX_TOKENS=1000

   # Service Configuration
   SERVICE_HOST="0.0.0.0"
   SERVICE_PORT=8001

   # Health Context Configuration
   HEALTH_CONTEXT_DAYS=7
   ```

6. **Set up the database:**
   - Go to your Supabase project dashboard
   - Navigate to SQL Editor
   - Copy and execute the contents of `database_schema.sql`
   - This creates the `patient_chat_history` table with RLS policies

## Running the Service

### Development Mode

```bash
python main.py
```

or with uvicorn directly:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8001
```

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --workers 4
```

The service will be available at:
- API: `http://localhost:8001`
- Interactive Docs: `http://localhost:8001/docs`
- ReDoc: `http://localhost:8001/redoc`

## API Endpoints

### POST /chat/message
Send a message to the chatbot and receive an AI-powered response.

**Request:**
```json
{
  "message": "Why is my glucose high today?",
  "include_history": true
}
```

**Response:**
```json
{
  "message_id": "uuid-here",
  "role": "assistant",
  "content": "Based on your recent data showing an average of 145 mg/dL...",
  "timestamp": "2025-01-20T10:30:00Z",
  "context_used": {
    "latest_glucose": 152.0,
    "average_glucose_7d": 145.2,
    ...
  }
}
```

### GET /chat/history
Retrieve conversation history.

**Query Parameters:**
- `limit`: Max messages to retrieve (default: 50, max: 100)

**Response:**
```json
{
  "messages": [
    {
      "id": "uuid",
      "role": "user",
      "content": "...",
      "timestamp": "2025-01-20T10:25:00Z",
      "context": null
    },
    ...
  ],
  "total_count": 25
}
```

### DELETE /chat/history
Clear all conversation history for the authenticated patient.

**Response:**
```json
{
  "message": "Chat history cleared successfully",
  "cleared_count": 25
}
```

### GET /chat/health
Health check endpoint for the chat service.

## Authentication

All endpoints require a valid Supabase JWT token in the Authorization header:

```
Authorization: Bearer <jwt-token>
```

The service:
1. Validates the token with Supabase Auth
2. Extracts the patient ID
3. Ensures all queries are scoped to that patient

## Security Features

### User Data Isolation

- **JWT Validation**: Every request requires valid authentication
- **Patient Scoping**: All database queries filtered by patient_id
- **RLS Policies**: Database-level security ensures data separation
- **No Cross-Patient Access**: Impossible to access another patient's data

### Data Protection

- Service role key used only by backend (never exposed to clients)
- Row Level Security (RLS) on all database tables
- HTTPS in production (recommended)
- Rate limiting (recommended for production)

## Health Data Context

The chatbot automatically includes a 7-day health summary with each conversation:

- **Glucose Metrics**: Latest reading, 7-day average, time in range, hyper/hypo events
- **Blood Pressure**: Average systolic/diastolic readings
- **Activity**: Total activity minutes
- **Meal Data**: Meal logs with glucose context

This context is fetched from Supabase and formatted for the LLM prompt.

## LLM Integration

### DeepSeek Configuration

- **Model**: deepseek-chat
- **Temperature**: 0.8 (conversational, balanced creativity)
- **Max Tokens**: 1000
- **System Prompt**: Includes patient health context and safety guidelines

### Fallback Responses

If the DeepSeek API fails, the service returns helpful fallback responses to maintain user experience.

## Database Schema

### patient_chat_history Table

| Column      | Type           | Description                                  |
|-------------|----------------|----------------------------------------------|
| id          | UUID           | Primary key                                  |
| patient_id  | INTEGER        | Foreign key to patient_profiles              |
| role        | VARCHAR(20)    | 'user', 'assistant', or 'system'            |
| content     | TEXT           | Message content                              |
| timestamp   | TIMESTAMPTZ    | When message was sent                        |
| context     | JSONB          | Health context snapshot (optional)           |

### Row Level Security (RLS) Policies

- Patients can only access their own messages
- Clinicians can view messages of assigned patients
- Service role has full access for backend operations

## Testing

### Manual Testing with cURL

```bash
# Get a JWT token by logging in via your app or Supabase

# Send a chat message
curl -X POST http://localhost:8001/chat/message \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "What is my glucose trend?", "include_history": true}'

# Get chat history
curl -X GET http://localhost:8001/chat/history?limit=10 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Clear history
curl -X DELETE http://localhost:8001/chat/history \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Testing with Interactive Docs

Visit `http://localhost:8001/docs` and use the "Authorize" button to enter your JWT token.

## Deployment

### Docker Deployment (Recommended)

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```

Build and run:
```bash
docker build -t florence-chatbot .
docker run -p 8001:8001 --env-file .env florence-chatbot
```

### Cloud Deployment

Suitable for:
- Google Cloud Run
- AWS ECS/Fargate
- Azure Container Instances
- Heroku
- Railway
- Render

## Monitoring

### Logging

The service logs:
- Patient interactions (message IDs only, not content)
- API errors and failures
- DeepSeek API calls
- Authentication failures

### Metrics to Track

- Request latency
- DeepSeek API response time
- Error rates by endpoint
- Token usage (DeepSeek)
- Active conversations

## Troubleshooting

### Common Issues

1. **"Invalid authentication token"**
   - Ensure JWT is valid and not expired
   - Check Supabase URL and service key in .env
   - Verify user is a patient (not clinician)

2. **"Patient profile not found"**
   - Ensure user has a patient profile in patient_profiles table
   - Check user_id matches between auth.users and patient_profiles

3. **"DeepSeek API error"**
   - Verify API key is valid
   - Check internet connectivity
   - Review DeepSeek API status
   - Fallback responses will be used automatically

4. **"No health data available"**
   - Ensure patient has monitor_data records
   - Check date range (default: last 7 days)
   - Verify patient_id matches in database

## Development

### Adding New Endpoints

1. Create endpoint in `routers/chat.py`
2. Add authentication dependency: `patient: dict = Depends(get_current_patient)`
3. Use `patient["patient_id"]` to scope database queries
4. Add endpoint to router

### Modifying Health Context

Edit `services/health_data.py` → `get_health_context()` method.

### Customizing LLM Prompts

Edit `services/deepseek.py` → `build_system_prompt()` method.

## Migration from Flutter

The chatbot was originally implemented in Flutter. This service replicates that functionality while:

1. Centralizing chat logic on the backend
2. Enabling multi-device conversation sync
3. Reducing Flutter app complexity
4. Improving scalability and maintenance

## License

Part of the Florence Digital Health Platform.

## Support

For issues or questions, contact the development team or create an issue in the project repository.
