import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { User, Session } from '@supabase/supabase-js'
import { useToast } from 'vue-toastification'
import api, { xpApi } from '@/lib/api'

export const useAuthStore = defineStore('auth', () => {
  // Initialize toast
  const toast = useToast()
  
  // State
  const user = ref<User | null>(null)
  const session = ref<Session | null>(null)
  const loading = ref(true)
  const xpNotification = ref<{amount: number, action: string} | null>(null)

  // Computed
  const isAuthenticated = computed(() => !!user.value)

  // Ensure user profile exists
  const ensureUserProfileExists = async () => {
    if (!user.value) return false

    try {
      // Try direct profile check first
      const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('id', user.value.id)
      .maybeSingle();
      
      if (profileError || !profile) {
        console.log('Creating new profile via direct insert');
        
        // Create profile via direct insert
        const { error: insertError } = await supabase
        .from('user_profiles')
        .insert([{
          id: user.value.id,
          username: user.value.user_metadata?.username || 'User',
          level: 1,
          current_xp: 0,
          xp_to_next_level: 100
        }]);
        
        if (insertError) {
          console.warn('Direct profile insert failed, trying RPC:', insertError);
          
          // Try RPC as fallback
          const { error: rpcError } = await supabase.rpc(
            'create_user_profile_safe',
            {
              user_id: user.value.id,
              username: user.value.user_metadata?.username || 'User'
            }
          );
          
          if (rpcError) {
            console.error('All profile creation attempts failed:', rpcError);
            return false;
          }
        }
      }
      
      return true
    } catch (error) {
      console.error('Failed to ensure user profile exists:', error)
      return false
    }
  }

  // Initialize auth state
  const initialize = async () => {
    try {
      // Get initial session
      const { data } = await supabase.auth.getSession()
      session.value = data.session
      user.value = data.session?.user ?? null

      // Listen for auth state changes
      const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, newSession) => {
        // Update session and user
        session.value = newSession
        user.value = newSession?.user ?? null

        loading.value = false
        
        // When user changes to logged in, ensure their profile exists
        if (newSession?.user) {
          ensureUserProfileExists()
        }
      })

      // Return cleanup function for component unmounting
      return () => subscription.unsubscribe()
    } catch (error) {
      console.error('Failed to initialize auth:', error)
      loading.value = false
    }
  }

  // Add experience function
  const addExperience = async (amount: number, action: string) => {
    if (!user.value || !isAuthenticated.value) {
      console.error('Cannot add XP - user not authenticated');
      return null;
    }

    try {
      // Use the refactored xpApi with Supabase Functions
      const response = await xpApi.awardXp(amount, action);

      if (response && response.success) {
        // Show toast notification
        xpNotification.value = { amount, action }
        toast.info(
          `+${amount} XP - ${action}`,
          { icon: '⭐' }
        )

        // Check for level up
        if (response.data && response.data.leveled_up) {
          setTimeout(() => {
            toast.success(
              `LEVEL UP! You've reached level ${response.data.new_level}!`,
              { 
                icon: '🏆',
                timeout: 4000 
              }
            )
          }, 2000)
        }
        
        return response.data
      }
      
      return null
    } catch (error) {
      console.error('Failed to add experience:', error);
      return null;
    }
  }

  // Sign up
  const signUp = async (email: string, password: string, username: string) => {
    try {
      loading.value = true;

      // Sign up with Supabase Auth - profile creation will be handled by auth state change listener
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            username,
          },
        },
      })

      if (error) {
        toast.error(error.message)
        return { error };
      }

      toast.success('Account created successfully!')
      return { data }
    } catch (error: any) {
      toast.error(error.message || 'An error occurred during sign up')
      return { error }
    } finally {
      loading.value = false
    }
  }

  // Sign in
  const signIn = async (email: string, password: string) => {
    try {
      loading.value = true;

      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        toast.error(error.message)
        return { error };
      }

      // Profile creation will be handled by auth state change listener
      toast.success('Signed in successfully!')
      return { data }
    } catch (error: any) {
      toast.error(error.message || 'An error occurred during sign in');
      return { error };
    } finally {
      loading.value = false;
    }
  }

  // Sign out
  const signOut = async () => {
    try {
      // Always clear local state first to ensure UI consistency
      user.value = null
      session.value = null
      loading.value = false
      
      // Only attempt to sign out from Supabase if there's an active session
      const { data: { session: currentSession } } = await supabase.auth.getSession()
      if (currentSession) {
        await supabase.auth.signOut()
      }
      
      toast.success('Signed out successfully')
      return true
    } catch (error: any) {
      // If there's any error, log it but still consider the logout successful
      // since we've already cleared the local state
      console.warn('SignOut warning (local state cleared):', error.message)
      toast.success('Signed out successfully')
      return true
    }
  }

  return {
    // State
    user,
    session,
    loading,
    isAuthenticated,
    xpNotification,
    
    // Actions
    initialize,
    ensureUserProfileExists,
    addExperience,
    signUp,
    signIn,
    signOut
  }
})