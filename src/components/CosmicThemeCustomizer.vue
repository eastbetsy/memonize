<template>
  <Teleport to="body">
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <!-- Backdrop -->
      <div 
        class="absolute inset-0 bg-black/50 backdrop-blur-sm" 
        @click="$emit('close')"
      />

      <!-- Modal -->
      <div class="relative w-full max-w-4xl max-h-[90vh] overflow-hidden">
        <div class="glass-card p-6">
          <div class="absolute inset-0 bg-gradient-to-br from-cosmic-600/10 to-nebula-600/10" />
          <div class="absolute top-0 right-0 w-32 h-32 bg-cosmic-500/20 rounded-full blur-3xl" />

          <div class="relative z-10">
            <!-- Header -->
            <div class="flex items-center justify-between p-6 border-b border-white/10">
              <div class="flex items-center space-x-3">
                <div class="p-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-lg">
                  <Palette class="h-6 w-6 text-white" />
                </div>
                <div>
                  <h2 class="text-xl font-bold text-glow">Cosmic Customizer</h2>
                  <p class="text-cosmic-300">Personalize your cosmic experience</p>
                </div>
              </div>
              
              <div class="flex items-center space-x-2">
                <button
                  @click="resetToDefaults"
                  class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                  title="Reset to defaults"
                >
                  <RotateCcw class="h-5 w-5" />
                </button>
                <button
                  @click="$emit('close')"
                  class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                >
                  <X class="h-5 w-5" />
                </button>
              </div>
            </div>

            <!-- Tabs -->
            <div class="flex border-b border-white/10">
              <button
                v-for="tab in tabs"
                :key="tab.id"
                @click="activeTab = tab.id"
                :class="[
                  'flex items-center space-x-2 px-6 py-4 transition-all',
                  activeTab === tab.id
                    ? 'text-cosmic-300 border-b-2 border-cosmic-500'
                    : 'text-cosmic-400 hover:text-cosmic-300'
                ]"
              >
                <component :is="tab.icon" class="h-4 w-4" />
                <span>{{ tab.label }}</span>
              </button>
            </div>

            <!-- Content -->
            <div class="p-6 max-h-[60vh] overflow-y-auto">
              <!-- Themes Tab -->
              <div v-if="activeTab === 'themes'" class="space-y-6">
                <div>
                  <h3 class="text-lg font-bold text-white mb-4">Choose Your Cosmic Theme</h3>
                  <div class="grid md:grid-cols-2 gap-4">
                    <div
                      v-for="theme in themes"
                      :key="theme.id"
                      @click="handleThemeChange(theme)"
                      class="glass-card p-4 cursor-pointer transition-all"
                      :class="[
                        selectedTheme === theme.id 
                          ? 'border-cosmic-400 ring-2 ring-cosmic-400/50' 
                          : 'hover:border-cosmic-400/50'
                      ]"
                    >
                      <div class="flex items-center justify-between mb-3">
                        <h4 class="font-bold text-white">{{ theme.name }}</h4>
                        <div v-if="selectedTheme === theme.id" class="w-4 h-4 bg-cosmic-500 rounded-full" />
                      </div>
                      <p class="text-cosmic-300 text-sm mb-4">{{ theme.description }}</p>
                      
                      <!-- Color Preview -->
                      <div class="flex space-x-2">
                        <div :class="['w-8 h-8 rounded bg-gradient-to-r', theme.colors.primary]" />
                        <div :class="['w-8 h-8 rounded bg-gradient-to-r', theme.colors.secondary]" />
                        <div :class="['w-8 h-8 rounded bg-gradient-to-r', theme.colors.accent]" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Accessibility Tab -->
              <div v-else-if="activeTab === 'accessibility'" class="space-y-6">
                <h3 class="text-lg font-bold text-white mb-4">Accessibility Settings</h3>
                
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <label class="text-white font-medium">Reduced Motion</label>
                      <p class="text-cosmic-300 text-sm">Minimize animations and transitions</p>
                    </div>
                    <button
                      @click="reducedMotion = !reducedMotion"
                      class="w-12 h-6 rounded-full transition-colors"
                      :class="reducedMotion ? 'bg-cosmic-500' : 'bg-gray-600'"
                    >
                      <div 
                        class="w-4 h-4 bg-white rounded-full transition-transform"
                        :class="reducedMotion ? 'translate-x-7' : 'translate-x-1'" 
                      />
                    </button>
                  </div>

                  <div class="flex items-center justify-between">
                    <div>
                      <label class="text-white font-medium">High Contrast</label>
                      <p class="text-cosmic-300 text-sm">Increase contrast for better visibility</p>
                    </div>
                    <button
                      @click="highContrast = !highContrast"
                      class="w-12 h-6 rounded-full transition-colors"
                      :class="highContrast ? 'bg-cosmic-500' : 'bg-gray-600'"
                    >
                      <div 
                        class="w-4 h-4 bg-white rounded-full transition-transform"
                        :class="highContrast ? 'translate-x-7' : 'translate-x-1'" 
                      />
                    </button>
                  </div>

                  <div>
                    <label class="text-white font-medium mb-2 block">Font Size</label>
                    <div class="flex space-x-2">
                      <button
                        v-for="size in ['small', 'medium', 'large']"
                        :key="size"
                        @click="fontSize = size"
                        :class="[
                          'px-4 py-2 rounded-lg capitalize transition-colors',
                          fontSize === size
                            ? 'bg-cosmic-500 text-white'
                            : 'bg-white/10 text-cosmic-300 hover:bg-white/20'
                        ]"
                      >
                        {{ size }}
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Advanced Tab -->
              <div v-else-if="activeTab === 'advanced'" class="space-y-6">
                <h3 class="text-lg font-bold text-white mb-4">Advanced Settings</h3>
                
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <label class="text-white font-medium">Sound Effects</label>
                      <p class="text-cosmic-300 text-sm">Enable cosmic sound effects</p>
                    </div>
                    <button
                      @click="soundEffects = !soundEffects"
                      class="p-2 text-cosmic-300 hover:text-white transition-colors"
                    >
                      <component :is="soundEffects ? Volume2 : VolumeX" class="h-5 w-5" />
                    </button>
                  </div>

                  <div class="flex items-center justify-between">
                    <div>
                      <label class="text-white font-medium">Background Effects</label>
                      <p class="text-cosmic-300 text-sm">Cosmic background animations</p>
                    </div>
                    <button
                      @click="backgroundEffects = !backgroundEffects"
                      class="w-12 h-6 rounded-full transition-colors"
                      :class="backgroundEffects ? 'bg-cosmic-500' : 'bg-gray-600'"
                    >
                      <div 
                        class="w-4 h-4 bg-white rounded-full transition-transform"
                        :class="backgroundEffects ? 'translate-x-7' : 'translate-x-1'" 
                      />
                    </button>
                  </div>

                  <div>
                    <label class="text-white font-medium mb-2 block">
                      Particle Count: {{ particleCount }}
                    </label>
                    <input
                      type="range"
                      min="0"
                      max="100"
                      v-model.number="particleCount"
                      class="w-full"
                    />
                  </div>

                  <div class="border-t border-white/10 pt-4">
                    <h4 class="text-white font-medium mb-3">Import/Export Settings</h4>
                    <div class="flex space-x-3">
                      <button
                        @click="exportSettings"
                        class="flex items-center space-x-2 cosmic-button"
                      >
                        <Download class="h-4 w-4" />
                        <span>Export</span>
                      </button>
                      
                      <label class="flex items-center space-x-2 nebula-button cursor-pointer">
                        <Upload class="h-4 w-4" />
                        <span>Import</span>
                        <input
                          type="file"
                          accept=".json"
                          @change="importSettings"
                          class="hidden"
                        />
                      </label>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { 
  Palette, 
  Eye,
  Volume2, 
  VolumeX,
  Settings,
  X,
  RotateCcw,
  Download,
  Upload
} from 'lucide-vue-next'

