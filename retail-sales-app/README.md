# Retail Sales Intelligence App

A FastAPI-based web application for retail sales intelligence, providing KPIs, chat functionality, and integration with Databricks Genie, Vector Search RAG, and agentic AI.

## Features

- **Health Check**: `/api/health` endpoint for application status
- **KPIs Dashboard**: `/api/kpis` endpoint with mocked retail metrics
- **Chat Interface**: `/api/chat` endpoint for AI-powered conversations (placeholder for Phase 4-6)
- **Web UI**: HTML interface served from templates and static files

## Project Structure

```
retail-sales-app/
├── app.py              # Main FastAPI application
├── app.yaml            # Databricks App configuration
├── requirements.txt    # Python dependencies
├── README.md           # This file
├── static/             # Static assets (CSS, JS)
│   ├── css/
│   └── js/
└── templates/          # Jinja2 HTML templates
    └── index.html
```

## Setup

1. **Clone or navigate to the project directory**:
   ```bash
   cd retail-sales-app
   ```

2. **Create a virtual environment** (optional but recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

## Running the Application

Start the FastAPI server with auto-reload:

```bash
uvicorn app:app --reload --host 127.0.0.1 --port 8000
```

Or if your main file is named differently:

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Visit `http://127.0.0.1:8000` in your browser to access the web interface.

## API Endpoints

- `GET /`: Home page with web interface
- `GET /api/health`: Health check
- `GET /api/kpis`: Retail KPIs (currently mocked)
- `POST /api/chat`: Chat endpoint (placeholder)

## Development Phases

This app follows a phased development approach:

- **Phase 2**: App shell with mocked endpoints
- **Phase 4**: Integrate with Databricks Genie for structured queries
- **Phase 5**: Add Vector Search RAG for document/context questions
- **Phase 6**: Implement agentic AI for complex mixed queries

## Deployment

This app is designed to be deployed as a Databricks App. Use the `app.yaml` configuration for deployment to Databricks.

## Requirements

- Python 3.8+
- FastAPI
- Uvicorn
- Jinja2
- Pydantic

See `requirements.txt` for full dependencies.