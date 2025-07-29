/*
  # AI Moderator System

  1. Create AI moderator user and functions
    - Create special AI user profile for Draco bot
    - Functions to automatically add AI moderator to rooms
    - AI content moderation logic with violation tracking
    - Automatic moderation responses and actions

  2. Enhanced moderation features
    - Violation counting and escalation
    - Automatic timeouts and kicks based on violation history
    - AI-generated moderation messages
    - Real-time moderation analytics
*/

-- Create the AI moderator user profile
DO $$
BEGIN
  -- Insert AI moderator profile (using a fixed UUID for consistency)
  INSERT INTO auth.users (id, email, email_confirmed_at, created_at, updated_at)
  VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'draco@memoquest.ai',
    now(),
    now(),
    now()
  ) ON CONFLICT (id) DO NOTHING;

  -- Create AI moderator profile
  INSERT INTO user_profiles (id, username, level, experience, created_at, updated_at)
  VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    '🤖Draco',
    100,
    999999,
    now(),
    now()
  ) ON CONFLICT (id) DO NOTHING;
END $$;

-- Enhanced user violation tracking
CREATE TABLE IF NOT EXISTS user_violations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  violation_type text CHECK (violation_type IN ('spam', 'harassment', 'inappropriate_content', 'disruption', 'off_topic', 'excessive_caps', 'repeated_messages')) NOT NULL,
  severity integer CHECK (severity >= 1 AND severity <= 5) NOT NULL, -- 1=minor, 5=severe
  auto_detected boolean DEFAULT true,
  message_content text,
  action_taken text CHECK (action_taken IN ('warning', 'timeout', 'kick', 'ban', 'none')) DEFAULT 'none',
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

-- Create indexes for violations
CREATE INDEX IF NOT EXISTS user_violations_user_id_idx ON user_violations(user_id);
CREATE INDEX IF NOT EXISTS user_violations_room_id_idx ON user_violations(room_id);
CREATE INDEX IF NOT EXISTS user_violations_created_at_idx ON user_violations(created_at DESC);

-- Function to add AI moderator to room
CREATE OR REPLACE FUNCTION add_ai_moderator_to_room(room_uuid uuid)
RETURNS void AS $$
DECLARE
  ai_moderator_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Add AI moderator as participant with admin privileges
  INSERT INTO room_participants (room_id, user_id, is_admin, joined_at)
  VALUES (room_uuid, ai_moderator_id, true, now())
  ON CONFLICT (room_id, user_id) DO NOTHING;

  -- Grant admin role to AI moderator
  INSERT INTO room_roles (room_id, user_id, role, granted_by, permissions)
  VALUES (
    room_uuid, 
    ai_moderator_id, 
    'admin',
    ai_moderator_id,
    '{
      "can_moderate_chat": true,
      "can_manage_timer": true,
      "can_kick_users": true,
      "can_manage_music": true,
      "can_manage_voice": true
    }'::jsonb
  )
  ON CONFLICT (room_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user violation count in a room
CREATE OR REPLACE FUNCTION get_user_violation_count(
  user_uuid uuid,
  room_uuid uuid,
  time_window_hours integer DEFAULT 24
)
RETURNS integer AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM user_violations
    WHERE user_id = user_uuid 
      AND room_id = room_uuid
      AND created_at > now() - (time_window_hours || ' hours')::interval
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced AI content moderation function
CREATE OR REPLACE FUNCTION ai_moderate_message(
  message_uuid uuid,
  room_uuid uuid
)
RETURNS jsonb AS $$
DECLARE
  message_data record;
  violation_count integer;
  violation_type text;
  severity_level integer;
  action_taken text := 'none';
  ai_moderator_id uuid := '00000000-0000-0000-0000-000000000001';
  moderation_response text;
  result jsonb;
BEGIN
  -- Get message content and user info
  SELECT cm.message, cm.user_id, cm.created_at
  INTO message_data
  FROM chat_messages cm
  WHERE cm.id = message_uuid;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Message not found');
  END IF;

  -- Skip moderation for AI moderator
  IF message_data.user_id = ai_moderator_id THEN
    RETURN jsonb_build_object('success', true, 'action', 'none', 'reason', 'AI moderator message');
  END IF;

  -- Check for various violations
  severity_level := 0;
  violation_type := null;

  -- Spam detection (repeated messages)
  IF EXISTS (
    SELECT 1 FROM chat_messages 
    WHERE room_id = room_uuid 
      AND user_id = message_data.user_id 
      AND message = message_data.message
      AND created_at > now() - interval '5 minutes'
      AND id != message_uuid
  ) THEN
    violation_type := 'repeated_messages';
    severity_level := 2;
  END IF;

  -- Excessive caps detection
  IF LENGTH(message_data.message) > 20 AND 
     LENGTH(REGEXP_REPLACE(message_data.message, '[^A-Z]', '', 'g')) > LENGTH(message_data.message) * 0.7 THEN
    violation_type := 'excessive_caps';
    severity_level := 1;
  END IF;

  -- Inappropriate content detection (basic keyword filtering)
  IF message_data.message ~* '\b(spam|scam|hack|cheat|inappropriate|offensive)\b' THEN
    violation_type := 'inappropriate_content';
    severity_level := 3;
  END IF;

  -- Message length spam
  IF LENGTH(message_data.message) > 500 THEN
    violation_type := 'spam';
    severity_level := 2;
  END IF;

  -- Off-topic detection (links to external sites)
  IF message_data.message ~* '\b(https?://(?!.*memoquest))\b' THEN
    violation_type := 'off_topic';
    severity_level := 2;
  END IF;

  -- If violation detected, take action
  IF violation_type IS NOT NULL THEN
    -- Get user's violation history
    violation_count := get_user_violation_count(message_data.user_id, room_uuid, 24);

    -- Determine action based on severity and history
    IF violation_count = 0 AND severity_level <= 2 THEN
      action_taken := 'warning';
      moderation_response := 'Please keep messages appropriate and follow the room guidelines. This is a friendly reminder! 🤖';
    ELSIF violation_count <= 1 AND severity_level <= 3 THEN
      action_taken := 'timeout';
      moderation_response := 'Your message violated our guidelines. You''ve been timed out for 5 minutes to cool down. 🤖⏰';
      
      -- Apply timeout
      UPDATE room_participants 
      SET timeout_until = now() + interval '5 minutes'
      WHERE room_id = room_uuid AND user_id = message_data.user_id;
      
    ELSIF violation_count <= 2 THEN
      action_taken := 'timeout';
      moderation_response := 'Multiple violations detected. Extended timeout of 15 minutes applied. Please review our code of conduct. 🤖⚠️';
      
      -- Apply longer timeout
      UPDATE room_participants 
      SET timeout_until = now() + interval '15 minutes'
      WHERE room_id = room_uuid AND user_id = message_data.user_id;
      
    ELSE
      action_taken := 'kick';
      moderation_response := 'Too many violations. You''ve been removed from the room. Take some time to reflect on appropriate behavior. 🤖🚫';
      
      -- Remove user from room
      DELETE FROM room_participants 
      WHERE room_id = room_uuid AND user_id = message_data.user_id;
    END IF;

    -- Flag the message
    UPDATE chat_messages 
    SET flagged = true, flagged_reason = violation_type || ' (AI detected)'
    WHERE id = message_uuid;

    -- Record the violation
    INSERT INTO user_violations (
      user_id, room_id, violation_type, severity, auto_detected, 
      message_content, action_taken
    ) VALUES (
      message_data.user_id, room_uuid, violation_type, severity_level, true,
      message_data.message, action_taken
    );

    -- Log the moderation action
    INSERT INTO moderation_logs (
      room_id, moderator_id, target_user_id, action, reason
    ) VALUES (
      room_uuid, ai_moderator_id, message_data.user_id, action_taken, 
      'AI detected: ' || violation_type
    );

    -- Send AI moderator response if needed
    IF action_taken != 'none' THEN
      INSERT INTO chat_messages (
        room_id, user_id, message, message_type
      ) VALUES (
        room_uuid, ai_moderator_id, moderation_response, 'moderation'
      );
    END IF;
  END IF;

  result := jsonb_build_object(
    'success', true,
    'violation_detected', violation_type IS NOT NULL,
    'violation_type', violation_type,
    'severity', severity_level,
    'action_taken', action_taken,
    'violation_count', violation_count
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send AI welcome message
CREATE OR REPLACE FUNCTION send_ai_welcome_message(room_uuid uuid)
RETURNS void AS $$
DECLARE
  ai_moderator_id uuid := '00000000-0000-0000-0000-000000000001';
  room_info record;
  welcome_message text;
BEGIN
  -- Get room information
  SELECT name, focus_mode_enforced, ai_moderation_enabled
  INTO room_info
  FROM pomodoro_rooms
  WHERE id = room_uuid;

  IF NOT FOUND OR NOT room_info.ai_moderation_enabled THEN
    RETURN;
  END IF;

  -- Create personalized welcome message based on focus mode
  CASE room_info.focus_mode_enforced
    WHEN 'deep_focus' THEN
      welcome_message := '🤖 Greetings, focused learners! I''m Draco, your AI study companion. This room is in Deep Focus mode - let''s maintain a distraction-free environment. I''ll help keep our cosmic study space peaceful and productive! 🧠✨';
    WHEN 'collaborative' THEN
      welcome_message := '🤖 Welcome to ' || room_info.name || '! I''m Draco, your AI moderator. This collaborative space encourages helpful discussion while staying on topic. Feel free to share knowledge and support each other! 🚀📚';
    ELSE
      welcome_message := '🤖 Hello, cosmic explorers! I''m Draco, your friendly AI companion. This flexible study room welcomes all kinds of learning. I''m here to help maintain a positive and respectful environment for everyone! 🌟';
  END CASE;

  -- Send welcome message
  INSERT INTO chat_messages (
    room_id, user_id, message, message_type
  ) VALUES (
    room_uuid, ai_moderator_id, welcome_message, 'system'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to provide study encouragement
CREATE OR REPLACE FUNCTION send_ai_encouragement(room_uuid uuid)
RETURNS void AS $$
DECLARE
  ai_moderator_id uuid := '00000000-0000-0000-0000-000000000001';
  encouragement_messages text[] := ARRAY[
    '🤖 Keep up the great work, cosmic learners! Your dedication to knowledge shines like the stars! ⭐',
    '🤖 Remember: every small step in learning takes you closer to mastering the universe of knowledge! 🌌',
    '🤖 Focus flows like cosmic energy - let it guide your learning journey today! 🌟',
    '🤖 The constellation of your achievements grows brighter with each study session! ✨',
    '🤖 Learning is like exploring distant galaxies - each discovery opens new worlds! 🚀',
    '🤖 Your brain is the most powerful cosmic computer in the universe - use it wisely! 🧠'
  ];
  selected_message text;
BEGIN
  -- Check if room has AI moderation enabled
  IF NOT EXISTS (
    SELECT 1 FROM pomodoro_rooms 
    WHERE id = room_uuid AND ai_moderation_enabled = true
  ) THEN
    RETURN;
  END IF;

  -- Select random encouragement message
  selected_message := encouragement_messages[1 + floor(random() * array_length(encouragement_messages, 1))];

  -- Send encouragement
  INSERT INTO chat_messages (
    room_id, user_id, message, message_type
  ) VALUES (
    room_uuid, ai_moderator_id, selected_message, 'system'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to add AI moderator when room is created with AI moderation
CREATE OR REPLACE FUNCTION trigger_add_ai_moderator()
RETURNS trigger AS $$
BEGIN
  IF NEW.ai_moderation_enabled = true THEN
    PERFORM add_ai_moderator_to_room(NEW.id);
    -- Send welcome message after a short delay to ensure room is fully set up
    PERFORM send_ai_welcome_message(NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new rooms
DROP TRIGGER IF EXISTS add_ai_moderator_trigger ON pomodoro_rooms;
CREATE TRIGGER add_ai_moderator_trigger
  AFTER INSERT ON pomodoro_rooms
  FOR EACH ROW
  EXECUTE FUNCTION trigger_add_ai_moderator();

-- Update existing rooms with AI moderation to include the AI moderator
DO $$
DECLARE
  room_record record;
BEGIN
  FOR room_record IN 
    SELECT id FROM pomodoro_rooms WHERE ai_moderation_enabled = true
  LOOP
    PERFORM add_ai_moderator_to_room(room_record.id);
  END LOOP;
END $$;

-- Enhanced trigger for message moderation
CREATE OR REPLACE FUNCTION trigger_enhanced_chat_moderation()
RETURNS trigger AS $$
BEGIN
  -- Only moderate text messages from real users (not AI)
  IF NEW.message_type = 'text' AND NEW.user_id != '00000000-0000-0000-0000-000000000001' THEN
    -- Check if room has AI moderation enabled
    IF EXISTS (
      SELECT 1 FROM pomodoro_rooms 
      WHERE id = NEW.room_id AND ai_moderation_enabled = true
    ) THEN
      PERFORM ai_moderate_message(NEW.id, NEW.room_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Replace the existing moderation trigger
DROP TRIGGER IF EXISTS moderate_new_messages ON chat_messages;
CREATE TRIGGER moderate_new_messages
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION trigger_enhanced_chat_moderation();

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION add_ai_moderator_to_room(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_violation_count(uuid, uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION ai_moderate_message(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION send_ai_welcome_message(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION send_ai_encouragement(uuid) TO authenticated;

-- Enable RLS on new tables
ALTER TABLE user_violations ENABLE ROW LEVEL SECURITY;

-- RLS policies for user_violations
CREATE POLICY "Room moderators can view violations"
  ON user_violations
  FOR SELECT
  TO authenticated
  USING (
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
    OR room_id IN (
      SELECT room_id FROM room_roles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "System can create violations"
  ON user_violations
  FOR INSERT
  TO authenticated
  WITH CHECK (true); -- AI system needs to create violations

-- Function to get room moderation stats
CREATE OR REPLACE FUNCTION get_room_moderation_stats(room_uuid uuid)
RETURNS jsonb AS $$
DECLARE
  stats jsonb;
  total_violations integer;
  violations_today integer;
  most_common_violation text;
BEGIN
  -- Count total violations
  SELECT COUNT(*) INTO total_violations
  FROM user_violations
  WHERE room_id = room_uuid;

  -- Count violations today
  SELECT COUNT(*) INTO violations_today
  FROM user_violations
  WHERE room_id = room_uuid
    AND created_at > CURRENT_DATE;

  -- Find most common violation type
  SELECT violation_type INTO most_common_violation
  FROM user_violations
  WHERE room_id = room_uuid
  GROUP BY violation_type
  ORDER BY COUNT(*) DESC
  LIMIT 1;

  stats := jsonb_build_object(
    'total_violations', total_violations,
    'violations_today', violations_today,
    'most_common_violation', COALESCE(most_common_violation, 'none'),
    'ai_moderator_active', EXISTS (
      SELECT 1 FROM room_participants 
      WHERE room_id = room_uuid 
        AND user_id = '00000000-0000-0000-0000-000000000001'
    )
  );

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_room_moderation_stats(uuid) TO authenticated;