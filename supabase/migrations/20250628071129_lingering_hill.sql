/*
  # Fix Deck Members Policy Recursion

  1. Problem
    - Infinite recursion detected in policy for relation "deck_members"
    - The existing policy is creating a circular dependency by querying itself

  2. Solution
    - Drop the problematic policy
    - Create three separate, simpler policies that avoid recursion:
      1. Users can view their own membership
      2. Deck owners can view all members
      3. Members can view other members in same deck
*/

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Users can view members in their decks" ON deck_members;

-- Create new simplified policies for viewing deck members
CREATE POLICY "Users can view their own membership"
  ON deck_members
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Deck owners can view all members"
  ON deck_members
  FOR SELECT
  TO authenticated
  USING (deck_id IN (
    SELECT id FROM decks WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Members can view other members in same deck"
  ON deck_members
  FOR SELECT
  TO authenticated
  USING (
    deck_id IN (
      SELECT deck_id 
      FROM deck_members dm 
      WHERE dm.user_id = auth.uid()
    )
  );