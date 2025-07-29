/*
  # Enhance MemoQuest Application Features

  1. New Tables
    - `user_preferences` - Store personalized settings and theme preferences
    - `ai_interactions` - Track AI assistant conversations and context
    - `learning_sessions` - Enhanced session tracking with detailed analytics
    - `achievements` - User achievement system with progress tracking
    - `study_insights` - AI-generated learning insights and recommendations

  2. Enhanced Tables
    - Add columns to existing tables for better functionality
    - Improve indexes and constraints for performance

  3. AI and Analytics Support
    - Functions for calculating learning analytics
    - Triggers for automatic insight generation
    - Better data structure for AI recommendations
*/

-- Create user_preferences table for theme and settings customization
CREATE TABLE IF NOT EXISTS user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  theme_id text DEFAULT 'cosmic',
  custom_settings jsonb DEFAULT '{
    "reducedMotion": false,
    "highContrast": false,
    "soundEffects": false,
    "backgroundEffects": true,
    "particleCount": 50,
    "fontSize": "medium",
    "notifications": true,
    "dailyGoal": 4,
    "preferredStudyTime": "evening"
  }'::jsonb,
  ai_preferences jsonb DEFAULT '{
    "assistantEnabled": true,
    "insightFrequency": "daily",
    "reminderStyle": "gentle",
    "focusAreas": []
  }'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- Create ai_interactions table for tracking AI assistant usage
CREATE TABLE IF NOT EXISTS ai_interactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  session_id uuid DEFAULT gen_random_uuid(),
  interaction_type text CHECK (interaction_type IN ('question', 'suggestion', 'insight', 'reminder')) NOT NULL,
  user_message text,
  ai_response text,
  context_data jsonb DEFAULT '{}',
  feedback_rating integer CHECK (feedback_rating >= 1 AND feedback_rating <= 5),
  created_at timestamptz DEFAULT now()
);

-- Create enhanced learning_sessions table for detailed analytics
CREATE TABLE IF NOT EXISTS learning_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  session_type text CHECK (session_type IN ('notes', 'flashcards', 'memoquest', 'pomodoro', 'study_group')) NOT NULL,
  subject_area text,
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  duration_minutes integer DEFAULT 0,
  goals_set text[],
  goals_completed text[],
  performance_metrics jsonb DEFAULT '{}', -- accuracy, speed, engagement, etc.
  mood_before text CHECK (mood_before IN ('excited', 'focused', 'tired', 'stressed', 'neutral')),
  mood_after text CHECK (mood_after IN ('accomplished', 'frustrated', 'confident', 'tired', 'motivated')),
  notes text,
  ai_insights text[],
  created_at timestamptz DEFAULT now()
);

-- Create achievements table for gamification
CREATE TABLE IF NOT EXISTS achievements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  achievement_type text NOT NULL,
  achievement_name text NOT NULL,
  description text NOT NULL,
  criteria_met jsonb NOT NULL, -- The specific criteria that were met
  experience_gained integer DEFAULT 0,
  rarity text CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')) DEFAULT 'common',
  unlocked_at timestamptz DEFAULT now(),
  displayed boolean DEFAULT false -- Whether user has seen the achievement notification
);

-- Create study_insights table for AI-generated recommendations
CREATE TABLE IF NOT EXISTS study_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  insight_type text CHECK (insight_type IN ('pattern', 'recommendation', 'warning', 'encouragement', 'optimization')) NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  data_source text[], -- Which data sources were used to generate this insight
  confidence_score real CHECK (confidence_score >= 0 AND confidence_score <= 1) DEFAULT 0.5,
  priority text CHECK (priority IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  action_suggested text,
  dismissed boolean DEFAULT false,
  acted_upon boolean DEFAULT false,
  generated_at timestamptz DEFAULT now(),
  valid_until timestamptz DEFAULT (now() + interval '7 days')
);

-- Add enhanced columns to existing tables

-- Enhance notes table with AI features
DO $$
BEGIN
  -- Add AI analysis columns to notes if they don't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'ai_summary') THEN
    ALTER TABLE notes ADD COLUMN ai_summary text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'key_concepts') THEN
    ALTER TABLE notes ADD COLUMN key_concepts text[];
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'difficulty_level') THEN
    ALTER TABLE notes ADD COLUMN difficulty_level text CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')) DEFAULT 'intermediate';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'study_time_estimate') THEN
    ALTER TABLE notes ADD COLUMN study_time_estimate integer; -- in minutes
  END IF;
END $$;

-- Enhance flashcards table with advanced spaced repetition
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'ease_factor') THEN
    ALTER TABLE flashcards ADD COLUMN ease_factor real DEFAULT 2.5;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'interval_days') THEN
    ALTER TABLE flashcards ADD COLUMN interval_days integer DEFAULT 1;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'next_review_date') THEN
    ALTER TABLE flashcards ADD COLUMN next_review_date date DEFAULT CURRENT_DATE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'learning_state') THEN
    ALTER TABLE flashcards ADD COLUMN learning_state text CHECK (learning_state IN ('new', 'learning', 'review', 'relearning')) DEFAULT 'new';
  END IF;
