<template>
  <Teleport to="body">
    <div 
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      @click="handleBackdropClick"
    >
      <div 
        class="glass-card w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto"
        @click.stop
      >
        <!-- Header -->
        <div class="flex items-center justify-between p-6 border-b border-white/10">
          <h2 class="text-xl font-bold text-white">Theme Customizer</h2>
          <button
            @click="$emit('close')"
            class="text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
          >
            <X class="h-6 w-6" />
          </button>
        </div>

        <!-- Content -->
        <div class="p-6 space-y-6">
          <!-- Theme Selection -->
          <div>
            <h3 class="text-lg font-semibold text-white mb-4">Choose Theme</h3>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div
                v-for="theme in themes"
                :key="theme.id"
                class="relative p-4 rounded-lg border-2 cursor-pointer transition-all"
                :class="[
                  selectedTheme === theme.id
                    ? 'border-cosmic-500 bg-cosmic-900/50'
                    : 'border-white/20 hover:border-white/40'
                ]"
                @click="selectTheme(theme.id)"
              >
                <div class="flex items-center space-x-3">
                  <div 
                    class="w-8 h-8 rounded-full"
                    :style="{ background: theme.preview }"
                  ></div>
                  <div>
                    <div class="text-white font-medium">{{ theme.name }}</div>
                    <div class="text-cosmic-400 text-sm">{{ theme.description }}</div>
                  </div>
                </div>
                <div
                  v-if="selectedTheme === theme.id"
                  class="absolute top-2 right-2"
                >
                  <Check class="h-5 w-5 text-cosmic-400" />
                </div>
              </div>
            </div>
          </div>

          <!-- Customization Options -->
          <div>
            <h3 class="text-lg font-semibold text-white mb-4">Customization</h3>
            <div class="space-y-4">
              <!-- Font Size -->
              <div>
                <label class="block text-cosmic-300 text-sm mb-2">Font Size</label>
                <select
                  v-model="fontSize"
                  class="w-full bg-cosmic-900/50 border border-white/20 rounded-lg px-3 py-2 text-white"
                >
                  <option value="small">Small</option>
                  <option value="medium">Medium</option>
                  <option value="large">Large</option>
                </select>
              </div>

              <!-- Reduced Motion -->
              <div class="flex items-center justify-between">
                <div>
                  <div class="text-white font-medium">Reduced Motion</div>
                  <div class="text-cosmic-400 text-sm">Minimize animations and transitions</div>
                </div>
                <button
                  @click="reducedMotion = !reducedMotion"
                  class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors"
                  :class="reducedMotion ? 'bg-cosmic-500' : 'bg-white/20'"
                >
                  <span
                    class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform"
                    :class="reducedMotion ? 'translate-x-6' : 'translate-x-1'"
                  />
                </button>
              </div>

              <!-- High Contrast -->
              <div class="flex items-center justify-between">
                <div>
                  <div class="text-white font-medium">High Contrast</div>
                  <div class="text-cosmic-400 text-sm">Improve visibility with enhanced contrast</div>
                </div>
                <button
                  @click="highContrast = !highContrast"
                  class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors"
                  :class="highContrast ? 'bg-cosmic-500' : 'bg-white/20'"
                >
                  <span
                    class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform"
                    :class="highContrast ? 'translate-x-6' : 'translate-x-1'"
                  />
                </button>
              </div>

              <!-- Background Effects -->
              <div class="flex items-center justify-between">
                <div>
                  <div class="text-white font-medium">Background Effects</div>
                  <div class="text-cosmic-400 text-sm">Enable particle animations and effects</div>
                </div>
                <button
                  @click="backgroundEffects = !backgroundEffects"
                  class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors"
                  :class="backgroundEffects ? 'bg-cosmic-500' : 'bg-white/20'"
                >
                  <span
                    class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform"
                    :class="backgroundEffects ? 'translate-x-6' : 'translate-x-1'"
                  />
                </button>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex justify-end space-x-3 pt-4 border-t border-white/10">
            <button
              @click="resetToDefaults"
              class="px-4 py-2 text-cosmic-300 hover:text-white transition-colors"
            >
              Reset to Defaults
            </button>
            <button
              @click="saveSettings"
              class="cosmic-button"
            >
              Save Changes
            </button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { X, Check } from 'lucide-vue-next'

