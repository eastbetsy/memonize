<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="text-center">
      <div class="flex items-center justify-center space-x-3 mb-4">
        <div class="p-3 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-xl">
          <Brain class="h-8 w-8 text-white" />
        </div>
        <h1 class="text-3xl md:text-4xl font-bold text-glow">Cosmic Analytics</h1>
      </div>
      <p class="text-cosmic-300 text-lg max-w-2xl mx-auto">
        Unlock the secrets of your learning universe with AI-powered insights and advanced analytics
      </p>
    </div>

    <div v-if="!authStore.isAuthenticated" class="text-center py-20">
      <BarChart3 class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h2 class="text-2xl font-bold text-white mb-4">Sign in to access analytics</h2>
      <p class="text-cosmic-300">Create an account to track your learning progress and insights</p>
    </div>
    
    <div v-else-if="loading" class="flex items-center justify-center py-20">
      <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
    </div>

    <div v-else>
      <!-- Pomodoro Integration - Show Stats with Insights -->
      <div v-if="productivityInsights?.pomodoroStats" class="mb-8">
        <h2 class="text-xl font-bold text-white mb-4 flex items-center">
          <Timer class="h-5 w-5 mr-2 text-cosmic-400" />
          Pomodoro Activity & Task Completion
        </h2>
        
        <!-- Productivity Overview -->
        <div class="glass-card p-6">
          <h3 class="text-xl font-bold text-white mb-6 flex items-center">
            <BarChart3 class="h-6 w-6 mr-2 text-cosmic-400" />
            Productivity Overview
          </h3>
          
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-green-400">{{ productivityInsights.pomodoroStats.sessionsToday }}</div>
              <div class="text-sm text-cosmic-300">Today</div>
              <div class="w-full bg-cosmic-900/50 rounded-full h-2 mt-2">
                <div
                  class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full"
                  :style="{ width: `${Math.min(progressToday, 100)}%` }"
                ></div>
              </div>
            </div>
            
            <div class="text-center">
              <div class="text-2xl font-bold text-cosmic-400">{{ productivityInsights.pomodoroStats.totalSessions }}</div>
              <div class="text-sm text-cosmic-300">Total Sessions</div>
            </div>
            
            <div class="text-center">
              <div class="text-2xl font-bold text-star-400">{{ productivityInsights.pomodoroStats.currentStreak }}</div>
              <div class="text-sm text-cosmic-300">Current Streak</div>
            </div>
            
            <div class="text-center">
              <div class="text-2xl font-bold text-nebula-400">{{ formatStudyTime(productivityInsights.pomodoroStats.focusTimeToday) }}</div>
              <div class="text-sm text-cosmic-300">Focus Time</div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Productivity Insights from Pomodoro Sessions -->
      <div v-if="productivityInsights" class="glass-card p-6 mb-8">
        <h2 class="text-xl font-bold text-white mb-4 flex items-center">
          <Timer class="h-5 w-5 mr-2 text-cosmic-400" />
          Pomodoro Session Insights
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="space-y-4">
            <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4">
              <div class="flex items-start space-x-3">
                <Calendar class="h-5 w-5 text-cosmic-400 mt-1 flex-shrink-0" />
                <div>
                  <h3 class="text-white font-medium">Time of Day Analysis</h3>
                  <p class="text-cosmic-300 text-sm mt-1">
                    You're <span class="text-white font-medium">{{ Math.round((productivityInsights.averageFocusScore / 60) * 100) }}% more productive</span> during 
                    the <span class="text-white font-medium">{{ productivityInsights.bestTimeOfDay }}</span>.
                    Consider scheduling challenging tasks during this optimal time window.
                  </p>
                </div>
              </div>
            </div>
            
            <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4">
              <div class="flex items-start space-x-3">
                <Target class="h-5 w-5 text-cosmic-400 mt-1 flex-shrink-0" />
                <div>
                  <h3 class="text-white font-medium">Subject Performance</h3>
                  <p class="text-cosmic-300 text-sm mt-1">
                    <span v-if="productivityInsights.bestSubject">
                      Your focus is highest when studying <span class="text-white font-medium">{{ productivityInsights.bestSubject }}</span>. 
                      This suggests a strong interest or confidence in this area.
                    </span>
                    <span v-else>
                      Not enough subject data available yet. Try setting specific goals for your Pomodoro sessions.
                    </span>
                  </p>
                </div>
              </div>
            </div>
          </div>
          
          <div class="space-y-4">
            <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4">
              <div class="flex items-start space-x-3">
                <Brain class="h-5 w-5 text-cosmic-400 mt-1 flex-shrink-0" />
                <div>
                  <h3 class="text-white font-medium">Focus Score</h3>
                  <p class="text-cosmic-300 text-sm mt-1">
                    Your average focus score is <span class="text-white font-medium">{{ productivityInsights.averageFocusScore.toFixed(1) }}%</span>.
                    <span v-if="productivityInsights.averageFocusScore > 80">
                      This indicates excellent concentration abilities!
                    </span>
                    <span v-else-if="productivityInsights.averageFocusScore > 60">
                      This is a solid score with room for improvement.
                    </span>
                    <span v-else>
                      Consider using techniques like the Pomodoro method to improve focus.
                    </span>
                  </p>
                </div>
              </div>
            </div>
            
            <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4">
              <div class="flex items-start space-x-3">
                <Award class="h-5 w-5 text-cosmic-400 mt-1 flex-shrink-0" />
                <div>
                  <h3 class="text-white font-medium">Productivity Peak</h3>
                  <p class="text-cosmic-300 text-sm mt-1">
                    <span v-if="productivityInsights.mostProductiveDay">
                      Your most productive day was <span class="text-white font-medium">{{ productivityInsights.mostProductiveDay }}</span>.
                      Try to replicate the conditions of this day for optimal results.
                    </span>
                    <span v-else>
                      Complete more Pomodoro sessions to identify your peak productivity patterns.
                    </span>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <p class="text-xs text-cosmic-400 mt-6 flex items-center">
          <Brain class="h-3 w-3 mr-1" />
          <span>These insights are based on your recent Pomodoro sessions and task completion patterns.</span>
        </p>
      </div>

      <!-- Learning Analytics Component Placeholder -->
      <div class="glass-card p-6">
        <h2 class="text-xl font-bold text-white mb-4">Learning Analytics</h2>
        <p class="text-cosmic-300 text-center py-6">
          Detailed learning analytics will be available as you use the platform more.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  BarChart3, 
  Brain, 
  Timer, 
  Calendar, 
  Target, 
  Award
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

