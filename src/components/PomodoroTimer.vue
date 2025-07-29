<template>
  <div class="glass-card p-6 md:p-8 max-w-md mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center space-x-2">
        <span class="text-2xl">{{ getSessionEmoji() }}</span>
        <h2 class="text-xl font-bold text-white">
          {{ currentSession === 'work' ? 'Focus Time' : 'Break Time' }}
        </h2>
      </div>
      
      <div class="flex items-center space-x-2">
        <button
          @click="toggleSound"
          class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
        >
          <component :is="soundEnabled ? Volume2 : VolumeX" class="h-4 w-4" />
        </button>
        
        <button
          @click="toggleSettings"
          class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
        >
          <Settings class="h-4 w-4" />
        </button>
      </div>
    </div>

    <!-- Session Goal -->
    <div v-if="currentSession === 'work'" class="mb-4">
      <input
        type="text"
        v-model="sessionGoal"
        placeholder="What's your focus for this session?"
        class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 text-sm"
      />
    </div>

    <!-- Timer Display -->
    <div class="text-center mb-6">
      <div class="text-5xl md:text-6xl font-bold text-white text-glow mb-4">
        {{ formatTime(timeRemaining) }}
      </div>
      
      <!-- Progress Ring -->
      <div class="relative w-32 h-32 mx-auto mb-4">
        <svg class="w-32 h-32 transform -rotate-90" viewBox="0 0 120 120">
          <circle
            cx="60"
            cy="60"
            r="54"
            stroke="rgba(255, 255, 255, 0.1)"
            stroke-width="12"
            fill="transparent"
          />
          <circle
            cx="60"
            cy="60"
            r="54"
            stroke="url(#progressGradient)"
            stroke-width="12"
            fill="transparent"
            :stroke-dasharray="339.292"
            :stroke-dashoffset="progressOffset"
            stroke-linecap="round"
          />
          <defs>
            <linearGradient id="progressGradient" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stop-color="#6366f1" />
              <stop offset="100%" stop-color="#d946ef" />
            </linearGradient>
          </defs>
        </svg>
        
        <div class="absolute inset-0 flex items-center justify-center">
          <span class="text-xl">{{ getSessionEmoji() }}</span>
        </div>
      </div>

      <div class="text-cosmic-300 text-sm">
        Session {{ sessionsCompleted + 1 }} • {{ Math.round(progress) }}% Complete
      </div>
    </div>

    <!-- Controls -->
    <div class="flex justify-center space-x-4 mb-6">
      <button
        @click="toggleTimer"
        :class="[
          'flex items-center space-x-2 px-6 py-3 rounded-lg font-medium transition-all',
          isActive ? 'nebula-button' : 'cosmic-button'
        ]"
      >
        <component :is="isActive ? Pause : Play" class="h-5 w-5" />
        <span>{{ isActive ? 'Pause' : 'Start' }}</span>
      </button>
      
      <button
        @click="resetTimer"
        class="p-3 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
      >
        <RotateCcw class="h-5 w-5" />
      </button>
    </div>

    <!-- Settings Panel -->
    <Transition>
      <div v-if="showSettings" class="border-t border-white/10 pt-4">
        <h3 class="text-lg font-bold text-white mb-4">Timer Settings</h3>
        
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Work (min)</label>
            <input
              type="number"
              min="1"
              max="120"
              v-model.number="settings.workDuration"
              class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm"
            />
          </div>
          
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Short Break</label>
            <input
              type="number"
              min="1"
              max="30"
              v-model.number="settings.shortBreak"
              class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm"
            />
          </div>
          
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Long Break</label>
            <input
              type="number"
              min="1"
              max="60"
              v-model.number="settings.longBreak"
              class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm"
            />
          </div>
          
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Sessions to Long Break</label>
            <input
              type="number"
              min="2"
              max="10"
              v-model.number="settings.sessionsUntilLongBreak"
              class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm"
            />
          </div>
        </div>
      </div>
    </Transition>

    <!-- Session Info -->
    <div class="text-center text-cosmic-300 text-sm">
      <div v-if="currentSession === 'work' && sessionGoal" class="mb-2">
        <Target class="h-4 w-4 inline mr-1" />
        {{ sessionGoal }}
      </div>
      <div>
        {{ sessionsCompleted }} session{{ sessionsCompleted !== 1 ? 's' : '' }} completed today
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { 
  Play, 
  Pause, 
  RotateCcw, 
  Settings, 
  Volume2, 
  VolumeX, 
  Target 
} from 'lucide-vue-next'