interface Theme {
  id: string
  name: string
  description: string
  colors: {
    primary: string
    secondary: string
    accent: string
    background: string
  }
  effects: {
    particles: boolean
    animations: boolean
    soundEffects: boolean
    backgrounds: string
  }
}

// Props
defineProps<{
  isOpen: boolean
}>()

// Emits
defineEmits<{
  (e: 'close'): void
}>()

// State
const selectedTheme = ref('cosmic')
const activeTab = ref('themes')
const fontSize = ref('medium')
const reducedMotion = ref(false)
const highContrast = ref(false)
const soundEffects = ref(false)
const backgroundEffects = ref(true)
const particleCount = ref(50)

// Tabs definition
const tabs = [
  { id: 'themes', label: 'Themes', icon: Palette },
  { id: 'accessibility', label: 'Accessibility', icon: Eye },
  { id: 'advanced', label: 'Advanced', icon: Settings }
]

// Available themes
const themes: Theme[] = [
  {
    id: 'cosmic',
    name: 'Cosmic Default',
    description: 'The original cosmic experience',
    colors: {
      primary: 'from-cosmic-500 to-cosmic-600',
      secondary: 'from-nebula-500 to-nebula-600',
      accent: 'from-star-500 to-star-600',
      background: 'from-space-900 to-cosmic-900'
    },
    effects: {
      particles: true,
      animations: true,
      soundEffects: false,
      backgrounds: 'nebula'
    }
  },
  {
    id: 'aurora',
    name: 'Aurora Borealis',
    description: 'Mystical northern lights theme',
    colors: {
      primary: 'from-green-500 to-emerald-600',
      secondary: 'from-blue-500 to-cyan-600',
      accent: 'from-purple-500 to-pink-600',
      background: 'from-slate-900 to-green-900'
    },
    effects: {
      particles: true,
      animations: true,
      soundEffects: false,
      backgrounds: 'aurora'
    }
  },
  {
    id: 'solar',
    name: 'Solar Flare',
    description: 'Bright and energetic solar theme',
    colors: {
      primary: 'from-orange-500 to-red-600',
      secondary: 'from-yellow-500 to-orange-600',
      accent: 'from-red-500 to-pink-600',
      background: 'from-slate-900 to-orange-900'
    },
    effects: {
      particles: true,
      animations: true,
      soundEffects: false,
      backgrounds: 'solar'
    }
  },
  {
    id: 'minimal',
    name: 'Minimal Focus',
    description: 'Clean and distraction-free',
    colors: {
      primary: 'from-slate-600 to-slate-700',
      secondary: 'from-gray-600 to-gray-700',
      accent: 'from-blue-500 to-blue-600',
      background: 'from-slate-900 to-gray-900'
    },
    effects: {
      particles: false,
      animations: false,
      soundEffects: false,
      backgrounds: 'minimal'
    }
  }
]

