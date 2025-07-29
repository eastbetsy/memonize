-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS ensure_user_profile_exists_trigger ON auth.users;

-- Now we can safely drop the functions
DROP FUNCTION IF EXISTS create_user_profile_safe(uuid, text);
DROP FUNCTION IF EXISTS ensure_user_profile_exists();

-- Create a robust function to ensure user profile exists
CREATE OR REPLACE FUNCTION ensure_user_profile_exists()
RETURNS TRIGGER AS $$
DECLARE
  username_value text;
  profile_exists boolean;
BEGIN
  -- Extract username from metadata or email
  username_value := COALESCE(
    (NEW.raw_user_meta_data->>'username')::text,
    split_part(COALESCE(NEW.email, ''), '@', 1),
    'User'
  );

  -- Check if profile already exists to avoid conflicts
  SELECT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = NEW.id
  ) INTO profile_exists;

  -- Only create if it doesn't exist
  IF NOT profile_exists THEN
    -- Create user profile with default values
    INSERT INTO public.user_profiles (
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
      focus_areas,
      weekly_goal,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      username_value,
      1,
      0,
      0,
      100,
      0,
      0,
      '{}',
      'visual',
      NULL,
      20,
      now(),
      now()
    );

    -- Create default user preferences
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
      INSERT INTO public.user_preferences (
        user_id,
        theme_id,
        custom_settings,
        ai_preferences,
        created_at,
        updated_at
      ) VALUES (
        NEW.id,
        'cosmic',
        '{"fontSize": "medium", "dailyGoal": 4, "highContrast": false, "soundEffects": false, "notifications": true, "particleCount": 50, "reducedMotion": false, "backgroundEffects": true, "preferredStudyTime": "evening"}'::jsonb,
        '{"focusAreas": [], "reminderStyle": "gentle", "assistantEnabled": true, "insightFrequency": "daily"}'::jsonb,
        now(),
        now()
      )
      ON CONFLICT (user_id) DO NOTHING;
    END IF;
  END IF;

  -- Also ensure an entry exists in the public.users table
  INSERT INTO public.users (id, email, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.created_at,
    NEW.updated_at
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = EXCLUDED.updated_at;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or replace the create_user_profile_safe function
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
  auth_user_exists boolean;
BEGIN
  -- First check if auth.user exists
  SELECT EXISTS(
    SELECT 1 FROM auth.users WHERE id = p_user_id
  ) INTO auth_user_exists;
  
  IF NOT auth_user_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Auth user does not exist'
    );
  END IF;

  -- Use a transaction to ensure consistency
  BEGIN
    -- Ensure user exists in public.users table
    INSERT INTO public.users (id, email, created_at, updated_at)
    SELECT id, email, created_at, updated_at
    FROM auth.users
    WHERE id = p_user_id
    ON CONFLICT (id) DO NOTHING;
    
    -- Check if profile already exists
    IF EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE user_profiles.id = p_user_id
    ) THEN
      -- Update existing profile with username if needed
      UPDATE user_profiles
      SET 
        username = COALESCE(NULLIF(p_username, ''), username, 'User'),
        updated_at = now()
      WHERE id = p_user_id
      RETURNING to_jsonb(user_profiles.*) INTO result;
      
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
      weekly_goal,
      created_at,
      updated_at
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
      20,
      now(),
      now()
    )
    RETURNING to_jsonb(user_profiles.*) INTO result;

    -- Create default user preferences
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
      INSERT INTO user_preferences (
        user_id,
        theme_id,
        custom_settings,
        ai_preferences,
        created_at,
        updated_at
      ) VALUES (
        p_user_id,
        'cosmic',
        '{"fontSize": "medium", "dailyGoal": 4, "highContrast": false, "soundEffects": false, "notifications": true, "particleCount": 50, "reducedMotion": false, "backgroundEffects": true, "preferredStudyTime": "evening"}'::jsonb,
        '{"focusAreas": [], "reminderStyle": "gentle", "assistantEnabled": true, "insightFrequency": "daily"}'::jsonb,
        now(),
        now()
      )
      ON CONFLICT (user_id) DO NOTHING;
    END IF;

    RETURN jsonb_build_object(
      'success', true,
      'profile', result,
      'created', true
    );
  END;

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- Create a function for direct use during login
CREATE OR REPLACE FUNCTION login_user(
  p_email text,
  p_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  profile_result jsonb;
  user_profile jsonb;
BEGIN
  -- Create or update user profile
  SELECT * FROM create_user_profile_safe(p_user_id) INTO profile_result;
  
  -- If profile creation failed, return error
  IF (profile_result->>'success')::boolean = false THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Failed to ensure user profile exists: ' || (profile_result->>'error'),
      'auth_status', 'profile_error'
    );
  END IF;
  
  -- Get full user profile data
  SELECT to_jsonb(up.*) INTO user_profile
  FROM user_profiles up
  WHERE up.id = p_user_id;
  
  -- Return success with user profile data
  RETURN jsonb_build_object(
    'success', true,
    'profile', user_profile,
    'auth_status', 'authenticated'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'auth_status', 'error'
    );
END;
$$;

-- Now recreate the trigger with our new function
CREATE TRIGGER ensure_user_profile_exists_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_user_profile_exists();

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile_safe(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION login_user(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_user_profile_exists() TO service_role;

-- Fix any missing profiles for existing auth users
DO $$
DECLARE
  auth_user record;
BEGIN
  FOR auth_user IN
    SELECT id, email, created_at, raw_user_meta_data
    FROM auth.users
    WHERE id NOT IN (SELECT id FROM public.user_profiles)
  LOOP
    -- Call the ensure_user_profile_exists function manually
    INSERT INTO public.user_profiles (
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
      weekly_goal,
      created_at,
      updated_at
    ) VALUES (
      auth_user.id,
      COALESCE(
        (auth_user.raw_user_meta_data->>'username')::text,
        split_part(COALESCE(auth_user.email, ''), '@', 1),
        'User'
      ),
      1,
      0,
      0,
      100,
      0,
      0,
      '{}',
      'visual',
      20,
      auth_user.created_at,
      now()
    )
    ON CONFLICT (id) DO NOTHING;
    
    -- Also ensure public.users entry
    INSERT INTO public.users (id, email, created_at, updated_at)
    VALUES (
      auth_user.id,
      auth_user.email,
      auth_user.created_at,
      now()
    )
    ON CONFLICT (id) DO NOTHING;
  END LOOP;
END $$;