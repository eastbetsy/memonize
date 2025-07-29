<template>
  <div class="min-h-screen bg-space-gradient relative overflow-hidden">
    <!-- Background elements -->
    <div class="fixed inset-0 constellation-bg opacity-30"></div>
    <div class="fixed inset-0 bg-nebula-gradient opacity-20"></div>
    
    <!-- Floating orbs -->
    <div 
      class="fixed top-20 left-10 w-32 h-32 bg-cosmic-500/20 rounded-full blur-xl"
      :style="floatingOrbStyle1"
    ></div>
    <div 
      class="fixed bottom-20 right-10 w-24 h-24 bg-nebula-500/20 rounded-full blur-xl"
      :style="floatingOrbStyle2"
    ></div>
    
    <div class="relative z-10">
      <Navbar />
      <main class="container mx-auto px-4 py-8">
        <RouterView />
      </main>
      
      <!-- Achievement Widget -->
      <UserAchievementWidget :minimized="true" />
      
      <!-- Bolt Logo -->
      <div class="fixed bottom-4 right-4 z-40">
        <a 
          href="https://bolt.new" 
          target="_blank" 
          rel="noopener noreferrer">
          <img 
            :src="isDarkMode ? '/whitebolt.png' : '/blackbolt.png'" 
            alt="Powered by Bolt"
            class="w-12 h-12 opacity-70 hover:opacity-100 transition-opacity"
          />
        </a>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { RouterView } from 'vue-router'
import Navbar from './components/Navbar.vue'
import UserAchievementWidget from './components/UserAchievementWidget.vue'
import { useAuthStore } from './stores/auth'

// Dark mode detection
const isDarkMode = ref(true)

// Animation setup
const floatingOrbStyle1 = reactive({
  transform: 'translate(0px, 0px)'
})

const floatingOrbStyle2 = reactive({
  transform: 'translate(0px, 0px)'
})

// Animate floating orbs
const animateOrbs = () => {
  let time = 0
  const animate = () => {
    time += 0.01
    floatingOrbStyle1.transform = `translate(${Math.sin(time) * 10}px, ${Math.cos(time) * 20}px)`
    floatingOrbStyle2.transform = `translate(${Math.cos(time) * 15}px, ${Math.sin(time) * 10}px)`
    requestAnimationFrame(animate)
  }
  animate()
}

// Initialize auth
const authStore = useAuthStore()

onMounted(() => {
  animateOrbs()
  authStore.initialize()
})
</script>