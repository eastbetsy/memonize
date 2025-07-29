/*
  # Ensure User Profiles Exist Before Join Operations

  1. Problem
    - Users can't join decks because of foreign key constraint violations
    - The "deck_members_user_profile_fkey" constraint requires a user_profile entry
    - Users are attempting to join decks before their user_profile is created

  2. Solution
    - Create a function to automatically ensure user profile exists 
    - Add trigger to create missing user profiles when auth users are accessed
    - Create a function for safely joining a deck that creates profile if needed

  3. Changes
    - New safe_join_deck function to handle profile creation + deck joining in a transaction
    - Fix foreign key violations by ensuring user_profiles exist
    - Add helper function for frontend to use when joining decks
*/

-- Create a function to ensure user profile exists and join deck
CREATE OR REPLACE FUNCTION safe_join_deck(
  p_user_id uuid,
  p_deck_id uuid,
  p_role text DEFAULT 'student'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  profile_result jsonb;
  membership_exists boolean;
  result jsonb;
BEGIN
  -- First check if user is already a member
  SELECT EXISTS (
    SELECT 1 FROM deck_members 
    WHERE user_id = p_user_id AND deck_id = p_deck_id
  ) INTO membership_exists;
  
  -- If already a member, return early
  IF membership_exists THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Already a member of this deck',
      'joined', false
    );
  END IF;
  
  -- Ensure user profile exists using the create_user_profile_safe function
  SELECT * FROM create_user_profile_safe(p_user_id) INTO profile_result;
  
  IF (profile_result->>'success')::boolean = false THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Failed to create user profile: ' || (profile_result->>'error')
    );
  END IF;
  
  -- Now it's safe to join the deck
  BEGIN
    INSERT INTO deck_members (deck_id, user_id, role)
    VALUES (p_deck_id, p_user_id, p_role);
    
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Successfully joined deck',
      'joined', true,
      'role', p_role
    );
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Failed to join deck: ' || SQLERRM
    );
  END;
END;
$$;

-- Create a function to ensure a valid user_profile exists for any auth user
CREATE OR REPLACE FUNCTION ensure_user_profile_exists()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user profile already exists
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = NEW.id
  ) THEN
    -- Create profile with default values
    INSERT INTO user_profiles (
      id, 
      username,
      level,
      current_xp,
      xp_to_next_level,
      experience,
      study_streak,
      total_study_time,
      learning_style,
      weekly_goal,
      achievements
    ) VALUES (
      NEW.id,
      COALESCE(
        (NEW.raw_user_meta_data->>'username')::text, 
        split_part(COALESCE(NEW.email, ''), '@', 1),
        'User'
      ),
      1,  -- level
      0,  -- current_xp
      100, -- xp_to_next_level
      0,  -- experience
      0,  -- study_streak
      0,  -- total_study_time
      'visual', -- learning_style
      20, -- weekly_goal
      '{}'::text[] -- achievements
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to ensure user profile exists when a user is created or updated
DO $$
BEGIN
  -- Drop existing trigger if it exists
  DROP TRIGGER IF EXISTS ensure_user_profile_exists_trigger ON auth.users;
  
  -- Create new trigger
  CREATE TRIGGER ensure_user_profile_exists_trigger
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION ensure_user_profile_exists();
END $$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION safe_join_deck(uuid, uuid, text) TO authenticated;