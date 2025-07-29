<template>
  <div class="space-y-6">
    <!-- XP Notification -->
    <Transition>
      <div 
        v-if="showXpNotification" 
        class="fixed top-20 right-4 glass-card p-3 z-50 border border-star-500/50"
      >
        <div class="flex items-center space-x-3">
          <Award class="h-5 w-5 text-star-400" />
          <div>
            <div class="text-sm text-cosmic-300">{{ showXpNotification.action }}</div>
            <div class="text-lg font-bold text-star-400">+{{ showXpNotification.xp }} XP</div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Focus Mode Selector -->
    <div class="glass-card p-4">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-bold text-white">Focus Mode</h3>
        <button
          v-if="!isGroupTimer"
          @click="showFocusModeSelector = !showFocusModeSelector"
          class="cosmic-button text-sm"
          :disabled="isActive"
        >
          Change Mode
        </button>
      </div>

      <div class="flex items-center space-x-3 mb-3">
        <div 
          class="p-2 rounded-lg bg-gradient-to-r" 
          :class="[
            focusMode === 'deep_focus' ? 'from-red-500 to-red-600' :
            focusMode === 'collaborative' ? 'from-blue-500 to-blue-600' :
            'from-green-500 to-green-600'
          ]"
        >
          <component 
            :is="focusMode === 'deep_focus' ? Brain :
                 focusMode === 'collaborative' ? Users :
                 Zap" 
            class="h-5 w-5 text-white" 
          />
        </div>
        <div>
          <div class="font-bold text-white">{{ currentFocusMode.displayName }}</div>
          <div class="text-sm text-cosmic-300">{{ currentFocusMode.description }}</div>
        </div>
      </div>

      <!-- Focus Mode Rules -->
      <div class="grid grid-cols-2 gap-2 text-xs">
        <div class="flex items-center space-x-2">
          <component 
            :is="currentFocusMode.rules.games_locked ? Lock : Unlock" 
            class="h-3 w-3" 
            :class="currentFocusMode.rules.games_locked ? 'text-red-400' : 'text-green-400'" 
          />
          <span class="text-cosmic-300">Games {{ currentFocusMode.rules.games_locked ? 'Locked' : 'Available' }}</span>
        </div>
        <div class="flex items-center space-x-2">
          <component 
            :is="currentFocusMode.rules.chat_restricted ? Lock : Unlock" 
            class="h-3 w-3" 
            :class="currentFocusMode.rules.chat_restricted ? 'text-red-400' : 'text-green-400'" 
          />
          <span class="text-cosmic-300">Chat {{ currentFocusMode.rules.chat_restricted ? 'Limited' : 'Open' }}</span>
        </div>
        <div class="flex items-center space-x-2">
          <span class="text-star-400">{{ currentFocusMode.xp_multiplier }}x</span>
          <span class="text-cosmic-300">XP Multiplier</span>
        </div>
        <div class="flex items-center space-x-2">
          <span class="text-star-400">+{{ sessionXp }}</span>
          <span class="text-cosmic-300">Session XP</span>
        </div>
      </div>

      <!-- Focus Mode Selector Dropdown -->
      <Transition>
        <div v-if="showFocusModeSelector && !isGroupTimer" class="mt-4 space-y-2">
          <button
            v-for="mode in focusModesList"
            :key="mode.name"
            @click="changeFocusMode(mode.name)"
            :class="[
              'w-full p-3 rounded-lg text-left transition-all',
              mode.name === focusMode
                ? 'bg-cosmic-500/20 border border-cosmic-400'
                : 'bg-white/5 hover:bg-white/10 border border-white/10'
            ]"
          >
            <div class="font-medium text-white">{{ mode.displayName }}</div>
            <div class="text-sm text-cosmic-300">{{ mode.description }}</div>
            <div class="text-xs text-star-400 mt-1">{{ mode.xp_multiplier }}x XP</div>
          </button>
        </div>
      </Transition>
    </div>

    <!-- Main Timer -->
    <div class="glass-card p-6 md:p-8">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center space-x-2">
          <span class="text-2xl">{{ getSessionEmoji() }}</span>
          <h2 class="text-xl font-bold text-white">
            {{ currentSession === 'work' ? 'Focus Time' : 'Break Time' }}
          </h2>
          <span v-if="isGroupTimer" class="text-sm text-cosmic-300">• Group Session</span>
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
          :disabled="isActive"
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
              :stroke-dashoffset="339.292 - (progress / 100) * 339.292"
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

        <!-- Session Info -->
        <div class="grid grid-cols-3 gap-4 text-sm text-cosmic-300 mb-4">
          <div>
            <div class="text-white font-bold">{{ sessionsCompleted + 1 }}</div>
            <div>Session</div>
          </div>
          <div>
            <div class="text-white font-bold">{{ Math.round(focusScore) }}%</div>
            <div>Focus Score</div>
          </div>
          <div>
            <div class="text-white font-bold">{{ interruptions }}</div>
            <div>Interruptions</div>
          </div>
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

      <!-- Session Goal Display -->
      <div v-if="currentSession === 'work' && sessionGoal" class="text-center text-cosmic-300 text-sm mb-4">
        <Target class="h-4 w-4 inline mr-1" />
        {{ sessionGoal }}
      </div>
    </div>

    <!-- Checklist -->
    <div v-if="currentSession === 'work'" class="glass-card p-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-bold text-white">Session Checklist</h3>
        <button
          @click="addChecklistItem"
          class="cosmic-button text-sm flex items-center space-x-1"
          :disabled="isActive"
        >
          <Plus class="h-4 w-4" />
          <span>Add</span>
        </button>
      </div>

      <div class="space-y-3">
        <div 
          v-for="item in checklistItems"
          :key="item.id"
          class="flex items-center space-x-3"
        >
          <button
            @click="updateChecklistItem(item.id, { completed: !item.completed })"
            :class="[
              'flex-shrink-0 w-5 h-5 rounded border',
              item.completed 
                ? 'bg-green-500 border-green-600 text-white' 
                : 'border-white/20 text-transparent'
            ]"
          >
            <CheckCircle class="h-full w-full" />
          </button>
          
          <div class="flex-1 min-w-0">
            <input
              type="text"
              v-model="item.text"
              @input="updateChecklistText(item.id, $event)"
              :class="[
                'w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 text-sm',
                item.completed ? 'line-through opacity-60' : ''
              ]"
              placeholder="Add checklist item..."
              :disabled="isActive"
            />
          </div>
          
          <Transition v-if="item.completed">
            <div class="text-xs text-green-400">+10 XP</div>
          </Transition>
          
          <select
            v-model="item.priority"
            @change="updateChecklistItem(item.id, { priority: $event.target.value })"
            class="px-2 py-1 bg-white/5 border border-white/10 rounded text-white text-xs"
            :disabled="isActive"
          >
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
          </select>
          
          <button
            @click="removeChecklistItem(item.id)"
            class="p-1 text-cosmic-400 hover:text-red-400 transition-colors"
            :disabled="isActive"
          >
            <Trash2 class="h-4 w-4" />
          </button>
        </div>
        
        <div v-if="checklistItems.length === 0" class="text-center text-cosmic-400 py-8">
          <Target class="h-8 w-8 mx-auto mb-2 opacity-50" />
          <p>No checklist items yet</p>
          <p class="text-xs">Add items to track your session goals and earn XP</p>
        </div>
      </div>
      
      <!-- XP Summary -->
      <div v-if="xpRewards.length > 0" class="mt-4 pt-4 border-t border-white/10">
        <h4 class="text-sm font-medium text-cosmic-300 mb-2 flex items-center">
          <Award class="h-4 w-4 mr-1 text-star-400" />
          XP Rewards
        </h4>
        <div class="space-y-1 max-h-32 overflow-y-auto">
          <div 
            v-for="(reward, index) in xpRewards"
            :key="index"
            class="flex justify-between items-center text-xs"
          >
            <div class="text-cosmic-300">{{ reward.action }}</div>
            <div class="text-star-400 font-medium">+{{ reward.xp }} XP</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Settings Panel -->
    <Transition>
      <div v-if="showSettings" class="glass-card p-6">
        <h3 class="text-lg font-bold text-white mb-4">Timer Settings</h3>
        
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Work Duration</label>
            <div class="text-white bg-white/5 px-3 py-2 rounded-lg">
              {{ currentFocusMode.timer_settings.work_duration }} min
            </div>
          </div>
          
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Short Break</label>
            <div class="text-white bg-white/5 px-3 py-2 rounded-lg">
              {{ currentFocusMode.timer_settings.short_break }} min
            </div>
          </div>
          
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Long Break</label>
            <div class="text-white bg-white/5 px-3 py-2 rounded-lg">
              {{ currentFocusMode.timer_settings.long_break }} min
            </div>
          </div>
          
          <div>
            <label class="block text-cosmic-200 text-sm mb-1">Sessions to Long Break</label>
            <div class="text-white bg-white/5 px-3 py-2 rounded-lg">
              {{ currentFocusMode.timer_settings.sessions_until_long_break }}
            </div>
          </div>
        </div>
        
        <div class="mt-4 text-xs text-cosmic-400">
          Timer settings are determined by the selected focus mode
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { 
  Award,
  Play, 
  Pause, 
  RotateCcw, 
  Settings, 
  Volume2, 
  VolumeX, 
  Target,
  CheckCircle,
  Plus,
  Trash2,
  Lock,
  Unlock,
  Brain,
  Users,
  Zap
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

// Focus mode types
interface FocusMode {
  name: 'deep_focus' | 'collaborative' | 'flexible'
  displayName: string
  description: string
  rules: {
    games_locked: boolean
    chat_restricted: boolean
    notifications_blocked: boolean
    breaks_enforced: boolean
    focus_reminders: boolean
  }
  timer_settings: {
    work_duration: number
    short_break: number
    long_break: number
    sessions_until_long_break: number
  }
  xp_multiplier: number
}

export interface ChecklistItem {
  id: string
  text: string
  completed: boolean
  priority: 'low' | 'medium' | 'high'
  xp_earned?: boolean
}

interface Props {
  focusMode: 'deep_focus' | 'collaborative' | 'flexible'
  onSessionComplete?: (sessionData: any) => void
  isGroupTimer?: boolean
  roomId?: string
  checklist?: ChecklistItem[]
  onChecklistUpdate?: (checklist: ChecklistItem[]) => void
  onFocusModeChange?: (mode: 'deep_focus' | 'collaborative' | 'flexible') => void
}

const props = withDefaults(defineProps<Props>(), {
  onSessionComplete: undefined,
  isGroupTimer: false,
  roomId: undefined,
  checklist: () => [],
  onChecklistUpdate: undefined,
  onFocusModeChange: undefined
})

// Focus modes configuration
const FOCUS_MODES = {
  deep_focus: {
    name: 'deep_focus',
    displayName: 'Deep Focus',
    description: 'Maximum concentration mode with strict rules and minimal distractions',
    rules: {
      games_locked: true,
      chat_restricted: true,
      notifications_blocked: true,
      breaks_enforced: true,
      focus_reminders: true
    },
    timer_settings: {
      work_duration: 50,
      short_break: 10,
      long_break: 30,
      sessions_until_long_break: 3
    },
    xp_multiplier: 1.5
  },
  collaborative: {
    name: 'collaborative',
    displayName: 'Collaborative Study',
    description: 'Balanced mode perfect for group study with controlled social interaction',
    rules: {
      games_locked: true,
      chat_restricted: false,
      notifications_blocked: false,
      breaks_enforced: true,
      focus_reminders: true
    },
    timer_settings: {
      work_duration: 25,
      short_break: 5,
      long_break: 15,
      sessions_until_long_break: 4
    },
    xp_multiplier: 1.2
  },
  flexible: {
    name: 'flexible',
    displayName: 'Flexible Flow',
    description: 'Relaxed mode with minimal restrictions for casual study sessions',
    rules: {
      games_locked: false,
      chat_restricted: false,
      notifications_blocked: false,
      breaks_enforced: false,
      focus_reminders: false
    },
    timer_settings: {
      work_duration: 25,
      short_break: 5,
      long_break: 15,
      sessions_until_long_break: 4
    },
    xp_multiplier: 1.0
  }
} as const

// Auth store
const authStore = useAuthStore()

// State
const timeRemaining = ref(0)
const isActive = ref(false)
const currentSession = ref<'work' | 'short_break' | 'long_break'>('work')
const sessionsCompleted = ref(0)
const soundEnabled = ref(true)
const showSettings = ref(false)
const sessionGoal = ref('')
const focusScore = ref(100)
const interruptions = ref(0)
const showFocusModeSelector = ref(false)
const sessionXp = ref(0)
const xpRewards = ref<{action: string, xp: number, timestamp: Date}[]>([])
const showXpNotification = ref<{action: string, xp: number} | null>(null)
const timerInterval = ref<number | null>(null)
const focusCheckInterval = ref<number | null>(null)
const checklistItems = ref<ChecklistItem[]>([...props.checklist])

// Computed
const currentFocusMode = computed<FocusMode>(() => FOCUS_MODES[props.focusMode])
const focusModesList = computed(() => Object.values(FOCUS_MODES))

const progress = computed(() => {
  const totalDuration = getDurationForSession(currentSession.value) * 60
  return ((totalDuration - timeRemaining.value) / totalDuration) * 100
})

// Watch for props changes
watch(() => props.focusMode, (newMode) => {
  if (!isActive.value) {
    resetTimer()
  }
})

watch(() => props.checklist, (newChecklist) => {
  if (newChecklist && newChecklist !== checklistItems.value) {
    checklistItems.value = [...newChecklist]
  }
})

// Initialize timer
onMounted(() => {
  // Set initial time remaining based on focus mode and session
  timeRemaining.value = getDurationForSession(currentSession.value) * 60
  
  // Setup focus monitoring
  setupFocusChecking()
  
  // If checklist items were passed via props, use them
  if (props.checklist && props.checklist.length > 0) {
    checklistItems.value = [...props.checklist]
  }
})

// Cleanup on unmount
onUnmounted(() => {
  // Clear all intervals
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
  }
  if (focusCheckInterval.value) {
    clearInterval(focusCheckInterval.value)
  }
})

