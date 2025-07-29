/*
  # Fix for moderation logs user profile reference

  1. Problem
    - RoomModerationPanel component fails with "Cannot read properties of null (reading 'username')"
    - This happens when trying to access moderator_profiles.username when moderator_profiles is null
    - This could occur when a moderator user has been deleted but their moderation actions remain

  2. Solution
    - Add a trigger to remove deleted user references in moderation logs
    - Ensure proper NULL handling for moderation logs
    - Clean up any orphaned moderation logs where moderator_id is not found in user_profiles
*/

-- First update any existing moderation logs that have null moderator profiles
-- Replace them with the AI moderator
UPDATE moderation_logs
SET moderator_id = '00000000-0000-0000-0000-000000000001'
WHERE moderator_id NOT IN (
  SELECT id FROM user_profiles
)
AND moderator_id IS NOT NULL;

-- Ensure proper deletion behavior when a user is deleted
CREATE OR REPLACE FUNCTION clean_up_moderation_references()
RETURNS TRIGGER AS $$
BEGIN
  -- When a user is deleted, set their moderation actions to AI moderator
  UPDATE moderation_logs
  SET moderator_id = '00000000-0000-0000-0000-000000000001'
  WHERE moderator_id = OLD.id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists
DROP TRIGGER IF EXISTS clean_moderation_logs_on_user_delete ON auth.users;

-- Create the trigger
CREATE TRIGGER clean_moderation_logs_on_user_delete
  BEFORE DELETE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION clean_up_moderation_references();

-- In the future, we'll use a safer query that handles NULL values for moderator_profiles
COMMENT ON FUNCTION clean_up_moderation_references() IS 
'When a user is deleted, this function updates moderation logs to attribute their actions to the AI moderator instead of leaving null references';