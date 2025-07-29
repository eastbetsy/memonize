<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-black/50 backdrop-blur-sm" 
          @click="closeModal"
        ></div>

        <!-- Modal -->
        <div 
          class="relative w-full max-w-md mx-4"
          @click.stop
        >
          <div class="glass-card p-6 md:p-8 h-full relative overflow-hidden">
            <div class="absolute inset-0 bg-gradient-to-br from-cosmic-600/10 to-nebula-600/10"></div>
            <div class="absolute top-0 right-0 w-32 h-32 bg-cosmic-500/20 rounded-full blur-3xl"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-nebula-500/20 rounded-full blur-2xl"></div>

            <div class="relative z-10">
              <!-- Header -->
              <div class="flex items-center justify-between mb-6 md:mb-8">
                <div class="flex items-center space-x-3">
                  <div class="p-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-lg">
                    <Sparkles class="h-6 w-6 text-white" />
                  </div>
                  <h2 class="text-xl md:text-2xl font-bold text-glow">
                    {{ isSignUp ? 'Join Memonize' : 'Welcome Back' }}
                  </h2>
                </div>
                <button
                  @click="closeModal"
                  class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                >
                  <X class="h-5 w-5" />
                </button>
              </div>

              <!-- Error Alert -->
              <div v-if="errorMessage" class="mb-4 p-4 bg-red-500/10 border border-red-500/20 rounded-lg">
                <div class="flex items-start space-x-3">
                  <div class="p-1 bg-red-500/20 rounded-full">
                    <X class="h-4 w-4 text-red-400" />
                  </div>
                  <div class="flex-1">
                    <h4 class="text-red-400 font-medium text-sm">{{ errorTitle }}</h4>
                    <p class="text-red-300 text-sm mt-1">{{ errorMessage }}</p>
                    <div v-if="showRetry" class="mt-3">
                      <button
                        @click="retrySignup"
                        :disabled="loading"
                        class="text-sm px-3 py-1 bg-red-500/20 hover:bg-red-500/30 text-red-300 rounded transition-colors disabled:opacity-50"
                      >
                        Try Again
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Form -->
              <form @submit.prevent="handleSubmit" class="space-y-4 md:space-y-6">
                <div v-if="isSignUp">
                  <label class="block text-sm font-medium text-cosmic-200 mb-2">
                    Username
                  </label>
                  <div class="relative">
                    <User class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-cosmic-400" />
                    <input
                      type="text"
                      v-model="username"
                      class="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                      placeholder="Choose a username"
                      required
                      :disabled="loading"
                      minlength="3"
                      maxlength="30"
                    />
                  </div>
                  <p class="text-xs text-cosmic-400 mt-1">3-30 characters, letters and numbers only</p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-cosmic-200 mb-2">
                    Email
                  </label>
                  <div class="relative">
                    <Mail class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-cosmic-400" />
                    <input
                      type="email"
                      v-model="email"
                      class="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                      placeholder="Enter your email"
                      required
                      :disabled="loading"
                    />
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-cosmic-200 mb-2">
                    Password
                  </label>
                  <div class="relative">
                    <Lock class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-cosmic-400" />
                    <input
                      type="password"
                      v-model="password"
                      class="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                      placeholder="Enter your password"
                      required
                      minlength="6"
                      :disabled="loading"
                    />
                  </div>
                  <p class="text-xs text-cosmic-400 mt-1">At least 6 characters</p>
                </div>

                <button
                  type="submit"
                  :disabled="loading || !isFormValid"
                  class="w-full cosmic-button py-3 md:py-3 font-semibold transition-all"
                  :class="{'opacity-50 cursor-not-allowed': loading || !isFormValid}"
                >
                  <div v-if="loading" class="flex items-center justify-center space-x-2">
                    <div class="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                    <span>{{ loadingText }}</span>
                  </div>
                  <span v-else>{{ isSignUp ? 'Create Account' : 'Sign In' }}</span>
                </button>
              </form>

              <!-- Toggle mode -->
              <div class="mt-4 md:mt-6 text-center">
                <span class="text-cosmic-300">
                  {{ isSignUp ? 'Already have an account?' : "Don't have an account?" }}
                </span>
                <button
                  @click="toggleMode"
                  :disabled="loading"
                  class="ml-2 text-cosmic-400 hover:text-cosmic-300 font-medium transition-colors disabled:opacity-50"
                >
                  {{ isSignUp ? 'Sign In' : 'Sign Up' }}
                </button>
              </div>

              <!-- Help Text -->
              <div class="mt-4 text-center">
                <p class="text-xs text-cosmic-400">
                  Having trouble? Contact support if issues persist.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { X, Mail, Lock, User, Sparkles } from 'lucide-vue-next'
import * as auth from '@/lib/auth'
import { useToast } from 'vue-toastification'

// Props
const props = defineProps<{
  isOpen: boolean
}>()

