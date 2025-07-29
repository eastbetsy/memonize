<template>
  <div class="max-w-4xl mx-auto space-y-8">
    <!-- Profile Header -->
    <div class="glass-card p-8 text-center relative overflow-hidden">
      <div class="absolute inset-0 bg-gradient-to-br from-cosmic-600/20 to-nebula-600/20"></div>
      
      <div class="relative z-10">
        <div class="w-24 h-24 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl">
          🚀
        </div>
        
        <h1 class="text-3xl font-bold text-glow mb-2">{{ profile.username }}</h1>
        <p class="text-cosmic-300 mb-6">Cosmic Explorer • Level {{ profile.level }}</p>
        
        <div class="max-w-md mx-auto relative">
          <div class="glass-card p-4 border-cosmic-500/30">
            <div class="flex justify-between text-sm text-cosmic-300 mb-2">
              <span>Level {{ profile.level }}</span>
              <span>{{ profile.experience }} XP Total</span>
            </div>
            <div class="w-full bg-cosmic-900/50 rounded-full h-3">
              <div
                class="bg-gradient-to-r from-cosmic-500 to-nebula-500 h-3 rounded-full"
                :style="{ width: `${getProgressToNextLevel(profile.experience)}%` }"
              ></div>
            </div>
            <div class="text-xs text-cosmic-400 mt-2 text-center">
              {{ Math.round(getExperienceForNextLevel(profile.experience) - profile.experience) }} XP until Level {{ profile.level + 1 }}
            </div>
            
            <button 
              @click="showGamificationPanel = true"
              class="absolute -top-10 -right-10 cosmic-button flex items-center space-x-1 px-3 py-1.5 rounded-full text-sm"
            >
              <Trophy class="h-4 w-4" />
              <span>Achievements</span>
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Recent XP Activity -->
    <div class="glass-card p-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-xl font-bold text-white flex items-center">
          <Zap class="h-5 w-5 mr-2 text-star-400" />
          Recent XP Activity
        </h3>
        
        <button 
          @click="showGamificationPanel = true"
          class="text-cosmic-300 hover:text-white text-sm flex items-center"
        >
          View All
          <ChevronRight class="h-4 w-4 ml-1" />
        </button>
      </div>
      
      <div v-if="loading" class="flex items-center justify-center py-8">
        <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
      
      <div v-else-if="recentXp.length > 0" class="space-y-3">
        <div 
          v-for="item in recentXp" 
          :key="item.id"
          class="flex justify-between items-center p-3 bg-white/5 rounded-lg"
        >
          <div>
            <div class="text-white">{{ item.description }}</div>
            <div class="text-xs text-cosmic-400">
              {{ formatDate(item.created_at) }}
            </div>
          </div>
          <div class="flex items-center space-x-1 text-star-400 font-bold">
            <Star class="h-4 w-4" />
            <span>+{{ item.amount }} XP</span>
          </div>
        </div>
      </div>
      
      <div v-else class="text-center py-6">
        <Clock class="h-12 w-12 text-cosmic-400 mx-auto mb-3 opacity-50" />
        <p class="text-cosmic-300">No XP activity yet</p>
        <button 
          @click="resetAndSyncAnalytics" 
          class="mt-3 cosmic-button text-xs"
          :disabled="isResetting"
        >
          <span v-if="isResetting">Syncing...</span>
          <span v-else>Reset & Sync Analytics</span>
        </button>
      </div>
    </div>
    
    <!-- Stats Grid -->
    <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div 
        v-for="(stat, index) in stats" 
        :key="index"
        class="glass-card p-6 text-center"
      >
        <div 
          class="inline-flex p-3 rounded-xl bg-gradient-to-r mb-4"
          :class="stat.color"
        >
          <component :is="stat.icon" class="h-6 w-6 text-white" />
        </div>
        <div class="text-2xl font-bold text-white mb-1">{{ stat.value }}</div>
        <div class="text-cosmic-300 text-sm">{{ stat.label }}</div>
      </div>
    </div>

    <!-- Achievements -->
    <div class="glass-card p-8">
      <h2 class="text-2xl font-bold text-white mb-6 flex items-center">
        <Trophy class="h-6 w-6 mr-2 text-star-400" />
        Cosmic Achievements
      </h2>
      
      <div v-if="loading" class="flex items-center justify-center py-8">
        <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
      
      <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="achievement in achievements"
          :key="achievement.id"
          class="glass-card p-6 text-center transition-all duration-300"
          :class="[
            isAchievementUnlocked(achievement.id) 
              ? 'border-star-400/50 hover:border-star-400' 
              : 'opacity-50'
          ]"
        >
          <div class="text-4xl mb-4">{{ achievement.icon }}</div>
          <h3 
            class="font-bold mb-2"
            :class="[
              isAchievementUnlocked(achievement.id) ? 'text-white text-glow' : 'text-cosmic-400'
            ]"
          >
            {{ achievement.title }}
          </h3>
          <p class="text-cosmic-300 text-sm">{{ achievement.description }}</p>
          
          <div v-if="isAchievementUnlocked(achievement.id)" class="mt-4">
            <span class="inline-flex items-center space-x-1 px-3 py-1 bg-star-500/20 text-star-300 rounded-full text-xs font-medium">
              <Sparkles class="h-3 w-3" />
              <span>Unlocked</span>
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Activity Timeline -->
    <div class="glass-card p-8">
      <h2 class="text-2xl font-bold text-white mb-6 flex items-center">
        <Calendar class="h-6 w-6 mr-2 text-cosmic-400" />
        Recent Activity
      </h2>
      
      <div class="space-y-4">
        <div
          v-for="(activity, index) in recentActivity"
          :key="index"
          class="flex items-center space-x-4 p-4 bg-white/5 rounded-lg hover:bg-white/10 transition-colors"
        >
          <div class="text-2xl">{{ activity.icon }}</div>
          <div class="flex-1">
            <div class="text-white font-medium">{{ activity.action }}</div>
            <div class="text-cosmic-300 text-sm">{{ activity.details }}</div>
          </div>
          <div class="text-cosmic-400 text-sm">{{ activity.time }}</div>
        </div>
      </div>
    </div>

    <!-- Gamification Panel -->
    <GamificationPanel
      :isOpen="showGamificationPanel"
      @close="showGamificationPanel = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Award,
  User, 
  Trophy,
  RefreshCw,
  BookOpen, 
  CreditCard, 
  Calendar,
  TrendingUp,
  Sparkles,
  ChevronRight,
  Star,
  Zap,
  Clock
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import GamificationPanel from '@/components/GamificationPanel.vue'

