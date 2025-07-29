/*
  # Fix User Signup Process

  1. Problem
    - New user signups fail with "Database error saving new user"
    - Missing trigger to create user profiles when auth users are created
    - Foreign key constraints failing due to missing user profiles
  
  2. Solution
    - Drop existing functions to avoid conflicts
    - Create function to handle new user creation
    - Create trigger to automatically create profiles on signup
    - Add safe profile creation function for manual use
    - Ensure proper permissions are granted
*/

-- First drop all existing functions to avoid conflicts
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.ensure_user_profile_exists() CASCADE;
DROP FUNCTION IF EXISTS public.create_user_profile_safe(UUID, TEXT) CASCADE;

-- Create or replace the function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert new user profile with safe defaults
  INSERT INTO public.user_profiles (
    id,
    username,
    level,
    experience,
    study_streak,
    total_study_time,
    last_study_date,
    achievements,
    learning_style,
    focus_areas,
    weekly_goal,
    current_xp,
    xp_to_next_level,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    1,
    0,
    0,
    0,
    NULL,
    '{}',
    'visual',
    NULL,
    20,
    0,
    100,
    NOW(),
    NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Profile already exists, that's fine
    RETURN NEW;
  WHEN OTHERS THEN
    -- Log error but don't prevent user creation
    RAISE WARNING 'Could not create user profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to automatically create user profile when new user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Also create or replace a function to ensure user profile exists (for existing users)
CREATE OR REPLACE FUNCTION public.ensure_user_profile_exists()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user profile exists, if not create it
  IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid()) THEN
    INSERT INTO public.user_profiles (
      id,
      username,
      level,
      experience,
      study_streak,
      total_study_time,
      last_study_date,
      achievements,
      learning_style,
      focus_areas,
      weekly_goal,
      current_xp,
      xp_to_next_level,
      created_at,
      updated_at
    ) VALUES (
      auth.uid(),
      'User',
      1,
      0,
      0,
      0,
      NULL,
      '{}',
      'visual',
      NULL,
      20,
      0,
      100,
      NOW(),
      NOW()
    );
  END IF;
  
  RETURN COALESCE(NEW, OLD);
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't prevent operation
    RAISE WARNING 'Could not ensure user profile exists for user %: %', auth.uid(), SQLERRM;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to handle user profile creation that can be called manually if needed
CREATE OR REPLACE FUNCTION public.create_user_profile_safe(user_id UUID, user_email TEXT DEFAULT NULL)
RETURNS jsonb AS $$
DECLARE
  profile_id UUID;
  result jsonb;
BEGIN
  -- Try to insert the user profile
  INSERT INTO public.user_profiles (
    id,
    username,
    level,
    experience,
    study_streak,
    total_study_time,
    last_study_date,
    achievements,
    learning_style,
    focus_areas,
    weekly_goal,
    current_xp,
    xp_to_next_level,
    created_at,
    updated_at
  ) VALUES (
    user_id,
    COALESCE(split_part(user_email, '@', 1), 'User'),
    1,
    0,
    0,
    0,
    NULL,
    '{}',
    'visual',
    NULL,
    20,
    0,
    100,
    NOW(),
    NOW()
  ) RETURNING id INTO profile_id;
  
  SELECT jsonb_build_object(
    'success', true,
    'profile_id', profile_id,
    'created', true
  ) INTO result;
  
  RETURN result;
EXCEPTION
  WHEN unique_violation THEN
    -- Profile already exists, return existing id
    SELECT id INTO profile_id FROM public.user_profiles WHERE id = user_id;
    
    SELECT jsonb_build_object(
      'success', true,
      'profile_id', profile_id,
      'created', false
    ) INTO result;
    
    RETURN result;
  WHEN OTHERS THEN
    -- Return error information
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'detail', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.ensure_user_profile_exists() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.create_user_profile_safe(UUID, TEXT) TO authenticated, anon;