END $$;

-- Enhance user_profiles with more detailed tracking
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'learning_style') THEN
    ALTER TABLE user_profiles ADD COLUMN learning_style text CHECK (learning_style IN ('visual', 'auditory', 'kinesthetic', 'reading')) DEFAULT 'visual';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'focus_areas') THEN
    ALTER TABLE user_profiles ADD COLUMN focus_areas text[];
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'weekly_goal') THEN
    ALTER TABLE user_profiles ADD COLUMN weekly_goal integer DEFAULT 20; -- hours per week
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'current_xp') THEN
    ALTER TABLE user_profiles ADD COLUMN current_xp integer DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'xp_to_next_level') THEN
    ALTER TABLE user_profiles ADD COLUMN xp_to_next_level integer DEFAULT 100;
  END IF;
END $$;

-- Enable RLS on new tables
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_insights ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables

-- User preferences policies
CREATE POLICY "Users can manage their own preferences"
  ON user_preferences
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- AI interactions policies
CREATE POLICY "Users can view their own AI interactions"
  ON ai_interactions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own AI interactions"
  ON ai_interactions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI interactions"
  ON ai_interactions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Learning sessions policies
CREATE POLICY "Users can manage their own learning sessions"
  ON learning_sessions
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Achievements policies
CREATE POLICY "Users can view their own achievements"
  ON achievements
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can create achievements"
  ON achievements
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update achievement display status"
  ON achievements
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Study insights policies
CREATE POLICY "Users can view their own insights"
  ON study_insights
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update insight status"
  ON study_insights
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS user_preferences_user_id_idx ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS ai_interactions_user_id_idx ON ai_interactions(user_id);
CREATE INDEX IF NOT EXISTS ai_interactions_session_id_idx ON ai_interactions(session_id);
CREATE INDEX IF NOT EXISTS ai_interactions_created_at_idx ON ai_interactions(created_at DESC);
CREATE INDEX IF NOT EXISTS learning_sessions_user_id_idx ON learning_sessions(user_id);
CREATE INDEX IF NOT EXISTS learning_sessions_session_type_idx ON learning_sessions(session_type);
CREATE INDEX IF NOT EXISTS learning_sessions_start_time_idx ON learning_sessions(start_time DESC);
CREATE INDEX IF NOT EXISTS achievements_user_id_idx ON achievements(user_id);
CREATE INDEX IF NOT EXISTS achievements_type_idx ON achievements(achievement_type);
CREATE INDEX IF NOT EXISTS achievements_unlocked_at_idx ON achievements(unlocked_at DESC);
CREATE INDEX IF NOT EXISTS study_insights_user_id_idx ON study_insights(user_id);
CREATE INDEX IF NOT EXISTS study_insights_priority_idx ON study_insights(priority);
CREATE INDEX IF NOT EXISTS study_insights_generated_at_idx ON study_insights(generated_at DESC);

-- Create functions for analytics and AI features

-- Function to calculate user learning analytics
CREATE OR REPLACE FUNCTION calculate_user_analytics(target_user_id uuid, days_back integer DEFAULT 7)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
  total_study_time integer;
  avg_accuracy real;
  session_count integer;
  streak_days integer;
