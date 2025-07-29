import { ref, computed, onMounted, onUnmounted, watch } from 'vue'

export interface PomodoroSettings {
  workDuration: number // in minutes
  shortBreak: number
  longBreak: number
  sessionsUntilLongBreak: number
}

export interface PomodoroSession {
  type: 'work' | 'short_break' | 'long_break'
  duration: number // in minutes
  completed: boolean
  startTime?: Date
  endTime?: Date
  goal?: string
  notes?: string
}

export interface PomodoroState {
  isActive: boolean
  timeRemaining: number // in seconds
  currentSession: PomodoroSession['type']
  sessionsCompleted: number
  settings: PomodoroSettings
  totalFocusTime: number // in minutes
  streak: number
  dailyGoal: number
  completedToday: number
}

const defaultSettings: PomodoroSettings = {
  workDuration: 25,
  shortBreak: 5,
  longBreak: 15,
  sessionsUntilLongBreak: 4
}

export function usePomodoro(initialSettings?: Partial<PomodoroSettings>) {
  // State
  const state = ref<PomodoroState>({
    isActive: false,
    timeRemaining: (initialSettings?.workDuration || defaultSettings.workDuration) * 60,
    currentSession: 'work',
    sessionsCompleted: 0,
    settings: { ...defaultSettings, ...initialSettings },
    totalFocusTime: 0,
    streak: 0,
    dailyGoal: 4,
    completedToday: 0
  })

  const sessionHistory = ref<PomodoroSession[]>([])
  const timerInterval = ref<number | null>(null)
  const onSessionCompleteCallbacks = ref<Array<(session: PomodoroSession) => void>>([])

  // Timer logic
  const startTimer = () => {
    if (timerInterval.value) {
      clearInterval(timerInterval.value)
    }
    
    timerInterval.value = window.setInterval(() => {
      if (state.value.timeRemaining <= 1) {
        completeCurrentSession()
      } else {
        state.value.timeRemaining--
      }
    }, 1000)
  }

  const stopTimer = () => {
    if (timerInterval.value) {
      clearInterval(timerInterval.value)
      timerInterval.value = null
    }
  }

  // Handle session completion
  const completeCurrentSession = () => {
    const session: PomodoroSession = {
      type: state.value.currentSession,
      duration: getDurationForSession(state.value.currentSession),
      completed: true,
      endTime: new Date()
    }

    // Add to history
    sessionHistory.value.push(session)

    // Update stats
    state.value.isActive = false
    
    if (state.value.currentSession === 'work') {
      state.value.sessionsCompleted++
      state.value.totalFocusTime += session.duration
      state.value.completedToday++
      state.value.streak++
    }

    // Determine next session
    if (state.value.currentSession === 'work') {
      const nextIsLongBreak = state.value.sessionsCompleted % state.value.settings.sessionsUntilLongBreak === 0
      state.value.currentSession = nextIsLongBreak ? 'long_break' : 'short_break'
    } else {
      state.value.currentSession = 'work'
    }

    state.value.timeRemaining = getDurationForSession(state.value.currentSession) * 60

    // Notify callbacks
    onSessionCompleteCallbacks.value.forEach(callback => callback(session))
  }

  // Helper functions
  const getDurationForSession = (sessionType: PomodoroSession['type']) => {
    switch (sessionType) {
      case 'work': return state.value.settings.workDuration
      case 'short_break': return state.value.settings.shortBreak
      case 'long_break': return state.value.settings.longBreak
    }
  }

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  // Public API methods
  const start = () => {
    state.value.isActive = true
    startTimer()
  }

  const pause = () => {
    state.value.isActive = false
    stopTimer()
  }

  const reset = () => {
    stopTimer()
    state.value.isActive = false
    state.value.timeRemaining = getDurationForSession(state.value.currentSession) * 60
  }

  const skip = () => {
    completeCurrentSession()
  }

  const updateSettings = (newSettings: Partial<PomodoroSettings>) => {
    stopTimer()
    state.value.settings = { ...state.value.settings, ...newSettings }
    state.value.timeRemaining = getDurationForSession(state.value.currentSession) * 60
    state.value.isActive = false
  }

  const setDailyGoal = (goal: number) => {
    state.value.dailyGoal = goal
  }

  const onSessionComplete = (callback: (session: PomodoroSession) => void) => {
    onSessionCompleteCallbacks.value.push(callback)
    
    // Return unsubscribe function
    return () => {
      const index = onSessionCompleteCallbacks.value.indexOf(callback)
      if (index > -1) {
        onSessionCompleteCallbacks.value.splice(index, 1)
      }
    }
  }

  const getStats = () => {
    const today = new Date().toDateString()
    const todaySessions = sessionHistory.value.filter(s => 
      s.endTime && s.endTime.toDateString() === today && s.type === 'work'
    )

    return {
      sessionsToday: state.value.completedToday,
      totalSessions: state.value.sessionsCompleted,
      focusTimeToday: todaySessions.reduce((total, session) => total + session.duration, 0),
      totalFocusTime: state.value.totalFocusTime,
      currentStreak: state.value.streak,
      longestStreak: state.value.streak, // Would need to calculate from history in real app
      averageSessionLength: state.value.settings.workDuration,
      completionRate: sessionHistory.value.length > 0 ? 
        (sessionHistory.value.filter(s => s.completed).length / sessionHistory.value.length) * 100 : 100,
      weeklyGoal: state.value.dailyGoal * 7,
      dailyGoal: state.value.dailyGoal
    }
  }

  // Start/stop timer based on isActive
  watch(() => state.value.isActive, (newValue) => {
    if (newValue) {
      startTimer()
    } else {
      stopTimer()
    }
  })

  // Clean up on unmount
  onUnmounted(() => {
    if (timerInterval.value) {
      clearInterval(timerInterval.value)
    }
  })

  return {
    // State
    ...state.value,
    sessionHistory,
    
    // Actions
    start,
    pause,
    reset,
    skip,
    updateSettings,
    setDailyGoal,
    onSessionComplete,
    
    // Utilities
    formatTime,
    getStats,
    getDurationForSession
  }
}