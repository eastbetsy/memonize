import { supabase } from './supabase'
import type { AuthError, Session, User } from '@supabase/supabase-js'

interface AuthResponse {
  user: User | null
  session: Session | null
  error?: AuthError | Error | null
}

interface LoginResponse extends AuthResponse {
  profile?: any
}

export async function signUp(email: string, password: string, username: string): Promise<AuthResponse> {
  try {
    // Create the auth user - profile creation will be handled by auth state change listener
    let { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          username,
        },
      },
    })

    if (error) {
      return { user: null, session: null, error }
    }
    
    return {
      user: data.user,
      session: data.session
    }
  } catch (error) {
    return {
      user: null,
      session: null,
      error: error as Error
    }
  }
}

export async function signIn(email: string, password: string): Promise<LoginResponse> {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password: password.trim(),
    })

    if (error) {
      return { user: null, session: null, error }
    }

    // Profile creation will be handled by auth state change listener
    return {
      user: data.user,
      session: data.session
    }
  } catch (error) {
    return {
      user: null,
      session: null,
      error: error as Error
    }
  }
}

export async function signOut(): Promise<{ error?: Error }> {
  try {
    const { error } = await supabase.auth.signOut()
    if (error) {
      return { error }
    }
    return {}
  } catch (error) {
    return { error: error as Error }
  }
}

export async function getUserProfile(userId: string) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Error fetching user profile:', error)
    return null
  }
}

// Get the current user and ensure their profile exists
export async function getCurrentUser(): Promise<{ user: User | null, profile: any | null }> {
  try {
    const { data, error } = await supabase.auth.getUser();
    
    if (error) {
      console.error('Error getting user:', error);
      return { user: null, profile: null };
    }
    
    const user = data?.user;
    
    if (!user) {
      return { user: null, profile: null };
    }
    
    // Ensure profile exists
    const profile = await ensureUserProfile(user.id, user.user_metadata?.username);
    
    return { 
      user,
      profile: profile ? true : null
    };
  } catch (error) {
    console.error('Error getting current user:', error);
    return { user: null, profile: null };
  }
}

export async function ensureUserProfile(userId: string, username?: string) {
  console.log(`Ensuring profile exists for user ${userId} with username ${username || 'undefined'}`);

  try {
    // Try direct insertion first (more reliable)
    const { error } = await supabase
      .from('user_profiles')
      .upsert([{
        id: userId,
        username: username || 'User',
        level: 1,
        experience: 0,
        current_xp: 0,
        xp_to_next_level: 100
      }])
      
    if (error) {
      console.warn('Direct profile insertion failed, trying RPC:', error);
      
      // Try RPC function as fallback
      console.log('Trying RPC function as fallback');
      const { data: rpcResult, error: rpcError } = await supabase.rpc(
        'create_user_profile_safe',
        {
          user_id: userId,
          username: username || 'User'
        }
      );
      
      if (rpcError) throw rpcError;
      return rpcResult;
    }
    return true;
  } catch (error) {
    console.error('All profile creation methods failed:', error)
    return null
  }
}