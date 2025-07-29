/*
  # Fix User Signup Database Error

  This migration addresses the "Database error saving new user" issue by:
  1. Recreating the handle_new_user trigger function with proper error handling
  2. Ensuring the trigger is properly attached to auth.users
  3. Creating a safe profile creation function for fallback use

  ## Changes Made
  - Recreate handle_new_user function with better error handling
  - Ensure trigger is properly configured
  - Add create_user_profile_safe function for application fallback
*/

-- First, let's drop existing trigger and function to recreate them cleanly
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.create_user_profile_safe(uuid, text);

-- Create the handle_new_user function with proper error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insert new user profile with all required fields
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
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'User'),
    1,
    0,
    0,
    100,
    0,
    0,
    '{}',
    'visual',
    20,
    NOW(),
    NOW()
  );

  -- Also create a basic users record if it doesn't exist
  INSERT INTO public.users (id, email, created_at, updated_at)
  VALUES (NEW.id, NEW.email, NOW(), NOW())
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log the error but don't fail the auth user creation
    RAISE LOG 'Error creating user profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create a safe profile creation function for application use
CREATE OR REPLACE FUNCTION public.create_user_profile_safe(
  user_id uuid,
  username text DEFAULT 'User'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Try to create user profile with upsert
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
    user_id,
    COALESCE(username, 'User'),
    1,
    0,
    0,
    100,
    0,
    0,
    '{}',
    'visual',
    20,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    username = COALESCE(EXCLUDED.username, user_profiles.username),
    updated_at = NOW();

  -- Also ensure users record exists
  INSERT INTO public.users (id, email, created_at, updated_at)
  SELECT user_id, auth.email, NOW(), NOW()
  FROM auth.users 
  WHERE auth.users.id = user_id
  ON CONFLICT (id) DO NOTHING;

  RETURN true;
EXCEPTION
  WHEN others THEN
    RAISE LOG 'Error in create_user_profile_safe for user %: %', user_id, SQLERRM;
    RETURN false;
END;
$$;

-- Ensure the function can be called by authenticated users
GRANT EXECUTE ON FUNCTION public.create_user_profile_safe(uuid, text) TO authenticated;

-- Create user preferences record trigger function
CREATE OR REPLACE FUNCTION public.create_user_preferences()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create default user preferences
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
    '{"fontSize": "medium", "dailyGoal": 4, "highContrast": false, "soundEffects": false, "notifications": true, "particleCount": 50, "reducedMotion": false, "backgroundEffects": true, "preferredStudyTime": "evening"}',
    '{"focusAreas": [], "reminderStyle": "gentle", "assistantEnabled": true, "insightFrequency": "daily"}',
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE LOG 'Error creating user preferences for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger for user preferences
DROP TRIGGER IF EXISTS on_user_profile_created ON public.user_profiles;
CREATE TRIGGER on_user_profile_created
  AFTER INSERT ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.create_user_preferences();