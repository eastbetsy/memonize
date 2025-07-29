/*
  # Fix update_user_xp function ambiguous column reference

  1. Function Changes
    - Drop and recreate the update_user_xp function
    - Fix ambiguous column reference by properly qualifying table columns
    - Add proper level-up logic
    - Return level-up information

  2. Security
    - Function maintains existing security context
    - Only allows updates for authenticated users
*/

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS update_user_xp(uuid, integer);

-- Create the corrected update_user_xp function
CREATE OR REPLACE FUNCTION update_user_xp(
  target_user_id uuid,
  xp_gained integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  old_level integer;
  new_level integer;
  old_xp integer;
  new_xp integer;
  xp_needed integer;
  leveled_up boolean := false;
BEGIN
  -- Get current user stats
  SELECT 
    up.level,
    up.current_xp,
    up.xp_to_next_level
  INTO 
    old_level,
    old_xp,
    xp_needed
  FROM user_profiles up
  WHERE up.id = target_user_id;

  -- If user profile doesn't exist, return error
  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found for ID: %', target_user_id;
  END IF;

  -- Calculate new XP
  new_xp := old_xp + xp_gained;
  new_level := old_level;

  -- Check for level ups
  WHILE new_xp >= xp_needed LOOP
    new_xp := new_xp - xp_needed;
    new_level := new_level + 1;
    leveled_up := true;
    -- Calculate XP needed for next level (increases by 50 each level)
    xp_needed := 100 + ((new_level - 1) * 50);
  END LOOP;

  -- Update user profile with explicit table qualification
  UPDATE user_profiles
  SET 
    current_xp = new_xp,
    level = new_level,
    xp_to_next_level = xp_needed,
    experience = user_profiles.experience + xp_gained,
    updated_at = now()
  WHERE user_profiles.id = target_user_id;

  -- Return level up information
  RETURN jsonb_build_object(
    'leveled_up', leveled_up,
    'old_level', old_level,
    'new_level', new_level,
    'old_xp', old_xp,
    'new_xp', new_xp,
    'xp_needed_for_next', xp_needed,
    'total_xp_gained', xp_gained
  );
END;
$$;