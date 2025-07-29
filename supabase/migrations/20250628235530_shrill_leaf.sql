/*
  # Fix foreign key relationships for deck assignments and materials

  1. Changes
     - Update deck_assignments foreign key to reference user_profiles instead of auth.users
     - Update deck_materials foreign key to reference user_profiles instead of auth.users
  
  2. Security
     - Maintains existing RLS policies
     - Preserves data integrity
*/

-- Drop existing foreign key constraints
ALTER TABLE deck_assignments 
DROP CONSTRAINT IF EXISTS deck_assignments_created_by_fkey;

ALTER TABLE deck_materials 
DROP CONSTRAINT IF EXISTS deck_materials_created_by_fkey;

-- Add new foreign key constraints pointing to user_profiles
ALTER TABLE deck_assignments 
ADD CONSTRAINT deck_assignments_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL;

ALTER TABLE deck_materials 
ADD CONSTRAINT deck_materials_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL;