<template>
  <div class="glass-card p-6 h-96 flex flex-col">
    <!-- Chat Header -->
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-bold text-white">Room Chat</h3>
      <div class="flex items-center space-x-2">
        <span v-if="chatRestricted" class="text-xs bg-red-500/20 text-red-300 px-2 py-1 rounded">
          Limited Chat
        </span>
        <span class="text-xs text-cosmic-400">
          {{ messages.length }} messages
        </span>
      </div>
    </div>

    <!-- Messages -->
    <div class="flex-1 overflow-y-auto space-y-3 mb-4" ref="messagesContainer">
      <TransitionGroup name="message">
        <div 
          v-for="(message, index) in messages" 
          :key="message.id"
          :class="[
            'flex',
            isOwnMessage(message) ? 'justify-end' : 'justify-start'
          ]"
        >
          <div :class="['max-w-[80%]', isOwnMessage(message) ? 'order-2' : 'order-1']">
            <!-- Reply Reference -->
            <div v-if="message.reply_to" class="text-xs text-cosmic-400 mb-1 ml-3">
              Replying to {{ message.reply_message?.user_profiles?.username || 'Unknown User' }}
            </div>

            <div :class="[
              'rounded-lg p-3 relative group',
              isOwnMessage(message) 
                ? 'bg-cosmic-500 text-white' 
                : message.flagged
                  ? 'bg-red-500/20 border border-red-400/50 text-red-300'
                  : 'bg-white/10 text-cosmic-100 border border-white/10'
            ]">
              <!-- Message Header -->
              <div v-if="showAvatar(message, index) && !isOwnMessage(message)" class="flex items-center space-x-2 mb-2">
                <div class="w-6 h-6 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full flex items-center justify-center text-xs font-bold text-white">
                  {{ getInitial(message) }}
                </div>
                <span class="text-sm font-medium">
                  {{ message.user_profiles?.username || 'Unknown User' }}
                </span>
                <span class="text-xs text-cosmic-400">
                  Lv.{{ message.user_profiles?.level || 1 }}
                </span>
              </div>

              <!-- Message Content -->
              <div v-if="editingMessage === message.id">
                <div class="space-y-2">
                  <textarea
                    v-model="editText"
                    class="w-full px-2 py-1 bg-white/10 border border-white/20 rounded text-white text-sm resize-none"
                    rows="2"
                  ></textarea>
                  <div class="flex space-x-2">
                    <button
                      @click="editMessage(message.id)"
                      class="text-xs bg-green-500 hover:bg-green-600 text-white px-2 py-1 rounded"
                    >
                      Save
                    </button>
                    <button
                      @click="cancelEdit"
                      class="text-xs text-cosmic-300 hover:text-white"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              </div>
              <div v-else>
                <div class="text-sm leading-relaxed">
                  {{ message.message }}
                  <span v-if="message.edited" class="text-xs text-cosmic-400 ml-2">(edited)</span>
                </div>

                <!-- Flagged Warning -->
                <div v-if="message.flagged" class="flex items-center space-x-1 mt-2 text-xs">
                  <AlertTriangle class="h-3 w-3" />
                  <span>Flagged: {{ message.flagged_reason || 'Inappropriate content' }}</span>
                </div>

                <!-- Message Actions -->
                <div 
                  class="opacity-0 group-hover:opacity-100 absolute top-1 right-1 flex space-x-1 transition-opacity"
                >
                  <button
                    @click="replyToMessage(message)"
                    class="p-1 hover:bg-white/20 rounded text-xs"
                    title="Reply"
                  >
                    <Reply class="h-3 w-3" />
                  </button>
                  
                  <button
                    v-if="canEditMessage(message)"
                    @click="startEditing(message)"
                    class="p-1 hover:bg-white/20 rounded text-xs"
                    title="Edit"
                  >
                    <Edit3 class="h-3 w-3" />
                  </button>
                  
                  <button
                    v-if="canDeleteMessage(message)"
                    @click="confirmDeleteMessage(message.id)"
                    class="p-1 hover:bg-red-500 rounded text-xs"
                    title="Delete"
                  >
                    <Trash2 class="h-3 w-3" />
                  </button>
                  
                  <button
                    v-if="!isOwnMessage(message) && !message.flagged"
                    @click="flagMessage(message.id, 'Inappropriate content')"
                    class="p-1 hover:bg-yellow-500 rounded text-xs"
                    title="Flag"
                  >
                    <Flag class="h-3 w-3" />
                  </button>
                </div>
              </div>

              <!-- Timestamp -->
              <div class="text-xs text-cosmic-400 mt-1">
                {{ formatTime(message.created_at) }}
              </div>
            </div>
          </div>
        </div>
      </TransitionGroup>
      
      <div v-if="messages.length === 0" class="text-center text-cosmic-400 py-8">
        <Bot class="h-8 w-8 mx-auto mb-2 opacity-50" />
        <p>No messages yet</p>
        <p class="text-xs">Start the conversation!</p>
      </div>
    </div>

    <!-- Reply Banner -->
    <div v-if="replyingTo" class="bg-white/5 border-l-2 border-cosmic-500 p-2 mb-2">
      <div class="flex items-center justify-between">
        <div class="text-xs text-cosmic-300">
          Replying to {{ replyingTo.user_profiles?.username }}: 
          {{ replyingTo.message.substring(0, 50) }}{{ replyingTo.message.length > 50 ? '...' : '' }}
        </div>
        <button
          @click="cancelReply"
          class="text-cosmic-400 hover:text-white"
        >
          ×
        </button>
      </div>
    </div>

    <!-- Message Input -->
    <div class="flex items-center space-x-2">
      <div class="flex-1 relative">
        <input
          type="text"
          v-model="newMessage"
          @keyup.enter="sendMessage"
          :placeholder="
            chatRestricted && !canModerate 
              ? 'Chat limited in Deep Focus mode...' 
              : 'Type a message...'
          "
          class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all text-sm"
          :disabled="chatRestricted && !canModerate"
        />
        <div class="absolute right-2 top-1/2 transform -translate-y-1/2 text-xs text-cosmic-400">
          {{ newMessage.length }}/{{ maxMessageLength }}
        </div>
      </div>
      
      <button
        @click="sendMessage"
        :disabled="!newMessage.trim() || (chatRestricted && !canModerate) || newMessage.length > maxMessageLength"
        class="p-2 cosmic-button disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <Send class="h-4 w-4" />
      </button>
    </div>

    <div v-if="chatRestricted && !canModerate" class="text-xs text-cosmic-400 mt-1 text-center">
      Chat is limited in Deep Focus mode. Moderators can still communicate.
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  AlertTriangle, 
  Bot, 
  Edit3, 
  Flag, 
  Reply, 
  Send, 
  Trash2 
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