// Emits
const emit = defineEmits<{
  (e: 'close'): void
}>()

// State
const isSignUp = ref(false)
const email = ref('')
const password = ref('')
const username = ref('')
const loading = ref(false)
const errorMessage = ref('')
const errorTitle = ref('')
const showRetry = ref(false)
const retryAttempts = ref(0)
const toast = useToast()

// Computed
const isFormValid = computed(() => {
  const emailValid = email.value.includes('@') && email.value.includes('.')
  const passwordValid = password.value.length >= 6
  const usernameValid = !isSignUp.value || (username.value.length >= 3 && username.value.length <= 30)
  
  return emailValid && passwordValid && usernameValid
})

const loadingText = computed(() => {
  if (isSignUp.value) {
    return retryAttempts.value > 0 ? 'Retrying...' : 'Creating Account...'
  }
  return 'Signing In...'
})

// Watch for modal open/close to reset form
watch(() => props.isOpen, (newValue) => {
  if (newValue) {
    resetForm()
  }
})

// Methods
const handleSubmit = async () => {
  if (loading.value || !isFormValid.value) return
  
  clearError()
  loading.value = true

  try {
    if (isSignUp.value) {
      await handleSignUp()
    } else {
      await handleSignIn()
    }
  } catch (error: any) {
    console.error('Auth error:', error)
    handleAuthError(error)
  } finally {
    loading.value = false
  }
}

const handleSignUp = async () => {
  try {
    const response = await auth.signUp(email.value.trim(), password.value, username.value.trim())
    
    if (response.error) {
      throw response.error
    }
    
    // Success
    retryAttempts.value = 0
    toast.success('Account created successfully! Welcome to Memonize!')
    closeModal()
    
  } catch (error: any) {
    retryAttempts.value++
    throw error
  }
}

const handleSignIn = async () => {
  const response = await auth.signIn(email.value.trim(), password.value)
  
  if (response.error) {
    throw response.error
  }
  
  // Success
  toast.success('Welcome back!')
  closeModal()
}

const handleAuthError = (error: any) => {
  console.error('Authentication error:', error)
  
  const errorMsg = error.message || error.toString()
  
  // Handle specific error types
  if (errorMsg.includes('Database error saving new user')) {
    errorTitle.value = 'Account Creation Error'
    errorMessage.value = 'There was a problem setting up your account. This is usually temporary.'
    showRetry.value = true
  } else if (errorMsg.includes('User already registered')) {
    errorTitle.value = 'Account Already Exists'
    errorMessage.value = 'An account with this email already exists. Try signing in instead.'
    showRetry.value = false
  } else if (errorMsg.includes('Invalid login credentials')) {
    errorTitle.value = 'Invalid Credentials'
    errorMessage.value = 'The email or password you entered is incorrect.'
    showRetry.value = false
  } else if (errorMsg.includes('Email not confirmed')) {
    errorTitle.value = 'Email Not Confirmed'
    errorMessage.value = 'Please check your email and click the confirmation link.'
    showRetry.value = false
  } else if (errorMsg.includes('Too many requests')) {
    errorTitle.value = 'Too Many Attempts'
    errorMessage.value = 'Please wait a moment before trying again.'
    showRetry.value = false
  } else {
    errorTitle.value = isSignUp.value ? 'Sign Up Failed' : 'Sign In Failed'
    errorMessage.value = 'An unexpected error occurred. Please try again.'
    showRetry.value = true
  }
  
  // Show toast for serious errors
  if (errorMsg.includes('Database error') || retryAttempts.value > 2) {
    toast.error(errorMessage.value)
  }
}

const retrySignup = async () => {
  if (retryAttempts.value >= 3) {
    toast.error('Multiple attempts failed. Please try again later or contact support.')
    return
  }
  
  await handleSubmit()
}

const toggleMode = () => {
  if (loading.value) return
  
  isSignUp.value = !isSignUp.value
  resetForm()
}

const resetForm = () => {
  email.value = ''
  password.value = ''
  username.value = ''
  loading.value = false
  retryAttempts.value = 0
  clearError()
}

const clearError = () => {
  errorMessage.value = ''
  errorTitle.value = ''
  showRetry.value = false
}

const closeModal = () => {
  if (loading.value) return
  emit('close')
}

// Clean up username input
watch(username, (newValue) => {
  // Remove special characters except letters, numbers, and underscores
  username.value = newValue.replace(/[^a-zA-Z0-9_]/g, '')
})
</script>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.glass-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
}

.cosmic-button {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  border: none;
  border-radius: 8px;
  color: white;
  transition: all 0.3s ease;
}

.cosmic-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #5856eb, #7c3aed);
  transform: translateY(-1px);
  box-shadow: 0 10px 25px rgba(99, 102, 241, 0.3);
}

.text-glow {
  text-shadow: 0 0 20px rgba(99, 102, 241, 0.5);
}
</style>