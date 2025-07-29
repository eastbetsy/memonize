/*
  # Fix Auth Trigger Issues

  1. Database Changes
    - Remove problematic auth trigger that causes signup failures
    - Create safer user profile creation mechanism
    - Fix RLS policies for proper user profile access

  2. Security
    - Ensure proper RLS policies are in place
    - Use safe profile creation without direct auth table access
*/

-- Remove the problematic trigger that causes signup failures
DROP TRIGGER IF EXISTS create_user_profile_trigger ON auth.users;
DROP FUNCTION IF EXISTS create_user_profile();

-- Create a safer function that can be called from the client
CREATE OR REPLACE FUNCTION create_user_profile_safe(user_id uuid, username text DEFAULT NULL)
RETURNS void AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username)
  VALUES (
    user_id,
    COALESCE(username, 'User')
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile_safe(uuid, text) TO authenticated;

-- Ensure user_profiles table exists with proper structure
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text,
  level integer DEFAULT 1,
  experience integer DEFAULT 0,
  study_streak integer DEFAULT 0,
  total_study_time integer DEFAULT 0,
  last_study_date date,
  achievements text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ensure RLS is enabled and policies are correct
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies and recreate them safely
DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.user_profiles;

-- Create proper RLS policies
CREATE POLICY "Users can view their own profile"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create updated_at trigger for user_profiles
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS user_profiles_username_idx ON public.user_profiles(username);
CREATE INDEX IF NOT EXISTS user_profiles_level_idx ON public.user_profiles(level);
CREATE INDEX IF NOT EXISTS user_profiles_experience_idx ON public.user_profiles(experience);