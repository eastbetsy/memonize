# Backend Setup

This project requires a Python FastAPI backend to handle API requests.

## Quick Start

1. **Install backend dependencies:**
   ```bash
   npm run backend:install
   ```

2. **Set up environment variables:**
   - Copy `backend/.env.example` to `backend/.env`
   - Add your Supabase URL and service role key

3. **Start the backend server:**
   ```bash
   npm run backend
   ```

4. **Start both frontend and backend together:**
   ```bash
   npm run dev:full
   ```

## Manual Setup

If you prefer to set up manually:

```bash
# Navigate to backend directory
cd backend

# Install Python dependencies
pip install -r requirements.txt

# Start the server
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

# Memonize Backend

The Memonize app requires a backend server for handling API requests related to notes, flashcards, and user progression.

## Troubleshooting

- **Connection refused errors**: Make sure the backend server is running on port 8000
- **Import errors**: Ensure all Python dependencies are installed
- **Database errors**: Check your Supabase configuration in the .env file

The backend server needs to be running for the frontend to work properly, as it handles all API requests for notes, flashcards, and XP management.