<template>
  <div v-if="!musicEnabled" class="glass-card p-6 text-center">
    <Music class="h-12 w-12 text-cosmic-400 mx-auto mb-4 opacity-50" />
    <p class="text-cosmic-400">Music is disabled for this room</p>
  </div>

  <div v-else class="glass-card p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-bold text-white flex items-center">
        <Music class="h-5 w-5 mr-2" />
        Room Music
      </h3>
      
      <button
        v-if="canControlMusic"
        @click="toggleTrackSelector"
        class="cosmic-button text-sm"
      >
        Browse Tracks
      </button>
    </div>

    <!-- Current Track -->
    <div v-if="currentTrack" class="space-y-4">
      <!-- Track Info -->
      <div class="text-center">
        <div class="text-white font-medium">{{ currentTrack.track_name }}</div>
        <div class="text-sm text-cosmic-300 capitalize">
          {{ currentTrack.track_type.replace('_', ' ') }}
        </div>
      </div>

      <!-- Audio Element -->
      <audio
        ref="audioRef"
        :src="currentTrack.track_url"
        @timeupdate="handleTimeUpdate"
        @loadedmetadata="handleMetadataLoaded"
        @ended="handleTrackEnded"
        loop
      ></audio>

      <!-- Progress Bar -->
      <div class="space-y-2">
        <div class="w-full bg-white/10 rounded-full h-1">
          <div 
            class="bg-gradient-to-r from-cosmic-500 to-nebula-500 h-1 rounded-full transition-all"
            :style="{ width: duration ? `${(currentTime / duration) * 100}%` : '0%' }"
          />
        </div>
        <div class="flex justify-between text-xs text-cosmic-400">
          <span>{{ formatTime(currentTime) }}</span>
          <span>{{ formatTime(duration) }}</span>
        </div>
      </div>

      <!-- Controls -->
      <div class="flex items-center justify-center space-x-4">
        <button
          @click="togglePlayPause"
          class="p-3 cosmic-button rounded-full"
          :disabled="!currentTrack.track_url"
        >
          <component :is="isPlaying ? Pause : Play" class="h-5 w-5" />
        </button>

        <button
          v-if="canControlMusic"
          @click="stopMusic"
          class="p-2 text-cosmic-300 hover:text-white transition-colors"
        >
          Stop
        </button>
      </div>

      <!-- Volume Control -->
      <div class="flex items-center space-x-3">
        <VolumeX class="h-4 w-4 text-cosmic-400" />
        <input
          type="range"
          min="0"
          max="1"
          step="0.1"
          v-model="volume"
          @change="updateVolume"
          class="flex-1"
          :disabled="!canControlMusic"
        />
        <Volume2 class="h-4 w-4 text-cosmic-400" />
        <span class="text-sm text-cosmic-300 w-8">{{ Math.round(volume * 100) }}</span>
      </div>
    </div>

    <div v-else class="text-center py-8">
      <Music class="h-12 w-12 text-cosmic-400 mx-auto mb-4 opacity-50" />
      <p class="text-cosmic-400 mb-4">No music playing</p>
      <button
        v-if="canControlMusic"
        @click="toggleTrackSelector"
        class="cosmic-button"
      >
        Start Music
      </button>
    </div>

    <!-- Track Selector -->
    <Transition>
      <div v-if="showTrackSelector && canControlMusic" class="mt-6 border-t border-white/10 pt-6">
        <h4 class="text-white font-medium mb-4">Select Track</h4>
        
        <!-- Category Tabs -->
        <div class="flex space-x-2 mb-4 overflow-x-auto">
          <button
            v-for="category in Object.keys(MUSIC_TRACKS)"
            :key="category"
            @click="selectedCategory = category"
            :class="[
              'flex items-center space-x-2 px-3 py-2 rounded-lg text-sm whitespace-nowrap transition-all',
              selectedCategory === category
                ? 'bg-cosmic-500 text-white'
                : 'bg-white/5 text-cosmic-300 hover:bg-white/10'
            ]"
          >
            <component :is="getCategoryIcon(category)" class="h-4 w-4" />
            <span class="capitalize">{{ category.replace('_', ' ') }}</span>
          </button>
        </div>

        <!-- Track List -->
        <div class="space-y-2 max-h-48 overflow-y-auto">
          <div v-if="loading" class="text-center py-4">
            <Loader class="h-6 w-6 animate-spin text-cosmic-400 mx-auto" />
          </div>
          
          <button
            v-for="track in MUSIC_TRACKS[selectedCategory]"
            :key="track.name"
            @click="playTrack(selectedCategory, track.name)"
            class="w-full text-left p-3 bg-white/5 hover:bg-white/10 rounded-lg transition-colors"
          >
            <div class="flex items-center justify-between">
              <span class="text-white">{{ track.name }}</span>
              <span class="text-xs text-cosmic-400">
                {{ formatTime(track.duration) }}
              </span>
            </div>
          </button>
        </div>
      </div>
    </Transition>

    <div v-if="!canControlMusic && currentTrack" class="mt-4 text-xs text-cosmic-400 text-center">
      Only room admins can control music
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Music, 
  Play, 
  Pause, 
  Volume2, 
  VolumeX, 
  Loader,
  FileAudio,
  Wind,
  Waves,
  Headphones
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