interface UserProfile {
  username: string
  level: number
  experience: number
  streak: number
  total_notes: number
  total_flashcards: number
  total_study_time: number
  achievements: string[]
}

interface Achievement {
  id: string
  title: string
  description: string
  icon: string
}

interface XpTransaction {
  id: string
  amount: number
  description: string
  created_at: string
}

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const isResetting = ref(false)
const profile = ref<UserProfile>({
  username: authStore.user?.user_metadata?.username || 'Cosmic Explorer',
  level: 1,
  experience: 250,
  streak: 3,
  total_notes: 12,
  total_flashcards: 45,
  total_study_time: 180, // minutes
  achievements: ['first_note', 'first_flashcard', 'first_quest']
})

const achievements = ref<Achievement[]>([
  {
    id: 'first_note',
    title: 'Cosmic Scribe',
    description: 'Created your first note',
    icon: '📝'
  },
  {
    id: 'first_flashcard',
    title: 'Memory Master',
    description: 'Generated your first flashcard',
    icon: '🧠'
  },
  {
    id: 'first_quest',
    title: 'Space Explorer',
    description: 'Completed your first MemoQuest',
    icon: '🚀'
  },
  {
    id: 'study_streak_7',
    title: 'Dedicated Learner',
    description: 'Maintained a 7-day study streak',
    icon: '🔥'
  },
  {
    id: 'notes_100',
    title: 'Knowledge Collector',
    description: 'Created 100 notes',
    icon: '📚'
  },
  {
    id: 'perfect_score',
    title: 'Ace Pilot',
    description: 'Achieved 100% accuracy in a quest',
    icon: '⭐'
  }
])

const recentXp = ref<XpTransaction[]>([])
const loading = ref(true)
const showGamificationPanel = ref(false)

// Recent activity mock data
const recentActivity = ref([
  { icon: '📝', action: 'Created a new note', time: '2 hours ago', details: 'Introduction to Stellar Navigation' },
  { icon: '🧠', action: 'Generated flashcards', time: '5 hours ago', details: '15 cards from Astronomy notes' },
  { icon: '🚀', action: 'Completed MemoQuest', time: '1 day ago', details: 'Score: 850 points' },
  { icon: '🏆', action: 'Unlocked achievement', time: '2 days ago', details: 'Space Explorer' },
  { icon: '📚', action: 'Study session', time: '3 days ago', details: '45 minutes focused study' }
])