// Types
interface ChatMessage {
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
  user_profiles?: {
    username: string
    level: number
  }
  reply_message?: {
    id: string
    message: string
    user_id: string
    user_profiles?: {
      username: string
    }
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
    can_moderate_chat: boolean
    can_manage_timer: boolean
    can_kick_users: boolean
  }
}

// Props
defineProps<{
  roomId: string
  focusMode: 'deep_focus' | 'collaborative' | 'flexible'
  userRoles: RoomRole[]
  isOwner: boolean
}>()

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const messages = ref<ChatMessage[]>([])
const newMessage = ref('')
const replyingTo = ref<ChatMessage | null>(null)
const editingMessage = ref<string | null>(null)
const editText = ref('')
const loading = ref(true)
const messagesContainer = ref<HTMLElement | null>(null)
const realtimeSubscription = ref<{ unsubscribe: () => void } | null>(null)

// Computed
const currentUserRole = computed(() => 
  props.userRoles.find(role => role.user_id === authStore.user?.id)
)

const canModerate = computed(() => 
  props.isOwner || 
  currentUserRole.value?.role === 'admin' || 
  currentUserRole.value?.role === 'moderator'
)

const chatRestricted = computed(() => props.focusMode === 'deep_focus')
const maxMessageLength = computed(() => props.focusMode === 'deep_focus' ? 100 : 500)

