/*
  # Fix RLS Infinite Recursion for Pomodoro Rooms

  1. Problem
    - Infinite recursion detected in policies for pomodoro_rooms table
    - Circular dependency between pomodoro_rooms and room_participants policies
    - pomodoro_rooms policy checks room_participants, which checks pomodoro_rooms

  2. Solution
    - Drop all existing problematic policies
    - Create new simplified policies without circular dependencies
    - Use direct authorization checks without cross-table references where possible

  3. Changes
    - Simplified pomodoro_rooms policies (public rooms + owned rooms only)
    - Simplified room_participants policies (participants can see other participants)
    - Remove complex nested queries that cause recursion
*/

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "Anyone can view public rooms - simplified" ON pomodoro_rooms;
DROP POLICY IF EXISTS "Users can create rooms" ON pomodoro_rooms;
DROP POLICY IF EXISTS "Room owners can update their rooms" ON pomodoro_rooms;
DROP POLICY IF EXISTS "Room owners can delete their rooms" ON pomodoro_rooms;

DROP POLICY IF EXISTS "Users can view room participants - simplified" ON room_participants;
DROP POLICY IF EXISTS "Users can join rooms" ON room_participants;
DROP POLICY IF EXISTS "Users can leave rooms or room owners can remove participants - simplified" ON room_participants;

DROP POLICY IF EXISTS "Users can view sessions in their rooms" ON room_sessions;
DROP POLICY IF EXISTS "Room admins can manage sessions" ON room_sessions;

-- Create new simplified pomodoro_rooms policies without recursion
CREATE POLICY "Public rooms and owned rooms viewable"
  ON pomodoro_rooms
  FOR SELECT
  TO authenticated
  USING (
    type = 'public' OR owner_id = auth.uid()
  );

CREATE POLICY "Users can create their own rooms"
  ON pomodoro_rooms
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their rooms"
  ON pomodoro_rooms
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can delete their rooms"
  ON pomodoro_rooms
  FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- Create new simplified room_participants policies
CREATE POLICY "Users can view participants in accessible rooms"
  ON room_participants
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see participants if they are also a participant
    room_id IN (
      SELECT room_id FROM room_participants WHERE user_id = auth.uid()
    )
    OR
    -- Room owners can see all participants (direct check, no recursion)
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can join rooms as themselves"
  ON room_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave rooms or owners can remove participants"
  ON room_participants
  FOR DELETE
  TO authenticated
  USING (
    -- Users can remove themselves
    user_id = auth.uid()
    OR
    -- Room owners can remove any participant (direct check)
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

-- Create new simplified room_sessions policies
CREATE POLICY "Participants can view room sessions"
  ON room_sessions
  FOR SELECT
  TO authenticated
  USING (
    -- Users who are participants can see sessions
    room_id IN (
      SELECT room_id FROM room_participants WHERE user_id = auth.uid()
    )
    OR
    -- Room owners can see sessions (direct check)
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage room sessions"
  ON room_sessions
  FOR ALL
  TO authenticated
  USING (
    -- Room owners can manage sessions
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
    OR
    -- Room admins can manage sessions
    room_id IN (
      SELECT room_id FROM room_participants 
      WHERE user_id = auth.uid() AND is_admin = true
    )
  )
  WITH CHECK (
    -- Same conditions for WITH CHECK
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
    OR
    room_id IN (
      SELECT room_id FROM room_participants 
      WHERE user_id = auth.uid() AND is_admin = true
    )
  );

-- Add a separate policy to allow viewing private rooms for participants
-- This is done through a function to avoid recursion
CREATE OR REPLACE FUNCTION user_can_access_private_room(room_uuid uuid)
RETURNS boolean AS $$
BEGIN
  -- Check if user is a participant in the room
  RETURN EXISTS (
    SELECT 1 FROM room_participants 
    WHERE room_id = room_uuid AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION user_can_access_private_room(uuid) TO authenticated;

-- Update pomodoro_rooms policy to include private room access through function
DROP POLICY "Public rooms and owned rooms viewable" ON pomodoro_rooms;

CREATE POLICY "Accessible rooms viewable"
  ON pomodoro_rooms
  FOR SELECT
  TO authenticated
  USING (
    type = 'public' 
    OR owner_id = auth.uid()
    OR (type = 'private' AND user_can_access_private_room(id))
  );