import { useState, useEffect, useRef, useCallback } from 'react'

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
  const [state, setState] = useState<PomodoroState>({
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

  const [sessionHistory, setSessionHistory] = useState<PomodoroSession[]>([])
  const timerRef = useRef<NodeJS.Timeout | null>(null)
  const onSessionCompleteCallbacks = useRef<Array<(session: PomodoroSession) => void>>([])

  // Timer logic
  useEffect(() => {
    if (state.isActive && state.timeRemaining > 0) {
      timerRef.current = setInterval(() => {
        setState(prev => ({
          ...prev,
          timeRemaining: prev.timeRemaining - 1
        }))
      }, 1000)
    } else {
      if (timerRef.current) {
        clearInterval(timerRef.current)
      }
    }

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current)
      }
    }
  }, [state.isActive, state.timeRemaining])

  // Handle session completion
  useEffect(() => {
    if (state.isActive && state.timeRemaining === 0) {
      completeCurrentSession()
    }
  }, [state.timeRemaining, state.isActive])

  const completeCurrentSession = useCallback(() => {
    const session: PomodoroSession = {
      type: state.currentSession,
      duration: getDurationForSession(state.currentSession),
      completed: true,
      endTime: new Date()
    }

    // Add to history
    setSessionHistory(prev => [...prev, session])

    // Update stats
    setState(prev => {
      const newState = { ...prev, isActive: false }
      
      if (state.currentSession === 'work') {
        newState.sessionsCompleted += 1
        newState.totalFocusTime += session.duration
        newState.completedToday += 1
        newState.streak += 1
      }

      // Determine next session
      if (state.currentSession === 'work') {
        const nextIsLongBreak = newState.sessionsCompleted % state.settings.sessionsUntilLongBreak === 0
        newState.currentSession = nextIsLongBreak ? 'long_break' : 'short_break'
      } else {
        newState.currentSession = 'work'
      }

      newState.timeRemaining = getDurationForSession(newState.currentSession) * 60

      return newState
    })

    // Notify callbacks
    onSessionCompleteCallbacks.current.forEach(callback => callback(session))
  }, [state.currentSession, state.settings.sessionsUntilLongBreak])

  const getDurationForSession = useCallback((sessionType: PomodoroSession['type']) => {
    switch (sessionType) {
      case 'work': return state.settings.workDuration
      case 'short_break': return state.settings.shortBreak
      case 'long_break': return state.settings.longBreak
    }
  }, [state.settings])

  const start = useCallback(() => {
    setState(prev => ({ ...prev, isActive: true }))
  }, [])

  const pause = useCallback(() => {
    setState(prev => ({ ...prev, isActive: false }))
  }, [])

  const reset = useCallback(() => {
    setState(prev => ({
      ...prev,
      isActive: false,
      timeRemaining: getDurationForSession(prev.currentSession) * 60
    }))
  }, [getDurationForSession])

  const skip = useCallback(() => {
    completeCurrentSession()
  }, [completeCurrentSession])

  const updateSettings = useCallback((newSettings: Partial<PomodoroSettings>) => {
    setState(prev => ({
      ...prev,
      settings: { ...prev.settings, ...newSettings },
      timeRemaining: getDurationForSession(prev.currentSession) * 60,
      isActive: false
    }))
  }, [getDurationForSession])

  const setDailyGoal = useCallback((goal: number) => {
    setState(prev => ({ ...prev, dailyGoal: goal }))
  }, [])

  const onSessionComplete = useCallback((callback: (session: PomodoroSession) => void) => {
    onSessionCompleteCallbacks.current.push(callback)
    
    // Return cleanup function
    return () => {
      const index = onSessionCompleteCallbacks.current.indexOf(callback)
      if (index > -1) {
        onSessionCompleteCallbacks.current.splice(index, 1)
      }
    }
  }, [])

  const getStats = useCallback(() => {
    const today = new Date().toDateString()
    const todaySessions = sessionHistory.filter(s => 
      s.endTime && s.endTime.toDateString() === today && s.type === 'work'
    )

    return {
      sessionsToday: state.completedToday,
      totalSessions: state.sessionsCompleted,
      focusTimeToday: todaySessions.reduce((total, session) => total + session.duration, 0),
      totalFocusTime: state.totalFocusTime,
      currentStreak: state.streak,
      longestStreak: state.streak, // Would need to calculate from history in real app
      averageSessionLength: state.settings.workDuration,
      completionRate: sessionHistory.length > 0 ? 
        (sessionHistory.filter(s => s.completed).length / sessionHistory.length) * 100 : 100,
      weeklyGoal: state.dailyGoal * 7,
      dailyGoal: state.dailyGoal
    }
  }, [state, sessionHistory])

  const formatTime = useCallback((seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }, [])

  return {
    // State
    ...state,
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