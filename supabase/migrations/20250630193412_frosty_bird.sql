/*
  # Fix Decks Privacy and Add Google Classroom Features
  
  1. Remove the current overly permissive policies
     - Drop the "Anyone can view decks" policy that makes all decks visible to all users
     - Drop the "Anyone can view deck members" policy that exposes all member relationships
  
  2. Create proper privacy policies
     - Users should only see decks they own
     - Users should only see decks they are members of
     - Calendar events should be visible only to deck members
  
  3. Additional Classroom Features
     - Improve RLS for existing classroom-like tables
     - Enhance integration between deck events and assignments
     - Update permissions for announcements and materials
*/

-- Drop the overly permissive policies that allow all users to see all decks/members
DROP POLICY IF EXISTS "Anyone can view decks" ON decks;
DROP POLICY IF EXISTS "Anyone can view deck members" ON deck_members;

-- Create proper privacy-focused policies for decks
CREATE POLICY "Users can view decks they own or are members of"
  ON decks
  FOR SELECT
  TO authenticated
  USING (
    -- Decks the user owns
    owner_id = auth.uid()
    OR
    -- Decks the user is a member of
    id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid()
    )
  );

-- Create proper privacy-focused policies for deck members
CREATE POLICY "Users can view members of decks they belong to"
  ON deck_members
  FOR SELECT
  TO authenticated
  USING (
    -- User can see members of decks they own
    deck_id IN (
      SELECT id FROM decks 
      WHERE owner_id = auth.uid()
    )
    OR
    -- User can see members of decks they're in
    deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid()
    )
  );

-- Enhance deck_events permissions to be more classroom-like
DROP POLICY IF EXISTS "Teachers can manage events" ON deck_events;
DROP POLICY IF EXISTS "Students can view events" ON deck_events;

-- More restricted event policies
CREATE POLICY "Teachers can manage events"
  ON deck_events
  FOR ALL
  TO authenticated
  USING (
    -- Deck owner can manage events
    deck_id IN (
      SELECT id FROM decks 
      WHERE owner_id = auth.uid()
    )
    OR
    -- Teachers and assistants can manage events
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() 
      AND role IN ('teacher', 'assistant')
    )
  )
  WITH CHECK (
    -- Deck owner can manage events
    deck_id IN (
      SELECT id FROM decks 
      WHERE owner_id = auth.uid()
    )
    OR
    -- Teachers and assistants can manage events
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() 
      AND role IN ('teacher', 'assistant')
    )
  );

CREATE POLICY "Students can view events in their decks"
  ON deck_events
  FOR SELECT
  TO authenticated
  USING (
    -- Students can only see events in decks they're members of
    deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid()
    )
  );

-- Improve deck messages policy for announcements
DROP POLICY IF EXISTS "Only teachers can make announcements" ON deck_messages;

CREATE POLICY "Only teachers can make announcements"
  ON deck_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Regular messages can be posted by any deck member
    (is_announcement = false AND user_id = auth.uid() AND
      deck_id IN (
        SELECT deck_id FROM deck_members
        WHERE user_id = auth.uid()
      ))
    OR
    -- Announcements can only be posted by teachers/owners
    (is_announcement = true AND user_id = auth.uid() AND (
      deck_id IN (
        SELECT deck_id FROM deck_members
        WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
      )
      OR
      deck_id IN (
        SELECT id FROM decks 
        WHERE owner_id = auth.uid()
      )
    ))
  );

-- Enhance deck materials policies
DROP POLICY IF EXISTS "Teachers can manage materials" ON deck_materials;
DROP POLICY IF EXISTS "Students can view materials" ON deck_materials;

CREATE POLICY "Teachers can manage materials"
  ON deck_materials
  FOR ALL
  TO authenticated
  USING (
    -- Deck owner can manage materials
    deck_id IN (
      SELECT id FROM decks 
      WHERE owner_id = auth.uid()
    )
    OR
    -- Teachers and assistants can manage materials
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() 
      AND role IN ('teacher', 'assistant')
    )
  )
  WITH CHECK (
    -- Deck owner can manage materials
    deck_id IN (
      SELECT id FROM decks 
      WHERE owner_id = auth.uid()
    )
    OR
    -- Teachers and assistants can manage materials
    deck_id IN (
      SELECT deck_id FROM deck_members 
      WHERE user_id = auth.uid() 
      AND role IN ('teacher', 'assistant')
    )
  );

CREATE POLICY "Students can view materials in their decks"
  ON deck_materials
  FOR SELECT
  TO authenticated
  USING (
    -- Students can only see materials in decks they're members of
    deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid()
    )
  );

