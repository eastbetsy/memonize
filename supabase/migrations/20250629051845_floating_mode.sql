/*
  # Add XP Transactions and Update Functions

  1. New Tables
    - `xp_transactions` - Track user XP earnings across the platform
  
  2. Functions
    - `update_user_xp` - Function to update user XP and handle level progression
  
  3. Security
    - Enable RLS on the new table
    - Create policies for secure access
*/

-- Create the xp_transactions table
CREATE TABLE IF NOT EXISTS public.xp_transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount integer NOT NULL CHECK (amount > 0),
    description text,
    action_type text,
    created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.xp_transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can read their own xp_transactions" 
  ON public.xp_transactions
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own xp_transactions" 
  ON public.xp_transactions
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Create or replace the update_user_xp function
CREATE OR REPLACE FUNCTION public.update_user_xp(
    target_user_id uuid,
    xp_gained integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  old_level integer;
  new_level integer;
  old_xp integer;
  new_xp integer;
  xp_needed integer;
  leveled_up boolean := false;
BEGIN
  -- Get current user stats
  SELECT 
    up.level,
    up.current_xp,
    up.xp_to_next_level
  INTO 
    old_level,
    old_xp,
    xp_needed
  FROM user_profiles up
  WHERE up.id = target_user_id;

  -- If user profile doesn't exist, return error
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'User profile not found');
  END IF;

  -- Calculate new XP
  new_xp := old_xp + xp_gained;
  new_level := old_level;

  -- Check for level ups
  WHILE new_xp >= xp_needed LOOP
    new_xp := new_xp - xp_needed;
    new_level := new_level + 1;
    leveled_up := true;
    -- Calculate XP needed for next level (increases by 50 each level)
    xp_needed := 100 + ((new_level - 1) * 50);
  END LOOP;

  -- Update user profile
  UPDATE user_profiles
  SET 
    current_xp = new_xp,
    level = new_level,
    xp_to_next_level = xp_needed,
    experience = user_profiles.experience + xp_gained,
    updated_at = now()
  WHERE user_profiles.id = target_user_id;

  -- Return level up information
  RETURN jsonb_build_object(
    'success', true,
    'leveled_up', leveled_up,
    'new_level', new_level,
    'old_level', old_level,
    'xp_gained', xp_gained,
    'current_xp', new_xp
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.update_user_xp(uuid, integer) TO authenticated;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS xp_transactions_user_id_idx ON xp_transactions(user_id);
CREATE INDEX IF NOT EXISTS xp_transactions_created_at_idx ON xp_transactions(created_at DESC);