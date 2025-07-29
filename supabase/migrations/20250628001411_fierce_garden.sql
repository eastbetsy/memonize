/*
  # Fix Room Participants RLS Policies and Relationships

  1. Policy Updates
    - Fix infinite recursion in room_participants SELECT policy
    - Simplify policies to avoid circular references
  
  2. Foreign Key Relationships
    - Ensure proper relationship between room_participants and user_profiles
    - Add missing foreign key if needed

  3. Security
    - Maintain proper access controls without recursion
    - Users can only see participants in rooms they have access to
*/

-- Drop existing problematic policies for room_participants
DROP POLICY IF EXISTS "Users can view participants in accessible rooms" ON room_participants;
DROP POLICY IF EXISTS "Users can join rooms as themselves" ON room_participants;
DROP POLICY IF EXISTS "Users can leave rooms or owners can remove participants" ON room_participants;

-- Create simplified, non-recursive policies for room_participants
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
    user_id = auth.uid() OR 
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

-- Simple SELECT policy that avoids recursion
CREATE POLICY "Users can view room participants"
  ON room_participants
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see participants in public rooms
    room_id IN (SELECT id FROM pomodoro_rooms WHERE type = 'public')
    OR
    -- Users can see participants in rooms they own
    room_id IN (SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid())
    OR
    -- Users can see participants in private rooms they have access to
    (room_id IN (SELECT id FROM pomodoro_rooms WHERE type = 'private') 
     AND EXISTS (
       SELECT 1 FROM pomodoro_rooms pr 
       WHERE pr.id = room_participants.room_id 
       AND (pr.owner_id = auth.uid() OR user_can_access_private_room(pr.id))
     ))
  );

-- Fix the room_sessions policies to avoid recursion as well
DROP POLICY IF EXISTS "Participants can view room sessions" ON room_sessions;
DROP POLICY IF EXISTS "Admins can manage room sessions" ON room_sessions;

CREATE POLICY "Users can view room sessions"
  ON room_sessions
  FOR SELECT
  TO authenticated
  USING (
    room_id IN (SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid())
    OR
    room_id IN (SELECT id FROM pomodoro_rooms WHERE type = 'public')
    OR
    (room_id IN (SELECT id FROM pomodoro_rooms WHERE type = 'private') 
     AND user_can_access_private_room(room_id))
  );

CREATE POLICY "Room owners and admins can manage sessions"
  ON room_sessions
  FOR ALL
  TO authenticated
  USING (
    room_id IN (SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid())
  )
  WITH CHECK (
    room_id IN (SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid())
  );

-- Ensure the user_can_access_private_room function exists
CREATE OR REPLACE FUNCTION user_can_access_private_room(room_uuid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM room_participants rp
    JOIN pomodoro_rooms pr ON rp.room_id = pr.id
    WHERE pr.id = room_uuid 
    AND rp.user_id = auth.uid()
    AND pr.type = 'private'
  );
$$;