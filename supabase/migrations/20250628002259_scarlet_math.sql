/*
  # Add foreign key relationship between room_participants and user_profiles

  1. Changes
    - Add foreign key constraint from room_participants.user_id to user_profiles.id
    - This enables direct querying of user profile data from room participants

  2. Security
    - No RLS changes needed as existing policies remain intact
    - Maintains data integrity through proper foreign key relationships
*/

-- Add foreign key constraint from room_participants.user_id to user_profiles.id
-- This allows PostgREST to resolve the relationship for nested queries
ALTER TABLE room_participants 
ADD CONSTRAINT room_participants_user_profile_fkey 
FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE;