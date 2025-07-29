/*
  # Enhanced AI Moderation System

  1. New Features
    - Comprehensive bad words list with multiple categories
    - Elevated AI moderator permissions to moderate room owners
    - Enhanced detection and scoring for violations
    - Automated progressive discipline system
  
  2. Security
    - AI moderator can now take action against room owners
    - More robust content violation detection
*/

-- Create a table to store bad words categories and their lists
CREATE TABLE IF NOT EXISTS moderation_word_lists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL,
  severity integer CHECK (severity >= 1 AND severity <= 5) NOT NULL,
  words text[] NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create an updated_at trigger for the word lists
CREATE TRIGGER update_moderation_word_lists_updated_at
  BEFORE UPDATE ON moderation_word_lists
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert word lists for different categories of violations
INSERT INTO moderation_word_lists (category, severity, words) VALUES
-- Profanity (moderate severity)
('profanity', 3, ARRAY[
  'badword1', 'badword2', 'badword3', 'badword4', 'badword5',
  'badword6', 'badword7', 'badword8', 'badword9', 'badword10',
  'badword11', 'badword12', 'badword13', 'badword14', 'badword15'
]),

-- Harassment (high severity)
('harassment', 4, ARRAY[
  'badword16', 'badword17', 'badword18', 'badword19', 'badword20',
  'badword21', 'badword22', 'badword23', 'badword24', 'badword25' 
]),

-- Spam (low severity)
('spam', 2, ARRAY[
  'free money', 'get rich', 'make money fast', 'click here', 'viagra',
  'earn from home', 'prize winner', 'lottery winner', 'claim now', 'guaranteed',
  'act now', 'limited time', 'best rates', 'cheap', 'discount',
  'double your', 'extra income', 'fast cash', 'free access', 'free consultation'
]),

-- Hate speech (extreme severity)
('hate_speech', 5, ARRAY[
  'badword26', 'badword27', 'badword28', 'badword29', 'badword30',
  'badword31', 'badword32', 'badword33', 'badword34', 'badword35'
]);

-- Grant AI moderator super permissions
DO $$
BEGIN
  -- Update the AI moderator in the user_profiles table to indicate special status
  UPDATE user_profiles 
  SET level = 999 
  WHERE id = '00000000-0000-0000-0000-000000000001';
END $$;

-- Enhanced AI content moderation function with bad words checking
CREATE OR REPLACE FUNCTION ai_moderate_message(
  message_uuid uuid,
  room_uuid uuid
)
RETURNS jsonb AS $$
DECLARE
  message_data record;
  violation_count integer;
  violation_type text;
  severity_level integer := 0;
  action_taken text := 'none';
  ai_moderator_id uuid := '00000000-0000-0000-0000-000000000001';
  moderation_response text;
  result jsonb;
  room_owner_id uuid;
  matched_category text;
  bad_word text;
  message_text text;
  word_score integer := 0;
  max_word_score integer := 0;
  owner_warning boolean := false;
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

  -- Get room owner ID for special handling
  SELECT owner_id INTO room_owner_id
  FROM pomodoro_rooms
  WHERE id = room_uuid;

  -- Store message for easier processing
  message_text := lower(message_data.message);

  -- Check against word lists
  FOR matched_category, bad_word, word_score IN
    SELECT mwl.category, word, mwl.severity
    FROM moderation_word_lists mwl,
         unnest(mwl.words) AS word
    WHERE message_text ~* ('\b' || word || '\b')
    ORDER BY mwl.severity DESC
  LOOP
    -- Track the highest severity violation
    IF word_score > max_word_score THEN
      max_word_score := word_score;
      violation_type := matched_category;
    END IF;
  END LOOP;

  -- If bad words were found, set severity based on highest score
  IF max_word_score > 0 THEN
    severity_level := max_word_score;
  ELSE
    -- Check for other violations
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
  END IF;

  -- If violation detected, take action
  IF violation_type IS NOT NULL AND severity_level > 0 THEN
    -- Special handling for room owner violations
    IF message_data.user_id = room_owner_id THEN
      owner_warning := true;
      
      -- For room owners, always use warning first unless extreme violation
      IF severity_level >= 5 THEN
        action_taken := 'timeout';
        moderation_response := '🤖 Room owner alert! I''ve detected extremely inappropriate content that violates our community standards. Even room owners must follow our platform guidelines. You''ve been temporarily muted for 5 minutes.';
        
        -- Apply timeout
        UPDATE room_participants 
        SET timeout_until = now() + interval '5 minutes'
        WHERE room_id = room_uuid AND user_id = message_data.user_id;
      ELSE
        action_taken := 'warning';
        moderation_response := '🤖 Room owner alert! I''ve detected content that may violate our community standards. As a room owner, please set a positive example for all participants.';
      END IF;
    ELSE
      -- Get user's violation history
      violation_count := get_user_violation_count(message_data.user_id, room_uuid, 24);

      -- Determine action based on severity and history
      IF violation_count = 0 AND severity_level <= 2 THEN
        action_taken := 'warning';
        moderation_response := '🤖 Please keep messages appropriate and follow the room guidelines. This is a friendly reminder!';
      ELSIF (violation_count <= 1 AND severity_level <= 3) OR severity_level = 3 THEN
        action_taken := 'timeout';
        moderation_response := '🤖 Your message violated our guidelines. You''ve been timed out for 5 minutes to cool down.';
        
        -- Apply timeout
        UPDATE room_participants 
        SET timeout_until = now() + interval '5 minutes'
        WHERE room_id = room_uuid AND user_id = message_data.user_id;
        
      ELSIF violation_count <= 2 OR severity_level = 4 THEN
        action_taken := 'timeout';
        moderation_response := '🤖 Multiple violations detected. Extended timeout of 15 minutes applied. Please review our code of conduct.';
        
        -- Apply longer timeout
        UPDATE room_participants 
        SET timeout_until = now() + interval '15 minutes'
        WHERE room_id = room_uuid AND user_id = message_data.user_id;
        
      ELSE
        action_taken := 'kick';
        moderation_response := '🤖 Too many violations or extreme content detected. You''ve been removed from the room. Take some time to reflect on appropriate behavior.';
        
        -- Remove user from room
        DELETE FROM room_participants 
        WHERE room_id = room_uuid AND user_id = message_data.user_id;
      END IF;
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
      'AI detected: ' || violation_type || (CASE WHEN owner_warning THEN ' (room owner)' ELSE '' END)
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
    'violation_count', violation_count,
    'is_owner', message_data.user_id = room_owner_id
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;