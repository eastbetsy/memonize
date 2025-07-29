<template>
  <Teleport to="body">
    <div 
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4"
    >
      <!-- Backdrop -->
      <div 
        class="absolute inset-0 bg-black/50 backdrop-blur-sm" 
        @click="$emit('close')"
      />

      <!-- Panel -->
      <div class="relative w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col">
        <div class="glass-card relative flex flex-col h-full">
          <!-- Background effects -->
          <div class="absolute inset-0 bg-gradient-to-br from-cosmic-600/10 to-nebula-600/10"></div>
          <div class="absolute top-0 right-0 w-32 h-32 bg-cosmic-500/20 rounded-full blur-3xl"></div>

          <div class="relative z-10 flex flex-col h-full">
            <!-- Header -->
            <div class="flex items-center justify-between p-4 md:p-6 border-b border-white/10">
              <div class="flex items-center space-x-3">
                <div class="p-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-lg">
                  <Trophy class="h-5 w-5 text-white" />
                </div>
                <div>
                  <h2 class="text-lg md:text-xl font-bold text-glow">Cosmic Achievements</h2>
                  <div class="flex items-center space-x-1">
                    <span class="text-cosmic-300 text-sm">Level {{ userProfile?.level || 1 }}</span>
                    <span v-if="userProfile" class="text-xs text-cosmic-400">
                      • {{ userProfile.current_xp }}/{{ userProfile.xp_to_next_level }} XP
                    </span>
                  </div>
                </div>
              </div>
              
              <button
                @click="$emit('close')"
                class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
              >
                ×
              </button>
            </div>

            <!-- Progress bar -->
            <div v-if="userProfile" class="relative px-4 md:px-6 py-3 border-b border-white/10 bg-white/5">
              <div class="flex justify-between text-xs text-cosmic-400 mb-1">
                <span>Level {{ userProfile.level }}</span>
                <span>Level {{ userProfile.level + 1 }}</span>
              </div>
              <div class="w-full h-2 bg-cosmic-900/50 rounded-full">
                <div
                  class="h-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full"
                  :style="{ width: `${(userProfile.current_xp / userProfile.xp_to_next_level) * 100}%` }"
                ></div>
              </div>
              <div class="flex justify-between text-xs text-cosmic-400 mt-1">
                <span>{{ userProfile.current_xp }} XP</span>
                <span>{{ userProfile.xp_to_next_level - userProfile.current_xp }} XP to next level</span>
              </div>
            </div>

            <!-- Navigation Tabs -->
            <div class="flex overflow-x-auto border-b border-white/10">
              <button
                v-for="tab in navigationTabs"
                :key="tab.id"
                @click="activeTab = tab.id"
                :class="[
                  'flex items-center space-x-2 px-4 py-3 transition-colors flex-shrink-0',
                  activeTab === tab.id
                    ? 'text-white border-b-2 border-cosmic-500 -mb-px'
                    : 'text-cosmic-300 hover:text-cosmic-200'
                ]"
              >
                <component :is="tab.icon" class="h-4 w-4" />
                <span>{{ tab.label }}</span>
              </button>
            </div>

            <!-- Tab Content -->
            <div class="flex-1 overflow-y-auto p-4 md:p-6">
              <div v-if="loading" class="flex items-center justify-center py-12">
                <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
              </div>
              
              <div v-else>
                <div v-if="activeTab === 'overview'" class="space-y-6">
                  <div class="text-center">
                    <Trophy class="h-12 w-12 text-cosmic-400 mx-auto mb-4" />
                    <p class="text-cosmic-400">Gamification panel coming soon!</p>
                    <p class="text-sm mt-2 text-cosmic-300">
                      Track your achievements, progress, and unlock new features as you level up.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import {
  Award,
  Trophy,
  Clock,
  BarChart2
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

// Props
defineProps<{
  isOpen: boolean
}>()

// Emits
defineEmits<{
  (e: 'close'): void
}>()

// Composables
const authStore = useAuthStore()

// State
const activeTab = ref('overview')
const loading = ref(true)
const userProfile = ref<{
  level: number
  current_xp: number
  xp_to_next_level: number
} | null>(null)

// Navigation tabs
const navigationTabs = [
  { id: 'overview', label: 'Overview', icon: Award },
  { id: 'achievements', label: 'Achievements', icon: Trophy },
  { id: 'history', label: 'XP History', icon: Clock },
  { id: 'stats', label: 'Stats', icon: BarChart2 }
]

// Lifecycle
onMounted(async () => {
  if (authStore.isAuthenticated) {
    await fetchUserProfile()
  }
})

// Methods
const fetchUserProfile = async () => {
  try {
    loading.value = true
    
    const { data, error } = await supabase
      .from('user_profiles')
      .select('level, current_xp, xp_to_next_level')
      .eq('id', authStore.user?.id)
      .single()
    
    if (error) throw error
    
    userProfile.value = {
      level: data.level || 1,
      current_xp: data.current_xp || 0,
      xp_to_next_level: data.xp_to_next_level || 100
    }
  } catch (error) {
    console.error('Error fetching user profile:', error)
  } finally {
    loading.value = false
  }
}
</script>