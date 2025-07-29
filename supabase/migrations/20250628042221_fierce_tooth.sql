/*
  # Ensure Chat System Permissions

  1. Purpose
     - Ensure all chat-related tables have proper RLS policies
     - Fix any permission issues that might cause RLS violations

  2. Changes
     - Review and fix chat_messages RLS policies
     - Ensure user_violations table has proper policies
     - Add missing policies for chat functionality
*/

-- Ensure chat_messages has proper RLS policies
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies and recreate them properly
DROP POLICY IF EXISTS "Room participants can send messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Room participants can view chat" ON public.chat_messages;
DROP POLICY IF EXISTS "Users can edit their own messages" ON public.chat_messages;

-- Recreate chat message policies with proper logic
CREATE POLICY "Users can insert messages in joined rooms"
  ON public.chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND
    room_id IN (
      SELECT rp.room_id 
      FROM room_participants rp 
      WHERE rp.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view messages in accessible rooms"
  ON public.chat_messages
  FOR SELECT
  TO authenticated
  USING (
    room_id IN (
      -- Public rooms
      SELECT pr.id 
      FROM pomodoro_rooms pr 
      WHERE pr.type = 'public'
    )
    OR
    room_id IN (
      -- Rooms user is participating in
      SELECT rp.room_id 
      FROM room_participants rp 
      WHERE rp.user_id = auth.uid()
    )
    OR
    room_id IN (
      -- Rooms user owns
      SELECT pr.id 
      FROM pomodoro_rooms pr 
      WHERE pr.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own messages"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages or moderators can delete"
  ON public.chat_messages
  FOR DELETE
  TO authenticated
  USING (
    auth.uid() = user_id OR
    room_id IN (
      SELECT pr.id 
      FROM pomodoro_rooms pr 
      WHERE pr.owner_id = auth.uid()
    ) OR
    room_id IN (
      SELECT rr.room_id 
      FROM room_roles rr 
      WHERE rr.user_id = auth.uid() AND rr.role IN ('admin', 'moderator')
    )
  );

-- Ensure user_violations table has proper policies
ALTER TABLE public.user_violations ENABLE ROW LEVEL SECURITY;

-- Fix user_violations policies to prevent RLS issues
DROP POLICY IF EXISTS "System can create violations" ON public.user_violations;
DROP POLICY IF EXISTS "Room moderators can view violations" ON public.user_violations;

CREATE POLICY "Authenticated users can create violations"
  ON public.user_violations
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Room moderators and owners can view violations"
  ON public.user_violations
  FOR SELECT
  TO authenticated
  USING (
    room_id IN (
      SELECT pr.id 
      FROM pomodoro_rooms pr 
      WHERE pr.owner_id = auth.uid()
    ) OR
    room_id IN (
      SELECT rr.room_id 
      FROM room_roles rr 
      WHERE rr.user_id = auth.uid() AND rr.role IN ('admin', 'moderator')
    )
  );

-- Ensure the function can access necessary tables
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.pomodoro_rooms TO authenticated;
GRANT SELECT ON public.moderation_word_lists TO authenticated;
GRANT INSERT ON public.user_violations TO authenticated;