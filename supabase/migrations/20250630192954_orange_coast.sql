/*
  # Fix Function Return Type Error

  1. Problem
    - Cannot change return type of existing function 'create_user_profile_safe'
    - Previous migrations defined this function to return jsonb
    - New migration is trying to redefine it to return UUID

  2. Solution
    - Drop existing functions first to avoid conflicts
    - Create new functions with consistent return types
    - Ensure proper error handling and permissions
*/

-- First drop all related functions to avoid conflicts
DROP FUNCTION IF EXISTS public.create_user_profile_safe(uuid, text);
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.ensure_user_profile_exists() CASCADE;

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
  
  -- Also create a users record
  INSERT INTO public.users (id, email, created_at, updated_at)
  VALUES (NEW.id, NEW.email, NEW.created_at, NEW.updated_at)
  ON CONFLICT (id) DO NOTHING;
  
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

-- Create a function to ensure user profile exists (for existing users)
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

-- Create a function to handle user profile creation that can be called manually
-- This MUST return jsonb to maintain compatibility with existing code
CREATE OR REPLACE FUNCTION public.create_user_profile_safe(user_id UUID, username TEXT DEFAULT NULL)
RETURNS jsonb AS $$
DECLARE
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
    COALESCE(username, 'User'),
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
  
  -- Also create a users record if needed
  INSERT INTO public.users (id, email, created_at, updated_at)
  SELECT id, email, created_at, updated_at
  FROM auth.users
  WHERE id = user_id
  ON CONFLICT (id) DO NOTHING;
  
  result := jsonb_build_object(
    'success', true,
    'profile_id', user_id,
    'created', true
  );
  
  RETURN result;
EXCEPTION
  WHEN unique_violation THEN
    -- Profile already exists, return existing id
    result := jsonb_build_object(
      'success', true,
      'profile_id', user_id,
      'created', false
    );
    
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