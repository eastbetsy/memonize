/*
  # Enhanced Pomodoro Platform Upgrade

  1. New Tables
    - `room_moderation` - Chat moderation and user violations tracking
    - `room_roles` - Admin/moderator role management
    - `focus_sessions` - Enhanced focus mode tracking
    - `user_checklists` - Personal pomodoro checklists
    - `room_music` - Background music/sounds for rooms
    - `chat_messages` - Real-time chat system
    - `moderation_logs` - Moderation action history

  2. Enhanced Tables
    - Add focus mode settings and XP tracking
    - Enhanced room features and settings
    - Better user progression tracking

  3. Security & Moderation
    - Comprehensive RLS policies
    - Moderation command system
    - Code of conduct enforcement
*/

-- Room moderation and violations tracking
CREATE TABLE IF NOT EXISTS room_moderation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  violation_type text CHECK (violation_type IN ('spam', 'harassment', 'inappropriate_content', 'disruption', 'off_topic')) NOT NULL,
  severity text CHECK (severity IN ('warning', 'timeout', 'kick', 'ban')) NOT NULL,
  description text,
  moderator_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  auto_detected boolean DEFAULT false,
  resolved boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

-- Room roles management (admins/moderators)
CREATE TABLE IF NOT EXISTS room_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role text CHECK (role IN ('admin', 'moderator')) NOT NULL,
  granted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  granted_at timestamptz DEFAULT now(),
  permissions jsonb DEFAULT '{"can_moderate_chat": true, "can_manage_timer": true, "can_kick_users": true}'::jsonb,
  UNIQUE(room_id, user_id)
);

-- Enhanced focus sessions with detailed tracking
CREATE TABLE IF NOT EXISTS focus_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE SET NULL,
  focus_mode text CHECK (focus_mode IN ('deep_focus', 'collaborative', 'flexible')) NOT NULL,
  session_goal text,
  checklist_items jsonb DEFAULT '[]'::jsonb,
  completed_items jsonb DEFAULT '[]'::jsonb,
  interruptions integer DEFAULT 0,
  focus_score real DEFAULT 0, -- 0-100 based on adherence to focus rules
  xp_earned integer DEFAULT 0,
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  is_active boolean DEFAULT true,
  session_data jsonb DEFAULT '{}'::jsonb
);

-- User personal checklists for pomodoro sessions
CREATE TABLE IF NOT EXISTS user_checklists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  items jsonb NOT NULL, -- Array of checklist items with completion status
  is_default boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Room background music and sounds
