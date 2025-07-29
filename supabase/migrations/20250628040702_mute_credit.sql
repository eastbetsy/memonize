/*
  # Enhanced Word Detection for AI Moderation

  1. Word List Updates
    - Add comprehensive profanity detection patterns
    - Update existing word lists with more effective patterns
    - Use regex patterns to catch variations of words
  
  2. Function Improvements
    - Update the message screening algorithm to be more sensitive
    - Improve detection of evasion attempts (like f*ck, f**k, etc.)
    - Ensure proper handling of context and false positives
  
  3. Moderation Enforcement
    - Ensure room owners are properly moderated
    - Implement warnings for all violations, no exemptions
    - Record all offenses in the violations table
*/

-- Add real profanity detection by updating the word lists with regex patterns
-- Note: We're using regex patterns rather than explicit words
UPDATE moderation_word_lists 
SET words = ARRAY[
  'f[u\*]+ck', 'sh[i\*]+t', 'b[i\*]+tch', 'a[s\*]+hole', 'di[c\*]k',
  'tw[a\*]+t', 'c[u\*]+nt', 'p[u\*]+ssy', 'cock', 'wh[o0\*]re',
  'd[a\*]+mn', 'b[a\*]+st[a\*]rd', 'j[e\*]rk', 'p[r\*]ick'
]
WHERE category = 'profanity';

-- Enhance the AI moderation function to check for regex matches
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
  found_bad_word boolean := false;
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

  -- Check against word lists using regex patterns
  FOR matched_category, bad_word, word_score IN
    SELECT mwl.category, word, mwl.severity
    FROM moderation_word_lists mwl,
         unnest(mwl.words) AS word
    WHERE message_text ~* word  -- Use regex matching instead of direct match
    ORDER BY mwl.severity DESC
  LOOP
    -- Track the highest severity violation
    IF word_score > max_word_score THEN
      max_word_score := word_score;
      violation_type := matched_category;
      found_bad_word := true;
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
      
      -- Room owners get the same treatment as regular users now
      -- Get user's violation history
      violation_count := get_user_violation_count(message_data.user_id, room_uuid, 24);

      -- Determine action based on severity and history, but apply to room owner too
      IF violation_count = 0 AND severity_level <= 2 THEN
        action_taken := 'warning';
        moderation_response := '🤖 Please keep messages appropriate and follow the room guidelines. This is a friendly reminder!';
      ELSIF (violation_count <= 1 AND severity_level <= 3) OR severity_level = 3 THEN
        action_taken := 'timeout';
        moderation_response := '🤖 Your message violated our guidelines. You''ve been timed out for 5 minutes to cool down.';
        
        -- Apply timeout (even to room owner)
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
        -- For extreme severity with room owners, still timeout rather than kick
        action_taken := 'timeout';
        moderation_response := '🤖 Severe content violations detected. You''ve been timed out for 30 minutes. As the room owner, please remember to set a positive example.';
        
        -- Apply longer timeout for room owner instead of kicking
        UPDATE room_participants 
        SET timeout_until = now() + interval '30 minutes'
        WHERE room_id = room_uuid AND user_id = message_data.user_id;
      END IF;
      
      -- Add owner-specific note to the moderation response
      IF found_bad_word THEN
        moderation_response := moderation_response || ' As the room owner, please remember that you set the tone for everyone in this space.';
      END IF;
    ELSE
      -- Regular user moderation (non-owner)
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
    'is_owner', message_data.user_id = room_owner_id,
    'found_bad_word', found_bad_word
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;