// Props
defineProps<{
  roomId: string
  musicEnabled: boolean
  userRoles: any[]
  isOwner: boolean
}>()

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const currentTrack = ref<any>(null)
const isPlaying = ref(false)
const volume = ref(0.5)
const currentTime = ref(0)
const duration = ref(0)
const selectedCategory = ref<string>('lofi')
const showTrackSelector = ref(false)
const loading = ref(false)
const audioRef = ref<HTMLAudioElement | null>(null)

// Sample music tracks (in production, these would be actual audio files)
const MUSIC_TRACKS = {
  lofi: [
    { name: 'Cosmic Study', url: '/audio/cosmic-study.mp3', duration: 180 },
    { name: 'Stellar Focus', url: '/audio/stellar-focus.mp3', duration: 240 },
    { name: 'Nebula Dreams', url: '/audio/nebula-dreams.mp3', duration: 200 },
    { name: 'Galaxy Drift', url: '/audio/galaxy-drift.mp3', duration: 220 }
  ],
  nature: [
    { name: 'Forest Rain', url: '/audio/forest-rain.mp3', duration: 300 },
    { name: 'Ocean Waves', url: '/audio/ocean-waves.mp3', duration: 600 },
    { name: 'Mountain Wind', url: '/audio/mountain-wind.mp3', duration: 450 },
    { name: 'Thunderstorm', url: '/audio/thunderstorm.mp3', duration: 400 }
  ],
  white_noise: [
    { name: 'Pure White Noise', url: '/audio/white-noise.mp3', duration: 3600 },
    { name: 'Pink Noise', url: '/audio/pink-noise.mp3', duration: 3600 },
    { name: 'Brown Noise', url: '/audio/brown-noise.mp3', duration: 3600 }
  ],
  binaural: [
    { name: 'Alpha Waves (10Hz)', url: '/audio/alpha-waves.mp3', duration: 1800 },
    { name: 'Beta Waves (20Hz)', url: '/audio/beta-waves.mp3', duration: 1800 },
    { name: 'Theta Waves (6Hz)', url: '/audio/theta-waves.mp3', duration: 1800 }
  ],
  ambient: [
    { name: 'Space Ambient', url: '/audio/space-ambient.mp3', duration: 900 },
    { name: 'Meditation Bells', url: '/audio/meditation-bells.mp3', duration: 600 },
    { name: 'Soft Pad', url: '/audio/soft-pad.mp3', duration: 720 }
  ]
}

// Computed
const canControlMusic = computed(() => {
  return props.isOwner || props.userRoles.some(role => 
    role.permissions?.can_manage_music && 
    authStore.user?.id === role.user_id
  )
})

// Watch for audio ref and volume changes
watch(audioRef, (newValue) => {
  if (newValue) {
    newValue.volume = volume.value
  }
})

watch(volume, (newValue) => {
  if (audioRef.value) {
    audioRef.value.volume = newValue
  }
})

// Lifecycle
onMounted(() => {
  fetchCurrentTrack()
  setupRealtimeSubscription()
})

// Methods
const fetchCurrentTrack = async () => {
  try {
    const { data, error } = await supabase
      .from('room_music')
      .select('*')
      .eq('room_id', props.roomId)
      .eq('is_active', true)
      .limit(1)
      .maybeSingle()

    if (error) {
      console.error('Failed to fetch current track:', error)
      currentTrack.value = null
      return
    }
    
    currentTrack.value = data
    
    if (data) {
      volume.value = data.volume || 0.5
      
      // Wait for next tick to ensure audioRef is mounted
      nextTick(() => {
        if (audioRef.value && data.track_url) {
          audioRef.value.volume = volume.value
          audioRef.value.play().catch(() => {
            console.log('Autoplay prevented - waiting for user interaction')
          })
          isPlaying.value = true
        }
      })
    }
  } catch (error) {
    console.error('Failed to fetch current track:', error)
    currentTrack.value = null
  }
}

const setupRealtimeSubscription = () => {
  const subscription = supabase
    .channel(`room_music_${props.roomId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'room_music',
        filter: `room_id=eq.${props.roomId}`
      },
      () => {
        fetchCurrentTrack()
      }
    )
    .subscribe()

  // Clean up subscription on component unmount
  onUnmounted(() => {
    subscription.unsubscribe()
  })
}

const playTrack = async (trackType: string, trackName: string) => {
  if (!canControlMusic.value) {
    toast.error('You need music management permissions')
    return
  }

  loading.value = true
  
  try {
    // Deactivate current track
    if (currentTrack.value) {
      await supabase
        .from('room_music')
        .update({ is_active: false })
        .eq('id', currentTrack.value.id)
    }

    // Add new track
    const trackInfo = MUSIC_TRACKS[trackType].find(t => t.name === trackName)
    
    const { data, error } = await supabase
      .from('room_music')
      .insert([{
        room_id: props.roomId,
        track_type: trackType,
        track_name: trackName,
        track_url: trackInfo?.url,
        volume: volume.value,
        is_active: true,
        set_by: authStore.user?.id
      }])
      .select()
      .single()

    if (error) throw error

    currentTrack.value = data
    isPlaying.value = true
    showTrackSelector.value = false
    toast.success(`Now playing: ${trackName}`)
    
    // Play the audio
    nextTick(() => {
      if (audioRef.value && data.track_url) {
        audioRef.value.volume = volume.value
        audioRef.value.play().catch(() => {
          toast.error('Unable to play audio - try clicking play')
        })
      }
    })
  } catch (error) {
    console.error('Failed to play track:', error)
    toast.error('Failed to play track')
  } finally {
    loading.value = false
  }
}

const togglePlayPause = async () => {
  if (!currentTrack.value) return

  if (isPlaying.value) {
    audioRef.value?.pause()
    isPlaying.value = false
  } else {
    try {
      await audioRef.value?.play()
      isPlaying.value = true
    } catch (err) {
      console.error('Failed to play audio:', err)
      toast.error('Failed to play audio')
    }
  }
}

const updateVolume = async () => {
  // Update audio player volume
  if (audioRef.value) {
    audioRef.value.volume = volume.value
  }
  
  // Update volume in database if user has permission
  if (currentTrack.value && canControlMusic.value) {
    try {
      await supabase
        .from('room_music')
        .update({ volume: volume.value })
        .eq('id', currentTrack.value.id)
    } catch (error) {
      console.error('Failed to update volume:', error)
    }
  }
}

const stopMusic = async () => {
  if (!currentTrack.value || !canControlMusic.value) return

  try {
    await supabase
      .from('room_music')
      .update({ is_active: false })
      .eq('id', currentTrack.value.id)

    currentTrack.value = null
    isPlaying.value = false
    
    if (audioRef.value) {
      audioRef.value.pause()
    }
  } catch (error) {
    console.error('Failed to stop music:', error)
    toast.error('Failed to stop music')
  }
}

const formatTime = (seconds: number) => {
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

const getCategoryIcon = (category: string) => {
  switch (category) {
    case 'lofi': return Music
    case 'nature': return Wind
    case 'white_noise': return Waves
    case 'binaural': return Headphones
    case 'ambient': return Music
    default: return Music
  }
}

const toggleTrackSelector = () => {
  showTrackSelector.value = !showTrackSelector.value
}

const handleTimeUpdate = (event: Event) => {
  const audio = event.target as HTMLAudioElement
  currentTime.value = audio.currentTime
}

const handleMetadataLoaded = (event: Event) => {
  const audio = event.target as HTMLAudioElement
  duration.value = audio.duration
}

const handleTrackEnded = () => {
  isPlaying.value = false
}
</script>

<style scoped>
.v-enter-active,
.v-leave-active {
  transition: opacity 0.3s, height 0.3s;
  overflow: hidden;
}

.v-enter-from,
.v-leave-to {
  opacity: 0;
  height: 0;
}

input[type="range"] {
  -webkit-appearance: none;
  height: 4px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 2px;
  overflow: hidden;
}

input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #6366f1;
  cursor: pointer;
  box-shadow: -100vw 0 0 100vw rgba(99, 102, 241, 0.4);
}

input[type="range"]::-moz-range-thumb {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #6366f1;
  cursor: pointer;
  box-shadow: -100vw 0 0 100vw rgba(99, 102, 241, 0.4);
}

input[type="range"]:focus {
  outline: none;
}

input[type="range"]:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>