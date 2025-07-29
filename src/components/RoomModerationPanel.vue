<template>
  <div class="space-y-6">
    <!-- Participants List -->
    <div class="glass-card p-6">
      <h3 class="text-lg font-bold text-white mb-4 flex items-center">
        <Eye class="h-5 w-5 mr-2" />
        Room Participants ({{ participants.length }})
      </h3>

      <div v-if="loading" class="text-center py-6">
        <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
      </div>

      <div v-else class="space-y-3">
        <div 
          v-for="participant in participants" 
          :key="participant.id" 
          class="flex items-center justify-between p-3 bg-white/5 rounded-lg"
        >
          <div class="flex items-center space-x-3">
            <div class="flex items-center space-x-2">
              <Crown v-if="isRoomOwner(participant)" class="h-4 w-4 text-star-400" />
              <Shield v-else-if="getUserRole(participant.user_id) === 'admin'" class="h-4 w-4 text-cosmic-400" />
              <Shield v-else-if="getUserRole(participant.user_id) === 'moderator'" class="h-4 w-4 text-nebula-400" />
              <span class="text-white font-medium">{{ participant.user_profiles.username }}</span>
            </div>
            
            <div class="flex items-center space-x-2 text-xs">
              <span class="text-cosmic-300">Level {{ participant.user_profiles.level }}</span>
              <span v-if="isTimedOut(participant)" class="bg-red-500/20 text-red-300 px-2 py-1 rounded">
                Timed Out
              </span>
              <span v-if="participant.is_muted" class="bg-gray-500/20 text-gray-300 px-2 py-1 rounded">
                Muted
              </span>
            </div>
          </div>

          <div v-if="participant.user_id !== authStore.user?.id" class="flex items-center space-x-2">
            <!-- Audio Controls -->
            <button
              @click="toggleMute(participant)"
              :class="[
                'p-2 rounded-lg transition-colors',
                participant.is_muted
                  ? 'text-gray-400 hover:text-white'
                  : 'text-white hover:text-gray-400'
              ]"
              :title="participant.is_muted ? 'Unmute' : 'Mute'"
            >
              <component :is="participant.is_muted ? MicOff : Mic" class="h-4 w-4" />
            </button>

            <!-- Moderation Actions -->
            <button
              @click="selectUser(participant.user_id)"
              class="cosmic-button text-xs"
              :disabled="isRoomOwner(participant)"
            >
              Moderate
            </button>

            <!-- Role Management (Owner only) -->
            <button
              v-if="isOwner && !isRoomOwner(participant)"
              @click="setShowPromoteDialog(participant.user_id)"
              class="nebula-button text-xs"
            >
              Promote
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Moderation Action Dialog -->
    <Transition>
      <div v-if="selectedUser" class="glass-card p-6">
        <h3 class="text-lg font-bold text-white mb-4">Moderation Actions</h3>
        
        <div class="space-y-4">
          <div>
            <label class="block text-cosmic-200 text-sm mb-2">Reason</label>
            <textarea
              v-model="actionReason"
              class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 resize-none"
              rows="3"
              placeholder="Explain the reason for this action..."
            ></textarea>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-cosmic-200 text-sm mb-2">Timeout Duration</label>
              <select
                v-model="timeoutDuration"
                class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white"
              >
                <option value="5">5 minutes</option>
                <option value="15">15 minutes</option>
                <option value="30">30 minutes</option>
                <option value="60">1 hour</option>
                <option value="180">3 hours</option>
              </select>
            </div>
          </div>

          <div class="flex space-x-3">
            <button
              @click="applyModerationAction('timeout')"
              class="flex items-center space-x-2 px-4 py-2 bg-yellow-500 hover:bg-yellow-600 text-white rounded-lg transition-colors"
            >
              <Clock class="h-4 w-4" />
              <span>Timeout</span>
            </button>

            <button
              @click="applyModerationAction('kick')"
              class="flex items-center space-x-2 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors"
            >
              <UserX class="h-4 w-4" />
              <span>Kick</span>
            </button>

            <button
              @click="applyModerationAction('ban')"
              class="flex items-center space-x-2 px-4 py-2 bg-red-700 hover:bg-red-800 text-white rounded-lg transition-colors"
            >
              <Ban class="h-4 w-4" />
              <span>Ban</span>
            </button>

            <button
              @click="cancelModeration"
              class="px-4 py-2 text-cosmic-300 hover:text-white transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Role Promotion Dialog -->
    <Transition>
      <div v-if="showPromoteDialog" class="glass-card p-6">
        <h3 class="text-lg font-bold text-white mb-4">Promote User</h3>
        
        <div class="space-y-4">
          <p class="text-cosmic-300">
            Select a role for {{ getParticipantName(showPromoteDialog) }}:
          </p>

          <div class="space-y-3">
            <button
              @click="handleRoleChange(showPromoteDialog, 'admin')"
              class="w-full p-3 text-left bg-cosmic-500/20 hover:bg-cosmic-500/30 border border-cosmic-400/50 rounded-lg transition-colors"
            >
              <div class="font-medium text-white">Admin</div>
              <div class="text-sm text-cosmic-300">Can manage timer, music, voice chat, and moderate</div>
            </button>

            <button
              @click="handleRoleChange(showPromoteDialog, 'moderator')"
              class="w-full p-3 text-left bg-nebula-500/20 hover:bg-nebula-500/30 border border-nebula-400/50 rounded-lg transition-colors"
            >
              <div class="font-medium text-white">Moderator</div>
              <div class="text-sm text-cosmic-300">Can moderate chat and kick users</div>
            </button>

            <button
              @click="handleRoleChange(showPromoteDialog, null)"
              class="w-full p-3 text-left bg-gray-500/20 hover:bg-gray-500/30 border border-gray-400/50 rounded-lg transition-colors"
            >
              <div class="font-medium text-white">Remove Role</div>
              <div class="text-sm text-cosmic-300">Remove admin/moderator permissions</div>
            </button>
          </div>

          <button
            @click="cancelPromote"
            class="w-full px-4 py-2 text-cosmic-300 hover:text-white transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </Transition>

    <!-- Moderation Logs -->
    <div class="glass-card p-6">
      <h3 class="text-lg font-bold text-white mb-4 flex items-center">
        <AlertTriangle class="h-5 w-5 mr-2" />
        Recent Moderation Actions
      </h3>

      <div v-if="loading" class="text-center py-6">
        <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
      </div>

      <div v-else-if="moderationLogs.length === 0" class="text-cosmic-400 text-center py-8">
        No moderation actions yet
      </div>

      <div v-else class="space-y-3">
        <div 
          v-for="log in moderationLogs" 
          :key="log.id" 
          class="p-3 bg-white/5 rounded-lg"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-2">
              <span :class="[
                'px-2 py-1 rounded text-xs font-medium',
                log.action === 'warn' ? 'bg-yellow-500/20 text-yellow-300' :
                log.action === 'timeout' ? 'bg-orange-500/20 text-orange-300' :
                log.action === 'kick' ? 'bg-red-500/20 text-red-300' :
                log.action === 'ban' ? 'bg-red-700/20 text-red-300' :
                'bg-green-500/20 text-green-300'
              ]">
                {{ log.action.toUpperCase() }}
              </span>
              <span class="text-white">
                {{ log.target_profiles?.username || 'Unknown User' }}
              </span>
            </div>
            <span class="text-cosmic-400 text-xs"> 
              {{ formatDate(log.created_at) }}
            </span>
          </div>
          
          <div class="mt-2 text-sm text-cosmic-300">
            <div>By: {{ getModeratorName(log) }}</div>
            <div v-if="log.reason">Reason: {{ log.reason }}</div>
            <div v-if="log.duration">Duration: {{ formatDuration(log.duration) }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Shield, 
  UserX, 
  Clock, 
  AlertTriangle, 
  Eye,
  Mic,
  MicOff,
  Crown,
  Ban
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface RoomParticipant {
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

interface ModerationLog {
  id: string
  room_id: string
  moderator_id: string
  target_user_id: string
  action: 'warn' | 'timeout' | 'kick' | 'ban' | 'unban'
  reason?: string
  duration?: string
  created_at: string
  moderator_profiles?: {
    username: string
  }
  target_profiles?: {
    username: string
  }
}

interface RoomRole {
  id: string
  room_id: string
  user_id: string
  role: 'admin' | 'moderator'
  granted_by: string
  granted_at: string
  permissions: {
    can_kick_users: boolean
    can_manage_timer: boolean
    can_moderate_chat: boolean
    can_manage_music: boolean
    can_manage_voice: boolean
  }
}

interface Props {
  roomId: string
  participants: RoomParticipant[]
  isOwner: boolean
  userRoles: RoomRole[]
}

// Props
const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
  (e: 'moderationAction', action: string, targetUser: string, reason?: string): void
}>()

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const moderationLogs = ref<ModerationLog[]>([])
const selectedUser = ref<string | null>(null)
const actionReason = ref('')
const timeoutDuration = ref<number>(5)
const showPromoteDialog = ref<string | null>(null)
const loading = ref(true)

// Computed
const canModerate = computed(() => {
  return props.isOwner || 
         currentUserRole.value?.role === 'admin' || 
         currentUserRole.value?.role === 'moderator'
})

const currentUserRole = computed(() => {
  return props.userRoles.find(role => role.user_id === authStore.user?.id)
})

// Lifecycle
onMounted(() => {
  if (canModerate.value) {
    fetchModerationLogs()
  }
})

// Methods
const fetchModerationLogs = async () => {
  try {
    const { data, error } = await supabase
      .from('moderation_logs')
      .select(`
        *,
        moderator_profiles:moderator_id(username),
        target_profiles:target_user_id(username)
      `)
      .eq('room_id', props.roomId)
      .order('created_at', { ascending: false })
      .limit(10)

    if (error) throw error
    moderationLogs.value = data || []
  } catch (error) {
    console.error('Failed to fetch moderation logs:', error)
  } finally {
    loading.value = false
  }
}

const applyModerationAction = async (action: string) => {
  if (!actionReason.value.trim() && action !== 'unmute') {
    toast.error('Please provide a reason for this action')
    return
  }

  if (!selectedUser.value) return

  try {
    // Call the database function for moderation
    const { data, error } = await supabase.rpc('apply_moderation_action', {
      room_uuid: props.roomId,
      target_user_uuid: selectedUser.value,
      action: action,
      reason: actionReason.value || null,
      duration_minutes: action === 'timeout' ? timeoutDuration.value : null
    })

    if (error) throw error

    if (data.success) {
      toast.success(`Action applied: ${action}`)
      emit('moderationAction', action, selectedUser.value, actionReason.value)
      actionReason.value = ''
      selectedUser.value = null
      fetchModerationLogs()
    } else {
      toast.error(data.error || 'Failed to apply moderation action')
    }
  } catch (error) {
    console.error('Moderation action failed:', error)
    toast.error('Failed to apply moderation action')
  }
}

const handleRoleChange = async (userId: string, newRole: 'admin' | 'moderator' | null) => {
  try {
    if (newRole === null) {
      // Remove role
      const { error } = await supabase
        .from('room_roles')
        .delete()
        .eq('room_id', props.roomId)
        .eq('user_id', userId)

      if (error) throw error
      toast.success('Role removed')
    } else {
      // Add or update role
      const { error } = await supabase
        .from('room_roles')
        .upsert({
          room_id: props.roomId,
          user_id: userId,
          role: newRole,
          granted_by: authStore.user?.id,
          permissions: {
            can_moderate_chat: true,
            can_manage_timer: newRole === 'admin',
            can_kick_users: true,
            can_manage_music: newRole === 'admin',
            can_manage_voice: newRole === 'admin'
          }
        })

      if (error) throw error
      toast.success(`Promoted to ${newRole}`)
    }

    showPromoteDialog.value = null
  } catch (error) {
    console.error('Failed to update role:', error)
    toast.error('Failed to update role')
  }
}

const toggleMute = (participant: RoomParticipant) => {
  applyModerationAction(participant.is_muted ? 'unmute' : 'mute', participant.user_id)
}

const applyModerationAction = async (action: string, targetUserId: string = selectedUser.value || '') => {
  if (!targetUserId) return
  
  try {
    // Call the database function for moderation
    const { data, error } = await supabase.rpc('apply_moderation_action', {
      room_uuid: props.roomId,
      target_user_uuid: targetUserId,
      action: action,
      reason: actionReason.value || null,
      duration_minutes: action === 'timeout' ? timeoutDuration.value : null
    })

    if (error) throw error

    if (data.success) {
      toast.success(`Action applied: ${action}`)
      emit('moderationAction', action, targetUserId, actionReason.value)
      actionReason.value = ''
      selectedUser.value = null
      fetchModerationLogs()
    } else {
      toast.error(data.error || 'Failed to apply moderation action')
    }
  } catch (error) {
    console.error('Moderation action failed:', error)
    toast.error('Failed to apply moderation action')
  }
}

const getUserRole = (userId: string): string | undefined => {
  if (isRoomOwnerById(userId)) {
    return 'owner'
  }
  return props.userRoles.find(role => role.user_id === userId)?.role
}

const isRoomOwner = (participant: RoomParticipant): boolean => {
  return participant.user_id === props.participants.find(p => p.is_admin)?.user_id
}

const isRoomOwnerById = (userId: string): boolean => {
  return userId === props.participants.find(p => p.is_admin)?.user_id
}

const isTimedOut = (participant: RoomParticipant): boolean => {
  return !!participant.timeout_until && new Date(participant.timeout_until) > new Date()
}

const formatDate = (dateStr: string): string => {
  return new Date(dateStr).toLocaleString()
}

const formatDuration = (duration: string): string => {
  const minutes = parseInt(duration.split(' ')[0])
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  return `${hours}h ${remainingMinutes}m`
}

const selectUser = (userId: string) => {
  selectedUser.value = userId
  actionReason.value = ''
}

const cancelModeration = () => {
  selectedUser.value = null
  actionReason.value = ''
}

const setShowPromoteDialog = (userId: string) => {
  showPromoteDialog.value = userId
}

const cancelPromote = () => {
  showPromoteDialog.value = null
}

const getParticipantName = (userId: string): string => {
  const participant = props.participants.find(p => p.user_id === userId)
  return participant?.user_profiles.username || 'Unknown User'
}

const getModeratorName = (log: ModerationLog): string => {
  if (log.moderator_profiles?.username) {
    return log.moderator_profiles.username
  }
  
  if (log.moderator_id === '00000000-0000-0000-0000-000000000001') {
    return '🤖 Draco'
  }
  
  return 'System'
}
</script>

<style scoped>
.v-enter-active,
.v-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.v-enter-from,
.v-leave-to {
  opacity: 0;
  transform: translateY(20px);
}
</style>