interface PomodoroTimerProps {
  onSessionComplete?: (sessionType: 'work' | 'short_break' | 'long_break', duration: number) => void
  customSettings?: {
    workDuration: number
    shortBreak: number
    longBreak: number
    sessionsUntilLongBreak: number
  }
}

// Props
const props = withDefaults(defineProps<PomodoroTimerProps>(), {
  onSessionComplete: undefined,
  customSettings: undefined
})

// Default settings
const defaultSettings = {
  workDuration: 25,
  shortBreak: 5,
  longBreak: 15,
  sessionsUntilLongBreak: 4
}

// State
const settings = ref(props.customSettings || defaultSettings)
const timeRemaining = ref(settings.value.workDuration * 60)
const isActive = ref(false)
const currentSession = ref<'work' | 'short_break' | 'long_break'>('work')
const sessionsCompleted = ref(0)
const soundEnabled = ref(true)
const showSettings = ref(false)
const sessionGoal = ref('')
const timerInterval = ref<number | null>(null)

// Computed
const progress = computed(() => {
  const totalDuration = getDurationForSession(currentSession.value) * 60
  return ((totalDuration - timeRemaining.value) / totalDuration) * 100
})

const progressOffset = computed(() => {
  return 339.292 - (progress.value / 100) * 339.292
})

// Methods
const getDurationForSession = (session: 'work' | 'short_break' | 'long_break') => {
  switch (session) {
    case 'work': return settings.value.workDuration
    case 'short_break': return settings.value.shortBreak
    case 'long_break': return settings.value.longBreak
  }
}

const toggleTimer = () => {
  isActive.value = !isActive.value
}

const resetTimer = () => {
  isActive.value = false
  timeRemaining.value = getDurationForSession(currentSession.value) * 60
}

const formatTime = (seconds: number) => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

const getSessionEmoji = () => {
  switch (currentSession.value) {
    case 'work': return '🧠'
    case 'short_break': return '☕'
    case 'long_break': return '🌴'
  }
}

const toggleSound = () => {
  soundEnabled.value = !soundEnabled.value
}

const toggleSettings = () => {
  showSettings.value = !showSettings.value
}

const handleSessionComplete = () => {
  isActive.value = false
  
  if (soundEnabled.value) {
    // Play completion sound
    const audio = new Audio('/notification.mp3')
    audio.play().catch(() => {})
  }

  // Show browser notification
  if ('Notification' in window && Notification.permission === 'granted') {
    const messages = {
      work: 'Work session completed! Time for a break 🎉',
      short_break: 'Break is over! Ready to focus? 🚀',
      long_break: 'Long break is over! Time to get back to work 💪'
    }
    new Notification('Pomodoro Timer', {
      body: messages[currentSession.value],
      icon: '/vite.svg'
    })
  }

  // Call completion callback
  props.onSessionComplete?.(currentSession.value, getDurationForSession(currentSession.value))

  // Auto-transition to next session
  if (currentSession.value === 'work') {
    sessionsCompleted.value++
    const nextSession = sessionsCompleted.value % settings.value.sessionsUntilLongBreak === 0 
      ? 'long_break' 
      : 'short_break'
    currentSession.value = nextSession
    timeRemaining.value = getDurationForSession(nextSession) * 60
  } else {
    currentSession.value = 'work'
    timeRemaining.value = settings.value.workDuration * 60
  }
}

// Watch for timer active state
watch(isActive, (newValue) => {
  if (newValue) {
    // Start the timer
    if (timerInterval.value) clearInterval(timerInterval.value)
    timerInterval.value = window.setInterval(() => {
      if (timeRemaining.value <= 1) {
        clearInterval(timerInterval.value as number)
        timerInterval.value = null
        timeRemaining.value = 0
        handleSessionComplete()
      } else {
        timeRemaining.value--
      }
    }, 1000)
  } else {
    // Stop the timer
    if (timerInterval.value) {
      clearInterval(timerInterval.value)
      timerInterval.value = null
    }
  }
})

// Watch for settings changes
watch(settings, () => {
  if (!isActive.value) {
    timeRemaining.value = getDurationForSession(currentSession.value) * 60
  }
}, { deep: true })

// Lifecycle hooks
onMounted(() => {
  // Request notification permission
  if ('Notification' in window && Notification.permission !== 'granted') {
    Notification.requestPermission()
  }
})

onUnmounted(() => {
  // Clean up timer
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
  }
})
</script>

<style scoped>
.v-enter-active,
.v-leave-active {
  transition: opacity 0.3s, height 0.3s;
  overflow: hidden;
}

.v-enter-from,
.v-leave-to {
  opacity: 0;
  height: 0;
}
</style>