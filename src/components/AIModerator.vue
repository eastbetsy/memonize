<template>
  <div class="space-y-4">
    <!-- AI Status Card -->
    <div class="glass-card p-6">
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center space-x-3">
          <div
            class="p-2 rounded-lg"
            :class="aiActive ? 'bg-green-500' : 'bg-gray-500'"
          >
            <Bot class="h-6 w-6 text-white" />
          </div>
          <div>
            <h3 class="text-lg font-bold text-white">🤖 Draco AI Moderator</h3>
            <p class="text-sm text-cosmic-300">
              {{ aiActive ? 'Active and monitoring' : 'Inactive' }}
            </p>
          </div>
        </div>
        
        <div class="flex items-center space-x-2">
          <div :class="[
            'w-3 h-3 rounded-full',
            aiActive ? 'bg-green-400 animate-pulse' : 'bg-gray-400'
          ]"></div>
          <span class="text-sm text-cosmic-300">
            {{ aiActive ? 'Online' : 'Offline' }}
          </span>
        </div>
      </div>

      <!-- AI Capabilities -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
        <div class="text-center p-3 bg-white/5 rounded-lg">
          <Shield class="h-5 w-5 text-cosmic-400 mx-auto mb-1" />
          <div class="text-xs text-cosmic-300">Content Filter</div>
          <div class="text-green-400 text-xs font-medium">Active</div>
        </div>
        <div class="text-center p-3 bg-white/5 rounded-lg">
          <TrendingUp class="h-5 w-5 text-cosmic-400 mx-auto mb-1" />
          <div class="text-xs text-cosmic-300">Spam Detection</div>
          <div class="text-green-400 text-xs font-medium">Active</div>
        </div>
        <div class="text-center p-3 bg-white/5 rounded-lg">
          <AlertTriangle class="h-5 w-5 text-cosmic-400 mx-auto mb-1" />
          <div class="text-xs text-cosmic-300">Auto Timeout</div>
          <div class="text-green-400 text-xs font-medium">Active</div>
        </div>
        <div class="text-center p-3 bg-white/5 rounded-lg">
          <Activity class="h-5 w-5 text-cosmic-400 mx-auto mb-1" />
          <div class="text-xs text-cosmic-300">Real-time</div>
          <div class="text-green-400 text-xs font-medium">Active</div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div v-if="isOwner || hasAdminRole" class="flex space-x-3">
        <button
          @click="sendEncouragementMessage"
          class="cosmic-button text-sm flex items-center space-x-2"
        >
          <Bot class="h-4 w-4" />
          <span>Send Encouragement</span>
        </button>
      </div>
    </div>

    <!-- Moderation Statistics -->
    <div class="glass-card p-6">
      <h4 class="text-lg font-bold text-white mb-4 flex items-center">
        <Activity class="h-5 w-5 mr-2 text-cosmic-400" />
        AI Moderation Stats
      </h4>

      <div v-if="loading" class="text-center py-4">
        <div class="w-6 h-6 border-2 border-cosmic-500 border-t-transparent rounded-full mx-auto animate-spin"></div>
      </div>
      
      <div v-else class="grid grid-cols-2 md:grid-cols-3 gap-4">
        <div class="text-center">
          <div class="text-2xl font-bold text-white">{{ stats.total_violations }}</div>
          <div class="text-sm text-cosmic-300">Total Violations</div>
          <div class="text-xs text-cosmic-400">All time</div>
        </div>
        
        <div class="text-center">
          <div class="text-2xl font-bold text-white">{{ stats.violations_today }}</div>
          <div class="text-sm text-cosmic-300">Today's Violations</div>
          <div class="text-xs text-cosmic-400">Last 24 hours</div>
        </div>
        
        <div class="text-center col-span-2 md:col-span-1">
          <div class="text-lg font-bold text-white capitalize">
            {{ stats.most_common_violation === 'none' ? 'Clean!' : stats.most_common_violation }}
          </div>
          <div class="text-sm text-cosmic-300">Most Common</div>
          <div class="text-xs text-cosmic-400">Violation type</div>
        </div>
      </div>

      <!-- AI Performance Indicator -->
      <div class="mt-4 p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
        <div class="flex items-center space-x-2">
          <CheckCircle class="h-5 w-5 text-green-400" />
          <span class="text-green-300 font-medium">AI Performance: Excellent</span>
        </div>
        <div class="text-xs text-green-400 mt-1">
          Fast response times • High accuracy • Continuous learning
        </div>
      </div>
    </div>

    <!-- AI Behavior Info -->
    <div class="glass-card p-6">
      <h4 class="text-white font-medium mb-3">🤖 How Draco Works</h4>
      <div class="space-y-3 text-sm text-cosmic-300">
        <div class="flex items-start space-x-2">
          <span class="text-cosmic-400 mt-1">•</span>
          <span>Monitors all messages in real-time for inappropriate content, spam, and violations</span>
        </div>
        <div class="flex items-start space-x-2">
          <span class="text-cosmic-400 mt-1">•</span>
          <span>Escalates actions based on violation history: Warning → Timeout → Kick</span>
        </div>
        <div class="flex items-start space-x-2">
          <span class="text-cosmic-400 mt-1">•</span>
          <span>Provides encouraging messages to keep the study environment positive</span>
        </div>
        <div class="flex items-start space-x-2">
          <span class="text-cosmic-400 mt-1">•</span>
          <span>Adapts behavior based on room focus mode and community guidelines</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Bot, 
  Shield, 
  TrendingUp, 
  AlertTriangle, 
  CheckCircle, 
  Activity
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'

interface AIModerationStats {
  total_violations: number
  violations_today: number
  most_common_violation: string
  ai_moderator_active: boolean
}

interface RoomRole {
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

// Props
defineProps<{
  roomId: string
  userRoles: RoomRole[]
  isOwner: boolean
}>()

// Composables
const toast = useToast()

// State
const stats = ref<AIModerationStats>({
  total_violations: 0,
  violations_today: 0,
  most_common_violation: 'none',
  ai_moderator_active: true
})
const aiActive = ref(true)
const loading = ref(true)

// Computed
const hasAdminRole = computed(() => {
  return props.userRoles.some(role => role.role === 'admin')
})

// Lifecycle
onMounted(() => {
  fetchModerationStats()
})

// Methods
const fetchModerationStats = async () => {
  try {
    const { data, error } = await supabase.rpc('get_room_moderation_stats', {
      room_uuid: props.roomId
    })

    if (error) throw error
    stats.value = data
    aiActive.value = data.ai_moderator_active
  } catch (error) {
    console.error('Failed to fetch moderation stats:', error)
  } finally {
    loading.value = false
  }
}

const sendEncouragementMessage = async () => {
  try {
    await supabase.rpc('send_ai_encouragement', {
      room_uuid: props.roomId
    })
    toast.success('AI encouragement message sent')
  } catch (error) {
    console.error('Failed to send encouragement:', error)
    toast.error('Failed to send message')
  }
}
</script>
```