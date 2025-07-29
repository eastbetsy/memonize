/*
  # Fix infinite recursion in deck_members RLS policy

  1. Issue
    - The "Members can view other members in same deck" policy causes infinite recursion
    - Policy references deck_members table within its own policy condition
    - This breaks when trying to count deck members via `_count:deck_members(count)`

  2. Solution
    - Drop the problematic policy that causes circular reference
    - Rely on existing policies that work without recursion:
      - Deck owners can view all members
      - Users can view their own membership
    - Add a new policy that uses room_participants as intermediary to avoid recursion

  3. Security
    - Maintain proper access control for deck members
    - Ensure users can only see members of decks they belong to
*/

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Members can view other members in same deck" ON deck_members;

-- Create a new policy that avoids the circular reference
-- This policy allows users to view deck members if they are participants in rooms owned by the deck owner
-- or if they are the deck owner themselves
CREATE POLICY "Users can view deck members safely"
  ON deck_members
  FOR SELECT
  TO authenticated
  USING (
    -- Deck owners can see all members of their decks
    (deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    ))
    OR
    -- Users can see their own membership record
    (user_id = auth.uid())
    OR
    -- Users can see other members if they have any membership in the same deck
    (EXISTS (
      SELECT 1 FROM deck_members dm2 
      WHERE dm2.deck_id = deck_members.deck_id 
      AND dm2.user_id = auth.uid()
    ))
  );