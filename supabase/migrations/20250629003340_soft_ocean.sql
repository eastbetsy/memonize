/*
  # Bridge Features for Platform Integration

  1. New Features
    - Helper views for cross-feature analytics
    - Improved XP tracking and rewards
    - Functions to support feature integration

  2. Security
    - Ensure proper RLS policies for new views
    - Maintain data integrity across features
*/

-- Create view for Pomodoro session productivity insights
CREATE OR REPLACE VIEW productivity_insights AS
SELECT 
  user_id,
  session_goal AS subject,
  AVG(focus_score) AS avg_focus_score,
  COUNT(*) AS session_count,
  SUM(CASE WHEN is_active = false THEN 1 ELSE 0 END) AS completed_sessions,
  SUM(xp_earned) AS total_xp_earned,
  COUNT(DISTINCT TO_CHAR(start_time, 'YYYY-MM-DD')) AS unique_days,
  EXTRACT(HOUR FROM start_time) AS hour_of_day,
  CASE 
    WHEN EXTRACT(HOUR FROM start_time) < 12 THEN 'morning'
    WHEN EXTRACT(HOUR FROM start_time) < 18 THEN 'afternoon'
    ELSE 'evening'
  END AS time_of_day,
  jsonb_agg(DISTINCT checklist_items) FILTER (WHERE checklist_items IS NOT NULL) AS all_checklist_items
FROM focus_sessions
WHERE user_id IS NOT NULL
GROUP BY 
  user_id, 
  subject, 
  EXTRACT(HOUR FROM start_time),
  CASE 
    WHEN EXTRACT(HOUR FROM start_time) < 12 THEN 'morning'
    WHEN EXTRACT(HOUR FROM start_time) < 18 THEN 'afternoon'
    ELSE 'evening'
  END;

-- Enable RLS on the view
ALTER VIEW productivity_insights ENABLE ROW LEVEL SECURITY;

-- Create policy for users to view their own insights
CREATE POLICY "Users can view their own productivity insights"
  ON productivity_insights
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Function to get productivity insights by time of day
CREATE OR REPLACE FUNCTION get_time_productivity(user_uuid uuid)
RETURNS TABLE(
  time_of_day text,
  avg_focus_score numeric,
  session_count bigint,
  most_productive_subject text
) AS $$
BEGIN
  RETURN QUERY
  WITH time_stats AS (
    SELECT 
      time_of_day,
      AVG(avg_focus_score) AS avg_focus,
      SUM(session_count) AS sessions,
      array_agg(subject ORDER BY avg_focus_score DESC) AS subjects
    FROM productivity_insights
    WHERE user_id = user_uuid
    GROUP BY time_of_day
  )
  SELECT 
    time_of_day,
    ROUND(avg_focus::numeric, 2),
    sessions,
    subjects[1] AS most_productive_subject
  FROM time_stats
  ORDER BY avg_focus DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION get_time_productivity(uuid) TO authenticated;

-- Function to get checklist completion stats by subject
CREATE OR REPLACE FUNCTION get_checklist_completion_by_subject(user_uuid uuid)
RETURNS TABLE(
  subject text,
  completed_tasks bigint,
  total_tasks bigint, 
  completion_rate numeric,
  avg_focus_score numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pi.subject,
    COUNT(*) FILTER (WHERE (item->>'completed')::boolean = true) AS completed_tasks,
    COUNT(*) AS total_tasks,
    ROUND((COUNT(*) FILTER (WHERE (item->>'completed')::boolean = true)::numeric / 
           NULLIF(COUNT(*)::numeric, 0)) * 100, 2) AS completion_rate,
    ROUND(AVG(pi.avg_focus_score), 2) AS avg_focus
  FROM 
    productivity_insights pi,
    jsonb_array_elements(pi.all_checklist_items) AS items,
    jsonb_array_elements(items) AS item
  WHERE 
    pi.user_id = user_uuid
    AND item IS NOT NULL
  GROUP BY 
    pi.subject
  HAVING 
    COUNT(*) > 0
  ORDER BY 
    completion_rate DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION get_checklist_completion_by_subject(uuid) TO authenticated;

-- Table to store cross-feature integration settings
CREATE TABLE IF NOT EXISTS feature_integration_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  ai_chat_integration boolean DEFAULT true,
  analytics_integration boolean DEFAULT true,
  xp_notifications boolean DEFAULT true,
  productivity_insights boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE feature_integration_settings ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Users can manage their own integration settings"
  ON feature_integration_settings
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Add updated_at trigger
CREATE TRIGGER update_feature_integration_settings_updated_at
  BEFORE UPDATE ON feature_integration_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();