-- Create an enrollment function for joining decks by code
CREATE OR REPLACE FUNCTION public.join_deck_by_code(enrollment_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_deck_id uuid;
  result jsonb;
BEGIN
  -- Find deck by enrollment code
  SELECT id INTO target_deck_id 
  FROM decks 
  WHERE decks.enrollment_code = enrollment_code;
  
  IF target_deck_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Invalid enrollment code'
    );
  END IF;
  
  -- Check if user is already a member
  IF EXISTS (
    SELECT 1 FROM deck_members 
    WHERE deck_id = target_deck_id AND user_id = auth.uid()
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'You are already a member of this deck'
    );
  END IF;
  
  -- Join the deck as a student
  INSERT INTO deck_members (deck_id, user_id, role)
  VALUES (target_deck_id, auth.uid(), 'student');
  
  -- Return success with deck info
  SELECT 
    jsonb_build_object(
      'success', true,
      'message', 'Successfully joined deck',
      'deck', jsonb_build_object(
        'id', d.id,
        'name', d.name,
        'description', d.description
      )
    ) INTO result
  FROM decks d
  WHERE d.id = target_deck_id;
  
  RETURN result;
EXCEPTION
  WHEN others THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Error joining deck: ' || SQLERRM
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.join_deck_by_code(text) TO authenticated;

-- Create a function to get a teacher's calendar (combining events and assignments)
CREATE OR REPLACE FUNCTION public.get_teacher_calendar(days_ahead int DEFAULT 30)
RETURNS SETOF jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  -- Get events for decks where user is teacher/owner
  SELECT jsonb_build_object(
    'id', e.id,
    'title', e.title,
    'description', e.description,
    'start_time', e.start_time,
    'end_time', e.end_time,
    'type', 'event',
    'deck_id', e.deck_id,
    'deck_name', d.name
  )
  FROM deck_events e
  JOIN decks d ON e.deck_id = d.id
  WHERE 
    -- Include decks where user is owner
    d.owner_id = auth.uid()
    OR
    -- Include decks where user is teacher/assistant
    e.deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
  -- Only include events in the specified time window
  AND e.start_time BETWEEN CURRENT_DATE AND (CURRENT_DATE + (days_ahead || ' days')::interval)

  UNION ALL

  -- Get assignments for decks where user is teacher/owner
  SELECT jsonb_build_object(
    'id', a.id,
    'title', a.title,
    'description', a.description,
    'start_time', NULL,
    'end_time', a.due_date,
    'type', 'assignment',
    'deck_id', a.deck_id,
    'deck_name', d.name,
    'status', a.status,
    'points', a.points
  )
  FROM deck_assignments a
  JOIN decks d ON a.deck_id = d.id
  WHERE 
    -- Include decks where user is owner
    d.owner_id = auth.uid()
    OR
    -- Include decks where user is teacher/assistant
    a.deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid() AND role IN ('teacher', 'assistant')
    )
  -- Only include assignments in the specified time window
  AND a.due_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + (days_ahead || ' days')::interval);
END;
$$;

-- Create a function to get a student's calendar
CREATE OR REPLACE FUNCTION public.get_student_calendar(days_ahead int DEFAULT 30)
RETURNS SETOF jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  -- Get events for decks where user is a member
  SELECT jsonb_build_object(
    'id', e.id,
    'title', e.title,
    'description', e.description,
    'start_time', e.start_time,
    'end_time', e.end_time,
    'type', 'event',
    'deck_id', e.deck_id,
    'deck_name', d.name
  )
  FROM deck_events e
  JOIN decks d ON e.deck_id = d.id
  WHERE e.deck_id IN (
    SELECT deck_id FROM deck_members
    WHERE user_id = auth.uid()
  )
  -- Only include events in the specified time window
  AND e.start_time BETWEEN CURRENT_DATE AND (CURRENT_DATE + (days_ahead || ' days')::interval)

  UNION ALL

  -- Get assignments for decks where user is a member
  SELECT jsonb_build_object(
    'id', a.id,
    'title', a.title,
    'description', a.description,
    'start_time', NULL,
    'end_time', a.due_date,
    'type', 'assignment',
    'deck_id', a.deck_id,
    'deck_name', d.name,
    'status', a.status,
    'points', a.points,
    -- Include submission status if it exists
    'submission_status', COALESCE(
      (SELECT ds.status FROM deck_submissions ds 
       WHERE ds.assignment_id = a.id AND ds.user_id = auth.uid()),
      'not_submitted'
    )
  )
  FROM deck_assignments a
  JOIN decks d ON a.deck_id = d.id
  WHERE 
    -- Only assignments from decks where user is a member
    a.deck_id IN (
      SELECT deck_id FROM deck_members
      WHERE user_id = auth.uid()
    )
    -- Only published assignments
    AND a.status = 'published'
    -- Only include assignments in the specified time window
    AND a.due_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + (days_ahead || ' days')::interval);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_teacher_calendar(int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_student_calendar(int) TO authenticated;