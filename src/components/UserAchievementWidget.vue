<template>
  <div v-if="authStore.isAuthenticated && userProfile" class="fixed bottom-4 right-4 z-40">
    <div 
      class="glass-card overflow-hidden transition-all duration-300"
      :class="{ 'w-80': !isMinimized, 'w-64': isMinimized, 'p-2': showResetButton }"
    >
      <!-- Header -->
      <div 
        class="flex items-center justify-between p-3 cursor-pointer border-b border-white/10"
        @click="toggleMinimize"
      >
        <div class="flex items-center space-x-2">
          <Award class="h-4 w-4 text-star-400" />
          <span class="text-white font-medium text-sm">Level {{ userProfile.level }}</span>
        </div>
        <button class="text-cosmic-300">
          <ChevronUp v-if="isMinimized" class="h-4 w-4" />
          <ChevronDown v-else class="h-4 w-4" />
        </button>
      </div>
      
      <!-- Reset Analytics Button -->
      <div v-if="showResetButton" class="border-t border-white/10 pt-2 mt-1">
        <button 
          @click="resetAnalytics"
          class="w-full text-xs text-center cosmic-button py-1.5 flex items-center justify-center space-x-1"
          :disabled="isResetting"
        >
          <RotateCcw v-if="!isResetting" class="h-3 w-3" />
          <div v-else class="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin"></div>
          <span>{{ isResetting ? 'Resetting...' : 'Reset & Sync Analytics' }}</span>
        </button>
      </div>
      
      <!-- Content -->
      <div v-if="!isMinimized" class="p-3 space-y-3">
        <!-- XP Progress -->
        <div>
          <div class="flex justify-between text-xs text-cosmic-400 mb-1">
            <span>{{ userProfile.current_xp }} XP</span>
            <span>{{ userProfile.xp_to_next_level }} XP</span>
          </div>
          <div class="w-full h-2 bg-cosmic-900/50 rounded-full">
            <div 
              class="h-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full transition-all duration-300"
              :style="{ width: `${(userProfile.current_xp / userProfile.xp_to_next_level) * 100}%` }"
            />
          </div>
        </div>
        
        <!-- Recent Achievements -->
        <div v-if="recentAchievements.length > 0">
          <div class="text-xs text-cosmic-300 mb-2">Recent Achievements</div>
          <div class="space-y-2">
            <div 
              v-for="(achievement, index) in recentAchievements"
              :key="index"
              class="text-xs flex justify-between items-center bg-white/5 p-2 rounded"
            >
              <span class="text-white">{{ achievement.achievement_name }}</span>
              <span :class="getRarityColor(achievement.rarity)" class="capitalize">
                {{ achievement.rarity }}
              </span>
            </div>
          </div>
        </div>
        
        <!-- View All Button -->
        <button
          @click="toggleResetButton"
          class="w-full py-2 text-xs text-center text-cosmic-300 hover:text-white hover:bg-white/10 rounded transition-colors flex items-center justify-center space-x-1"
        >
          <RefreshCw class="h-3 w-3" />
          <span>Manage Analytics</span>
        </button>
      </div>
    </div>
  </div>

  <GamificationPanel
    :isOpen="showGamificationPanel"
    @close="showGamificationPanel = false"
  />
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { Award, ChevronUp, ChevronDown, RefreshCw, RotateCcw } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'
import { supabase } from '@/lib/supabase'
import GamificationPanel from './GamificationPanel.vue'

interface Props {
  minimized?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  minimized: false
})

// State
const isMinimized = ref(props.minimized)
const showResetButton = ref(false)
const isResetting = ref(false)
const userProfile = ref<{
  level: number
  current_xp: number
  xp_to_next_level: number
} | null>(null)

const recentAchievements = ref<{
  achievement_name: string
  rarity: string
  unlocked_at: string
}[]>([])

const showGamificationPanel = ref(false)

// Store
const authStore = useAuthStore()
const toast = useToast()

// Methods
const fetchUserProfile = async () => {
  if (!authStore.user?.id) return
  
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('level, current_xp, xp_to_next_level')
      .eq('id', authStore.user.id)
      .single()

    if (error) throw error
    userProfile.value = data
  } catch (error) {
    console.error('Error fetching user profile:', error)
  }
}

const fetchRecentAchievements = async () => {
  if (!authStore.user?.id) return
  
  try {
    const { data, error } = await supabase
      .from('achievements')
      .select('achievement_name, rarity, unlocked_at')
      .eq('user_id', authStore.user.id)
      .order('unlocked_at', { ascending: false })
      .limit(3)

    if (error) throw error
    recentAchievements.value = data || []
  } catch (error) {
    console.error('Error fetching achievements:', error)
  }
}

const toggleMinimize = () => {
  isMinimized.value = !isMinimized.value
}

const toggleResetButton = () => {
  showResetButton.value = !showResetButton.value
}

const resetAnalytics = async () => {
  if (!confirm('This will reset and recalculate your analytics based on your activity. Continue?')) {
    return
  }
  
  isResetting.value = true
  try {
    const { data, error } = await fetch('/api/reset-analytics', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.session?.access_token}`
      },
      body: JSON.stringify({
        resetAchievements: false
      })
    }).then(res => res.json())
    
    if (error) throw error
    
    toast.success('Analytics reset and synced successfully')
    fetchUserProfile()
    fetchRecentAchievements()
  } catch (error) {
    console.error('Error resetting analytics:', error)
    toast.error('Failed to reset analytics')
  } finally {
    isResetting.value = false
    showResetButton.value = false
  }
}

const getRarityColor = (rarity: string): string => {
  switch (rarity) {
    case 'common': return 'text-green-400'
    case 'uncommon': return 'text-blue-400'
    case 'rare': return 'text-purple-400'
    case 'epic': return 'text-nebula-400'
    case 'legendary': return 'text-star-400'
    default: return 'text-cosmic-400'
  }
}

// Lifecycle
onMounted(() => {
  if (authStore.isAuthenticated) {
    fetchUserProfile()
    fetchRecentAchievements()
  }
})
</script>