/*
  # Reset and Sync User Analytics

  1. New Functions
    - `reset_user_analytics` - Resets a user's analytics data while preserving content
    - `sync_user_analytics` - Recalculates analytics based on actual user activity
    - `reset_and_sync_all_analytics` - Admin function to reset and sync all users
    - `daily_analytics_sync` - Automated function to keep analytics in sync

  2. Analytics Reset Process
    - Clears study insights while preserving content (notes, flashcards)
    - Resets XP, levels, and streak data
    - Optionally reset achievements

  3. Analytics Sync Process
    - Counts user content (notes, flashcards, sessions)
    - Calculates proper XP, level, and streak based on activity dates
    - Regenerates insights from actual usage data
*/

-- Function to reset analytics for a specific user
CREATE OR REPLACE FUNCTION reset_user_analytics(target_user_id uuid, reset_achievements boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
  deleted_insights integer;
  reset_achievements_count integer := 0;
  deleted_focus_sessions integer;
  deleted_study_sessions integer;
BEGIN
  -- Delete study insights
  DELETE FROM study_insights 
  WHERE user_id = target_user_id
  RETURNING count(*) INTO deleted_insights;
  
  -- Optionally reset achievements
  IF reset_achievements THEN
    DELETE FROM achievements
    WHERE user_id = target_user_id
    RETURNING count(*) INTO reset_achievements_count;
  END IF;

  -- Reset focus sessions data
  DELETE FROM focus_sessions
  WHERE user_id = target_user_id
  RETURNING count(*) INTO deleted_focus_sessions;
  
  -- Reset study sessions data
  DELETE FROM study_sessions
  WHERE user_id = target_user_id
  RETURNING count(*) INTO deleted_study_sessions;
  
  -- Reset XP transactions
  DELETE FROM xp_transactions
  WHERE user_id = target_user_id;
  
  -- Reset user profile analytics data
  UPDATE user_profiles
  SET 
    level = 1,
    current_xp = 0,
    xp_to_next_level = 100,
    experience = 0,
    study_streak = 0,
    total_study_time = 0,
    last_study_date = NULL
  WHERE id = target_user_id;

  -- Build result object
  result := jsonb_build_object(
    'success', true,
    'user_id', target_user_id,
    'reset_insights', deleted_insights,
    'reset_achievements', reset_achievements_count,
    'reset_focus_sessions', deleted_focus_sessions,
    'reset_study_sessions', deleted_study_sessions
  );

  RETURN result;
END;
$$;

-- Function to sync analytics based on actual user activity
CREATE OR REPLACE FUNCTION sync_user_analytics(target_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
  notes_count integer;
  flashcards_count integer;
  calculated_level integer;
  calculated_xp integer := 0;
  calculated_study_time integer := 0;
  calculated_streak integer := 0;
  most_recent_date date := NULL;
  consecutive_days integer := 0;
  xp_to_next_level integer := 100;
  content_xp integer := 0;
  sessions_xp integer := 0;
  submissions_xp integer := 0;
BEGIN
  -- Count notes
  SELECT count(*) INTO notes_count
  FROM notes
  WHERE user_id = target_user_id;
  
  -- Count flashcards
  SELECT count(*) INTO flashcards_count
  FROM flashcards
  WHERE user_id = target_user_id;
  
  -- Calculate base XP for content creation
  content_xp := (notes_count * 30) + (flashcards_count * 15);
  
  -- Add XP from study sessions if they exist
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'study_sessions') THEN
    SELECT COALESCE(sum(score), 0) INTO sessions_xp
    FROM study_sessions
    WHERE user_id = target_user_id;
    
    -- Also calculate total study time
    SELECT COALESCE(sum(duration), 0) INTO calculated_study_time
    FROM study_sessions
    WHERE user_id = target_user_id;
  END IF;
  
  -- Add XP from deck submissions if they exist
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'deck_submissions') THEN
    SELECT COALESCE(sum(grade), 0) INTO submissions_xp
    FROM deck_submissions
    WHERE user_id = target_user_id AND grade IS NOT NULL;
  END IF;
  
  -- Sum all XP sources
  calculated_xp := content_xp + sessions_xp + submissions_xp;
  
  -- Ensure minimum XP of 0
  IF calculated_xp < 0 THEN
    calculated_xp := 0;
  END IF;
  
  -- Calculate level based on XP (100 for first level, +50 for each level after)
  calculated_level := 1;
  DECLARE
    temp_xp integer := calculated_xp;
    level_threshold integer := 100;
  BEGIN
    WHILE temp_xp >= level_threshold LOOP
      temp_xp := temp_xp - level_threshold;
      calculated_level := calculated_level + 1;
      level_threshold := 100 + ((calculated_level - 1) * 50);
    END LOOP;
  END;
  
  -- Calculate XP to next level
  xp_to_next_level := 100 + ((calculated_level - 1) * 50);
  
  -- Calculate streak by analyzing consecutive days of activity
  WITH active_days AS (
    -- Combine all activity sources
    SELECT DISTINCT date(created_at) as activity_date
    FROM notes
    WHERE user_id = target_user_id
    UNION
    SELECT DISTINCT date(created_at) as activity_date
    FROM flashcards
    WHERE user_id = target_user_id
    UNION
    SELECT DISTINCT date(created_at) as activity_date
    FROM study_sessions
    WHERE user_id = target_user_id
  ),
  ordered_days AS (
    SELECT 
      activity_date,
      lag(activity_date, 1) OVER (ORDER BY activity_date) as prev_date
    FROM active_days
    ORDER BY activity_date DESC
  ),
  streak_groups AS (
    SELECT
      activity_date,
      prev_date,
      CASE 
        WHEN prev_date IS NULL OR activity_date - prev_date = 1 THEN 0
        ELSE 1
      END as new_group
    FROM ordered_days
  ),
  grouped_days AS (
    SELECT
      activity_date,
      sum(new_group) OVER (ORDER BY activity_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as group_id
    FROM streak_groups
  )
  SELECT 
    count(*) as streak_length,
    max(activity_date) as latest_date
  INTO 
    calculated_streak,
    most_recent_date
  FROM grouped_days
  WHERE group_id = 0
  GROUP BY group_id;
  
  -- If most recent activity is not today or yesterday, streak is broken
  IF most_recent_date IS NOT NULL AND most_recent_date < (CURRENT_DATE - interval '1 day') THEN
    calculated_streak := 0;
  END IF;

  -- Update user profile with calculated values
  UPDATE user_profiles
  SET 
    level = calculated_level,
    current_xp = calculated_xp - (
      -- Calculate XP for completed levels
      SELECT COALESCE(sum(100 + ((level - 1) * 50)), 0) 
      FROM generate_series(1, greatest(1, calculated_level - 1)) as level
    ),
    experience = calculated_xp, -- Total experience
    xp_to_next_level = xp_to_next_level,
    study_streak = calculated_streak,
    total_study_time = calculated_study_time,
    last_study_date = most_recent_date
  WHERE id = target_user_id;

  -- Generate insights based on updated data
  IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_study_insights') THEN
    PERFORM generate_study_insights(target_user_id);
  END IF;
  
  -- Return results
  result := jsonb_build_object(
    'success', true,
    'user_id', target_user_id,
    'notes_count', notes_count,
    'flashcards_count', flashcards_count,
    'calculated_level', calculated_level,
    'calculated_xp', calculated_xp,
    'current_level_xp', calculated_xp - (
      -- Calculate XP for completed levels
      SELECT COALESCE(sum(100 + ((level - 1) * 50)), 0) 
      FROM generate_series(1, greatest(1, calculated_level - 1)) as level
    ),
    'xp_to_next', xp_to_next_level,
    'calculated_study_time', calculated_study_time,
    'calculated_streak', calculated_streak,
    'most_recent_activity', most_recent_date
  );

  RETURN result;
END;
$$;

-- Function to reset and sync all users
CREATE OR REPLACE FUNCTION reset_and_sync_all_analytics()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_record record;
  users_processed integer := 0;
  users_failed integer := 0;
  result jsonb;
BEGIN
  -- Process all users
  FOR user_record IN 
    SELECT id FROM user_profiles
  LOOP
    BEGIN
      -- Reset and then sync
      PERFORM reset_user_analytics(user_record.id, false);
      PERFORM sync_user_analytics(user_record.id);
      users_processed := users_processed + 1;
    EXCEPTION WHEN OTHERS THEN
      users_failed := users_failed + 1;
      -- Continue with next user on error
      CONTINUE;
    END;
  END LOOP;

  -- Return results
  result := jsonb_build_object(
    'success', true,
    'users_processed', users_processed,
    'users_failed', users_failed,
    'timestamp', CURRENT_TIMESTAMP
  );

  RETURN result;
END;
$$;

-- Function to run daily to sync analytics
CREATE OR REPLACE FUNCTION daily_analytics_sync()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_record record;
  users_processed integer := 0;
  result jsonb;
BEGIN
  -- Process all users
  FOR user_record IN 
    SELECT id FROM user_profiles
  LOOP
    BEGIN
      -- Only sync, don't reset
      PERFORM sync_user_analytics(user_record.id);
      users_processed := users_processed + 1;
    EXCEPTION WHEN OTHERS THEN
      -- Continue with next user on error
      CONTINUE;
    END;
  END LOOP;

  -- Return results
  result := jsonb_build_object(
    'success', true,
    'users_processed', users_processed,
    'timestamp', CURRENT_TIMESTAMP
  );

  RETURN result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION reset_user_analytics(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION sync_user_analytics(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION reset_and_sync_all_analytics() TO authenticated;
GRANT EXECUTE ON FUNCTION daily_analytics_sync() TO authenticated;