/*
  # Fix Chat Moderation RLS Violation

  1. Problem
     - The chat moderation trigger is violating RLS policies on the users table
     - This prevents users from sending messages in chat rooms

  2. Solution
     - Drop the problematic trigger temporarily
     - Create a fixed version of the moderation function that respects RLS
     - Re-enable the trigger with proper permissions

  3. Changes
     - Remove direct user table manipulation from moderation function
     - Ensure all operations use proper RLS-compliant queries
     - Focus moderation on message content only, not user manipulation
*/

-- Drop the problematic trigger temporarily
DROP TRIGGER IF EXISTS moderate_new_messages ON public.chat_messages;

-- Create or replace the enhanced chat moderation function with proper RLS handling
CREATE OR REPLACE FUNCTION public.trigger_enhanced_chat_moderation()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  word_found text;
  violation_severity integer;
  room_ai_enabled boolean;
BEGIN
  -- Check if AI moderation is enabled for this room
  SELECT ai_moderation_enabled INTO room_ai_enabled
  FROM pomodoro_rooms 
  WHERE id = NEW.room_id;
  
  -- If AI moderation is disabled, skip checks
  IF NOT COALESCE(room_ai_enabled, false) THEN
    RETURN NEW;
  END IF;

  -- Check for prohibited words/content
  SELECT w.words[1], w.severity INTO word_found, violation_severity
  FROM moderation_word_lists w
  WHERE NEW.message ~* ANY(w.words)
  ORDER BY w.severity DESC
  LIMIT 1;

  -- If violation found, create violation record but don't modify users table
  IF word_found IS NOT NULL THEN
    -- Insert violation record (this table should have proper RLS)
    INSERT INTO user_violations (
      user_id,
      room_id,
      violation_type,
      severity,
      auto_detected,
      message_content,
      action_taken,
      created_at
    ) VALUES (
      NEW.user_id,
      NEW.room_id,
      CASE 
        WHEN violation_severity >= 4 THEN 'inappropriate_content'
        WHEN violation_severity >= 3 THEN 'harassment'
        ELSE 'spam'
      END,
      violation_severity,
      true,
      NEW.message,
      CASE 
        WHEN violation_severity >= 4 THEN 'timeout'
        WHEN violation_severity >= 3 THEN 'warning'
        ELSE 'none'
      END,
      NOW()
    );

    -- Flag the message for review
    NEW.flagged := true;
    NEW.flagged_reason := 'Auto-detected: inappropriate content';
    
    -- For severe violations, don't save the message content
    IF violation_severity >= 4 THEN
      NEW.message := '[Message removed by auto-moderation]';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Re-enable the trigger with the fixed function
CREATE TRIGGER moderate_new_messages
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_enhanced_chat_moderation();

-- Ensure proper permissions for the function
GRANT EXECUTE ON FUNCTION public.trigger_enhanced_chat_moderation() TO authenticated;

-- Also create a simpler backup function that just flags without complex logic
CREATE OR REPLACE FUNCTION public.trigger_simple_chat_moderation()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Simple moderation that doesn't touch user tables
  -- Just return the message as-is for now
  RETURN NEW;
END;
$$;