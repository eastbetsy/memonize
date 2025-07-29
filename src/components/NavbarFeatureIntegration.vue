<template>
  <Teleport to="body">
    <div 
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      @click="handleBackdropClick"
    >
      <div 
        class="glass-card w-full max-w-2xl mx-4"
        @click.stop
      >
        <!-- Header -->
        <div class="flex items-center justify-between p-6 border-b border-white/10">
          <h2 class="text-xl font-bold text-white flex items-center">
            <Zap class="h-5 w-5 mr-2 text-cosmic-400" />
            Platform Integration
          </h2>
          
          <button
            @click="$emit('close')"
            class="text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
          >
            ×
          </button>
        </div>
        
        <div class="p-6">
          <div class="space-y-6">
            <!-- Notes <-> AI Chat -->
            <div class="glass-card p-4">
              <div class="flex items-center space-x-3 mb-3">
                <div class="p-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-lg">
                  <Brain class="h-4 w-4 text-white" />
                </div>
                <h3 class="text-white font-medium">Smart Notes & AI Chat</h3>
              </div>
              
              <p class="text-cosmic-300 text-sm mb-3">
                Highlight text in your notes to directly interact with Draco AI for explanations, 
                flashcard creation, and resource recommendations.
              </p>
              
              <div class="text-xs text-cosmic-400 flex items-center">
                <Star class="h-3 w-3 mr-1 text-star-400" />
                <span>Select text in any note and ask Draco to explain concepts or create study materials</span>
              </div>
            </div>
            
            <!-- Analytics <-> Pomodoro -->
            <div class="glass-card p-4">
              <div class="flex items-center space-x-3 mb-3">
                <div class="p-2 bg-gradient-to-r from-nebula-500 to-cosmic-500 rounded-lg">
                  <LayoutDashboard class="h-4 w-4 text-white" />
                </div>
                <h3 class="text-white font-medium">Analytics & Pomodoro Integration</h3>
              </div>
              
              <p class="text-cosmic-300 text-sm mb-3">
                Your Analytics dashboard now shows personalized productivity insights based on your 
                Pomodoro sessions, revealing when and how you study most effectively.
              </p>
              
              <div class="text-xs text-cosmic-400 flex items-center">
                <Star class="h-3 w-3 mr-1 text-star-400" />
                <span>Complete Pomodoro sessions with different subjects to unlock personalized insights</span>
              </div>
            </div>
            
            <!-- RPG <-> All Tools -->
            <div class="glass-card p-4">
              <div class="flex items-center space-x-3 mb-3">
                <div class="p-2 bg-gradient-to-r from-star-500 to-nebula-500 rounded-lg">
                  <Award class="h-4 w-4 text-white" />
                </div>
                <h3 class="text-white font-medium">XP Rewards Across All Tools</h3>
              </div>
              
              <p class="text-cosmic-300 text-sm mb-3">
                Earn XP for all productive actions throughout the app - creating notes, completing 
                Pomodoro sessions, mastering flashcards, and participating in study groups.
              </p>
              
              <div class="text-xs text-cosmic-400 flex items-center">
                <Star class="h-3 w-3 mr-1 text-star-400" />
                <span>All your learning activities now contribute to your overall level progression</span>
              </div>
            </div>
            
            <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4">
              <div class="flex items-start space-x-3">
                <Bell class="h-5 w-5 mt-0.5 text-cosmic-400 flex-shrink-0" />
                <div>
                  <h3 class="text-white font-medium mb-1">Coming Soon</h3>
                  <ul class="space-y-2 text-cosmic-300 text-sm">
                    <li class="flex items-center">
                      <Star class="h-3 w-3 mr-2 text-star-400" />
                      <span>Galaxy Library - Community knowledge repository</span>
                    </li>
                    <li class="flex items-center">
                      <Star class="h-3 w-3 mr-2 text-star-400" />
                      <span>Collaborative Whiteboards for Study Groups</span>
                    </li>
                    <li class="flex items-center">
                      <Star class="h-3 w-3 mr-2 text-star-400" />
                      <span>Parent/Guardian Progress Portal</span>
                    </li>
                  </ul>
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
import { ref } from 'vue'
import { 
  Brain, 
  Zap, 
  Award, 
  Bell, 
  Star, 
  LayoutDashboard
} from 'lucide-vue-next'

// Props
defineProps<{
  isOpen: boolean
}>()

// Emits
defineEmits<{
  (e: 'close'): void
}>()

// Methods
const handleBackdropClick = () => {
  // Use emit to close the modal
  emit('close')
}
</script>