// Lifecycle hooks
onMounted(() => {
  fetchMessages()
  setupRealtimeSubscription()
})

onUnmounted(() => {
  if (realtimeSubscription.value) {
    realtimeSubscription.value.unsubscribe()
  }
})

// Watch for new messages to scroll to bottom
watch(messages, () => {
  nextTick(() => {
    scrollToBottom()
  })
})

// Methods
const fetchMessages = async () => {
  try {
    // First, fetch the basic chat messages
    const { data, error } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('room_id', props.roomId)
      .order('created_at', { ascending: true })
      .limit(100)

    if (error) throw error
    
    if (!data || data.length === 0) {
      messages.value = []
      loading.value = false
      return
    }

    // Get unique user IDs from messages
    const userIds = [...new Set(data.map(msg => msg.user_id))]
    
    // Fetch user profiles for all users in the chat
    const { data: profiles, error: profileError } = await supabase
      .from('user_profiles')
      .select('id, username, level')
      .in('id', userIds)

    if (profileError) throw profileError

    // Get unique reply_to IDs for replied messages
    const replyIds = data
      .filter(msg => msg.reply_to)
      .map(msg => msg.reply_to)
      .filter(id => id !== null) as string[]

    let replyMessages: any[] = []
    if (replyIds.length > 0) {
      const { data: replies, error: replyError } = await supabase
        .from('chat_messages')
        .select('id, message, user_id')
        .in('id', replyIds)

      if (replyError) throw replyError
      replyMessages = replies || []
    }

    // Create profile lookup map
    const profileMap = new Map(profiles?.map(p => [p.id, p]) || [])
    
    // Create reply message lookup map with user profiles
    const replyMap = new Map(
      replyMessages.map(reply => [
        reply.id, 
        {
          ...reply,
          user_profiles: profileMap.get(reply.user_id)
        }
      ])
    )

    // Merge all data
    const messagesWithProfiles = data.map(message => ({
      ...message,
      user_profiles: profileMap.get(message.user_id),
      reply_message: message.reply_to ? replyMap.get(message.reply_to) : null
    }))

    messages.value = messagesWithProfiles
  } catch (error) {
    console.error('Failed to fetch messages:', error)
    toast.error('Failed to load chat messages')
  } finally {
    loading.value = false
    nextTick(() => {
      scrollToBottom()
    })
  }
}

