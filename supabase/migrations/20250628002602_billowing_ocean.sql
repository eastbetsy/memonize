/*
  # Final Pomodoro Rooms Fix

  1. Database Changes
    - Ensure all foreign key relationships are properly established
    - Fix any remaining constraint issues
    - Add missing indexes for performance

  2. Security
    - Verify all RLS policies are working correctly
    - Remove any potential for infinite recursion
*/

-- Ensure the room_participants to user_profiles relationship exists
DO $$
BEGIN
  -- Add foreign key constraint if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'room_participants_user_profile_fkey'
    AND table_name = 'room_participants'
  ) THEN
    ALTER TABLE room_participants
    ADD CONSTRAINT room_participants_user_profile_fkey
    FOREIGN KEY (user_id) REFERENCES user_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Ensure the pomodoro_rooms to user_profiles relationship exists for owner
DO $$
BEGIN
  -- Add foreign key constraint if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'pomodoro_rooms_owner_profile_fkey'
    AND table_name = 'pomodoro_rooms'
  ) THEN
    ALTER TABLE pomodoro_rooms
    ADD CONSTRAINT pomodoro_rooms_owner_profile_fkey
    FOREIGN KEY (owner_id) REFERENCES user_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Create additional helpful indexes
CREATE INDEX IF NOT EXISTS pomodoro_rooms_room_code_idx ON pomodoro_rooms(room_code) WHERE room_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS room_participants_user_profile_idx ON room_participants(user_id);

-- Ensure our helper function is optimized
CREATE OR REPLACE FUNCTION user_can_access_private_room(room_uuid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM room_participants 
    WHERE room_id = room_uuid 
    AND user_id = auth.uid()
  );
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION user_can_access_private_room(uuid) TO authenticated;

-- Verify all policies are clean and non-recursive
-- Drop and recreate room_participants policies to ensure they're correct
DROP POLICY IF EXISTS "Users can view room participants" ON room_participants;

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
    -- Users can see participants in private rooms they're part of
    (room_id IN (SELECT id FROM pomodoro_rooms WHERE type = 'private') 
     AND user_can_access_private_room(room_id))
  );