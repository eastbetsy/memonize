/*
  # Pomodoro Rooms Database Schema

  1. New Tables
    - `pomodoro_rooms`
      - `id` (uuid, primary key)
      - `name` (text, room name)
      - `description` (text, room description)
      - `type` (text, 'private' or 'public')
      - `tags` (text array, for filtering)
      - `focus_mode` (text, focus mode type)
      - `max_participants` (integer, max room size)
      - `current_participants` (integer, current count)
      - `is_active` (boolean, if session is running)
      - `owner_id` (uuid, room creator)
      - `timer_settings` (jsonb, timer configuration)
      - `room_code` (text, for private room access)
      - `created_at` (timestamp)
    
    - `room_participants`
      - `id` (uuid, primary key)
      - `room_id` (uuid, foreign key)
      - `user_id` (uuid, foreign key)
      - `joined_at` (timestamp)
      - `is_admin` (boolean)
    
    - `room_sessions`
      - `id` (uuid, primary key)
      - `room_id` (uuid, foreign key)
      - `session_type` (text, 'work', 'break', 'long_break')
      - `duration` (integer, in minutes)
      - `start_time` (timestamp)
      - `end_time` (timestamp)
      - `is_active` (boolean)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create pomodoro_rooms table
CREATE TABLE IF NOT EXISTS pomodoro_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  type text CHECK (type IN ('private', 'public')) DEFAULT 'public',
  tags text[] DEFAULT '{}',
  focus_mode text CHECK (focus_mode IN ('classic', 'extended', 'short_burst', 'custom')) DEFAULT 'classic',
  max_participants integer DEFAULT 10 CHECK (max_participants > 0 AND max_participants <= 50),
  current_participants integer DEFAULT 0,
  is_active boolean DEFAULT false,
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  timer_settings jsonb DEFAULT '{"work_duration": 25, "short_break": 5, "long_break": 15, "sessions_until_long_break": 4}',
  room_code text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create room_participants table
CREATE TABLE IF NOT EXISTS room_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  joined_at timestamptz DEFAULT now(),
  is_admin boolean DEFAULT false,
  UNIQUE(room_id, user_id)
);

-- Create room_sessions table
CREATE TABLE IF NOT EXISTS room_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  session_type text CHECK (session_type IN ('work', 'short_break', 'long_break')) NOT NULL,
  duration integer NOT NULL, -- in minutes
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE pomodoro_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_sessions ENABLE ROW LEVEL SECURITY;

-- Pomodoro Rooms Policies
CREATE POLICY "Anyone can view public rooms"
  ON pomodoro_rooms
  FOR SELECT
  TO authenticated
  USING (type = 'public' OR owner_id = auth.uid() OR id IN (
    SELECT room_id FROM room_participants WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can create rooms"
  ON pomodoro_rooms
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Room owners can update their rooms"
  ON pomodoro_rooms
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Room owners can delete their rooms"
  ON pomodoro_rooms
  FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- Room Participants Policies
CREATE POLICY "Users can view room participants if they're in the room"
  ON room_participants
  FOR SELECT
  TO authenticated
  USING (room_id IN (
    SELECT id FROM pomodoro_rooms 
    WHERE type = 'public' OR owner_id = auth.uid() OR id IN (
      SELECT room_id FROM room_participants WHERE user_id = auth.uid()
    )
  ));

CREATE POLICY "Users can join rooms"
  ON room_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave rooms or room owners can remove participants"
  ON room_participants
  FOR DELETE
  TO authenticated
  USING (
    auth.uid() = user_id OR 
    room_id IN (SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid())
  );

-- Room Sessions Policies
CREATE POLICY "Users can view sessions in their rooms"
  ON room_sessions
  FOR SELECT
  TO authenticated
  USING (room_id IN (
    SELECT room_id FROM room_participants WHERE user_id = auth.uid()
  ) OR room_id IN (
    SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Room admins can manage sessions"
  ON room_sessions
  FOR ALL
  TO authenticated
  USING (
    room_id IN (SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()) OR
    room_id IN (SELECT room_id FROM room_participants WHERE user_id = auth.uid() AND is_admin = true)
  )
  WITH CHECK (
    room_id IN (SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()) OR
    room_id IN (SELECT room_id FROM room_participants WHERE user_id = auth.uid() AND is_admin = true)
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS pomodoro_rooms_type_idx ON pomodoro_rooms(type);
CREATE INDEX IF NOT EXISTS pomodoro_rooms_focus_mode_idx ON pomodoro_rooms(focus_mode);
CREATE INDEX IF NOT EXISTS pomodoro_rooms_tags_idx ON pomodoro_rooms USING GIN(tags);
CREATE INDEX IF NOT EXISTS pomodoro_rooms_owner_id_idx ON pomodoro_rooms(owner_id);
CREATE INDEX IF NOT EXISTS pomodoro_rooms_is_active_idx ON pomodoro_rooms(is_active);
CREATE INDEX IF NOT EXISTS room_participants_room_id_idx ON room_participants(room_id);
CREATE INDEX IF NOT EXISTS room_participants_user_id_idx ON room_participants(user_id);
CREATE INDEX IF NOT EXISTS room_sessions_room_id_idx ON room_sessions(room_id);
CREATE INDEX IF NOT EXISTS room_sessions_is_active_idx ON room_sessions(is_active);

-- Function to generate room codes
CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS text AS $$
BEGIN
  RETURN upper(substr(md5(random()::text), 1, 6));
END;
$$ LANGUAGE plpgsql;

-- Function to update participant count
CREATE OR REPLACE FUNCTION update_participant_count()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE pomodoro_rooms 
    SET current_participants = current_participants + 1
    WHERE id = NEW.room_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE pomodoro_rooms 
    SET current_participants = current_participants - 1
    WHERE id = OLD.room_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update participant count
CREATE TRIGGER update_room_participant_count
  AFTER INSERT OR DELETE ON room_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_participant_count();

-- Add updated_at trigger for pomodoro_rooms
CREATE TRIGGER update_pomodoro_rooms_updated_at
  BEFORE UPDATE ON pomodoro_rooms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();