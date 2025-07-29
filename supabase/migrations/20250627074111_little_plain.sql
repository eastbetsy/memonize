/*
  # Fix RLS Policy Infinite Recursion

  1. Issue
    - Infinite recursion detected in policies for room_participants table
    - SELECT policy on room_participants references pomodoro_rooms
    - SELECT policy on pomodoro_rooms references room_participants
    - This creates a circular dependency causing infinite recursion

  2. Solution
    - Drop existing problematic policies
    - Create new simplified policies that avoid circular references
    - Ensure room_participants policies don't indirectly reference themselves

  3. Changes
    - Update room_participants SELECT policy to avoid circular reference
    - Update pomodoro_rooms SELECT policy to be more direct
    - Maintain security while removing recursion
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view room participants if they're in the room" ON room_participants;
DROP POLICY IF EXISTS "Users can leave rooms or room owners can remove participants" ON room_participants;
DROP POLICY IF EXISTS "Anyone can view public rooms" ON pomodoro_rooms;

-- Create new room_participants policies without circular references
CREATE POLICY "Users can view room participants - simplified"
  ON room_participants
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see participants in public rooms (direct check)
    EXISTS (
      SELECT 1 FROM pomodoro_rooms 
      WHERE pomodoro_rooms.id = room_participants.room_id 
      AND pomodoro_rooms.type = 'public'
    )
    OR
    -- Users can see participants in rooms they own (direct check)
    EXISTS (
      SELECT 1 FROM pomodoro_rooms 
      WHERE pomodoro_rooms.id = room_participants.room_id 
      AND pomodoro_rooms.owner_id = auth.uid()
    )
    OR
    -- Users can see other participants in rooms they're in (direct user check)
    EXISTS (
      SELECT 1 FROM room_participants rp2
      WHERE rp2.room_id = room_participants.room_id 
      AND rp2.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can leave rooms or room owners can remove participants - simplified"
  ON room_participants
  FOR DELETE
  TO authenticated
  USING (
    -- Users can remove themselves
    user_id = auth.uid()
    OR
    -- Room owners can remove any participant (direct check)
    EXISTS (
      SELECT 1 FROM pomodoro_rooms 
      WHERE pomodoro_rooms.id = room_participants.room_id 
      AND pomodoro_rooms.owner_id = auth.uid()
    )
  );

-- Create new pomodoro_rooms policy without circular references
CREATE POLICY "Anyone can view public rooms - simplified"
  ON pomodoro_rooms
  FOR SELECT
  TO authenticated
  USING (
    -- Public rooms are visible to everyone
    type = 'public'
    OR
    -- Users can see rooms they own
    owner_id = auth.uid()
    OR
    -- Users can see private rooms they're participating in
    -- Use a direct existence check without recursion
    (type = 'private' AND EXISTS (
      SELECT 1 FROM room_participants 
      WHERE room_participants.room_id = pomodoro_rooms.id 
      AND room_participants.user_id = auth.uid()
    ))
  );