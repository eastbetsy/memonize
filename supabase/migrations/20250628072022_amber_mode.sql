/*
  # Add Missing Foreign Key Relationships to Deck Tables

  1. New Foreign Keys
    - `deck_messages.user_id` to `user_profiles.id` (if not exists)
    - `deck_assignments.created_by` to `user_profiles.id` (if not exists)
    - `deck_materials.created_by` to `user_profiles.id` (if not exists)
    - `deck_events.created_by` to `user_profiles.id` (if not exists)
    - `deck_submissions.graded_by` to `user_profiles.id` (if not exists)
  
  2. Benefits
    - Enables proper join queries through the Supabase API
    - Resolves "Could not find a relationship" errors
    - Ensures referential integrity for deck-related operations

  3. Safety Features
    - Uses conditional logic to only add constraints that don't exist yet
    - Appropriate ON DELETE behaviors for different relationships
    - Prevents duplicate constraint errors
*/

-- Use PL/pgSQL to conditionally add constraints only if they don't exist
DO $$
BEGIN
  -- Check if deck_messages.user_id constraint exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'deck_messages_user_id_fkey'
    AND table_name = 'deck_messages'
  ) THEN
    ALTER TABLE public.deck_messages
    ADD CONSTRAINT deck_messages_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;
  END IF;

  -- Check if deck_assignments.created_by constraint exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'deck_assignments_created_by_fkey'
    AND table_name = 'deck_assignments'
  ) THEN
    ALTER TABLE public.deck_assignments
    ADD CONSTRAINT deck_assignments_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
  END IF;

  -- Check if deck_materials.created_by constraint exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'deck_materials_created_by_fkey'
    AND table_name = 'deck_materials'
  ) THEN
    ALTER TABLE public.deck_materials
    ADD CONSTRAINT deck_materials_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
  END IF;

  -- Check if deck_events.created_by constraint exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'deck_events_created_by_fkey'
    AND table_name = 'deck_events'
  ) THEN
    ALTER TABLE public.deck_events
    ADD CONSTRAINT deck_events_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
  END IF;

  -- Check if deck_submissions.graded_by constraint exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'deck_submissions_graded_by_fkey'
    AND table_name = 'deck_submissions'
  ) THEN
    ALTER TABLE public.deck_submissions
    ADD CONSTRAINT deck_submissions_graded_by_fkey
    FOREIGN KEY (graded_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
  END IF;
END $$;