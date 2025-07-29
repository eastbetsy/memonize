/*
  # Create flashcards table

  1. New Tables
    - `flashcards`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `term` (text, required)
      - `definition` (text, required)
      - `difficulty` (text, enum: easy/medium/hard)
      - `confidence_level` (integer, 1-5 scale)
      - `source_note_id` (uuid, optional reference to notes)
      - `last_reviewed` (timestamp, optional)
      - `review_count` (integer, default 0)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `flashcards` table
    - Add policy for authenticated users to manage their own flashcards
*/

CREATE TABLE IF NOT EXISTS flashcards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  term text NOT NULL,
  definition text NOT NULL,
  difficulty text CHECK (difficulty IN ('easy', 'medium', 'hard')) DEFAULT 'medium',
  confidence_level integer CHECK (confidence_level >= 1 AND confidence_level <= 5) DEFAULT 1,
  source_note_id uuid REFERENCES notes(id) ON DELETE SET NULL,
  last_reviewed timestamptz,
  review_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own flashcards"
  ON flashcards
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own flashcards"
  ON flashcards
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own flashcards"
  ON flashcards
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own flashcards"
  ON flashcards
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS flashcards_user_id_idx ON flashcards(user_id);
CREATE INDEX IF NOT EXISTS flashcards_difficulty_idx ON flashcards(difficulty);
CREATE INDEX IF NOT EXISTS flashcards_confidence_level_idx ON flashcards(confidence_level);
CREATE INDEX IF NOT EXISTS flashcards_source_note_id_idx ON flashcards(source_note_id);
CREATE INDEX IF NOT EXISTS flashcards_last_reviewed_idx ON flashcards(last_reviewed);