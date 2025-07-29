/*
  # XP Tracking and Cross-Feature Integration

  1. New Tables
    - `xp_transactions` - Track all XP awards across features
  
  2. Enhanced Fields
    - Add new columns to existing tables to support XP tracking

  3. Functions
    - Create function for consistent XP awarding across features
    - Create functions to query cross-feature analytics
*/

-- Create the XP transactions table to track all earned XP
CREATE TABLE IF NOT EXISTS xp_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount integer NOT NULL CHECK (amount > 0),
  action_type text NOT NULL, -- notes, flashcards, pomodoro, quiz, etc.
  action_id uuid, -- Optional reference to the specific item that generated XP
  description text, -- Human-readable description of what earned the XP
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own XP transactions"
  ON xp_transactions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own XP transactions"
  ON xp_transactions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create function to award XP consistently across features
CREATE OR REPLACE FUNCTION award_xp(
  user_uuid uuid,
  xp_amount integer,
  action_type text,
  action_id uuid DEFAULT NULL,
  description text DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
  xp_transaction_id uuid;
  user_level_before integer;
  user_level_after integer;
  leveled_up boolean := false;
BEGIN
  -- Get current user level
  SELECT level INTO user_level_before
  FROM user_profiles
  WHERE id = user_uuid;
  
  -- Record XP transaction
  INSERT INTO xp_transactions (user_id, amount, action_type, action_id, description)
  VALUES (user_uuid, xp_amount, action_type, action_id, description)
  RETURNING id INTO xp_transaction_id;
  
  -- Update user profile XP
  UPDATE user_profiles
  SET 
    current_xp = current_xp + xp_amount,
    experience = experience + xp_amount
  WHERE id = user_uuid;
  
  -- Check if level increased
  SELECT level INTO user_level_after
  FROM user_profiles
  WHERE id = user_uuid;
  
  IF user_level_after > user_level_before THEN
    leveled_up := true;
  END IF;
  
  -- Return results
  result := jsonb_build_object(
    'success', true,
    'xp_awarded', xp_amount,
    'transaction_id', xp_transaction_id,
    'leveled_up', leveled_up,
    'new_level', user_level_after
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION award_xp(uuid, integer, text, uuid, text) TO authenticated;

-- Create function to get cross-feature analytics
CREATE OR REPLACE FUNCTION get_cross_feature_analytics(
  user_uuid uuid,
  days_back integer DEFAULT 30
)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
  total_xp_earned integer;
  feature_breakdown jsonb;
  daily_xp jsonb;
BEGIN
  -- Calculate total XP earned in the time period
  SELECT COALESCE(SUM(amount), 0)
  INTO total_xp_earned
  FROM xp_transactions
  WHERE user_id = user_uuid
  AND created_at > (now() - (days_back || ' days')::interval);
  
  -- Get XP breakdown by feature
  WITH feature_xp AS (
    SELECT 
      action_type, 
      SUM(amount) as feature_total
    FROM xp_transactions
    WHERE user_id = user_uuid
    AND created_at > (now() - (days_back || ' days')::interval)
    GROUP BY action_type
  )
  SELECT jsonb_object_agg(action_type, feature_total)
  INTO feature_breakdown
  FROM feature_xp;
  
  -- Get daily XP totals
  WITH daily_totals AS (
    SELECT 
      TO_CHAR(created_at, 'YYYY-MM-DD') as day, 
      SUM(amount) as day_total
    FROM xp_transactions
    WHERE user_id = user_uuid
    AND created_at > (now() - (days_back || ' days')::interval)
    GROUP BY day
    ORDER BY day
  )
  SELECT jsonb_object_agg(day, day_total)
  INTO daily_xp
  FROM daily_totals;
  
  -- Build complete result
  result := jsonb_build_object(
    'total_xp', total_xp_earned,
    'feature_breakdown', COALESCE(feature_breakdown, '{}'::jsonb),
    'daily_xp', COALESCE(daily_xp, '{}'::jsonb)
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_cross_feature_analytics(uuid, integer) TO authenticated;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS xp_transactions_user_id_idx ON xp_transactions(user_id);
CREATE INDEX IF NOT EXISTS xp_transactions_created_at_idx ON xp_transactions(created_at);
CREATE INDEX IF NOT EXISTS xp_transactions_action_type_idx ON xp_transactions(action_type);

-- Add XP rewards to checklist items in focus sessions
ALTER TABLE focus_sessions
ADD COLUMN IF NOT EXISTS checklist_item_xp jsonb DEFAULT '[]'::jsonb;