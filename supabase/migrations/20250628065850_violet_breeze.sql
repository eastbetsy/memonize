/*
  # Create Decks Classroom System

  1. New Tables
    - `decks` - Classroom containers similar to Google Classroom
    - `deck_assignments` - Assignments with deadlines and materials
    - `deck_members` - Student/teacher membership in decks
    - `deck_submissions` - Assignment submissions
    - `deck_materials` - Study materials for decks
    - `deck_events` - Calendar events for decks
    - `deck_messages` - Chat messages for deck communication

  2. Security
    - Enable RLS on all tables
    - Policies for teachers to manage decks and assignments
    - Policies for students to view and submit assignments
*/

-- Create decks table (classrooms)
CREATE TABLE IF NOT EXISTS decks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  banner_url text,
  color text DEFAULT 'cosmic',
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  enrollment_code text UNIQUE NOT NULL,
  is_archived boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create deck_members table (students and teachers)
CREATE TABLE IF NOT EXISTS deck_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id uuid REFERENCES decks(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role text CHECK (role IN ('teacher', 'student', 'assistant')) NOT NULL,
  joined_at timestamptz DEFAULT now(),
  UNIQUE(deck_id, user_id)
);

-- Create deck_assignments table
CREATE TABLE IF NOT EXISTS deck_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id uuid REFERENCES decks(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text DEFAULT '',
  instructions text DEFAULT '',
  due_date timestamptz,
  points integer DEFAULT 100,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status text CHECK (status IN ('draft', 'published', 'archived')) DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create deck_submissions table
CREATE TABLE IF NOT EXISTS deck_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id uuid REFERENCES deck_assignments(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content text DEFAULT '',
  flashcards_created integer DEFAULT 0,
  attachments jsonb DEFAULT '[]'::jsonb,
  status text CHECK (status IN ('draft', 'submitted', 'late', 'graded')) DEFAULT 'draft',
  grade integer,
  feedback text,
  graded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  submitted_at timestamptz,
  graded_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(assignment_id, user_id)
);

-- Create deck_materials table
CREATE TABLE IF NOT EXISTS deck_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id uuid REFERENCES decks(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text DEFAULT '',
  content_type text CHECK (content_type IN ('notes', 'flashcards', 'link', 'text', 'reference')) NOT NULL,
  content text DEFAULT '',
  linked_resources jsonb DEFAULT '[]'::jsonb,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create deck_events table
CREATE TABLE IF NOT EXISTS deck_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id uuid REFERENCES decks(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text DEFAULT '',
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  location text DEFAULT '',
  is_recurring boolean DEFAULT false,
  recurrence_rule text, -- iCal format recurrence rule
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create deck_messages table
CREATE TABLE IF NOT EXISTS deck_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id uuid REFERENCES decks(id) ON DELETE CASCADE NOT NULL,
  channel text DEFAULT 'general',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message text NOT NULL,
  is_announcement boolean DEFAULT false,
  is_pinned boolean DEFAULT false,
  parent_id uuid REFERENCES deck_messages(id) ON DELETE SET NULL, -- For threaded replies
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Generate random enrollment code function
CREATE OR REPLACE FUNCTION generate_enrollment_code()
RETURNS text AS $$
BEGIN
  RETURN upper(substring(md5(random()::text) from 1 for 6));
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate enrollment code
CREATE OR REPLACE FUNCTION set_enrollment_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.enrollment_code IS NULL THEN
    NEW.enrollment_code := generate_enrollment_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_deck_enrollment_code
  BEFORE INSERT ON decks
  FOR EACH ROW
  EXECUTE FUNCTION set_enrollment_code();

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_decks_updated_at
  BEFORE UPDATE ON decks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deck_assignments_updated_at
  BEFORE UPDATE ON deck_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deck_submissions_updated_at
  BEFORE UPDATE ON deck_submissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deck_materials_updated_at
  BEFORE UPDATE ON deck_materials
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deck_events_updated_at
  BEFORE UPDATE ON deck_events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS on all tables
ALTER TABLE decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for decks
CREATE POLICY "Deck owners can manage their decks"
  ON decks
  FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Members can view decks they belong to"
  ON decks
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT deck_id FROM deck_members WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for deck_members
CREATE POLICY "Deck owners can manage all members"
  ON deck_members
  FOR ALL
  TO authenticated
  USING (
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can view members in their decks"
  ON deck_members
  FOR SELECT
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id FROM deck_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join decks"
  ON deck_members
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can leave decks"
  ON deck_members
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- RLS Policies for deck_assignments
CREATE POLICY "Teachers can manage assignments"
  ON deck_assignments
  FOR ALL
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
    OR
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
    OR
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Students can view published assignments"
  ON deck_assignments
  FOR SELECT
  TO authenticated
  USING (
    status = 'published'
    AND
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for deck_submissions
CREATE POLICY "Teachers can manage all submissions"
  ON deck_submissions
  FOR ALL
  TO authenticated
  USING (
    assignment_id IN (
      SELECT id FROM deck_assignments
      WHERE deck_id IN (
        SELECT deck_id FROM deck_members 
        WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
      )
      OR deck_id IN (
        SELECT id FROM decks WHERE owner_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    assignment_id IN (
      SELECT id FROM deck_assignments
      WHERE deck_id IN (
        SELECT deck_id FROM deck_members 
        WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
      )
      OR deck_id IN (
        SELECT id FROM decks WHERE owner_id = auth.uid()
      )
    )
  );

CREATE POLICY "Students can manage their own submissions"
  ON deck_submissions
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- RLS Policies for deck_materials
CREATE POLICY "Teachers can manage materials"
  ON deck_materials
  FOR ALL
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
    OR
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
    OR
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Students can view materials"
  ON deck_materials
  FOR SELECT
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for deck_events
CREATE POLICY "Teachers can manage events"
  ON deck_events
  FOR ALL
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
    OR
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
    OR
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Students can view events"
  ON deck_events
  FOR SELECT
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for deck_messages
CREATE POLICY "Members can send messages in their decks"
  ON deck_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid()
    )
    AND user_id = auth.uid()
  );

CREATE POLICY "Only teachers can make announcements"
  ON deck_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (is_announcement = false) 
    OR 
    (
      is_announcement = true AND
      deck_id IN (
        SELECT deck_id FROM deck_members
        WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
      )
      OR
      deck_id IN (
        SELECT id FROM decks WHERE owner_id = auth.uid()
      )
    )
  );

CREATE POLICY "Members can view messages in their decks"
  ON deck_messages
  FOR SELECT
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own messages"
  ON deck_messages
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Teachers can delete any message"
  ON deck_messages
  FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
    OR
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS decks_owner_id_idx ON decks(owner_id);
CREATE INDEX IF NOT EXISTS deck_members_deck_id_idx ON deck_members(deck_id);
CREATE INDEX IF NOT EXISTS deck_members_user_id_idx ON deck_members(user_id);
CREATE INDEX IF NOT EXISTS deck_assignments_deck_id_idx ON deck_assignments(deck_id);
CREATE INDEX IF NOT EXISTS deck_submissions_assignment_id_idx ON deck_submissions(assignment_id);
CREATE INDEX IF NOT EXISTS deck_submissions_user_id_idx ON deck_submissions(user_id);
CREATE INDEX IF NOT EXISTS deck_materials_deck_id_idx ON deck_materials(deck_id);
CREATE INDEX IF NOT EXISTS deck_events_deck_id_idx ON deck_events(deck_id);
CREATE INDEX IF NOT EXISTS deck_messages_deck_id_idx ON deck_messages(deck_id);
CREATE INDEX IF NOT EXISTS deck_messages_created_at_idx ON deck_messages(created_at);