// Methods
function getDurationForSession(session: 'work' | 'short_break' | 'long_break'): number {
  switch (session) {
    case 'work': return currentFocusMode.value.timer_settings.work_duration
    case 'short_break': return currentFocusMode.value.timer_settings.short_break
    case 'long_break': return currentFocusMode.value.timer_settings.long_break
  }
}

function toggleTimer() {
  isActive.value = !isActive.value
  
  if (isActive.value) {
    startTimer()
  } else {
    stopTimer()
  }
}

function startTimer() {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
  }

  timerInterval.value = window.setInterval(() => {
    if (timeRemaining.value <= 1) {
      handleSessionComplete()
    } else {
      timeRemaining.value--
    }
  }, 1000)
}

function stopTimer() {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
    timerInterval.value = null
  }
}

function resetTimer() {
  stopTimer()
  timeRemaining.value = getDurationForSession(currentSession.value) * 60
  focusScore.value = 100
  interruptions.value = 0
}

function handleSessionComplete() {
  isActive.value = false
  stopTimer()
  
  if (soundEnabled.value) {
    // Play completion sound
    const audio = new Audio('/notification.mp3')
    audio.play().catch(() => {})
  }

  // Calculate XP based on focus mode and performance
  const baseXp = currentSession.value === 'work' ? 50 : 10
  const focusMultiplier = focusScore.value / 100
  const modeMultiplier = currentFocusMode.value.xp_multiplier
  const earnedXp = Math.floor(baseXp * focusMultiplier * modeMultiplier)
  sessionXp.value += earnedXp
  
  // Award XP through the auth store
  const actionName = currentSession.value === 'work' 
    ? 'Completed Focus Session' 
    : currentSession.value === 'short_break' 
      ? 'Completed Short Break' 
      : 'Completed Long Break'
  
  authStore.addExperience(earnedXp, actionName)
  
  xpRewards.value.push({
    action: actionName,
    xp: earnedXp,
    timestamp: new Date()
  })
  
  // Show XP notification
  showXpNotification.value = { action: actionName, xp: earnedXp }
  setTimeout(() => showXpNotification.value = null, 3000)

  // Show browser notification
  if ('Notification' in window && Notification.permission === 'granted') {
    const messages = {
      work: `🎯 ${currentFocusMode.value.displayName} session complete! +${earnedXp} XP`,
      short_break: 'Break time over! Ready to focus? 🚀',
      long_break: 'Long break complete! Time for deep work 💪'
    }
    new Notification('MemoQuest Focus Timer', {
      body: messages[currentSession.value],
      icon: '/vite.svg'
    })
  }
  
  // Track completed tasks and XP for analytics
  const completedTasksCount = checklistItems.value.filter(item => item.completed).length
  if (completedTasksCount > 0 && currentSession.value === 'work') {
    // Mark items as having earned XP to avoid duplicates
    const newChecklist = [...checklistItems.value].map(item => 
      item.completed && !item.xp_earned 
        ? {...item, xp_earned: true} 
        : item
    )
    updateChecklist(newChecklist)
    
    // Count only newly completed tasks for XP
    const newlyCompletedCount = newChecklist.filter(item => item.completed && item.xp_earned).length
    
    // Award XP for completed tasks
    const taskXp = newlyCompletedCount * 10
    if (taskXp > 0) {
      sessionXp.value += taskXp
      
      // Award XP through auth store
      authStore.addExperience(taskXp, `Completed ${newlyCompletedCount} Tasks`)
    }
    
    xpRewards.value.push({
      action: `Completed ${completedTasksCount} Tasks`,
      xp: taskXp,
      timestamp: new Date()
    })
    
    setTimeout(() => {
      showXpNotification.value = { 
        action: `Completed ${completedTasksCount} Tasks`, 
        xp: taskXp 
      }
      setTimeout(() => showXpNotification.value = null, 3000)
    }, 500)
  }

  // Call completion callback
  if (props.onSessionComplete) {
    props.onSessionComplete({
      sessionType: currentSession.value,
      duration: getDurationForSession(currentSession.value),
      focusScore: focusScore.value,
      interruptions: interruptions.value,
      xpEarned: earnedXp,
      focusMode: props.focusMode,
      completedTasks: checklistItems.value.filter(item => item.completed),
      goal: sessionGoal.value,
      checklist: checklistItems.value
    })
  }

  // Auto-transition to next session
  if (currentSession.value === 'work') {
    sessionsCompleted.value++
    const nextSession = (sessionsCompleted.value % currentFocusMode.value.timer_settings.sessions_until_long_break === 0) 
      ? 'long_break' 
      : 'short_break'
    currentSession.value = nextSession
    timeRemaining.value = getDurationForSession(nextSession) * 60
  } else {
    currentSession.value = 'work'
    timeRemaining.value = getDurationForSession('work') * 60
  }

  // Reset focus tracking
  focusScore.value = 100
  interruptions.value = 0
}