CREATE TABLE IF NOT EXISTS room_music (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  track_type text CHECK (track_type IN ('lofi', 'nature', 'white_noise', 'binaural', 'ambient')) NOT NULL,
  track_name text NOT NULL,
  track_url text,
  volume real DEFAULT 0.5 CHECK (volume >= 0 AND volume <= 1),
  is_active boolean DEFAULT false,
  set_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Real-time chat messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message text NOT NULL,
  message_type text CHECK (message_type IN ('text', 'system', 'moderation')) DEFAULT 'text',
  flagged boolean DEFAULT false,
  flagged_reason text,
  edited boolean DEFAULT false,
  reply_to uuid REFERENCES chat_messages(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Moderation action logs
CREATE TABLE IF NOT EXISTS moderation_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES pomodoro_rooms(id) ON DELETE CASCADE NOT NULL,
  moderator_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  target_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  action text CHECK (action IN ('warn', 'timeout', 'kick', 'ban', 'unban')) NOT NULL,
  reason text,
  duration interval, -- For timeouts
  created_at timestamptz DEFAULT now()
);

-- Enhance existing pomodoro_rooms table
DO $$
BEGIN
  -- Add new columns for enhanced features
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pomodoro_rooms' AND column_name = 'code_of_conduct') THEN
    ALTER TABLE pomodoro_rooms ADD COLUMN code_of_conduct text DEFAULT 'Be respectful, stay focused, support fellow learners';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pomodoro_rooms' AND column_name = 'ai_moderation_enabled') THEN
    ALTER TABLE pomodoro_rooms ADD COLUMN ai_moderation_enabled boolean DEFAULT true;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pomodoro_rooms' AND column_name = 'music_enabled') THEN
    ALTER TABLE pomodoro_rooms ADD COLUMN music_enabled boolean DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pomodoro_rooms' AND column_name = 'voice_chat_enabled') THEN
    ALTER TABLE pomodoro_rooms ADD COLUMN voice_chat_enabled boolean DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pomodoro_rooms' AND column_name = 'video_chat_enabled') THEN
    ALTER TABLE pomodoro_rooms ADD COLUMN video_chat_enabled boolean DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pomodoro_rooms' AND column_name = 'focus_mode_enforced') THEN
    ALTER TABLE pomodoro_rooms ADD COLUMN focus_mode_enforced text CHECK (focus_mode_enforced IN ('deep_focus', 'collaborative', 'flexible')) DEFAULT 'flexible';
  END IF;
END $$;

-- Enhance room_participants table for better tracking
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'room_participants' AND column_name = 'focus_score') THEN
    ALTER TABLE room_participants ADD COLUMN focus_score real DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'room_participants' AND column_name = 'total_xp_earned') THEN
    ALTER TABLE room_participants ADD COLUMN total_xp_earned integer DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'room_participants' AND column_name = 'is_muted') THEN
    ALTER TABLE room_participants ADD COLUMN is_muted boolean DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'room_participants' AND column_name = 'timeout_until') THEN
    ALTER TABLE room_participants ADD COLUMN timeout_until timestamptz;
  END IF;
END $$;

-- Enable RLS on new tables
ALTER TABLE room_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_music ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for room_moderation
CREATE POLICY "Room moderators can view moderation records"
  ON room_moderation
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

