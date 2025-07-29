export interface PomodoroRoom {
  id: string
  name: string
  description: string
  type: 'public' | 'private'
  tags: string[]
  focus_mode: 'classic' | 'extended' | 'short_burst' | 'custom'
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

export interface FocusSession {
  id: string
  user_id: string
  room_id?: string
  focus_mode: 'deep_focus' | 'collaborative' | 'flexible'
  session_goal?: string
  checklist_items: ChecklistItem[] 
  completed_items: string[]
  interruptions: number
  focus_score: number
  xp_earned: number
  start_time: string
  end_time?: string
  is_active: boolean
  session_data: Record<string, any>
}

export interface ChecklistItem {
  id: string
  text: string
  completed: boolean
  priority: 'low' | 'medium' | 'high' 
  xp_earned?: boolean
}

export interface UserChecklist {
  id: string
  user_id: string
  name: string
  items: ChecklistItem[]
  is_default: boolean
  created_at: string
  updated_at: string
}

export interface RoomMusic {
  id: string
  room_id: string
  track_type: 'lofi' | 'nature' | 'white_noise' | 'binaural' | 'ambient'
  track_name: string
  track_url?: string
  volume: number
  is_active: boolean
  set_by?: string
  created_at: string
}

export interface ChatMessage {
  id: string
  room_id: string
  user_id: string
  message: string
  message_type: 'text' | 'system' | 'moderation'
  flagged: boolean
  flagged_reason?: string
  edited: boolean
  reply_to?: string
  created_at: string
  updated_at: string
  user_profiles: {
    username: string
    level: number
  }
}

export interface ModerationLog {
  id: string
  room_id: string
  moderator_id: string
  target_user_id: string
  action: 'warn' | 'timeout' | 'kick' | 'ban' | 'unban'
  reason?: string
  duration?: string
  created_at: string
  moderator_profiles: {
    username: string
  } | null
  target_profiles: {
    username: string
  } | null
}

export interface FocusMode {
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

export const FOCUS_MODES: Record<string, FocusMode> = {
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
}

export const CODE_OF_CONDUCT = {
  public: `# MemoQuest Public Room Code of Conduct

## 🌟 Our Commitment
We're building a supportive cosmic learning community where everyone can thrive.

## ✅ Encouraged Behaviors
- **Stay Focused**: Use study time for learning and growth
- **Be Supportive**: Encourage fellow learners and celebrate achievements
- **Communicate Respectfully**: Use kind, constructive language
- **Share Knowledge**: Help others when appropriate
- **Follow Focus Modes**: Respect the room's chosen focus level

## ❌ Prohibited Behaviors
- **Harassment or Bullying**: No personal attacks, insults, or discrimination
- **Spam or Disruption**: Avoid repetitive messages or off-topic conversations
- **Inappropriate Content**: No explicit, offensive, or harmful material
- **Academic Dishonesty**: No sharing of answers for assessments or cheating
- **External Links**: No sharing of unrelated websites or promotional content

## 🔨 Consequences
- **Warning**: First offense or minor violations
- **Timeout**: Temporary removal from chat (5-60 minutes)
- **Kick**: Removal from room for the session
- **Ban**: Permanent removal from room (serious violations)

## 🤖 AI Moderation
Our AI assistant helps maintain a positive environment by:
- Automatically flagging potentially inappropriate content
- Providing real-time guidance on community standards
- Supporting human moderators in decision-making

*By joining this room, you agree to follow these guidelines and help create a positive learning environment for all.*`,

  private: `# Private Room Guidelines

## 🏠 Your Space, Your Rules
Private rooms allow more flexibility while maintaining respect.

## 🎯 Core Principles
- **Respect All Members**: Treat everyone with kindness and consideration
- **Stay On Topic**: Keep conversations relevant to your study goals
- **Support Each Other**: Create an encouraging learning environment
- **Follow Room Creator's Rules**: Additional rules set by the room creator apply

## 🛡️ Room Creator Responsibilities
- Set clear expectations for behavior
- Moderate fairly and consistently
- Address conflicts promptly and respectfully
- Use moderation tools appropriately

## ⚡ Flexible Moderation
Private rooms have more lenient automated moderation, but serious violations of basic respect and safety will still be addressed.

*Remember: Even in private spaces, we're all part of the Memonize learning community.*`
}