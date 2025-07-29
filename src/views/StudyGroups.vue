<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-glow mb-2">Study Groups</h1>
        <p class="text-cosmic-300">Connect with fellow cosmic learners across the universe</p>
      </div>
      
      <button
        @click="showCreateForm = true"
        class="cosmic-button flex items-center space-x-2"
      >
        <Plus class="h-5 w-5" />
        <span>Create Group</span>
      </button>
    </div>

    <div v-if="!authStore.isAuthenticated" class="text-center py-20">
      <Users class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h2 class="text-2xl font-bold text-white mb-4">Sign in to join study groups</h2>
      <p class="text-cosmic-300">Create an account to collaborate with fellow cosmic learners</p>
    </div>

    <div v-else-if="!activeGroup">
      <!-- Create Group Form -->
      <Transition>
        <div v-if="showCreateForm" class="glass-card p-6">
          <h3 class="text-xl font-bold text-white mb-4">Create New Study Group</h3>
          
          <div class="space-y-4">
            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Group Name</label>
              <input
                type="text"
                v-model="newGroup.name"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                placeholder="Enter a name for your group..."
              />
            </div>
            
            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Description</label>
              <textarea
                v-model="newGroup.description"
                rows="3"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
                placeholder="Describe the purpose and focus of your group..."
              ></textarea>
            </div>
            
            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Subject</label>
              <select
                v-model="newGroup.subject"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
              >
                <option value="">Select a subject...</option>
                <option value="Physics">Physics</option>
                <option value="History">History</option>
                <option value="Mathematics">Mathematics</option>
                <option value="Chemistry">Chemistry</option>
                <option value="Biology">Biology</option>
                <option value="Literature">Literature</option>
              </select>
            </div>
            
            <div>
              <label class="block text-cosmic-200 font-medium mb-2">Maximum Members</label>
              <input
                type="number"
                v-model="newGroup.maxMembers"
                min="2"
                max="20"
                class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
              />
            </div>
            
            <div class="flex gap-3">
              <button
                @click="createGroup"
                class="cosmic-button flex-1"
              >
                Create Group
              </button>
              <button
                @click="showCreateForm = false"
                class="nebula-button flex-1"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </Transition>

      <!-- Study Groups Grid -->
      <div v-if="studyGroups.length === 0" class="text-center py-20">
        <Users class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
        <h3 class="text-xl font-bold text-white mb-2">No study groups yet</h3>
        <p class="text-cosmic-300 mb-6">Create the first study group and start collaborating!</p>
        <button
          @click="showCreateForm = true"
          class="cosmic-button"
        >
          Create First Group
        </button>
      </div>
      
      <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="group in studyGroups"
          :key="group.id"
          class="glass-card p-6 hover:border-cosmic-400/50 transition-all duration-300 group"
        >
          <div class="flex items-start justify-between mb-4">
            <div>
              <h3 class="font-bold text-white group-hover:text-glow transition-all mb-2">{{ group.name }}</h3>
              <p class="text-cosmic-300 text-sm mb-3 line-clamp-2">{{ group.description }}</p>
            </div>
            
            <div v-if="group.isActive" class="flex items-center space-x-1 text-green-400 text-xs">
              <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span>Live</span>
            </div>
          </div>

          <div class="space-y-3">
            <div class="flex items-center justify-between text-sm">
              <span class="text-cosmic-400">Members</span>
              <span class="text-white">{{ group.members }} / {{ group.maxMembers }}</span>
            </div>
            
            <div class="flex items-center justify-between text-sm">
              <span class="text-cosmic-400">Owner</span>
              <div class="flex items-center space-x-1">
                <Crown class="h-3 w-3 text-star-400" />
                <span class="text-white">{{ group.owner }}</span>
              </div>
            </div>
            
            <div 
              class="px-3 py-1 rounded-full text-xs font-medium bg-gradient-to-r text-white w-fit"
              :class="getSubjectColor(group.subject)"
            >
              {{ group.subject }}
            </div>
            
            <div v-if="group.currentSession" class="bg-white/5 rounded-lg p-3">
              <div class="flex items-center justify-between text-sm">
                <span class="text-cosmic-300">
                  {{ group.currentSession.isBreak ? 'Break' : 'Focus' }} Session
                </span>
                <span class="text-white font-medium">
                  {{ formatTime(group.currentSession.timeRemaining || 0) }}
                </span>
              </div>
            </div>
          </div>
          
          <button
            @click="joinGroup(group)"
            class="w-full mt-4 cosmic-button flex items-center justify-center space-x-2"
          >
            <UserPlus class="h-4 w-4" />
            <span>Join Group</span>
          </button>
        </div>
      </div>
    </div>

    <div v-else class="max-w-6xl mx-auto space-y-6">
      <!-- Group Header -->
      <div class="glass-card p-6">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h1 class="text-2xl font-bold text-white text-glow">{{ activeGroup.name }}</h1>
            <p class="text-cosmic-300">{{ activeGroup.description }}</p>
          </div>
          <button
            @click="leaveGroup"
            class="nebula-button"
          >
            Leave Group
          </button>
        </div>

        <!-- Session Info -->
        <div v-if="activeGroup.currentSession" class="bg-white/5 rounded-lg p-4 mb-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <Clock class="h-5 w-5 text-cosmic-400" />
              <span class="text-white font-medium">
                {{ activeGroup.currentSession.isBreak ? 'Break Time' : 'Focus Session' }}
              </span>
              <span class="text-2xl font-bold text-cosmic-300">
                {{ formatTime(activeGroup.currentSession.timeRemaining || 0) }}
              </span>
            </div>
            <div class="flex items-center space-x-2">
              <Pause class="h-4 w-4 text-cosmic-400" />
              <span class="text-cosmic-300">Pomodoro Active</span>
            </div>
          </div>
        </div>

        <!-- Member Info -->
        <div class="flex items-center space-x-6 text-sm text-cosmic-300">
          <span>{{ activeGroup.members }} / {{ activeGroup.maxMembers }} members</span>
          <span 
            class="px-2 py-1 rounded-full text-xs font-medium bg-gradient-to-r text-white"
            :class="getSubjectColor(activeGroup.subject)"
          >
            {{ activeGroup.subject }}
          </span>
          <div class="flex items-center space-x-1">
            <Crown class="h-4 w-4" />
            <span>{{ activeGroup.owner }}</span>
          </div>
        </div>
      </div>

      <div class="grid lg:grid-cols-3 gap-6">
        <!-- Video Call Area -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Main Video -->
          <div class="glass-card p-6 h-96 flex items-center justify-center bg-gradient-to-br from-cosmic-900/50 to-nebula-900/50">
            <div class="text-center">
              <div class="w-24 h-24 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full flex items-center justify-center mx-auto mb-4 text-3xl">
                {{ isVideoOn ? '📹' : '🎥' }}
              </div>
              <h3 class="text-xl font-bold text-white mb-2">
                {{ authStore.user?.user_metadata?.username || 'You' }}
              </h3>
              <p class="text-cosmic-300">
                {{ isVideoOn ? 'Camera On' : 'Camera Off' }}
              </p>
            </div>
          </div>

          <!-- Video Controls -->
          <div class="flex justify-center space-x-4">
            <button
              @click="isAudioOn = !isAudioOn"
              :class="[
                'p-4 rounded-full transition-all',
                isAudioOn 
                  ? 'bg-green-500 hover:bg-green-600 text-white' 
                  : 'bg-red-500 hover:bg-red-600 text-white'
              ]"
            >
              <component :is="isAudioOn ? Mic : MicOff" class="h-6 w-6" />
            </button>
            
            <button
              @click="isVideoOn = !isVideoOn"
              :class="[
                'p-4 rounded-full transition-all',
                isVideoOn 
                  ? 'bg-green-500 hover:bg-green-600 text-white' 
                  : 'bg-red-500 hover:bg-red-600 text-white'
              ]"
            >
              <component :is="isVideoOn ? Video : VideoOff" class="h-6 w-6" />
            </button>
            
            <button class="cosmic-button p-4">
              <Settings class="h-6 w-6" />
            </button>
          </div>

          <!-- Participant Grid -->
          <div class="grid grid-cols-3 gap-4">
            <div 
              v-for="index in Math.min(6, activeGroup.members - 1)"
              :key="index"
              class="glass-card p-4 aspect-video flex items-center justify-center"
            >
              <div class="text-center">
                <div class="w-12 h-12 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full flex items-center justify-center mx-auto mb-2 text-lg">
                  🧑‍🚀
                </div>
                <div class="text-sm text-cosmic-300">Member {{ index }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Chat & Tools -->
        <div class="space-y-6">
          <!-- Chat -->
          <div class="glass-card p-6 h-96 flex flex-col">
            <h3 class="text-lg font-bold text-white mb-4 flex items-center">
              <MessageCircle class="h-5 w-5 mr-2" />
              Group Chat
            </h3>
            
            <div class="flex-1 space-y-4 overflow-y-auto">
              <div class="text-sm">
                <div class="font-medium text-cosmic-300">CosmicExplorer</div>
                <div class="text-white">Welcome everyone! Let's start our study session 🚀</div>
              </div>
              <div class="text-sm">
                <div class="font-medium text-cosmic-300">StarChaser</div>
                <div class="text-white">Ready to dive into stellar physics!</div>
              </div>
              <div class="text-sm">
                <div class="font-medium text-cosmic-300">You</div>
                <div class="text-white bg-cosmic-500/20 p-2 rounded">Just joined the session!</div>
              </div>
            </div>
            
            <div class="mt-4">
              <input
                type="text"
                placeholder="Type a message..."
                class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
              />
            </div>
          </div>

          <!-- Study Tools -->
          <div class="glass-card p-6">
            <h3 class="text-lg font-bold text-white mb-4">Study Tools</h3>
            
            <div class="space-y-3">
              <button class="w-full cosmic-button text-left">
                📝 Shared Whiteboard
              </button>
              <button class="w-full nebula-button text-left">
                🃏 Group Flashcards
              </button>
              <button class="w-full star-button text-left">
                📊 Screen Share
              </button>
              <button class="w-full bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg transition-colors text-left">
                ⏰ Start Pomodoro Timer
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, h } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Users, 
  Plus, 
  Video, 
  Mic, 
  MicOff, 
  VideoOff,
  MessageCircle,
  Clock,
  Crown,
  UserPlus,
  Settings
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

interface StudyGroup {
  id: string
  name: string
  description: string
  members: number
  maxMembers: number
  isActive: boolean
  subject: string
  owner: string
  currentSession?: {
    type: 'pomodoro' | 'freeform'
    timeRemaining?: number
    isBreak?: boolean
  }
}

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const studyGroups = ref<StudyGroup[]>([
  {
    id: '1',
    name: 'Stellar Physics Study Circle',
    description: 'Exploring the mysteries of stars and cosmic phenomena',
    members: 8,
    maxMembers: 12,
    isActive: true,
    subject: 'Physics',
    owner: 'CosmicExplorer',
    currentSession: {
      type: 'pomodoro',
      timeRemaining: 1340,
      isBreak: false
    }
  },
  {
    id: '2',
    name: 'Galactic History Collective',
    description: 'Diving deep into the history of space exploration',
    members: 5,
    maxMembers: 10,
    isActive: false,
    subject: 'History',
    owner: 'StarChaser'
  },
  {
    id: '3',
    name: 'Nebula Mathematics Academy',
    description: 'Conquering calculus and beyond together',
    members: 12,
    maxMembers: 15,
    isActive: true,
    subject: 'Mathematics',
    owner: 'QuantumCalculator'
  },
  {
    id: '4',
    name: 'Constellation Chemistry Lab',
    description: 'Mixing knowledge like compounds in space',
    members: 6,
    maxMembers: 8,
    isActive: false,
    subject: 'Chemistry',
    owner: 'ElementMaster'
  }
])

