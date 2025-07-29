<template>
  <div class="space-y-6">
    <!-- Overview Stats -->
    <div class="glass-card p-6">
      <h3 class="text-xl font-bold text-white mb-6 flex items-center">
        <BarChart class="h-6 w-6 mr-2 text-cosmic-400" />
        Productivity Overview
      </h3>
      
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="text-center">
          <div class="text-2xl font-bold text-green-400">{{ stats.sessionsToday }}</div>
          <div class="text-sm text-cosmic-300">Today</div>
          <div class="w-full bg-cosmic-900/50 rounded-full h-2 mt-2">
            <div
              class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full transition-all"
              :style="{ width: `${Math.min(progressToday, 100)}%` }"
            ></div>
          </div>
        </div>
        
        <div class="text-center">
          <div class="text-2xl font-bold text-cosmic-400">{{ stats.totalSessions }}</div>
          <div class="text-sm text-cosmic-300">Total Sessions</div>
        </div>
        
        <div class="text-center">
          <div class="text-2xl font-bold text-star-400">{{ stats.currentStreak }}</div>
          <div class="text-sm text-cosmic-300">Current Streak</div>
        </div>
        
        <div class="text-center">
          <div class="text-2xl font-bold text-nebula-400">{{ formatTime(stats.focusTimeToday) }}</div>
          <div class="text-sm text-cosmic-300">Focus Time</div>
        </div>
      </div>
    </div>

    <!-- Productivity Insights -->
    <div v-if="stats.taskCompletion && stats.taskCompletion.length > 0" class="glass-card p-6 mb-6">
      <h4 class="text-lg font-bold text-white mb-4 flex items-center">
        <Brain class="h-5 w-5 mr-2 text-cosmic-400" />
        Productivity Insights
      </h4>
      
      <div class="space-y-4">
        <div 
          v-for="(subject, index) in stats.taskCompletion" 
          :key="index" 
          class="bg-white/5 p-3 rounded-lg"
        >
          <div class="flex justify-between items-center mb-2">
            <div class="flex items-center">
              <FileText class="h-4 w-4 mr-2 text-cosmic-400" />
              <span class="text-white">{{ subject.subject }}</span>
            </div>
            <div class="flex items-center">
              <TrendingUp class="h-4 w-4 mr-1 text-cosmic-400" />
              <span class="text-sm text-cosmic-300">{{ subject.focusScore }}% Focus</span>
            </div>
          </div>
          
          <div class="flex justify-between text-sm text-cosmic-300 mb-1">
            <span>Task Completion</span>
            <span>{{ subject.completedTasks }}/{{ subject.totalTasks }} Tasks</span>
          </div>
          
          <div class="w-full bg-cosmic-900/50 rounded-full h-2">
            <div 
              class="bg-gradient-to-r from-cosmic-500 to-cosmic-600 h-2 rounded-full transition-all" 
              :style="{ width: `${(subject.completedTasks / Math.max(1, subject.totalTasks)) * 100}%` }"
            ></div>
          </div>
          
          <div v-if="subject.focusScore > 80" class="text-xs text-green-400 mt-2 flex items-center">
            <CheckCircle class="h-3 w-3 mr-1" />
            <span>You are {{ Math.round((subject.focusScore / 60) * 100) }}% more productive when studying {{ subject.subject }} in the {{ getTimeOfDay() }}</span>
          </div>
        </div>
        
        <div class="text-center text-xs text-cosmic-400 mt-2">
          These insights are based on analysis of your task completion patterns and focus scores.
        </div>
      </div>
    </div>

    <!-- Detailed Stats -->
    <div class="grid md:grid-cols-2 gap-6">
      <!-- Time Analytics -->
      <div class="glass-card p-6">
        <h4 class="text-lg font-bold text-white mb-4 flex items-center">
          <Clock class="h-5 w-5 mr-2 text-cosmic-400" />
          Time Analytics
        </h4>
        
        <div class="space-y-4">
          <div class="flex justify-between items-center">
            <span class="text-cosmic-300">Total Focus Time</span>
            <span class="text-white font-bold">{{ formatTime(stats.totalFocusTime) }}</span>
          </div>
          
          <div class="flex justify-between items-center">
            <span class="text-cosmic-300">Average Session</span>
            <span class="text-white font-bold">{{ stats.averageSessionLength }}m</span>
          </div>
          
          <div class="flex justify-between items-center">
            <span class="text-cosmic-300">Completion Rate</span>
            <span 
              :class="[
                'font-bold', 
                stats.completionRate >= 80 ? 'text-green-400' : 
                stats.completionRate >= 60 ? 'text-star-400' : 'text-red-400'
              ]"
            >
              {{ stats.completionRate }}%
            </span>
          </div>
          
          <div class="flex justify-between items-center">
            <span class="text-cosmic-300">Longest Streak</span>
            <span class="text-white font-bold">{{ stats.longestStreak }} days 🔥</span>
          </div>
        </div>
      </div>

      <!-- Goals & Progress -->
      <div class="glass-card p-6">
        <h4 class="text-lg font-bold text-white mb-4 flex items-center">
          <Target class="h-5 w-5 mr-2 text-cosmic-400" />
          Goals & Progress
        </h4>
        
        <div class="space-y-4">
          <div>
            <div class="flex justify-between items-center mb-2">
              <span class="text-cosmic-300">Daily Goal</span>
              <span class="text-white font-bold">{{ stats.sessionsToday }} / {{ stats.dailyGoal }}</span>
            </div>
            <div class="w-full bg-cosmic-900/50 rounded-full h-3">
              <div
                class="bg-gradient-to-r from-green-500 to-green-600 h-3 rounded-full transition-all"
                :style="{ width: `${Math.min(progressToday, 100)}%` }"
              ></div>
            </div>
          </div>
          
          <div>
            <div class="flex justify-between items-center mb-2">
              <span class="text-cosmic-300">Weekly Progress</span>
              <span class="text-white font-bold">{{ Math.round(weeklyProgress) }}%</span>
            </div>
            <div class="w-full bg-cosmic-900/50 rounded-full h-3">
              <div
                class="bg-gradient-to-r from-cosmic-500 to-nebula-500 h-3 rounded-full transition-all"
                :style="{ width: `${Math.min(weeklyProgress, 100)}%` }"
              ></div>
            </div>
          </div>
          
          <div class="pt-2 border-t border-white/10">
            <div class="text-center">
              <div class="text-sm text-cosmic-300 mb-1">Productivity Score</div>
              <div class="text-2xl font-bold text-glow">
                {{ productivityScore }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Achievements -->
    <div class="glass-card p-6">
      <h4 class="text-lg font-bold text-white mb-4 flex items-center">
        <Award class="h-5 w-5 mr-2 text-cosmic-400" />
        Achievements ({{ unlockedAchievements.length }}/{{ achievements.length }})
      </h4>
      
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
        <div 
          v-for="achievement in achievements" 
          :key="achievement.id"
          :class="[
            'text-center p-4 rounded-lg transition-all',
            achievement.unlocked 
              ? 'bg-gradient-to-br from-star-500/20 to-star-600/20 border border-star-400/50' 
              : 'bg-white/5 border border-white/10 opacity-50'
          ]"
        >
          <div class="text-2xl mb-2">{{ achievement.icon }}</div>
          <div 
            :class="[
              'text-sm font-medium mb-1', 
              achievement.unlocked ? 'text-white' : 'text-cosmic-400'
            ]"
          >
            {{ achievement.title }}
          </div>
          <div class="text-xs text-cosmic-300">
            {{ achievement.description }}
          </div>
          <div v-if="achievement.unlocked" class="mt-2">
            <span class="inline-flex items-center px-2 py-1 bg-star-500/20 text-star-300 rounded-full text-xs">
              ✓ Unlocked
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Weekly Calendar View -->
    <div class="glass-card p-6">
      <h4 class="text-lg font-bold text-white mb-4 flex items-center">
        <Calendar class="h-5 w-5 mr-2 text-cosmic-400" />
        This Week's Activity
      </h4>
      
      <div class="grid grid-cols-7 gap-2">
        <div v-for="(day, index) in weekDays" :key="day" class="text-center">
          <div class="text-xs text-cosmic-300 mb-2">{{ day }}</div>
          <div 
            :class="[
              'w-8 h-8 mx-auto rounded-lg flex items-center justify-center text-xs font-bold',
              index === todayIndex 
                ? 'bg-cosmic-500 text-white ring-2 ring-cosmic-400' 
                : day in sessionsPerDay && sessionsPerDay[day] > 0
                  ? 'bg-green-500/20 text-green-300' 
                  : 'bg-white/5 text-cosmic-400'
            ]"
          >
            {{ day in sessionsPerDay ? sessionsPerDay[day] : '-' }}
          </div>
        </div>
      </div>
      
      <div class="text-center mt-4 text-xs text-cosmic-300">
        Numbers represent completed pomodoro sessions
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { 
  BarChart, 
  Clock, 
  Target, 
  Award, 
  Calendar, 
  Brain, 
  TrendingUp, 
  FileText, 
  CheckCircle 
} from 'lucide-vue-next'

