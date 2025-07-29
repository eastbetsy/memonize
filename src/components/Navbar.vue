<template>
  <nav class="glass-card border-b border-white/10 sticky top-0 z-50">
    <div class="container mx-auto px-4">
      <div class="flex items-center justify-between h-16">
        <!-- Logo -->
        <RouterLink to="/" class="flex items-center space-x-2 group">
          <div 
            class="p-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-lg"
            :class="{ 'animate-spin': isLogoSpinning }"
            @mouseenter="startLogoSpin"
            @mouseleave="stopLogoSpin"
          >
            <Sparkles class="h-6 w-6 text-white" />
          </div>
          <span class="text-xl font-bold text-glow">Memonize</span>
        </RouterLink>

        <!-- Desktop Navigation -->
        <div class="hidden md:flex items-center space-x-1">
          <RouterLink
            v-for="item in navigation"
            :key="item.name"
            :to="item.href"
            class="flex items-center space-x-2 px-4 py-2 rounded-lg transition-all duration-200 relative overflow-hidden group"
            :class="[
              $route.path === item.href
                ? 'text-cosmic-300 bg-cosmic-900/50'
                : 'text-cosmic-200 hover:text-white hover:bg-white/10'
            ]"
          >
            <component :is="item.icon" class="h-4 w-4" />
            <span class="font-medium">{{ item.name }}</span>
            <div 
              v-if="$route.path === item.href"
              class="absolute inset-0 bg-gradient-to-r from-cosmic-600/20 to-nebula-600/20 rounded-lg"
              :key="`active-${item.href}`"
            ></div>
          </RouterLink>
        </div>

        <!-- Auth Section -->
        <div class="hidden md:flex items-center space-x-4">
          <template v-if="isAuthenticated">
            <div class="flex items-center space-x-4">
              <!-- AI Assistant Button -->
              <button
                @click="showAIAssistant = true"
                class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10 relative"
                title="Draco AI Assistant"
              >
                <Bot class="h-5 w-5" />
                <div class="absolute -top-1 -right-1 w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
              </button>
              
              <!-- Theme Customizer Button -->
              <button
                @click="showFeatureIntegration = true"
                class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                title="Feature Integration"
              >
                <Zap class="h-5 w-5" />
              </button>
              
              <button
                @click="showThemeCustomizer = true"
                class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                title="Customize Theme"
              >
                <Palette class="h-5 w-5" />
              </button>
              
              <!-- Gamification Panel Button -->
              <button
                @click="showGamificationPanel = true"
                class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                title="Achievements & Progress"
              >
                <Trophy class="h-5 w-5" />
              </button>
              
              <span class="text-cosmic-200">
                Welcome, {{ authUser?.user_metadata?.username || authUser?.email }}
              </span>
              <button
                @click="handleSignOut"
                class="nebula-button"
              >
                Sign Out
              </button>
            </div>
          </template>
          <template v-if="!isAuthenticated">
            <button
              @click="showAuthModal = true"
              class="cosmic-button"
            >
              Sign In
            </button>
          </template>
        </div>

        <!-- Mobile menu button -->
        <button
          @click="isMenuOpen = !isMenuOpen"
          class="md:hidden p-2 rounded-lg text-cosmic-200 hover:text-white hover:bg-white/10 transition-colors"
        >
          <Menu v-if="!isMenuOpen" class="h-6 w-6" />
          <X v-else class="h-6 w-6" />
        </button>
      </div>

      <!-- Mobile Navigation -->
      <TransitionGroup v-if="isMenuOpen">
        <div class="md:hidden border-t border-white/10 py-4">
          <div class="space-y-2">
            <RouterLink
              v-for="item in navigation"
              :key="item.name"
              :to="item.href"
              @click="isMenuOpen = false"
              class="flex items-center space-x-3 px-4 py-3 rounded-lg transition-all duration-200"
              :class="[
                $route.path === item.href
                  ? 'text-cosmic-300 bg-cosmic-900/50'
                  : 'text-cosmic-200 hover:text-white hover:bg-white/10'
              ]"
            >
              <component :is="item.icon" class="h-5 w-5" />
              <span class="font-medium">{{ item.name }}</span>
            </RouterLink>
            
            <div class="border-t border-white/10 pt-4 mt-4">
              <template v-if="isAuthenticated">
                <div class="space-y-2">
                  <div class="px-4 py-2 text-cosmic-200">
                    {{ authUser?.user_metadata?.username || authUser?.email }}
                  </div>
                  <button
                    @click="handleSignOut"
                    class="w-full text-left px-4 py-3 text-cosmic-200 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
                  >
                    Sign Out
                  </button>
                </div>
              </template>
              <template v-if="!isAuthenticated">
                <button
                  @click="showAuthModal = true; isMenuOpen = false"
                  class="w-full cosmic-button"
                >
                  Sign In
                </button>
              </template>
            </div>
          </div>
        </div>
      </TransitionGroup>
    </div>
  </nav>

  <!-- Modals -->
  <AuthModal 
    :isOpen="showAuthModal"
    @close="showAuthModal = false"
  />
  
  <AIAssistant
    :isOpen="showAIAssistant"
    @close="showAIAssistant = false"
    :context="{
      currentPage: currentPage,
      recentActivity: [],
      studyGoals: []
    }"
  />
  
  <ThemeCustomizer
    :isOpen="showThemeCustomizer"
    @close="showThemeCustomizer = false"
  />
  
  <NavbarFeatureIntegration
    :isOpen="showFeatureIntegration"
    @close="showFeatureIntegration = false"
  />
  
  <GamificationPanel
    :isOpen="showGamificationPanel"
    @close="showGamificationPanel = false"
  />
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { 
  Home, 
  BookOpen, 
  CreditCard, 
  FileText,
  Gamepad2, 
  User, 
  Users,
  Menu,
  X,
  Sparkles,
  Timer,
  Bot,
  Palette,
  Zap,
  BarChart3,
  Trophy
} from 'lucide-vue-next'
import { useToast } from 'vue-toastification'
import AuthModal from '@/components/AuthModal.vue'
import AIAssistant from '@/components/AIAssistant.vue'
import ThemeCustomizer from '@/components/ThemeCustomizer.vue'
import NavbarFeatureIntegration from '@/components/NavbarFeatureIntegration.vue'
import GamificationPanel from '@/components/GamificationPanel.vue'
import { TransitionGroup } from 'vue'

