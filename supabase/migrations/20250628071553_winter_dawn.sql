/*
  # Fix Recursive Policy on deck_members

  1. Problem
    - Infinite recursion detected in policies for deck_members table
    - SELECT policy creates a circular dependency by referencing itself
    - Previous fixes still have recursion issues

  2. Solution
    - Drop ALL existing policies on deck_members
    - Create simplified, non-recursive policies
    - Separate policies for different access patterns to avoid circular references
    - Use proper auth.uid() function instead of uid()
*/

-- Drop ALL existing policies on deck_members to start fresh
DROP POLICY IF EXISTS "Deck owners can manage all members" ON deck_members;
DROP POLICY IF EXISTS "Users can view members in their decks" ON deck_members;
DROP POLICY IF EXISTS "Users can join decks" ON deck_members;
DROP POLICY IF EXISTS "Users can leave decks" ON deck_members;
DROP POLICY IF EXISTS "Users can view their own membership" ON deck_members;
DROP POLICY IF EXISTS "Deck owners can view all members" ON deck_members;
DROP POLICY IF EXISTS "Members can view other members in same deck" ON deck_members;
DROP POLICY IF EXISTS "Users can view deck members safely" ON deck_members;
DROP POLICY IF EXISTS "Members can view deck membership" ON deck_members;

-- Create new, simplified policies that avoid recursion

-- 1. Policy for owners to manage all members
CREATE POLICY "Deck owners can manage all members"
  ON deck_members
  FOR ALL
  TO authenticated
  USING (deck_id IN (
    SELECT id FROM decks WHERE owner_id = auth.uid()
  ))
  WITH CHECK (deck_id IN (
    SELECT id FROM decks WHERE owner_id = auth.uid()
  ));

-- 2. Policy for members to view - avoid recursion by keeping it simple
CREATE POLICY "Members can view deck membership"
  ON deck_members
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own membership
    user_id = auth.uid()
    OR 
    -- Users can see members in decks they own
    deck_id IN (SELECT id FROM decks WHERE owner_id = auth.uid())
  );

-- 3. Policy for users to join decks
CREATE POLICY "Users can join decks"
  ON deck_members
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 4. Policy for users to leave decks
CREATE POLICY "Users can leave decks"
  ON deck_members
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());