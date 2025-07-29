// User and Authentication Types
export interface User {
  id: string
  email: string
  user_metadata?: {
    username?: string
    [key: string]: any
  }
}

export interface UserProfile {
  id: string
  username: string
  level: number
  experience: number
  study_streak: number
  total_study_time: number
  last_study_date?: string
  achievements: string[]
  learning_style: 'visual' | 'auditory' | 'kinesthetic' | 'reading'
  focus_areas?: string[]
  weekly_goal: number
  current_xp: number
  xp_to_next_level: number
}

// Note Types
export interface Note {
  id: string
  user_id: string
  title: string
  content: string
  is_favorite: boolean
  created_at: string
  updated_at: string
  ai_summary?: string
  key_concepts?: string[]
  difficulty_level?: 'beginner' | 'intermediate' | 'advanced'
  study_time_estimate?: number
}

// Flashcard Types
export interface Flashcard {
  id: string
  user_id: string
  term: string
  definition: string
  difficulty: 'easy' | 'medium' | 'hard'
  confidence_level: number
  source_note_id?: string
  last_reviewed?: string
  review_count: number
  created_at: string
  ease_factor?: number
  interval_days?: number
  next_review_date?: string
  learning_state?: 'new' | 'learning' | 'review' | 'relearning'
  content_source?: string
  source_file_url?: string
  ocr_confidence?: number
  ai_generated?: boolean
  media_timestamp?: number
}

// Pomodoro Types
export interface PomodoroRoom {
  id: string
  name: string
  description: string
  type: 'public' | 'private'
  tags: string[]
  focus_mode: string
  max_participants: number
  current_participants: number
  is_active: boolean
  owner_id: string
  timer_settings: {
    work_duration: number
    short_break: number
    long_break: number
    sessions_until_long_break: number
  }
  room_code?: string
  created_at: string
  updated_at: string
  code_of_conduct: string
  ai_moderation_enabled: boolean
  music_enabled: boolean
  voice_chat_enabled: boolean
  video_chat_enabled: boolean
  focus_mode_enforced: 'deep_focus' | 'collaborative' | 'flexible'
  user_profiles?: {
    username: string
  }
}

export interface RoomParticipant {
  id: string
  room_id: string
  user_id: string
  joined_at: string
  is_admin: boolean
  focus_score: number
  total_xp_earned: number
  is_muted: boolean
  timeout_until?: string
  user_profiles: {
    id: string
    username: string
    level: number
  }
}

export interface RoomRole {
  id: string
  room_id: string
  user_id: string
  role: 'admin' | 'moderator'
  granted_by: string
  granted_at: string
  permissions: {
    can_moderate_chat: boolean
    can_manage_timer: boolean
    can_kick_users: boolean
    can_manage_music: boolean
    can_manage_voice: boolean
  }
}

export interface ChecklistItem {
  id: string
  text: string
  completed: boolean
  priority: 'low' | 'medium' | 'high'
  xp_earned?: boolean
}

// AI and Analytics Types
export interface StudyInsight {
  id: string
  user_id: string
  insight_type: 'pattern' | 'recommendation' | 'warning' | 'encouragement' | 'optimization'
  title: string
  description: string
  data_source?: string[]
  confidence_score: number
  priority: 'low' | 'medium' | 'high' | 'critical'
  action_suggested?: string
  dismissed: boolean
  acted_upon: boolean
  generated_at: string
  valid_until: string
}

export interface XpTransaction {
  id: string
  user_id: string
  amount: number
  action_type: string
  description: string
  created_at: string
}

export interface Achievement {
  id: string
  user_id: string
  achievement_type: string
  achievement_name: string
  description: string
  criteria_met: Record<string, any>
  experience_gained: number
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
  unlocked_at: string
  displayed: boolean
}

// Deck Classroom Types
export interface Deck {
  id: string
  name: string
  description: string
  banner_url?: string
  color: string
  owner_id: string
  enrollment_code: string
  is_archived: boolean
  created_at: string
  updated_at: string
}

export interface DeckMember {
  id: string
  deck_id: string
  user_id: string
  role: 'teacher' | 'student' | 'assistant'
  joined_at: string
}

export interface DeckAssignment {
  id: string
  deck_id: string
  title: string
  description: string
  instructions: string
  due_date?: string
  points: number
  created_by?: string
  status: 'draft' | 'published' | 'archived'
  created_at: string
  updated_at: string
}

export interface DeckSubmission {
  id: string
  assignment_id: string
  user_id: string
  content: string
  flashcards_created: number
  attachments: any[]
  status: 'draft' | 'submitted' | 'late' | 'graded'
  grade?: number
  feedback?: string
  graded_by?: string
  submitted_at?: string
  graded_at?: string
  created_at: string
  updated_at: string
}