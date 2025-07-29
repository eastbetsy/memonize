/*
  # Fix deck_messages foreign key relationship

  1. Foreign Key Addition
    - Add foreign key constraint from deck_messages.user_id to user_profiles.id
    - This allows direct joins between deck_messages and user_profiles tables
  
  2. Security
    - Maintains existing RLS policies
    - No changes to existing permissions
  
  This migration fixes the error "Could not find a relationship between 'deck_messages' and 'user_profiles'" 
  by establishing the necessary foreign key relationship that allows Supabase to perform the join operation.
*/

-- Add foreign key constraint from deck_messages.user_id to user_profiles.id
-- This enables direct joins between deck_messages and user_profiles tables
ALTER TABLE deck_messages 
ADD CONSTRAINT deck_messages_user_profile_fkey 
FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE;