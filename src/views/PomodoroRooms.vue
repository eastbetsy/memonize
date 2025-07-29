<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-glow mb-2">Enhanced Pomodoro Rooms</h1>
        <p class="text-cosmic-300">Join collaborative focus sessions with advanced features</p>
      </div>
      
      <button
        v-if="!roomDetail"
        @click="showCreateForm = true"
        class="cosmic-button flex items-center space-x-2"
      >
        <Plus class="h-5 w-5" />
        <span>Create Room</span>
      </button>
      
      <button
        v-else
        @click="goBackToRooms"
        class="cosmic-button flex items-center space-x-2"
      >
        <ChevronLeft class="h-5 w-5" />
        <span>Back to Rooms</span>
      </button>
    </div>

    <!-- Loading Indicator -->
    <div v-if="loading" class="flex items-center justify-center py-20">
      <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
    </div>

    <!-- Error Message -->
    <div v-else-if="error" class="glass-card p-6 text-center">
      <AlertTriangle class="h-12 w-12 text-red-400 mx-auto mb-4" />
      <h3 class="text-xl font-bold text-white mb-2">Something went wrong</h3>
      <p class="text-cosmic-300 mb-4">{{ error }}</p>
      <button @click="refreshData" class="cosmic-button">Try Again</button>
    </div>

    <!-- Auth Required Message -->
    <div v-else-if="!authStore.isAuthenticated" class="text-center py-20">
      <Timer class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h2 class="text-2xl font-bold text-white mb-4">Sign in to access Pomodoro Rooms</h2>
      <p class="text-cosmic-300">Create an account to join collaborative focus sessions</p>
    </div>

    <!-- Create Room Form -->
    <Transition>
      <div v-if="showCreateForm" class="glass-card p-6">
        <h3 class="text-xl font-bold text-white mb-6">Create Enhanced Pomodoro Room</h3>
        
        <div class="grid md:grid-cols-2 gap-6">
          <!-- Basic Info -->
          <div class="space-y-4">
            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Room Name</label>
              <input
                type="text"
                v-model="newRoom.name"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                placeholder="Enter room name..."
              />
            </div>
            
            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Description</label>
              <textarea
                v-model="newRoom.description"
                rows="3"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
                placeholder="Describe your room..."
              ></textarea>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-cosmic-200 font-medium mb-2">Room Type</label>
                <select
                  v-model="newRoom.type"
                  class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                >
                  <option value="public">Public</option>
                  <option value="private">Private</option>
                </select>
              </div>

              <div>
                <label class="block text-cosmic-200 font-medium mb-2">Max Participants</label>
                <input
                  type="number"
                  min="2"
                  max="50"
                  v-model="newRoom.max_participants"
                  class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                />
              </div>
            </div>
          </div>

          <!-- Advanced Settings -->
          <div class="space-y-4">
            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Focus Mode</label>
              <select
                v-model="newRoom.focus_mode_enforced"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
              >
                <option value="flexible">Flexible Flow</option>
                <option value="collaborative">Collaborative Study</option>
                <option value="deep_focus">Deep Focus</option>
              </select>
            </div>

            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Tags</label>
              <div class="flex flex-wrap gap-2 mb-2">
                <span
                  v-for="tag in newRoom.tags"
                  :key="tag"
                  class="flex items-center space-x-1 px-2 py-1 bg-cosmic-500/20 text-cosmic-300 rounded text-sm"
                >
                  <span>{{ tag }}</span>
                  <button
                    @click="removeRoomTag(tag)"
                    class="text-cosmic-400 hover:text-white"
                  >
                    ×
                  </button>
                </span>
              </div>
              <select
                @change="addRoomTag"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
              >
                <option value="">Add tags...</option>
                <option 
                  v-for="tag in availableTags.filter(tag => !newRoom.tags.includes(tag))" 
                  :key="tag" 
                  :value="tag"
                >
                  {{ tag }}
                </option>
              </select>
            </div>

            <!-- Feature Toggles -->
            <div class="space-y-3">
              <label class="flex items-center space-x-3">
                <input
                  type="checkbox"
                  v-model="newRoom.music_enabled"
                  class="w-4 h-4 text-cosmic-500 rounded"
                />
                <span class="text-cosmic-200">Enable Background Music</span>
              </label>

              <label class="flex items-center space-x-3">
                <input
                  type="checkbox"
                  v-model="newRoom.voice_chat_enabled"
                  class="w-4 h-4 text-cosmic-500 rounded"
                />
                <span class="text-cosmic-200">Enable Voice Chat</span>
              </label>

              <label class="flex items-center space-x-3">
                <input
                  type="checkbox"
                  v-model="newRoom.video_chat_enabled"
                  class="w-4 h-4 text-cosmic-500 rounded"
                />
                <span class="text-cosmic-200">Enable Video Chat</span>
              </label>

              <label class="flex items-center space-x-3">
                <input
                  type="checkbox"
                  v-model="newRoom.ai_moderation_enabled"
                  class="w-4 h-4 text-cosmic-500 rounded"
                />
                <span class="text-cosmic-200">Enable AI Moderation</span>
              </label>
            </div>
          </div>
        </div>
        
        <div class="flex gap-3 mt-6">
          <button
            @click="createRoom"
            class="cosmic-button"
          >
            Create Room
          </button>
          <button
            @click="showCreateForm = false"
            class="px-4 py-2 text-cosmic-300 hover:text-white transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </Transition>

    <!-- Room Detail View -->
    <div v-if="roomDetail && !loading && !error" class="space-y-6">
      <div class="glass-card p-6">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-2xl font-bold text-white">{{ roomDetail.name }}</h2>
            <p class="text-cosmic-300">{{ roomDetail.description }}</p>
          </div>
          
          <div v-if="roomDetail" class="flex space-x-3">
            <button
              v-if="isRoomOwner"
              @click="toggleRoomActive"
              :class="[
                roomDetail.is_active ? 'nebula-button' : 'cosmic-button',
                'flex items-center space-x-2'
              ]"
            >
              <component :is="roomDetail.is_active ? Pause : Play" class="h-4 w-4" />
              <span>{{ roomDetail.is_active ? 'Stop Session' : 'Start Session' }}</span>
            </button>
            
            <button
              v-if="!isRoomOwner && !isParticipant"
              @click="joinRoom(roomDetail)"
              class="cosmic-button"
            >
              Join Room
            </button>
            
            <button
              v-if="isParticipant && !isRoomOwner"
              @click="leaveRoom"
              class="nebula-button"
            >
              Leave Room
            </button>
          </div>
        </div>
        
        <!-- Room Info -->
        <div class="grid md:grid-cols-3 gap-4">
          <div class="glass-card p-4">
            <h3 class="text-lg font-bold text-white mb-2">Participants</h3>
            <div class="space-y-2 max-h-48 overflow-y-auto">
              <div 
                v-for="participant in roomDetail.participants" 
                :key="participant.id"
                class="flex items-center justify-between p-2 bg-white/5 rounded"
              >
                <div class="flex items-center space-x-2">
                  <div class="w-8 h-8 bg-cosmic-500 rounded-full flex items-center justify-center text-white font-bold">
                    {{ participant.user?.username?.[0] || '?' }}
                  </div>
                  <div>
                    <div class="text-white">{{ participant.user?.username }}</div>
                    <div class="text-xs text-cosmic-400">Lv.{{ participant.user?.level || 1 }}</div>
                  </div>
                </div>
                
                <div class="flex items-center space-x-1">
                  <Crown v-if="participant.is_admin || participant.user_id === roomDetail.owner_id" class="h-4 w-4 text-star-400" />
                  <MicOff v-if="participant.is_muted" class="h-4 w-4 text-red-400" />
                </div>
              </div>
            </div>
          </div>
          
          <div class="glass-card p-4">
            <h3 class="text-lg font-bold text-white mb-2">Room Settings</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span class="text-cosmic-300">Focus Mode:</span>
                <span class="text-white">{{ getFocusModeName(roomDetail.focus_mode_enforced) }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-cosmic-300">Room Type:</span>
                <span class="text-white capitalize">{{ roomDetail.type }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-cosmic-300">Music:</span>
                <span class="text-white">{{ roomDetail.music_enabled ? 'Enabled' : 'Disabled' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-cosmic-300">Voice Chat:</span>
                <span class="text-white">{{ roomDetail.voice_chat_enabled ? 'Enabled' : 'Disabled' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-cosmic-300">Video Chat:</span>
                <span class="text-white">{{ roomDetail.video_chat_enabled ? 'Enabled' : 'Disabled' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-cosmic-300">AI Moderation:</span>
                <span class="text-white">{{ roomDetail.ai_moderation_enabled ? 'Enabled' : 'Disabled' }}</span>
              </div>
            </div>
          </div>
          
          <div class="glass-card p-4">
            <h3 class="text-lg font-bold text-white mb-2">Pomodoro Timer</h3>
            <div class="space-y-3">
              <div class="text-center">
                <div class="text-3xl font-bold text-cosmic-300">
                  {{ isTimerActive ? formatTime(timerRemaining) : '00:00' }}
                </div>
                <div class="text-sm text-cosmic-400">
                  {{ isTimerActive ? (isBreakTime ? 'Break Time' : 'Focus Time') : 'Timer not started' }}
                </div>
              </div>
              
              <div v-if="isTimerActive" class="w-full bg-white/10 h-2 rounded-full">
                <div 
                  class="bg-cosmic-500 h-2 rounded-full transition-all duration-300"
                  :style="{ width: `${timerProgress}%` }"
                ></div>
              </div>
              
              <button
                v-if="roomDetail.is_active && isParticipant"
                @click="isTimerActive ? pauseTimer() : startTimer()"
                class="w-full cosmic-button flex items-center justify-center space-x-2"
              >
                <component :is="isTimerActive ? Pause : Play" class="h-4 w-4" />
                <span>{{ isTimerActive ? 'Pause Timer' : 'Start Timer' }}</span>
              </button>
              
              <div v-else class="text-sm text-cosmic-400 text-center">
                {{ roomDetail.is_active ? 'Join the room to use the timer' : 'Room session not active' }}
              </div>
            </div>
          </div>
        </div>
        
        <!-- Room Features -->
        <div class="mt-6 grid md:grid-cols-2 gap-6">
          <!-- Chat -->
          <div class="glass-card p-4 h-72">
            <h3 class="text-lg font-bold text-white mb-2 flex items-center">
              <MessageSquare class="h-5 w-5 mr-2 text-cosmic-400" />
              Room Chat
            </h3>
            
            <div class="flex flex-col h-full">
              <div class="flex-1 overflow-y-auto mb-3 space-y-2">
                <div v-if="messages.length === 0" class="text-center py-8">
                  <MessageSquare class="h-8 w-8 text-cosmic-400 mx-auto mb-2 opacity-50" />
                  <p class="text-cosmic-400">No messages yet</p>
                </div>
                
                <div 
                  v-for="(message, index) in messages" 
                  :key="index"
                  class="flex items-start space-x-2"
                >
                  <div 
                    class="w-6 h-6 rounded-full bg-cosmic-500 flex items-center justify-center text-xs text-white font-bold"
                  >
                    {{ message.user[0] }}
                  </div>
                  <div>
                    <div class="flex items-center space-x-2">
                      <span class="text-sm font-medium text-white">{{ message.user }}</span>
                      <span class="text-xs text-cosmic-400">{{ message.time }}</span>
                    </div>
                    <div class="text-sm text-cosmic-200">{{ message.text }}</div>
                  </div>
                </div>
              </div>
              
              <div>
                <div class="flex items-center space-x-2">
                  <input
                    type="text"
                    v-model="newMessage"
                    @keyup.enter="sendMessage"
                    class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 text-sm"
                    placeholder="Type a message..."
                  />
                  <button
                    @click="sendMessage"
                    :disabled="!newMessage.trim()"
                    class="p-2 cosmic-button disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Send class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Music Player -->
          <div class="glass-card p-4 h-72">
            <h3 class="text-lg font-bold text-white mb-2 flex items-center">
              <Music class="h-5 w-5 mr-2 text-cosmic-400" />
              Background Music
            </h3>
            
            <div class="flex flex-col items-center justify-center h-full">
              <div v-if="!roomDetail.music_enabled" class="text-center">
                <Music class="h-12 w-12 text-cosmic-400 mx-auto mb-4 opacity-50" />
                <p class="text-cosmic-400">Music is disabled for this room</p>
              </div>
              
              <div v-else class="text-center w-full">
                <div class="text-cosmic-300 mb-4">
                  <div class="text-xl">🎵</div>
                  <div>Lofi Study Beats</div>
                </div>
                
                <div class="w-full bg-white/10 h-1 rounded-full mb-4">
                  <div 
                    class="bg-cosmic-500 h-1 rounded-full w-3/4"
                  ></div>
                </div>
                
                <div class="flex justify-center space-x-4 mb-4">
                  <button class="p-2 bg-white/5 rounded-full">
                    <SkipBack class="h-5 w-5 text-cosmic-300" />
                  </button>
                  <button class="p-2 bg-cosmic-500 rounded-full">
                    <Play class="h-5 w-5 text-white" />
                  </button>
                  <button class="p-2 bg-white/5 rounded-full">
                    <SkipForward class="h-5 w-5 text-cosmic-300" />
                  </button>
                </div>
                
                <div class="flex items-center space-x-2">
                  <Volume1 class="h-4 w-4 text-cosmic-400" />
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value="50"
                    class="w-full"
                  />
                  <Volume2 class="h-4 w-4 text-cosmic-400" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Rooms Grid (Only shown when not viewing a specific room) -->
    <div v-if="!roomDetail && !loading && !error && authStore.isAuthenticated" class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="room in rooms"
        :key="room.id"
        class="glass-card p-6 hover:border-cosmic-400/50 transition-all duration-300 group"
      >
        <div class="flex items-start justify-between mb-4">
          <div class="flex-1">
            <div class="flex items-center space-x-2 mb-2">
              <component 
                :is="room.type === 'private' ? Lock : Globe" 
                class="h-4 w-4 text-cosmic-400" 
              />
              <h3 class="font-bold text-white group-hover:text-glow transition-all">
                {{ room.name }}
              </h3>
            </div>
            <p class="text-cosmic-300 text-sm mb-3 line-clamp-2">
              {{ room.description }}
            </p>
          </div>
          
          <div v-if="room.is_active" class="flex items-center space-x-1 text-green-400 text-xs">
            <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
            <span>Live</span>
          </div>
        </div>
        
        <div class="space-y-3">
          <!-- Focus Mode Badge -->
          <div 
            class="inline-flex items-center space-x-1 px-2 py-1 rounded-full text-xs font-medium bg-gradient-to-r text-white"
            :class="[
              room.focus_mode_enforced === 'deep_focus' ? 'from-red-500 to-red-600' :
              room.focus_mode_enforced === 'collaborative' ? 'from-blue-500 to-blue-600' :
              'from-green-500 to-green-600'
            ]"
          >
            <component 
              :is="room.focus_mode_enforced === 'deep_focus' 
                ? Brain 
                : room.focus_mode_enforced === 'collaborative' 
                  ? Users 
                  : Zap" 
              class="h-3 w-3" 
            />
            <span>{{ getFocusModeName(room.focus_mode_enforced) }}</span>
          </div>

          <!-- Room Stats -->
          <div class="grid grid-cols-3 gap-2 text-xs">
            <div class="text-center">
              <div class="text-white font-bold">{{ room.current_participants }}</div>
              <div class="text-cosmic-400">Participants</div>
            </div>
            <div class="text-center">
              <div class="text-white font-bold">{{ room.max_participants }}</div>
              <div class="text-cosmic-400">Max</div>
            </div>
            <div class="text-center">
              <div class="flex justify-center space-x-1">
                <Music v-if="room.music_enabled" class="h-3 w-3 text-green-400" />
                <Mic v-if="room.voice_chat_enabled" class="h-3 w-3 text-blue-400" />
                <Video v-if="room.video_chat_enabled" class="h-3 w-3 text-purple-400" />
              </div>
              <div class="text-cosmic-400">Features</div>
            </div>
          </div>

          <!-- Tags -->
          <div v-if="room.tags && room.tags.length > 0" class="flex flex-wrap gap-1">
            <span 
              v-for="tag in room.tags.slice(0, 3)" 
              :key="tag" 
              class="px-2 py-1 bg-cosmic-500/20 text-cosmic-300 rounded text-xs"
            >
              {{ tag }}
            </span>
            <span v-if="room.tags.length > 3" class="px-2 py-1 bg-cosmic-500/20 text-cosmic-300 rounded text-xs">
              +{{ room.tags.length - 3 }}
            </span>
          </div>

          <!-- Owner -->
          <div class="flex items-center justify-between text-xs">
            <div class="flex items-center space-x-1 text-cosmic-400">
              <Crown class="h-3 w-3" />
              <span>{{ room.owner?.username ?? 'Unknown User' }}</span>
            </div>
            <span class="text-cosmic-400">
              {{ formatDate(room.created_at) }}
            </span>
          </div>
        </div>
        
        <div class="flex space-x-3 mt-4">
          <button
            @click="viewRoomDetails(room)"
            class="flex-1 cosmic-button flex items-center justify-center space-x-2"
          >
            <Eye class="h-4 w-4" />
            <span>View</span>
          </button>
          
          <button
            @click="joinRoom(room)"
            class="flex-1 nebula-button flex items-center justify-center space-x-2"
            :disabled="room.current_participants >= room.max_participants"
            :class="{'opacity-50 cursor-not-allowed': room.current_participants >= room.max_participants}"
          >
            <UserPlus class="h-4 w-4" />
            <span>
              {{ room.current_participants >= room.max_participants ? 'Full' : 'Join' }}
            </span>
          </button>
        </div>
      </div>
    </div>

    <!-- No Rooms Available -->
    <div 
      v-if="!roomDetail && !loading && !error && rooms.length === 0 && authStore.isAuthenticated" 
      class="glass-card p-8 text-center"
    >
      <Timer class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h3 class="text-xl font-bold text-white mb-2">No rooms available</h3>
      <p class="text-cosmic-300 mb-6">Create the first room to get started!</p>
      <button
        @click="showCreateForm = true"
        class="cosmic-button"
      >
        Create First Room
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, reactive, watch } from 'vue'
import { useToast } from 'vue-toastification'
import { useRouter, useRoute } from 'vue-router'
import { 
  Users, 
  Plus, 
  Video, 
  Mic,
  MicOff,
  Lock, 
  Globe,
  MessageSquare,
  Clock,
  Crown,
  UserPlus,
  Play,
  Pause,
  Timer,
  Music,
  Brain,
  Zap,
  ChevronLeft,
  Eye,
  AlertTriangle,
  Send,
  Volume1,
  Volume2,
  SkipBack,
  SkipForward
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { pomodoroApi } from '@/lib/api'

// Focus modes configuration
const FOCUS_MODES = {
  deep_focus: {
    name: 'Deep Focus',
    description: 'Maximum concentration mode with strict rules and minimal distractions'
  },
  collaborative: {
    name: 'Collaborative Study',
    description: 'Balanced mode for group study with controlled social interaction'
  },
  flexible: {
    name: 'Flexible Flow',
    description: 'Relaxed mode with minimal restrictions for casual study sessions'
  }
}

// Composables
const toast = useToast()
const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()

// State
const rooms = ref<any[]>([])
const roomDetail = ref<any>(null)
const loading = ref(true)
const error = ref<string | null>(null)
const showCreateForm = ref(false)
const messages = ref<{ user: string, text: string, time: string }[]>([])
const newMessage = ref('')

// Timer state
const isTimerActive = ref(false)
const isBreakTime = ref(false)
const timerRemaining = ref(0)
const timerDuration = ref(0)
const timerInterval = ref<number | null>(null)

const newRoom = reactive({
  name: '',
  description: '',
  type: 'public' as 'public' | 'private',
  tags: [] as string[],
  focus_mode_enforced: 'flexible' as 'deep_focus' | 'collaborative' | 'flexible',
  max_participants: 10,
  music_enabled: true,
  voice_chat_enabled: false,
  video_chat_enabled: false,
  ai_moderation_enabled: true
})

const availableTags = [
  'Study', 'Work', 'Productivity', 'Focus', 'Math', 'Science', 'Languages', 
  'Programming', 'Art', 'Music', 'Writing', 'Research', 'Exam Prep', 
  'Group Study', 'Silent', 'Collaborative', 'Deep Focus'
]

// Computed properties
const isRoomOwner = computed(() => {
  return roomDetail.value?.owner_id === authStore.user?.id
})

const isParticipant = computed(() => {
  if (!roomDetail.value?.participants || !authStore.user?.id) return false
  return roomDetail.value.participants.some((p: any) => p.user_id === authStore.user?.id)
})

const timerProgress = computed(() => {
  if (timerDuration.value <= 0) return 0
  return ((timerDuration.value - timerRemaining.value) / timerDuration.value) * 100
})

// Watch for route changes to load room details
watch(() => route.params.roomId, (newRoomId) => {
  if (newRoomId) {
    fetchRoomDetail(newRoomId as string)
  } else {
    roomDetail.value = null
  }
}, { immediate: true })

// Methods
const fetchRooms = async () => {
  if (!authStore.isAuthenticated) return
  
  loading.value = true
  error.value = null
  
  try {
    const response = await pomodoroApi.getRooms()
    
    if (response.success) {
      rooms.value = response.rooms || []
    } else {
      throw new Error(response.error || 'Failed to fetch rooms')
    }
  } catch (err: any) {
    error.value = err.message || 'Failed to load rooms'
    console.error('Error fetching rooms:', err)
  } finally {
    loading.value = false
  }
}

const fetchRoomDetail = async (roomId: string) => {
  if (!authStore.isAuthenticated) return
  
  loading.value = true
  error.value = null
  
  try {
    const response = await pomodoroApi.getRoom(roomId)
    
    if (response.success) {
      roomDetail.value = response.room
      
      // If we're a participant and the room is active, set up the timer
      if (isParticipant.value && roomDetail.value.is_active) {
        setupTimer()
      }
    } else {
      throw new Error(response.error || 'Failed to fetch room details')
    }
  } catch (err: any) {
    error.value = err.message || 'Failed to load room details'
    console.error('Error fetching room detail:', err)
    
    // Redirect back to rooms list on error
    router.push('/pomodoro-rooms')
  } finally {
    loading.value = false
  }
}

const createRoom = async () => {
  if (!newRoom.name.trim()) {
    toast.error('Please enter a room name')
    return
  }
  
  if (!authStore.isAuthenticated) {
    toast.error('You must be signed in to create a room')
    return
  }
  
  loading.value = true
  
  try {
    const { data, error: createError } = await supabase
      .from('pomodoro_rooms')
      .insert([{
        name: newRoom.name,
        description: newRoom.description,
        type: newRoom.type,
        tags: newRoom.tags,
        focus_mode_enforced: newRoom.focus_mode_enforced,
        max_participants: newRoom.max_participants,
        music_enabled: newRoom.music_enabled,
        voice_chat_enabled: newRoom.voice_chat_enabled,
        video_chat_enabled: newRoom.video_chat_enabled,
        ai_moderation_enabled: newRoom.ai_moderation_enabled,
        owner_id: authStore.user?.id
      }])
      .select()
      .single()
      
    if (createError) throw createError
    
    // Join the room as owner
    await supabase
      .from('room_participants')
      .insert([{
        room_id: data.id,
        user_id: authStore.user?.id,
        is_admin: true
      }])
    
    // Award XP for creating a room
    if (authStore.addExperience) {
      authStore.addExperience(50, "Created Pomodoro Room")
    }
    
    toast.success('Room created successfully!')
    showCreateForm.value = false
    
    // Navigate to the new room
    router.push(`/pomodoro-rooms/${data.id}`)
  } catch (err: any) {
    toast.error(err.message || 'Failed to create room')
  } finally {
    loading.value = false
  }
}

const joinRoom = async (room: any) => {
  if (!authStore.isAuthenticated) {
    toast.error('You must be signed in to join a room')
    return
  }
  
  try {
    const response = await pomodoroApi.joinRoom(room.id)
    
    if (response.success) {
      toast.success(response.message || 'Joined room successfully!')
      
      // Navigate to the room detail
      router.push(`/pomodoro-rooms/${room.id}`)
    } else {
      toast.error(response.error || 'Failed to join room')
    }
  } catch (err: any) {
    toast.error(err.message || 'Failed to join room')
  }
}

const viewRoomDetails = (room: any) => {
  router.push(`/pomodoro-rooms/${room.id}`)
}

const leaveRoom = async () => {
  if (!roomDetail.value || !authStore.user?.id) return
  
  try {
    // Find participant record
    const participant = roomDetail.value.participants.find((p: any) => p.user_id === authStore.user?.id)
    
    if (!participant) {
      toast.error('You are not a participant in this room')
      return
    }
    
    // Delete participant record
    const { error } = await supabase
      .from('room_participants')
      .delete()
      .eq('id', participant.id)
    
    if (error) throw error
    
    toast.success('Left room successfully')
    router.push('/pomodoro-rooms')
  } catch (err: any) {
    toast.error(err.message || 'Failed to leave room')
  }
}

const toggleRoomActive = async () => {
  if (!roomDetail.value || !isRoomOwner.value) return
  
  try {
    const { error } = await supabase
      .from('pomodoro_rooms')
      .update({ is_active: !roomDetail.value.is_active })
      .eq('id', roomDetail.value.id)
    
    if (error) throw error
    
    // Update local state
    roomDetail.value.is_active = !roomDetail.value.is_active
    
    // Set up timer if activated
    if (roomDetail.value.is_active) {
      setupTimer()
      toast.success('Room session started!')
    } else {
      stopTimer()
      toast.info('Room session stopped')
    }
  } catch (err: any) {
    toast.error(err.message || 'Failed to update room status')
  }
}

const setupTimer = () => {
  // Set default timer values based on focus mode
  const focusMode = roomDetail.value?.focus_mode_enforced || 'flexible'
  
  // Default timer settings based on focus mode
  let workDuration = 25
  let breakDuration = 5
  
  if (focusMode === 'deep_focus') {
    workDuration = 50
    breakDuration = 10
  }
  
  // Use timer settings from room if available
  if (roomDetail.value?.timer_settings) {
    const settings = roomDetail.value.timer_settings
    workDuration = settings.work_duration || workDuration
    breakDuration = settings.short_break || breakDuration
  }
  
  // Initialize timer with work duration
  timerDuration.value = workDuration * 60
  timerRemaining.value = workDuration * 60
  isBreakTime.value = false
}

const startTimer = () => {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
  }
  
  isTimerActive.value = true
  
  timerInterval.value = window.setInterval(() => {
    if (timerRemaining.value <= 0) {
      // Timer finished
      clearInterval(timerInterval.value as number)
      handleTimerComplete()
    } else {
      timerRemaining.value--
    }
  }, 1000)
}

const pauseTimer = () => {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
    timerInterval.value = null
  }
  
  isTimerActive.value = false
}

const stopTimer = () => {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
    timerInterval.value = null
  }
  
  isTimerActive.value = false
  timerRemaining.value = 0
}

const handleTimerComplete = () => {
  // Toggle between work and break
  isBreakTime.value = !isBreakTime.value
  
  // Set new timer duration
  if (isBreakTime.value) {
    const breakDuration = roomDetail.value?.timer_settings?.short_break || 5
    timerDuration.value = breakDuration * 60
    timerRemaining.value = breakDuration * 60
    toast.info(`Break time! (${breakDuration} minutes)`)
  } else {
    const workDuration = roomDetail.value?.timer_settings?.work_duration || 25
    timerDuration.value = workDuration * 60
    timerRemaining.value = workDuration * 60
    toast.success(`Focus time! (${workDuration} minutes)`)
    
    // Award XP for completing a work session
    if (authStore.addExperience) {
      authStore.addExperience(25, "Completed Pomodoro Session")
    }
  }
  
  // Restart timer
  startTimer()
}

const sendMessage = () => {
  if (!newMessage.trim()) return
  
  // Add message to local state
  messages.value.push({
    user: authStore.user?.user_metadata?.username || 'You',
    text: newMessage,
    time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  })
  
  // Clear input
  newMessage.value = ''
  
  // In a real app, this would send the message to the server
  // For now, we'll just add a bot response
  setTimeout(() => {
    messages.value.push({
      user: 'System',
      text: 'This is a demo chat. In the real app, you would be chatting with other participants.',
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    })
  }, 1000)
}

const formatTime = (seconds: number) => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

const formatDate = (dateString: string): string => {
  return new Date(dateString).toLocaleDateString()
}

const getFocusModeName = (focusMode: string): string => {
  return FOCUS_MODES[focusMode as keyof typeof FOCUS_MODES]?.name || 'Flexible Flow'
}

const addRoomTag = (event: Event) => {
  const selectElement = event.target as HTMLSelectElement
  const tag = selectElement.value
  
  if (tag && !newRoom.tags.includes(tag)) {
    newRoom.tags.push(tag)
  }
  
  selectElement.value = ''
}

const removeRoomTag = (tag: string) => {
  newRoom.tags = newRoom.tags.filter(t => t !== tag)
}

const refreshData = () => {
  const roomId = route.params.roomId
  if (roomId) {
    fetchRoomDetail(roomId as string)
  } else {
    fetchRooms()
  }
}

const goBackToRooms = () => {
  router.push('/pomodoro-rooms')
}

// Lifecycle hooks
onMounted(async () => {
  if (authStore.isAuthenticated) {
    const roomId = route.params.roomId
    if (roomId) {
      await fetchRoomDetail(roomId as string)
    } else {
      await fetchRooms()
    }
  }
})

// Cleanup on unmount
onUnmounted(() => {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
  }
})
</script>