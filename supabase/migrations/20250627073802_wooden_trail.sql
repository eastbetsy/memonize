/*
  # Fix Pomodoro Rooms User Profiles Relationship

  1. Database Changes
    - Add foreign key constraint between pomodoro_rooms.owner_id and user_profiles.id
    - This allows direct querying of user profile information from pomodoro rooms

  2. Security
    - No changes to existing RLS policies
    - Maintains existing security model

  This migration fixes the Supabase query error by establishing the proper relationship
  between pomodoro rooms and user profiles for fetching owner usernames.
*/

-- Add foreign key constraint to link pomodoro_rooms.owner_id directly to user_profiles.id
-- This enables the Supabase query to join these tables directly
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'pomodoro_rooms_owner_profile_fkey'
    AND table_name = 'pomodoro_rooms'
  ) THEN
    ALTER TABLE public.pomodoro_rooms
    ADD CONSTRAINT pomodoro_rooms_owner_profile_fkey
    FOREIGN KEY (owner_id) REFERENCES public.user_profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;