const setupRealtimeSubscription = () => {
  const subscription = supabase
    .channel(`room_chat_${props.roomId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'chat_messages',
        filter: `room_id=eq.${props.roomId}`
      },
      async (payload) => {
        // Handle new message in real-time with profile data
        const newMessage = payload.new
        
        // Fetch user profile for the new message
        const { data: profile } = await supabase
          .from('user_profiles')
          .select('id, username, level')
          .eq('id', newMessage.user_id)
          .single()
        
        // Fetch reply message if exists
        let replyMessage = null
        if (newMessage.reply_to) {
          const { data: reply } = await supabase
            .from('chat_messages')
            .select('id, message, user_id')
            .eq('id', newMessage.reply_to)
            .single()
          
          if (reply) {
            const { data: replyProfile } = await supabase
              .from('user_profiles')
              .select('id, username, level')
              .eq('id', reply.user_id)
              .single()
            
            replyMessage = {
              ...reply,
              user_profiles: replyProfile
            }
          }
        }
        
        const messageWithProfile = {
          ...newMessage,
          user_profiles: profile,
          reply_message: replyMessage
        }
        
        messages.value.push(messageWithProfile)
      }
    )
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'chat_messages',
        filter: `room_id=eq.${props.roomId}`
      },
      () => {
        fetchMessages()
      }
    )
    .on(
      'postgres_changes',
      {
        event: 'DELETE',
        schema: 'public',
        table: 'chat_messages',
        filter: `room_id=eq.${props.roomId}`
      },
      (payload) => {
        messages.value = messages.value.filter(msg => msg.id !== payload.old.id)
      }
    )
    .subscribe()

  // Store subscription for cleanup
  realtimeSubscription.value = {
    unsubscribe: () => subscription.unsubscribe()
  }
}

const sendMessage = async () => {
  if (!newMessage.value.trim() || newMessage.value.length > maxMessageLength.value) {
    return
  }

  if (chatRestricted.value && !canModerate.value) {
    toast.error('Chat is restricted in Deep Focus mode')
    return
  }

  try {
    const messageData = {
      room_id: props.roomId,
      user_id: authStore.user?.id,
      message: newMessage.value.trim(),
      reply_to: replyingTo.value?.id || null
    }

    const { error } = await supabase
      .from('chat_messages')
      .insert([messageData])

    if (error) throw error
    
    // Award XP for participating in group chat
    // Only award XP for every 5th message to prevent spam
    const { count } = await supabase
      .from('chat_messages')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', authStore.user?.id)
      .eq('room_id', props.roomId)
        
    if (count !== null && count % 5 === 0) {
      authStore.addExperience(5, "Active Participation in Study Group")
    }
    
    newMessage.value = ''
    replyingTo.value = null
  } catch (error) {
    console.error('Failed to send message:', error)
    toast.error('Failed to send message')
  }
}

const editMessage = async (messageId: string) => {
  if (!editText.value.trim()) return

  try {
    const { error } = await supabase
      .from('chat_messages')
      .update({
        message: editText.value.trim(),
        edited: true,
        updated_at: new Date().toISOString()
      })
      .eq('id', messageId)

    if (error) throw error

    editingMessage.value = null
    editText.value = ''
    await fetchMessages()
  } catch (error) {
    console.error('Failed to edit message:', error)
    toast.error('Failed to edit message')
  }
}

const deleteMessage = async (messageId: string) => {
  try {
    const { error } = await supabase
      .from('chat_messages')
      .delete()
      .eq('id', messageId)

    if (error) throw error
    
    toast.success('Message deleted')
  } catch (error) {
    console.error('Failed to delete message:', error)
    toast.error('Failed to delete message')
  }
}

const flagMessage = async (messageId: string, reason: string) => {
  try {
    const { error } = await supabase
      .from('chat_messages')
      .update({
        flagged: true,
        flagged_reason: reason
      })
      .eq('id', messageId)

    if (error) throw error

    toast.success('Message flagged for review')
  } catch (error) {
    console.error('Failed to flag message:', error)
    toast.error('Failed to flag message')
  }
}

const replyToMessage = (message: ChatMessage) => {
  replyingTo.value = message
}

const startEditing = (message: ChatMessage) => {
  editingMessage.value = message.id
  editText.value = message.message
}

const cancelEdit = () => {
  editingMessage.value = null
  editText.value = ''
}

const cancelReply = () => {
  replyingTo.value = null
}

const confirmDeleteMessage = (messageId: string) => {
  if (confirm('Are you sure you want to delete this message?')) {
    deleteMessage(messageId)
  }
}

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

const formatTime = (timestamp: string) => {
  return new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

const canEditMessage = (message: ChatMessage) => {
  return message.user_id === authStore.user?.id && !message.flagged
}

const canDeleteMessage = (message: ChatMessage) => {
  return message.user_id === authStore.user?.id || canModerate.value
}

const isOwnMessage = (message: ChatMessage) => {
  return message.user_id === authStore.user?.id
}

const showAvatar = (message: ChatMessage, index: number) => {
  return index === 0 || messages.value[index - 1]?.user_id !== message.user_id
}

const getInitial = (message: ChatMessage) => {
  return (message.user_profiles?.username || 'U').charAt(0).toUpperCase()
}
</script>

<style scoped>
.message-enter-active,
.message-leave-active {
  transition: all 0.3s ease;
}

.message-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.message-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}
</style>