// Computed stats based on profile
const stats = computed(() => [
  { 
    icon: BookOpen, 
    label: 'Notes Created', 
    value: profile.value.total_notes, 
    color: 'from-cosmic-500 to-cosmic-600' 
  },
  { 
    icon: CreditCard, 
    label: 'Flashcards', 
    value: profile.value.total_flashcards, 
    color: 'from-nebula-500 to-nebula-600' 
  },
  { 
    icon: Calendar, 
    label: 'Study Streak', 
    value: `${profile.value.streak} days`, 
    color: 'from-star-500 to-star-600' 
  },
  { 
    icon: TrendingUp, 
    label: 'Study Time', 
    value: formatTime(profile.value.total_study_time),
    color: 'from-green-500 to-green-600' 
  }
])

// Lifecycle
onMounted(async () => {
  if (authStore.isAuthenticated) {
    await fetchUserData()
  }
})

// Methods
const fetchUserData = async () => {
  loading.value = true
  try {
    // Fetch user profile
    const { data, error } = await supabase
      .from('user_profiles')
      .select('username, level, experience, study_streak, total_study_time, achievements, current_xp, xp_to_next_level')
      .eq('id', authStore.user?.id)
      .single()

    if (error) throw error
    
    profile.value = {
      username: data.username || authStore.user?.user_metadata?.username || 'Cosmic Explorer',
      level: data.level || 1,
      experience: data.current_xp || 0,
      streak: data.study_streak || 0,
      total_notes: 0,
      total_flashcards: 0,
      total_study_time: data.total_study_time || 0,
      achievements: data.achievements || []
    }
    
    // Fetch note and flashcard counts
    try {
      const [notesResponse, flashcardsResponse] = await Promise.all([
        supabase.from('notes').select('*', { count: 'exact', head: true }).eq('user_id', authStore.user?.id),
        supabase.from('flashcards').select('*', { count: 'exact', head: true }).eq('user_id', authStore.user?.id)
      ])
      
      profile.value.total_notes = notesResponse.count || 0
      profile.value.total_flashcards = flashcardsResponse.count || 0
    } catch (countError) {
      console.error('Error counting notes/flashcards:', countError)
    }

    // Fetch recent XP transactions
    try {
      const { data: xpData, error: xpError } = await supabase
        .from('xp_transactions')
        .select('id, amount, description, created_at')
        .eq('user_id', authStore.user?.id)
        .order('created_at', { ascending: false })
        .limit(5)

      if (xpError) throw xpError
      recentXp.value = xpData || []
    } catch (xpError) {
      console.error('Error fetching XP history:', xpError)
    }
  } catch (error) {
    console.error('Error fetching user data:', error)
    toast.error('Failed to load profile data')
  } finally {
    loading.value = false
  }
}

const calculateLevel = (exp: number) => {
  return Math.floor(exp / 100) + 1
}

const getExperienceForNextLevel = (currentExp: number) => {
  const currentLevel = calculateLevel(currentExp)
  return currentLevel * 100
}

const getProgressToNextLevel = (currentExp: number) => {
  const currentLevel = calculateLevel(currentExp)
  const expInCurrentLevel = currentExp - ((currentLevel - 1) * 100)
  return (expInCurrentLevel / 100) * 100
}

const formatTime = (minutes: number): string => {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  return date.toLocaleDateString(undefined, { 
    month: 'short', 
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const isAchievementUnlocked = (id: string): boolean => {
  return profile.value.achievements.includes(id)
}

// Reset and sync analytics
const resetAndSyncAnalytics = async () => {
  if (!confirm('This will reset and recalculate your analytics based on your activity. Continue?')) {
    return
  }
  
  isResetting.value = true
  try {
    const response = await fetch('/api/reset-analytics', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.session?.access_token}`
      },
      body: JSON.stringify({
        resetAchievements: false
      })
    });
    
    const data = await response.json();
    
    if (!data.success) {
      throw new Error(data.error || 'Failed to reset analytics');
    }
    
    toast.success('Analytics reset and synced successfully');
    // Refresh data
    await fetchUserProfile();
    await fetchXP();
  } catch (error) {
    console.error('Error resetting analytics:', error);
    toast.error('Failed to reset analytics');
  } finally {
    isResetting.value = false;
  }
}
</script>