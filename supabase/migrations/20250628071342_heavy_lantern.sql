/*
  # Fix infinite recursion in deck_members policies

  1. Problem
    - The "Users can view deck members safely" policy has a recursive subquery
    - It queries deck_members from within a policy ON deck_members
    - This creates infinite recursion when evaluating the policy

  2. Solution
    - Remove the problematic recursive policy
    - Consolidate multiple SELECT policies into one simple policy
    - Avoid self-referencing subqueries in deck_members policies

  3. Changes
    - Drop problematic policies
    - Create a single, non-recursive SELECT policy for deck_members
*/

-- Drop the problematic policies that cause recursion
DROP POLICY IF EXISTS "Users can view deck members safely" ON deck_members;
DROP POLICY IF EXISTS "Users can view their own membership" ON deck_members;
DROP POLICY IF EXISTS "Deck owners can view all members" ON deck_members;

-- Create a single, simple SELECT policy without recursion
CREATE POLICY "Members can view deck membership" 
  ON deck_members 
  FOR SELECT 
  TO authenticated 
  USING (
    -- Users can see members of decks they own
    deck_id IN (
      SELECT id FROM decks WHERE owner_id = auth.uid()
    )
    OR
    -- Users can see their own membership records
    user_id = auth.uid()
  );