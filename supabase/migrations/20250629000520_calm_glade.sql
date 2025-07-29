/*
  # Add foreign key relationship between deck_members and user_profiles

  1. Changes
    - Add foreign key constraint from deck_members.user_id to user_profiles.id
    - This enables proper joins between deck_members and user_profiles tables

  2. Security
    - No changes to RLS policies needed
    - Existing policies remain intact

  3. Notes
    - This allows the frontend to properly fetch user profile data when loading deck members
    - Resolves the "Could not find a relationship" error in Supabase queries
*/

-- Add foreign key constraint from deck_members.user_id to user_profiles.id
ALTER TABLE deck_members 
ADD CONSTRAINT deck_members_user_profile_fkey 
FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE;