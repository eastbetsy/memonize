// Helper functions for user profile management across edge functions

// Ensure a user profile exists in the database
export async function ensureUserProfile(supabase, userId, username = 'User') {
  try {
    // Check if profile exists
    const { data: existingProfile } = await supabase
      .from('user_profiles')
      .select('id, username')
      .eq('id', userId)
      .maybeSingle();
    
    if (existingProfile) {
      return { success: true, profile: existingProfile, created: false };
    }
    
    // Try to create profile using create_user_profile_safe RPC
    try {
      const { data, error } = await supabase.rpc(
        'create_user_profile_safe',
        { 
          user_id: userId, 
          username: username || 'User'
        }
      );
      
      if (error) throw error;
      
      return { success: true, profile: data, created: true };
    } catch (rpcError) {
      console.error('RPC profile creation failed, trying direct insert:', rpcError);
      
      // Fall back to direct insert
      const { data, error } = await supabase
        .from('user_profiles')
        .insert([{
          id: userId,
          username: username || 'User',
          level: 1,
          current_xp: 0,
          xp_to_next_level: 100,
          experience: 0,
          study_streak: 0,
          total_study_time: 0,
          achievements: [],
          learning_style: 'visual',
          weekly_goal: 20
        }])
        .select()
        .single();
      
      if (error) throw error;
      
      return { success: true, profile: data, created: true };
    }
  } catch (error) {
    console.error('Failed to ensure user profile exists:', error);
    return { success: false, error: error.message };
  }
}

// Get a user's profile
export async function getUserProfile(supabase, userId) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single();
    
    if (error) throw error;
    
    return { success: true, profile: data };
  } catch (error) {
    console.error('Failed to get user profile:', error);
    return { success: false, error: error.message };
  }
}