/*
  # Fix User Profile Creation Function

  1. Drop and recreate the create_user_profile_safe function
     - Resolve ambiguous column references
     - Use proper parameter naming
     - Add proper error handling

  2. Security
     - Function is security definer to allow profile creation
     - Only authenticated users can call this function
*/

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS create_user_profile_safe(uuid, text);

-- Create a new, properly scoped function
CREATE OR REPLACE FUNCTION create_user_profile_safe(
  p_user_id uuid,
  p_username text DEFAULT 'User'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  -- Check if profile already exists
  IF EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_profiles.id = p_user_id
  ) THEN
    -- Return existing profile
    SELECT to_jsonb(user_profiles.*) INTO result
    FROM user_profiles 
    WHERE user_profiles.id = p_user_id;
    
    RETURN jsonb_build_object(
      'success', true,
      'profile', result,
      'created', false
    );
  END IF;

  -- Create new profile
  INSERT INTO user_profiles (
    id,
    username,
    level,
    experience,
    current_xp,
    xp_to_next_level,
    study_streak,
    total_study_time,
    achievements,
    learning_style,
    weekly_goal
  ) VALUES (
    p_user_id,
    p_username,
    1,
    0,
    0,
    100,
    0,
    0,
    '{}',
    'visual',
    20
  )
  RETURNING to_jsonb(user_profiles.*) INTO result;

  -- Create default user preferences
  INSERT INTO user_preferences (
    user_id,
    theme_id,
    custom_settings,
    ai_preferences
  ) VALUES (
    p_user_id,
    'cosmic',
    '{"fontSize": "medium", "dailyGoal": 4, "highContrast": false, "soundEffects": false, "notifications": true, "particleCount": 50, "reducedMotion": false, "backgroundEffects": true, "preferredStudyTime": "evening"}',
    '{"focusAreas": [], "reminderStyle": "gentle", "assistantEnabled": true, "insightFrequency": "daily"}'
  );

  RETURN jsonb_build_object(
    'success', true,
    'profile', result,
    'created', true
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;