interface SessionProductivity {
  date: string
  timeOfDay: string
  subject: string
  focusScore: number
  tasksCompleted: number
  sessionDuration: number
}

interface ProductivityInsights {
  pomodoroStats: {
    sessionsToday: number
    totalSessions: number
    focusTimeToday: number
    totalFocusTime: number
    currentStreak: number
    longestStreak: number
    averageSessionLength: number
    completionRate: number
    weeklyGoal: number
    dailyGoal: number
    taskCompletion?: {
      subject: string
      completedTasks: number
      totalTasks: number
      focusScore: number
    }[]
  }
  bestTimeOfDay: string
  bestSubject: string
  mostProductiveDay: string
  averageFocusScore: number
}

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const loading = ref(true)
const productivityInsights = ref<ProductivityInsights | null>(null)

// Computed
const progressToday = computed(() => {
  if (!productivityInsights.value?.pomodoroStats) return 0
  const { sessionsToday, dailyGoal } = productivityInsights.value.pomodoroStats
  return dailyGoal > 0 ? (sessionsToday / dailyGoal) * 100 : 0
})

// Lifecycle
onMounted(() => {
  if (authStore.isAuthenticated) {
    fetchSessionData()
  }
})

// Methods
const fetchSessionData = async () => {
  loading.value = true
  try {
    // This is a simplified version for the template
    // In a real app, this would call a backend API to get sophisticated analytics
    
    // Simulate loading time
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // Create mock data
    productivityInsights.value = {
      pomodoroStats: {
        sessionsToday: 3,
        totalSessions: 45,
        focusTimeToday: 120, // minutes
        totalFocusTime: 2250, // minutes
        currentStreak: 5,
        longestStreak: 12,
        averageSessionLength: 25,
        completionRate: 92,
        weeklyGoal: 20,
        dailyGoal: 4,
        taskCompletion: [
          {
            subject: 'Mathematics',
            completedTasks: 15,
            totalTasks: 20,
            focusScore: 92
          },
          {
            subject: 'Physics',
            completedTasks: 12,
            totalTasks: 15,
            focusScore: 85
          },
          {
            subject: 'Chemistry',
            completedTasks: 8,
            totalTasks: 12,
            focusScore: 76
          }
        ]
      },
      bestTimeOfDay: 'evening',
      bestSubject: 'Mathematics',
      mostProductiveDay: 'Thursday',
      averageFocusScore: 88.5
    }
  } catch (error) {
    console.error('Error fetching analytics:', error)
    toast.error('Failed to load analytics')
  } finally {
    loading.value = false
  }
}

const formatStudyTime = (minutes: number): string => {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`
}
</script>