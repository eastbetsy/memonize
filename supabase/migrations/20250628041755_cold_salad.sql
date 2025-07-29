/*
  # Fix moderation action values

  1. Issue
    - The trigger_enhanced_chat_moderation function is inserting 'warning' into moderation_logs
    - The database constraint only allows 'warn', 'timeout', 'kick', 'ban', 'unban'
    - This causes constraint violations when AI moderation tries to log actions

  2. Solution
    - Update the trigger function to use 'warn' instead of 'warning'
    - Ensure all moderation actions use the correct constraint-compliant values
*/

-- Drop and recreate the enhanced chat moderation function with correct action values
CREATE OR REPLACE FUNCTION trigger_enhanced_chat_moderation()
RETURNS TRIGGER AS $$
DECLARE
  violation_detected boolean := false;
  violation_type text;
  severity_level integer;
  action_to_take text;
  ai_moderator_id uuid;
BEGIN
  -- Get AI moderator ID for this room
  SELECT id INTO ai_moderator_id 
  FROM users 
  WHERE email = 'ai-moderator@memoquest.app' 
  LIMIT 1;

  -- If no AI moderator exists, create one
  IF ai_moderator_id IS NULL THEN
    INSERT INTO users (email, id) 
    VALUES ('ai-moderator@memoquest.app', '00000000-0000-0000-0000-000000000001')
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO ai_moderator_id;
    
    -- If still null, use the default AI moderator ID
    IF ai_moderator_id IS NULL THEN
      ai_moderator_id := '00000000-0000-0000-0000-000000000001';
    END IF;
  END IF;

  -- Check for spam/repeated messages
  IF EXISTS (
    SELECT 1 FROM chat_messages 
    WHERE room_id = NEW.room_id 
    AND user_id = NEW.user_id 
    AND message = NEW.message 
    AND created_at > NOW() - INTERVAL '5 minutes'
    AND id != NEW.id
  ) THEN
    violation_detected := true;
    violation_type := 'repeated_messages';
    severity_level := 2;
    action_to_take := 'warn';  -- Changed from 'warning' to 'warn'
  END IF;

  -- Check for excessive caps
  IF LENGTH(NEW.message) > 10 AND 
     LENGTH(REGEXP_REPLACE(NEW.message, '[^A-Z]', '', 'g')) > LENGTH(NEW.message) * 0.7 THEN
    violation_detected := true;
    violation_type := 'excessive_caps';
    severity_level := 1;
    action_to_take := 'warn';  -- Changed from 'warning' to 'warn'
  END IF;

  -- Check for excessive length (potential spam)
  IF LENGTH(NEW.message) > 1000 THEN
    violation_detected := true;
    violation_type := 'spam';
    severity_level := 3;
    action_to_take := 'timeout';
  END IF;

  -- Check for rapid message posting
  IF (
    SELECT COUNT(*) FROM chat_messages 
    WHERE room_id = NEW.room_id 
    AND user_id = NEW.user_id 
    AND created_at > NOW() - INTERVAL '30 seconds'
  ) > 5 THEN
    violation_detected := true;
    violation_type := 'spam';
    severity_level := 3;
    action_to_take := 'timeout';
  END IF;

  -- Log violation if detected
  IF violation_detected THEN
    -- Insert into user_violations table
    INSERT INTO user_violations (
      user_id,
      room_id,
      violation_type,
      severity,
      auto_detected,
      message_content,
      action_taken
    ) VALUES (
      NEW.user_id,
      NEW.room_id,
      violation_type,
      severity_level,
      true,
      NEW.message,
      action_to_take
    );

    -- Get room owner info for context
    DECLARE
      room_owner_username text;
      target_username text;
    BEGIN
      SELECT up.username INTO room_owner_username
      FROM pomodoro_rooms pr
      JOIN user_profiles up ON pr.owner_id = up.id
      WHERE pr.id = NEW.room_id;

      SELECT up.username INTO target_username
      FROM user_profiles up
      WHERE up.id = NEW.user_id;

      -- Insert into moderation_logs table with correct action value
      INSERT INTO moderation_logs (
        room_id,
        moderator_id,
        target_user_id,
        action,  -- This now uses the correct constraint-compliant values
        reason,
        created_at
      ) VALUES (
        NEW.room_id,
        ai_moderator_id,
        NEW.user_id,
        action_to_take,  -- 'warn' or 'timeout' - both are constraint-compliant
        'AI detected: ' || violation_type || 
        CASE 
          WHEN room_owner_username IS NOT NULL THEN ' (room owner: ' || room_owner_username || ')'
          ELSE ''
        END,
        NOW()
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- If there's an error with the moderation log, don't fail the entire trigger
        NULL;
    END;

    -- Flag the message if it's a serious violation
    IF severity_level >= 3 THEN
      UPDATE chat_messages 
      SET flagged = true, 
          flagged_reason = 'AI detected: ' || violation_type
      WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS moderate_new_messages ON chat_messages;
CREATE TRIGGER moderate_new_messages
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION trigger_enhanced_chat_moderation();