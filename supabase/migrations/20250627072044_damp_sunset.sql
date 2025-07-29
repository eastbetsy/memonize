/*
  # Create study sessions table

  1. New Tables
    - `study_sessions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `session_type` (text, enum: flashcards/memoquest/notes)
      - `duration` (integer, minutes)
      - `score` (integer, optional)
      - `questions_answered` (integer, default 0)
      - `correct_answers` (integer, default 0)
      - `flashcards_reviewed` (integer, default 0)
      - `notes_created` (integer, default 0)
      - `session_data` (jsonb, optional for storing additional data)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `study_sessions` table
    - Add policy for authenticated users to manage their own sessions
*/

CREATE TABLE IF NOT EXISTS study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  session_type text CHECK (session_type IN ('flashcards', 'memoquest', 'notes', 'study_group')) NOT NULL,
  duration integer DEFAULT 0, -- in minutes
  score integer DEFAULT 0,
  questions_answered integer DEFAULT 0,
  correct_answers integer DEFAULT 0,
  flashcards_reviewed integer DEFAULT 0,
  notes_created integer DEFAULT 0,
  session_data jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own study sessions"
  ON study_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own study sessions"
  ON study_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own study sessions"
  ON study_sessions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS study_sessions_user_id_idx ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS study_sessions_type_idx ON study_sessions(session_type);
CREATE INDEX IF NOT EXISTS study_sessions_created_at_idx ON study_sessions(created_at DESC);