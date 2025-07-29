/*
  # Create missing users table

  1. New Tables
    - `users` - Public table that mirrors auth.users for foreign key references
      - `id` (uuid, primary key)
      - `email` (text, unique)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Functions
    - Drop and recreate create_user_profile_safe to avoid parameter conflict
    - Create trigger function to sync auth.users with public.users

  3. Security
    - Enable RLS on users table
    - Add policies for authenticated users

  4. Data Migration
    - Backfill existing auth users into users table
*/

-- Create the users table that other tables reference
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY,
  email text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read their own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at, updated_at)
  VALUES (new.id, new.email, new.created_at, new.updated_at)
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = EXCLUDED.updated_at;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user record when auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- Drop existing function first to avoid parameter default conflict
DROP FUNCTION IF EXISTS create_user_profile_safe(uuid, text);

-- Create function for safe user profile creation (used in AuthContext)
CREATE FUNCTION create_user_profile_safe(user_id uuid, username text)
RETURNS void AS $$
BEGIN
  -- First ensure user exists in users table
  INSERT INTO public.users (id, email, created_at, updated_at)
  SELECT user_id, COALESCE(auth.email, ''), auth.created_at, auth.updated_at
  FROM auth.users auth
  WHERE auth.id = user_id
  ON CONFLICT (id) DO NOTHING;
  
  -- Then create or update user profile
  INSERT INTO public.user_profiles (id, username, created_at, updated_at)
  VALUES (user_id, username, now(), now())
  ON CONFLICT (id) DO UPDATE SET
    username = COALESCE(EXCLUDED.username, user_profiles.username),
    updated_at = now();
    
  -- Create default user preferences if they don't exist
  INSERT INTO public.user_preferences (user_id, created_at, updated_at)
  VALUES (user_id, now(), now())
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile_safe(uuid, text) TO authenticated;

-- Backfill existing auth users into users table
INSERT INTO public.users (id, email, created_at, updated_at)
SELECT id, COALESCE(email, ''), created_at, updated_at
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  updated_at = EXCLUDED.updated_at;

-- Ensure update_updated_at_column function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update the updated_at trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();