interface PomodoroStatsProps {
  stats: {
    sessionsToday: number
    totalSessions: number
    focusTimeToday: number // in minutes
    totalFocusTime: number // in minutes
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
}

// Props
const props = defineProps<PomodoroStatsProps>()

// Setup achievements data
const achievements = ref([
  {
    id: 'first_session',
    title: 'Getting Started',
    description: 'Complete your first pomodoro session',
    icon: '🚀',
    unlocked: props.stats.totalSessions >= 1
  },
  {
    id: 'daily_goal',
    title: 'Daily Warrior',
    description: 'Reach your daily session goal',
    icon: '🎯',
    unlocked: props.stats.sessionsToday >= props.stats.dailyGoal
  },
  {
    id: 'streak_master',
    title: 'Streak Master',
    description: 'Maintain a 7-day focus streak',
    icon: '🔥',
    unlocked: props.stats.currentStreak >= 7
  },
  {
    id: 'focus_champion',
    title: 'Focus Champion',
    description: 'Complete 50 pomodoro sessions',
    icon: '🏆',
    unlocked: props.stats.totalSessions >= 50
  },
  {
    id: 'consistency_king',
    title: 'Consistency King',
    description: 'Maintain 90% completion rate',
    icon: '👑',
    unlocked: props.stats.completionRate >= 90
  }
])

// Mock data for calendar view
const sessionsPerDay = ref({
  'Mon': 3,
  'Tue': 4,
  'Wed': 0,
  'Thu': 5,
  'Fri': 2,
  'Sat': 0,
  'Sun': 1
})

const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
const todayIndex = ref(2) // Mock today as Wednesday

// Computed properties
const progressToday = computed(() => {
  return props.stats.dailyGoal > 0 ? (props.stats.sessionsToday / props.stats.dailyGoal) * 100 : 0
})

const weeklyProgress = computed(() => {
  return props.stats.weeklyGoal > 0 ? (props.stats.totalSessions / props.stats.weeklyGoal) * 100 : 0
})

const unlockedAchievements = computed(() => {
  return achievements.value.filter(a => a.unlocked)
})

const productivityScore = computed(() => {
  return Math.round((props.stats.completionRate + progressToday.value + Math.min(props.stats.currentStreak * 5, 50)) / 3)
})

// Methods
const formatTime = (minutes: number): string => {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`
}

const getTimeOfDay = (): string => {
  const now = new Date()
  const hour = now.getHours()
  if (hour < 12) return 'morning'
  if (hour < 18) return 'afternoon'
  return 'evening'
}
</script>