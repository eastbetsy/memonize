/*
  # Add foreign key relationship between decks and user_profiles

  1. Changes
     - Add foreign key constraint from decks.owner_id to user_profiles.id
     - This allows querying owner username from user_profiles table
  
  2. Security
     - Maintains existing data integrity
     - Keeps existing auth.users foreign key for authentication
*/

-- Add foreign key constraint to link decks.owner_id to user_profiles.id
-- This enables querying the owner's username from user_profiles
ALTER TABLE decks 
ADD CONSTRAINT decks_owner_profile_fkey 
FOREIGN KEY (owner_id) REFERENCES user_profiles(id) ON DELETE CASCADE;