const activeGroup = ref<StudyGroup | null>(null)
const showCreateForm = ref(false)
const isVideoOn = ref(false)
const isAudioOn = ref(false)

const newGroup = reactive({
  name: '',
  description: '',
  subject: '',
  maxMembers: 10
})

// Methods
const formatTime = (seconds: number) => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

const getSubjectColor = (subject: string) => {
  const colors: { [key: string]: string } = {
    'Physics': 'from-cosmic-500 to-cosmic-600',
    'History': 'from-nebula-500 to-nebula-600',
    'Mathematics': 'from-star-500 to-star-600',
    'Chemistry': 'from-green-500 to-green-600',
    'Biology': 'from-blue-500 to-blue-600',
    'Literature': 'from-purple-500 to-purple-600'
  }
  return colors[subject] || 'from-cosmic-500 to-cosmic-600'
}

const joinGroup = (group: StudyGroup) => {
  activeGroup.value = group
  toast.success(`Joined ${group.name}`)
}

const leaveGroup = () => {
  activeGroup.value = null
  isVideoOn.value = false
  isAudioOn.value = false
  toast.success('Left study group')
}

const createGroup = () => {
  if (!newGroup.name.trim()) {
    toast.error('Please enter a group name')
    return
  }

  const group: StudyGroup = {
    id: Date.now().toString(),
    name: newGroup.name,
    description: newGroup.description || 'No description provided',
    members: 1,
    maxMembers: newGroup.maxMembers,
    isActive: false,
    subject: newGroup.subject || 'General',
    owner: authStore.user?.user_metadata?.username || 'You'
  }

  studyGroups.value = [group, ...studyGroups.value]
  newGroup.name = ''
  newGroup.description = ''
  newGroup.subject = ''
  newGroup.maxMembers = 10
  showCreateForm.value = false
  
  toast.success('Study group created successfully!')
}
</script>