function setupFocusChecking() {
  if (focusCheckInterval.value) {
    clearInterval(focusCheckInterval.value)
  }
  
  if (currentSession.value === 'work' && isActive.value && currentFocusMode.value.rules.focus_reminders) {
    // Check for focus every 5 minutes during work sessions
    focusCheckInterval.value = window.setInterval(() => {
      if (document.hasFocus()) {
        // Document is focused, maintain score
      } else {
        // User switched away, reduce focus score
        focusScore.value = Math.max(0, focusScore.value - 5)
        interruptions.value++
      }
    }, 300000) // 5 minutes
  }
}

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

function getSessionEmoji(): string {
  switch (currentSession.value) {
    case 'work': return '🧠'
    case 'short_break': return '☕'
    case 'long_break': return '🌴'
  }
}

function toggleSound() {
  soundEnabled.value = !soundEnabled.value
}

function toggleSettings() {
  showSettings.value = !showSettings.value
}

function addChecklistItem() {
  const newItem: ChecklistItem = {
    id: Date.now().toString(),
    text: '',
    completed: false,
    priority: 'medium'
  }
  checklistItems.value = [...checklistItems.value, newItem]
  updateChecklist(checklistItems.value)
}

function updateChecklistItem(id: string, updates: Partial<ChecklistItem>) {
  const updatedChecklist = checklistItems.value.map(item => 
    item.id === id ? { ...item, ...updates } : item
  )
  checklistItems.value = updatedChecklist
  updateChecklist(updatedChecklist)
}

function updateChecklistText(id: string, event: Event) {
  const input = event.target as HTMLInputElement
  updateChecklistItem(id, { text: input.value })
}

function removeChecklistItem(id: string) {
  const updatedChecklist = checklistItems.value.filter(item => item.id !== id)
  checklistItems.value = updatedChecklist
  updateChecklist(updatedChecklist)
}

function updateChecklist(newChecklist: ChecklistItem[]) {
  if (props.onChecklistUpdate) {
    props.onChecklistUpdate(newChecklist)
  }
}

function changeFocusMode(mode: 'deep_focus' | 'collaborative' | 'flexible') {
  if (props.onFocusModeChange) {
    props.onFocusModeChange(mode)
  }
  showFocusModeSelector.value = false
  
  // If we're not active, update the timer
  if (!isActive.value) {
    timeRemaining.value = FOCUS_MODES[mode].timer_settings.work_duration * 60
  }
}

// Watch for activity changes to start/stop focus checking
watch([isActive, currentSession], () => {
  setupFocusChecking()
})
</script>

<style scoped>
.v-enter-active,
.v-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.v-enter-from,
.v-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>