CREATE POLICY "Room moderators can create moderation records"
  ON room_moderation
  FOR INSERT
  TO authenticated
  WITH CHECK (
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
    OR room_id IN (
      SELECT room_id FROM room_roles WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for room_roles
CREATE POLICY "Room members can view roles"
  ON room_roles
  FOR SELECT
  TO authenticated
  USING (
    room_id IN (
      SELECT room_id FROM room_participants WHERE user_id = auth.uid()
    )
    OR room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Room owners can manage roles"
  ON room_roles
  FOR ALL
  TO authenticated
  USING (
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

-- RLS Policies for focus_sessions
CREATE POLICY "Users can manage their own focus sessions"
  ON focus_sessions
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for user_checklists
CREATE POLICY "Users can manage their own checklists"
  ON user_checklists
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for room_music
CREATE POLICY "Room participants can view music"
  ON room_music
  FOR SELECT
  TO authenticated
  USING (
    room_id IN (
      SELECT room_id FROM room_participants WHERE user_id = auth.uid()
    )
    OR room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Room moderators can manage music"
  ON room_music
  FOR ALL
  TO authenticated
  USING (
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
    OR room_id IN (
      SELECT room_id FROM room_roles WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
    OR room_id IN (
      SELECT room_id FROM room_roles WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for chat_messages
CREATE POLICY "Room participants can view chat"
  ON chat_messages
  FOR SELECT
  TO authenticated
  USING (
    room_id IN (
      SELECT room_id FROM room_participants WHERE user_id = auth.uid()
    )
    OR room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Room participants can send messages"
  ON chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND room_id IN (
      SELECT room_id FROM room_participants WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can edit their own messages"
  ON chat_messages
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for moderation_logs
CREATE POLICY "Room moderators can view moderation logs"
  ON moderation_logs
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

CREATE POLICY "Room moderators can create moderation logs"
  ON moderation_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    room_id IN (
      SELECT id FROM pomodoro_rooms WHERE owner_id = auth.uid()
    )
    OR room_id IN (
      SELECT room_id FROM room_roles WHERE user_id = auth.uid()
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS room_moderation_room_id_idx ON room_moderation(room_id);
CREATE INDEX IF NOT EXISTS room_moderation_user_id_idx ON room_moderation(user_id);
CREATE INDEX IF NOT EXISTS room_moderation_created_at_idx ON room_moderation(created_at DESC);
CREATE INDEX IF NOT EXISTS room_roles_room_id_idx ON room_roles(room_id);
CREATE INDEX IF NOT EXISTS room_roles_user_id_idx ON room_roles(user_id);
CREATE INDEX IF NOT EXISTS focus_sessions_user_id_idx ON focus_sessions(user_id);
CREATE INDEX IF NOT EXISTS focus_sessions_room_id_idx ON focus_sessions(room_id);
CREATE INDEX IF NOT EXISTS focus_sessions_start_time_idx ON focus_sessions(start_time DESC);
CREATE INDEX IF NOT EXISTS user_checklists_user_id_idx ON user_checklists(user_id);
CREATE INDEX IF NOT EXISTS room_music_room_id_idx ON room_music(room_id);
CREATE INDEX IF NOT EXISTS chat_messages_room_id_idx ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS moderation_logs_room_id_idx ON moderation_logs(room_id);
CREATE INDEX IF NOT EXISTS moderation_logs_created_at_idx ON moderation_logs(created_at DESC);

-- Functions for moderation and XP system

-- Function to check if user has moderation permissions
CREATE OR REPLACE FUNCTION user_has_moderation_permission(room_uuid uuid, user_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM pomodoro_rooms WHERE id = room_uuid AND owner_id = user_uuid
  ) OR EXISTS (
    SELECT 1 FROM room_roles 
    WHERE room_id = room_uuid AND user_id = user_uuid 
    AND role IN ('admin', 'moderator')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to apply moderation action
CREATE OR REPLACE FUNCTION apply_moderation_action(
  room_uuid uuid,
  target_user_uuid uuid,
  action text,
  reason text DEFAULT NULL,
  duration_minutes integer DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
  moderator_uuid uuid := auth.uid();
  result jsonb;
BEGIN
  -- Check if user has moderation permissions
  IF NOT user_has_moderation_permission(room_uuid, moderator_uuid) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient permissions');
  END IF;

  -- Apply the action
  CASE action
    WHEN 'timeout' THEN
      UPDATE room_participants 
      SET timeout_until = now() + (duration_minutes || ' minutes')::interval
      WHERE room_id = room_uuid AND user_id = target_user_uuid;
      
    WHEN 'mute' THEN
      UPDATE room_participants 
      SET is_muted = true
      WHERE room_id = room_uuid AND user_id = target_user_uuid;
      
    WHEN 'unmute' THEN
      UPDATE room_participants 
      SET is_muted = false
      WHERE room_id = room_uuid AND user_id = target_user_uuid;
      
    WHEN 'kick' THEN
      DELETE FROM room_participants 
      WHERE room_id = room_uuid AND user_id = target_user_uuid;
      
    ELSE
      RETURN jsonb_build_object('success', false, 'error', 'Invalid action');
  END CASE;

  -- Log the moderation action
  INSERT INTO moderation_logs (room_id, moderator_id, target_user_id, action, reason, duration)
  VALUES (
    room_uuid, 
    moderator_uuid, 
    target_user_uuid, 
    action, 
    reason,
    CASE WHEN duration_minutes IS NOT NULL THEN (duration_minutes || ' minutes')::interval ELSE NULL END
  );

  result := jsonb_build_object(
    'success', true,
    'action', action,
    'target_user', target_user_uuid,
    'moderator', moderator_uuid
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to award XP for focus session completion
CREATE OR REPLACE FUNCTION award_focus_xp(
  user_uuid uuid,
  session_uuid uuid,
  base_xp integer DEFAULT 50
)
RETURNS jsonb AS $$
DECLARE
  session_data record;
  multiplier real := 1.0;
  bonus_xp integer := 0;
  total_xp integer;
  result jsonb;
BEGIN
  -- Get session data
  SELECT focus_score, focus_mode, interruptions, 
         EXTRACT(EPOCH FROM (end_time - start_time))/60 as duration_minutes
  INTO session_data
  FROM focus_sessions 
  WHERE id = session_uuid AND user_id = user_uuid;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Session not found');
  END IF;

  -- Calculate multipliers based on performance
  IF session_data.focus_score >= 90 THEN
    multiplier := 1.5;
    bonus_xp := 25;
  ELSIF session_data.focus_score >= 75 THEN
    multiplier := 1.25;
    bonus_xp := 15;
  ELSIF session_data.focus_score >= 60 THEN
    multiplier := 1.1;
    bonus_xp := 10;
  END IF;

  -- Focus mode bonuses
  CASE session_data.focus_mode
    WHEN 'deep_focus' THEN
      multiplier := multiplier * 1.2;
    WHEN 'collaborative' THEN
      bonus_xp := bonus_xp + 10;
  END CASE;

  -- Duration bonus (minimum 25 minutes for bonus)
  IF session_data.duration_minutes >= 25 THEN
    bonus_xp := bonus_xp + FLOOR(session_data.duration_minutes / 25) * 5;
  END IF;

  -- Calculate total XP
  total_xp := FLOOR(base_xp * multiplier) + bonus_xp;

  -- Update user profile
  UPDATE user_profiles 
  SET 
    current_xp = current_xp + total_xp,
    experience = experience + total_xp
  WHERE id = user_uuid;

  -- Update session record
  UPDATE focus_sessions 
  SET xp_earned = total_xp
  WHERE id = session_uuid;

  result := jsonb_build_object(
    'success', true,
    'xp_awarded', total_xp,
    'base_xp', base_xp,
    'multiplier', multiplier,
    'bonus_xp', bonus_xp,
    'focus_score', session_data.focus_score
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function for AI content moderation
CREATE OR REPLACE FUNCTION moderate_chat_message(
  message_uuid uuid,
  room_uuid uuid
)
RETURNS jsonb AS $$
DECLARE
  message_text text;
  flagged boolean := false;
  flag_reason text;
  result jsonb;
BEGIN
  -- Get message content
  SELECT message INTO message_text
  FROM chat_messages 
  WHERE id = message_uuid;

  -- Simple content moderation (in real app, this would use AI/ML)
  IF message_text ~* '\b(spam|scam|inappropriate)\b' THEN
    flagged := true;
    flag_reason := 'Potentially inappropriate content detected';
  ELSIF LENGTH(message_text) > 500 THEN
    flagged := true;
    flag_reason := 'Message too long';
  ELSIF message_text ~* '\b(https?://)\b' THEN
    flagged := true;
    flag_reason := 'External links not allowed';
  END IF;

  -- Update message if flagged
  IF flagged THEN
    UPDATE chat_messages 
    SET flagged = true, flagged_reason = flag_reason
    WHERE id = message_uuid;

    -- Create moderation record
    INSERT INTO room_moderation (room_id, user_id, violation_type, severity, description, auto_detected)
    SELECT room_uuid, user_id, 'inappropriate_content', 'warning', flag_reason, true
    FROM chat_messages WHERE id = message_uuid;
  END IF;

  result := jsonb_build_object(
    'flagged', flagged,
    'reason', flag_reason
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION user_has_moderation_permission(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION apply_moderation_action(uuid, uuid, text, text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION award_focus_xp(uuid, uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION moderate_chat_message(uuid, uuid) TO authenticated;

-- Create triggers for automatic moderation
CREATE OR REPLACE FUNCTION trigger_chat_moderation()
RETURNS trigger AS $$
BEGIN
  -- Only moderate text messages
  IF NEW.message_type = 'text' THEN
    PERFORM moderate_chat_message(NEW.id, NEW.room_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER moderate_new_messages
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION trigger_chat_moderation();

-- Create triggers for updated_at columns
CREATE TRIGGER update_user_checklists_updated_at
  BEFORE UPDATE ON user_checklists
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_messages_updated_at
  BEFORE UPDATE ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();