// Methods
const handleThemeChange = (theme: Theme) => {
  selectedTheme.value = theme.id
  applyTheme(theme)
}

const applyTheme = (theme: Theme) => {
  const root = document.documentElement
  
  // Apply CSS variables for the theme
  root.style.setProperty('--theme-primary', theme.colors.primary)
  root.style.setProperty('--theme-secondary', theme.colors.secondary)
  root.style.setProperty('--theme-accent', theme.colors.accent)
  root.style.setProperty('--theme-background', theme.colors.background)
  
  // Apply theme class
  document.body.className = `theme-${theme.id}`
  
  localStorage.setItem('cosmic-theme', theme.id)
}

const applySettings = () => {
  const root = document.documentElement
  
  // Apply accessibility settings
  if (reducedMotion.value) {
    root.style.setProperty('--animation-duration', '0s')
  } else {
    root.style.removeProperty('--animation-duration')
  }
  
  if (highContrast.value) {
    document.body.classList.add('high-contrast')
  } else {
    document.body.classList.remove('high-contrast')
  }
  
  // Apply font size
  document.body.classList.remove('font-small', 'font-medium', 'font-large')
  document.body.classList.add(`font-${fontSize.value}`)
  
  localStorage.setItem('cosmic-settings', JSON.stringify({
    fontSize: fontSize.value,
    reducedMotion: reducedMotion.value,
    highContrast: highContrast.value,
    soundEffects: soundEffects.value,
    backgroundEffects: backgroundEffects.value,
    particleCount: particleCount.value
  }))
}

const resetToDefaults = () => {
  const defaultTheme = themes[0]
  selectedTheme.value = defaultTheme.id
  fontSize.value = 'medium'
  reducedMotion.value = false
  highContrast.value = false
  soundEffects.value = false
  backgroundEffects.value = true
  particleCount.value = 50
  
  applyTheme(defaultTheme)
  applySettings()
}

const exportSettings = () => {
  const exportData = {
    theme: selectedTheme.value,
    settings: {
      fontSize: fontSize.value,
      reducedMotion: reducedMotion.value,
      highContrast: highContrast.value,
      soundEffects: soundEffects.value,
      backgroundEffects: backgroundEffects.value,
      particleCount: particleCount.value
    },
    exported: new Date().toISOString()
  }
  
  const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'memoquest-theme.json'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

const importSettings = (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  
  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      const data = JSON.parse(e.target?.result as string)
      const theme = themes.find(t => t.id === data.theme) || themes[0]
      selectedTheme.value = theme.id
      
      // Apply imported settings
      if (data.settings) {
        fontSize.value = data.settings.fontSize || 'medium'
        reducedMotion.value = data.settings.reducedMotion || false
        highContrast.value = data.settings.highContrast || false
        soundEffects.value = data.settings.soundEffects || false
        backgroundEffects.value = data.settings.backgroundEffects ?? true
        particleCount.value = data.settings.particleCount || 50
      }
      
      applyTheme(theme)
      applySettings()
    } catch (error) {
      console.error('Failed to import settings:', error)
    }
  }
  reader.readAsText(file)
}

// Lifecycle hooks
onMounted(() => {
  // Load saved theme and settings
  const savedTheme = localStorage.getItem('cosmic-theme')
  const savedSettings = localStorage.getItem('cosmic-settings')
  
  if (savedTheme) {
    const theme = themes.find(t => t.id === savedTheme) || themes[0]
    selectedTheme.value = theme.id
    applyTheme(theme)
  }
  
  if (savedSettings) {
    try {
      const settings = JSON.parse(savedSettings)
      fontSize.value = settings.fontSize || 'medium'
      reducedMotion.value = settings.reducedMotion || false
      highContrast.value = settings.highContrast || false
      soundEffects.value = settings.soundEffects || false
      backgroundEffects.value = settings.backgroundEffects ?? true
      particleCount.value = settings.particleCount || 50
      
      applySettings()
    } catch (error) {
      console.error('Failed to parse saved settings:', error)
    }
  }
})
</script>