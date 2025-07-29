/*
  # Add Updated At Triggers

  1. Functions
    - `update_updated_at_column()` - Automatically updates the updated_at timestamp

  2. Triggers
    - Add triggers to notes and user_profiles tables to auto-update timestamps
    - Only create triggers if tables exist

  3. Safety Features
    - Check for table existence before creating triggers
    - Use CREATE OR REPLACE for functions
    - Drop existing triggers safely
*/

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Only create trigger for notes table if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notes' AND table_schema = 'public') THEN
    -- Drop existing trigger if it exists
    DROP TRIGGER IF EXISTS update_notes_updated_at ON public.notes;
    
    -- Create new trigger
    CREATE TRIGGER update_notes_updated_at
      BEFORE UPDATE ON public.notes
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Only create trigger for user_profiles table if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
    -- Drop existing trigger if it exists
    DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
    
    -- Create new trigger
    CREATE TRIGGER update_user_profiles_updated_at
      BEFORE UPDATE ON public.user_profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;