BEGIN
  -- Calculate total study time
  SELECT COALESCE(SUM(duration_minutes), 0)
  INTO total_study_time
  FROM learning_sessions
  WHERE user_id = target_user_id
    AND start_time >= (now() - (days_back || ' days')::interval);

  -- Calculate average accuracy from performance metrics
  SELECT COALESCE(AVG((performance_metrics->>'accuracy')::real), 0)
  INTO avg_accuracy
  FROM learning_sessions
  WHERE user_id = target_user_id
    AND start_time >= (now() - (days_back || ' days')::interval)
    AND performance_metrics->>'accuracy' IS NOT NULL;

  -- Count sessions
  SELECT COUNT(*)
  INTO session_count
  FROM learning_sessions
  WHERE user_id = target_user_id
    AND start_time >= (now() - (days_back || ' days')::interval);

  -- Calculate streak (simplified - consecutive days with sessions)
  WITH daily_sessions AS (
    SELECT DISTINCT DATE(start_time) as session_date
    FROM learning_sessions
    WHERE user_id = target_user_id
    ORDER BY session_date DESC
  ),
  streak_calc AS (
    SELECT session_date,
           ROW_NUMBER() OVER (ORDER BY session_date DESC) as rn,
           session_date - (ROW_NUMBER() OVER (ORDER BY session_date DESC) * interval '1 day') as group_date
    FROM daily_sessions
  )
  SELECT COUNT(*)
  INTO streak_days
  FROM streak_calc
  WHERE group_date = (SELECT group_date FROM streak_calc LIMIT 1);

  -- Build result
  result := jsonb_build_object(
    'total_study_time', total_study_time,
    'average_accuracy', ROUND(avg_accuracy::numeric, 2),
    'session_count', session_count,
    'streak_days', COALESCE(streak_days, 0),
    'calculated_at', now()
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate study insights
CREATE OR REPLACE FUNCTION generate_study_insights(target_user_id uuid)
RETURNS void AS $$
DECLARE
  analytics jsonb;
  insight_record record;
BEGIN
  -- Get recent analytics
  analytics := calculate_user_analytics(target_user_id, 7);

  -- Generate insights based on patterns
  
  -- Low study time warning
  IF (analytics->>'total_study_time')::integer < 300 THEN -- Less than 5 hours per week
    INSERT INTO study_insights (user_id, insight_type, title, description, priority, action_suggested)
    VALUES (
      target_user_id,
      'warning',
      'Study Time Below Recommended',
      'You''ve studied less than 5 hours this week. Consider increasing your study time to reach your learning goals.',
      'medium',
      'Schedule more study sessions'
    )
    ON CONFLICT DO NOTHING;
  END IF;

  -- High accuracy encouragement
  IF (analytics->>'average_accuracy')::real > 85 THEN
    INSERT INTO study_insights (user_id, insight_type, title, description, priority, action_suggested)
    VALUES (
      target_user_id,
      'encouragement',
      'Excellent Performance!',
      'Your accuracy is above 85%! You''re demonstrating strong mastery of the material.',
      'low',
      'Consider advancing to more challenging content'
    )
    ON CONFLICT DO NOTHING;
  END IF;

  -- Streak achievement
  IF (analytics->>'streak_days')::integer >= 7 THEN
    INSERT INTO achievements (user_id, achievement_type, achievement_name, description, criteria_met, experience_gained, rarity)
    VALUES (
      target_user_id,
      'consistency',
      'Week Warrior',
      'Studied for 7 consecutive days',
      jsonb_build_object('streak_days', analytics->>'streak_days'),
      100,
      'uncommon'
    )
    ON CONFLICT DO NOTHING;
  END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user XP and level
CREATE OR REPLACE FUNCTION update_user_xp(target_user_id uuid, xp_gained integer)
RETURNS jsonb AS $$
DECLARE
  current_xp integer;
  current_level integer;
  xp_to_next integer;
  new_level integer;
  result jsonb;
BEGIN
  -- Get current stats
  SELECT current_xp, level, xp_to_next_level
  INTO current_xp, current_level, xp_to_next
  FROM user_profiles
  WHERE id = target_user_id;

  -- Add XP
  current_xp := current_xp + xp_gained;
  
  -- Check for level up
  new_level := current_level;
  WHILE current_xp >= xp_to_next LOOP
    current_xp := current_xp - xp_to_next;
    new_level := new_level + 1;
    xp_to_next := xp_to_next + 50; -- Each level requires 50 more XP than the previous
  END LOOP;

  -- Update user profile
  UPDATE user_profiles
  SET 
    current_xp = current_xp,
    level = new_level,
    xp_to_next_level = xp_to_next,
    experience = experience + xp_gained
  WHERE id = target_user_id;

  -- Build result
  result := jsonb_build_object(
    'leveled_up', new_level > current_level,
    'new_level', new_level,
    'xp_gained', xp_gained,
    'current_xp', current_xp,
    'xp_to_next', xp_to_next
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION calculate_user_analytics(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_study_insights(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_xp(uuid, integer) TO authenticated;

-- Create triggers for automatic insight generation

-- Trigger to generate insights after learning sessions
CREATE OR REPLACE FUNCTION trigger_insight_generation()
RETURNS trigger AS $$
BEGIN
  -- Generate insights for the user after each session
  PERFORM generate_study_insights(NEW.user_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Only create trigger if learning_sessions table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'learning_sessions') THEN
    DROP TRIGGER IF EXISTS generate_insights_after_session ON learning_sessions;
    CREATE TRIGGER generate_insights_after_session
      AFTER INSERT ON learning_sessions
      FOR EACH ROW
      EXECUTE FUNCTION trigger_insight_generation();
  END IF;
END $$;

-- Add updated_at triggers for new tables
DO $$
BEGIN
  -- Only create triggers if the update_updated_at_column function exists
  IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'update_updated_at_column') THEN
    
    -- User preferences trigger
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
      DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;
      CREATE TRIGGER update_user_preferences_updated_at
        BEFORE UPDATE ON user_preferences
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;

  END IF;
END $$;

-- Insert sample data for better UX

-- Sample achievements that users can unlock
INSERT INTO achievements (user_id, achievement_type, achievement_name, description, criteria_met, experience_gained, rarity, unlocked_at)
SELECT 
  up.id,
  'welcome',
  'Cosmic Explorer',
  'Welcome to MemoQuest! Your journey among the stars begins.',
  '{"action": "signup"}'::jsonb,
  50,
  'common',
  up.created_at
FROM user_profiles up
WHERE NOT EXISTS (
  SELECT 1 FROM achievements a 
  WHERE a.user_id = up.id AND a.achievement_type = 'welcome'
);