<template>
  <div class="space-y-20">
    <!-- Hero Section -->
    <section class="text-center py-20 relative">
      <div class="relative z-10">
        <div 
          class="inline-block mb-8 relative"
          :class="{ 'animate-spin-slow': isSpinning }"
        >
          <div class="relative">
            <div class="w-24 h-24 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full flex items-center justify-center mx-auto">
              <Sparkles class="h-12 w-12 text-white" />
            </div>
            <div class="absolute inset-0 w-24 h-24 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full animate-pulse-glow opacity-50"></div>
          </div>
        </div>

        <h1 class="text-6xl md:text-7xl font-bold mb-6 text-glow">
          <span class="bg-gradient-to-r from-cosmic-300 via-nebula-300 to-star-300 bg-clip-text text-transparent">
            Memonize ⭐
          </span>
        </h1>
        
        <p class="text-xl md:text-2xl text-cosmic-200 mb-8 max-w-3xl mx-auto">
          Every hour is a memo. Memonize your day ✨
        </p>

        <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
          <RouterLink 
            v-if="authStore.isAuthenticated" 
            to="/memoquest" 
            class="cosmic-button text-lg px-6 py-3 sm:px-8 sm:py-4 w-full sm:w-auto text-center"
          >
            <Rocket class="inline-block mr-2 h-5 w-5" />
            Launch Mission
          </RouterLink>
          <button 
            v-else
            @click="showAuthModal = true"
            class="cosmic-button text-lg px-6 py-3 sm:px-8 sm:py-4 w-full sm:w-auto text-center"
          >
            <Rocket class="inline-block mr-2 h-5 w-5" />
            Start Your Journey
          </button>
          
          <RouterLink 
            to="/notes" 
            class="nebula-button text-lg px-6 py-3 sm:px-8 sm:py-4 w-full sm:w-auto text-center"
          >
            <BookOpen class="inline-block mr-2 h-5 w-5" />
            Explore Features
          </RouterLink>
        </div>
      </div>

      <!-- Floating elements -->
      <div 
        class="absolute top-20 left-10 text-6xl opacity-20"
        :style="floatingElement1Style"
      >
        🚀
      </div>
      <div 
        class="absolute top-32 right-16 text-4xl opacity-20"
        :style="floatingElement2Style"
      >
        ⭐
      </div>
      <div 
        class="absolute bottom-20 left-20 text-5xl opacity-20"
        :style="floatingElement3Style"
      >
        🌟
      </div>
    </section>

    <!-- Features Section -->
    <section>
      <div class="text-center mb-16">
        <h2 class="text-4xl font-bold mb-4 text-glow">
          Discover Your Learning Universe
        </h2>
        <p class="text-xl text-cosmic-200 max-w-2xl mx-auto">
          Explore powerful features designed to transform your study experience
        </p>
      </div>

      <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
        <div 
          v-for="feature in features" 
          :key="feature.title"
          class="relative group"
        >
          <template v-if="feature.href === '#'">
            <div class="block cursor-default">
              <div class="glass-card p-6 md:p-8 h-full hover:border-cosmic-400/50 transition-all duration-300 relative overflow-hidden">
                <div 
                  class="absolute inset-0 bg-gradient-to-br opacity-0 group-hover:opacity-10 transition-opacity duration-300"
                  :class="feature.color"
                ></div>
                
                <div 
                  class="inline-flex p-3 md:p-4 rounded-xl bg-gradient-to-r mb-4 md:mb-6"
                  :class="feature.color"
                >
                  <component :is="feature.icon" class="h-6 w-6 md:h-8 md:w-8 text-white" />
                </div>
                
                <h3 class="text-lg md:text-xl font-bold mb-3 md:mb-4 text-white group-hover:text-glow transition-all">
                  {{ feature.title }}
                </h3>
                
                <p class="text-sm md:text-base text-cosmic-300 group-hover:text-cosmic-200 transition-colors mb-3">
                  {{ feature.description }}
                </p>
                
                <div class="text-xs text-star-400 font-medium">
                  ✨ Available in navigation
                </div>
              </div>
            </div>
          </template>
          <RouterLink v-else :to="feature.href" class="block">
            <div class="glass-card p-6 md:p-8 h-full hover:border-cosmic-400/50 transition-all duration-300 relative overflow-hidden">
              <div 
                class="absolute inset-0 bg-gradient-to-br opacity-0 group-hover:opacity-10 transition-opacity duration-300"
                :class="feature.color"
              ></div>
              
              <div 
                class="inline-flex p-3 md:p-4 rounded-xl bg-gradient-to-r mb-4 md:mb-6"
                :class="feature.color"
              >
                <component :is="feature.icon" class="h-6 w-6 md:h-8 md:w-8 text-white" />
              </div>
              
              <h3 class="text-lg md:text-xl font-bold mb-3 md:mb-4 text-white group-hover:text-glow transition-all">
                {{ feature.title }}
              </h3>
              
              <p class="text-sm md:text-base text-cosmic-300 group-hover:text-cosmic-200 transition-colors">
                {{ feature.description }}
              </p>
            </div>
          </RouterLink>
        </div>
      </div>
    </section>

    <!-- Stats Section -->
    <section class="py-16">
      <div class="glass-card p-6 md:p-8 lg:p-12">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-6 md:gap-8 text-center">
          <div
            v-for="stat in stats"
            :key="stat.label"
            class="space-y-4"
          >
            <div class="inline-flex p-3 md:p-4 rounded-full bg-gradient-to-r from-cosmic-500 to-nebula-500">
              <component :is="stat.icon" class="h-6 w-6 md:h-8 md:w-8 text-white" />
            </div>
            <div>
              <div class="text-2xl md:text-3xl font-bold text-white text-glow">
                {{ stat.value }}
              </div>
              <div class="text-sm md:text-base text-cosmic-300">
                {{ stat.label }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="text-center py-20">
      <div class="glass-card p-6 md:p-8 lg:p-12 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-r from-cosmic-600/20 to-nebula-600/20"></div>
        <div class="relative z-10">
          <h2 class="text-2xl md:text-3xl lg:text-4xl font-bold mb-4 md:mb-6 text-glow">
            Ready to Transform Your Learning?
          </h2>
          <p class="text-lg md:text-xl text-cosmic-200 mb-6 md:mb-8 max-w-2xl mx-auto">
            Join thousands of students who are already exploring the cosmos of knowledge
          </p>
          <div class="flex flex-col sm:flex-row gap-4 justify-center">
            <RouterLink to="/memoquest" class="star-button text-lg px-6 py-3 md:px-8 md:py-4 w-full sm:w-auto text-center">
              <Zap class="inline-block mr-2 h-5 w-5" />
              Start Playing
            </RouterLink>
            <RouterLink to="/notes" class="cosmic-button text-lg px-6 py-3 md:px-8 md:py-4 w-full sm:w-auto text-center">
              <Star class="inline-block mr-2 h-5 w-5" />
              Create Notes
            </RouterLink>
          </div>
        </div>
      </div>
    </section>
  </div>
  
  <!-- Auth Modal -->
  <AuthModal :isOpen="showAuthModal" @close="showAuthModal = false" />
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { RouterLink } from 'vue-router'
import { 
  BookOpen, 
  CreditCard, 
  Gamepad2, 
  Users, 
  Brain, 
  Target,
  Zap,
  Star,
  Rocket,
  Sparkles,
  Timer,
  BarChart3
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import AuthModal from '@/components/AuthModal.vue'

// Auth store
const authStore = useAuthStore()
const showAuthModal = ref(false)

// Animation
const isSpinning = ref(false)
const floatingElement1Style = reactive({ transform: 'translate(0px, 0px)' })
const floatingElement2Style = reactive({ transform: 'translate(0px, 0px)' })
const floatingElement3Style = reactive({ transform: 'translate(0px, 0px)' })

// Animate floating elements
const animateFloatingElements = () => {
  let time = 0
  
  const animate = () => {
    time += 0.01
    floatingElement1Style.transform = `translate(0px, ${Math.sin(time) * 10}px) rotate(${Math.sin(time * 0.5) * 5}deg)`
    floatingElement2Style.transform = `translate(${Math.sin(time * 0.7) * 15}px, ${Math.cos(time * 0.7) * 10}px) rotate(${Math.sin(time) * -5}deg)`
    floatingElement3Style.transform = `translate(${Math.sin(time * 0.5) * 10}px, ${Math.cos(time * 0.5) * 10}px)`
    requestAnimationFrame(animate)
  }
  
  animate()
}

onMounted(() => {
  animateFloatingElements()
  
  // Add hover effect to the logo
  const logoElement = document.querySelector('.inline-block.mb-8')
  if (logoElement) {
    logoElement.addEventListener('mouseenter', () => { isSpinning.value = true })
    logoElement.addEventListener('mouseleave', () => { isSpinning.value = false })
  }
})

// Features data
const features = [
  {
    icon: BookOpen,
    title: 'Smart Notes',
    description: 'AI-powered note taking with enhanced pattern recognition and smart flashcard generation',
    href: '/notes',
    color: 'from-cosmic-500 to-cosmic-600'
  },
  {
    icon: CreditCard,
    title: 'Dynamic Flashcards',
    description: 'Intelligent flashcards with adaptive difficulty and personalized review schedules',
    href: '/flashcards',
    color: 'from-nebula-500 to-nebula-600'
  },
  {
    icon: Gamepad2,
    title: 'MemoQuest RPG',
    description: 'Immersive learning adventures with achievements, leveling, and cosmic rewards',
    href: '/memoquest',
    color: 'from-star-500 to-star-600'
  },
  {
    icon: Timer,
    title: 'Pomodoro Rooms',
    description: 'Enhanced collaborative focus sessions with AI insights and productivity analytics',
    href: '/pomodoro-rooms',
    color: 'from-red-500 to-red-600'
  },
  {
    icon: BarChart3,
    title: 'Learning Analytics',
    description: 'AI-powered insights into your learning patterns and performance optimization',
    href: '/analytics',
    color: 'from-purple-500 to-purple-600'
  },
  {
    icon: Brain,
    title: 'Draco AI',
    description: 'Personal cosmic study companion providing real-time guidance and support',
    href: '#',
    color: 'from-green-500 to-green-600'
  }
]

// Stats data
const stats = [
  { label: 'Active Learners', value: '10,000+', icon: Users },
  { label: 'Notes Created', value: '50,000+', icon: BookOpen },
  { label: 'Quests Completed', value: '25,000+', icon: Target },
  { label: 'Study Hours', value: '100,000+', icon: Brain },
]
</script>

<style scoped>
.animate-spin-slow {
  animation: spin 20s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>