// Import our custom auth lib alongside the store
import * as authLib from '@/lib/auth'
import { useAuthStore } from '@/stores/auth'

// Navigation items
const navigation = [
  { name: 'Home', href: '/', icon: Home },
  { name: 'Notes', href: '/notes', icon: BookOpen },
  { name: 'Flashcards', href: '/flashcards', icon: CreditCard },
  { name: 'Decks', href: '/decks', icon: FileText },
  { name: 'MemoQuest', href: '/memoquest', icon: Gamepad2 },
  { name: 'Pomodoro', href: '/pomodoro-rooms', icon: Timer },
  { name: 'Study Groups', href: '/study-groups', icon: Users },
  { name: 'Analytics', href: '/analytics', icon: BarChart3 },
  { name: 'Profile', href: '/profile', icon: User },
]

// State
const isMenuOpen = ref(false)
const showAuthModal = ref(false)
const showAIAssistant = ref(false)
const showThemeCustomizer = ref(false)
const showFeatureIntegration = ref(false)
const showGamificationPanel = ref(false)
const isLogoSpinning = ref(false)

// Composables
const toast = useToast()
const authStore = useAuthStore()

// Router
const route = useRoute()
const router = useRouter()

// Computed
const isAuthenticated = computed(() => authStore.isAuthenticated)
const authUser = computed(() => authStore.user)

const currentPage = computed(() => {
  // Ensure the user profile exists if authenticated
  if (authStore.isAuthenticated && authStore.user) {
    authLib.ensureUserProfile(
      authStore.user.id, 
      authStore.user.user_metadata?.username
    )
    .then(result => {
      if (result) {
        console.log('User profile checked/created');
      }
    })
    .catch(err => {
      console.warn('Error ensuring user profile exists:', err);
    });
  }
  
  const path = route.path
  return path.slice(1) || 'home'
})

// Methods
const handleSignOut = () => {
  authStore.signOut()
    .then(() => {
      isMenuOpen.value = false
      router.push('/')
    })
    .catch(error => {
      // Even if signOut fails, still navigate and close menu
      isMenuOpen.value = false
      router.push('/')
      console.error('Sign out error:', error)
    })
}

const startLogoSpin = () => {
  isLogoSpinning.value = true
}

const stopLogoSpin = () => {
  isLogoSpinning.value = false
}
</script>

<style scoped>
.animate-spin {
  animation: spin 0.6s linear;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>