// Props
defineProps<{
  isOpen: boolean
}>()

// Emits
const emit = defineEmits<{
  (e: 'close'): void
}>()

// State
const selectedTheme = ref('cosmic')
const fontSize = ref('medium')
const reducedMotion = ref(false)
const highContrast = ref(false)
const backgroundEffects = ref(true)

// Theme options
const themes = [
  {
    id: 'cosmic',
    name: 'Cosmic',
    description: 'Deep space vibes',
    preview: 'linear-gradient(45deg, #6366f1, #8b5cf6)'
  },
  {
    id: 'nebula',
    name: 'Nebula',
    description: 'Colorful cosmic clouds',
    preview: 'linear-gradient(45deg, #f59e0b, #ef4444)'
  },
  {
    id: 'aurora',
    name: 'Aurora',
    description: 'Northern lights inspired',
    preview: 'linear-gradient(45deg, #10b981, #3b82f6)'
  },
  {
    id: 'stellar',
    name: 'Stellar',
    description: 'Bright star clusters',
    preview: 'linear-gradient(45deg, #fbbf24, #f59e0b)'
  },
  {
    id: 'void',
    name: 'Void',
    description: 'Minimal dark theme',
    preview: 'linear-gradient(45deg, #374151, #1f2937)'
  },
  {
    id: 'galaxy',
    name: 'Galaxy',
    description: 'Spiral galaxy colors',
    preview: 'linear-gradient(45deg, #7c3aed, #ec4899)'
  }
]

// Methods
const handleBackdropClick = () => {
  emit('close')
}

const selectTheme = (themeId: string) => {
  selectedTheme.value = themeId
}

const resetToDefaults = () => {
  selectedTheme.value = 'cosmic'
  fontSize.value = 'medium'
  reducedMotion.value = false
  highContrast.value = false
  backgroundEffects.value = true
}

const saveSettings = () => {
  // Save settings to localStorage or user preferences
  const settings = {
    theme: selectedTheme.value,
    fontSize: fontSize.value,
    reducedMotion: reducedMotion.value,
    highContrast: highContrast.value,
    backgroundEffects: backgroundEffects.value
  }
  
  localStorage.setItem('themeSettings', JSON.stringify(settings))
  
  // Apply theme changes to document
  applyTheme()
  
  emit('close')
}

const applyTheme = () => {
  const root = document.documentElement
  
  // Apply theme class
  root.className = root.className.replace(/theme-\w+/g, '')
  root.classList.add(`theme-${selectedTheme.value}`)
  
  // Apply font size
  root.classList.remove('font-small', 'font-medium', 'font-large')
  root.classList.add(`font-${fontSize.value}`)
  
  // Apply accessibility settings
  if (reducedMotion.value) {
    root.classList.add('reduced-motion')
  } else {
    root.classList.remove('reduced-motion')
  }
  
  if (highContrast.value) {
    root.classList.add('high-contrast')
  } else {
    root.classList.remove('high-contrast')
  }
  
  if (!backgroundEffects.value) {
    root.classList.add('no-bg-effects')
  } else {
    root.classList.remove('no-bg-effects')
  }
}

const loadSettings = () => {
  const saved = localStorage.getItem('themeSettings')
  if (saved) {
    try {
      const settings = JSON.parse(saved)
      selectedTheme.value = settings.theme || 'cosmic'
      fontSize.value = settings.fontSize || 'medium'
      reducedMotion.value = settings.reducedMotion || false
      highContrast.value = settings.highContrast || false
      backgroundEffects.value = settings.backgroundEffects ?? true
      
      // Apply loaded settings
      applyTheme()
    } catch (error) {
      console.error('Failed to load theme settings:', error)
    }
  }
}

// Lifecycle
onMounted(() => {
  loadSettings()
})
</script>