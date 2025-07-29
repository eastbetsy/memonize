<template>
  <div class="flex flex-col items-center space-y-4">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-xl font-bold text-white mb-2">🐻 Ursa Major's Star Hunt</h3>
      <p class="text-cosmic-300 text-sm mb-4">Help the Great Bear collect stars to form constellations!</p>
      <div class="flex items-center justify-center space-x-6 text-cosmic-300">
        <div>Score: <span class="text-white font-bold">{{ score }}</span></div>
        <div>Level: <span class="text-white font-bold">{{ level }}</span></div>
        <div>Stars: <span class="text-white font-bold">{{ starsCollected }}/{{ starsNeeded }}</span></div>
        <div>Time: <span class="text-white font-bold">{{ timeLeft }}s</span></div>
      </div>
    </div>

    <!-- Game Board -->
    <div 
      class="relative bg-gradient-to-br from-space-900 to-cosmic-900 rounded-lg border-2 border-cosmic-500/50 overflow-hidden"
      style="width: 500px; height: 400px"
    >
      <!-- Background -->
      <div class="absolute inset-0 constellation-bg opacity-30"></div>

      <!-- Stars -->
      <TransitionGroup name="star">
        <div
          v-for="star in stars.filter(star => !star.collected)"
          :key="star.id"
          class="absolute rounded-full shadow-lg flex items-center justify-center"
          :class="[`bg-gradient-to-r ${getStarColor(star.type)}`]"
          :style="{
            left: `${star.x}px`,
            top: `${star.y}px`,
            width: `${STAR_SIZE}px`,
            height: `${STAR_SIZE}px`,
            boxShadow: getStarShadow(star.type),
            animation: 'star-pulse 2s infinite alternate, star-rotate 3s infinite linear'
          }"
        >
          <span class="text-xs">{{ getStarEmoji(star.type) }}</span>
        </div>
      </TransitionGroup>

      <!-- Bear -->
      <div
        class="absolute flex items-center justify-center"
        :style="{
          left: `${bear.x}px`,
          top: `${bear.y}px`,
          width: `${BEAR_SIZE}px`,
          height: `${BEAR_SIZE}px`,
          transform: `translateX(${bearTransitionX}px) ${bear.direction === 'left' ? 'scaleX(-1)' : ''}`,
          transition: 'transform 0.1s'
        }"
      >
        <div class="text-2xl animate-bounce-slow">
          🐻
        </div>
      </div>

      <!-- Level Complete Animation -->
      <Transition>
        <div
          v-if="starsCollected >= starsNeeded && gameStarted && !gameOver"
          class="absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg"
        >
          <div class="text-center">
            <div class="text-6xl mb-4 animate-spin-slow">
              🌌
            </div>
            <div class="text-white font-bold text-xl">Constellation Complete!</div>
            <div class="text-star-400">Level {{ level }} • +100 bonus points</div>
          </div>
        </div>
      </Transition>

      <!-- Game Over Overlay -->
      <div v-if="gameOver" class="absolute inset-0 bg-black/80 flex items-center justify-center rounded-lg">
        <div class="text-center">
          <div class="text-4xl mb-2">🐻</div>
          <div class="text-white font-bold mb-2">Great Bear's Journey Complete!</div>
          <div class="text-cosmic-300 mb-2">Reached Level: {{ level }}</div>
          <div class="text-cosmic-300 mb-4">Final Score: {{ score }}</div>
          <button
            @click="resetGame"
            class="cosmic-button"
          >
            New Journey
          </button>
        </div>
      </div>

      <!-- Start Game Overlay -->
      <div v-if="!gameStarted" class="absolute inset-0 bg-black/80 flex items-center justify-center rounded-lg">
        <div class="text-center">
          <div class="text-4xl mb-2">🐻</div>
          <div class="text-white font-bold mb-2">Ready for the Star Hunt?</div>
          <div class="text-cosmic-300 mb-4">
            Use arrow keys or WASD to move
          </div>
          <button
            @click="resetGame"
            class="cosmic-button"
          >
            Start Hunt
          </button>
        </div>
      </div>
    </div>

    <div class="text-center text-cosmic-400 text-xs max-w-md">
      ⭐ Normal (10pts) • 🌟 Special (25pts) • 💫 Bonus (50pts)<br/>
      Collect {{ starsNeeded }} stars to complete each constellation level!
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'

interface Star {
  id: number
  x: number
  y: number
  type: 'normal' | 'special' | 'bonus'
  collected: boolean
}

interface Bear {
  x: number
  y: number
  direction: 'up' | 'down' | 'left' | 'right'
}

interface Props {
  onGameEnd?: (score: number) => void
  isActive?: boolean
}

// Props
const props = withDefaults(defineProps<Props>(), {
  onGameEnd: () => {},
  isActive: true
})

// Emits
const emit = defineEmits<{
  (e: 'gameEnd', score: number): void
}>()

// Constants
const GAME_WIDTH = 500
const GAME_HEIGHT = 400
const BEAR_SIZE = 32
const STAR_SIZE = 16

// State
const bear = ref<Bear>({ x: 250, y: 200, direction: 'right' })
const bearTransitionX = ref(0)
const stars = ref<Star[]>([])
const score = ref(0)
const level = ref(1)
const starsCollected = ref(0)
const starsNeeded = ref(7) // Big Dipper has 7 stars
const gameOver = ref(false)
const gameStarted = ref(false)
const timeLeft = ref(90)
const starId = ref(0)
const gameLoopInterval = ref<number | null>(null)

// Generate random stars
const generateStars = (count: number) => {
  const newStars: Star[] = []
  for (let i = 0; i < count; i++) {
    const starType = Math.random() < 0.1 ? 'special' : Math.random() < 0.05 ? 'bonus' : 'normal'
    newStars.push({
      id: starId.value + i,
      x: Math.random() * (GAME_WIDTH - STAR_SIZE),
      y: Math.random() * (GAME_HEIGHT - STAR_SIZE),
      type: starType,
      collected: false
    })
  }
  starId.value += count
  return newStars
}

// Reset game
const resetGame = () => {
  bear.value = { x: 250, y: 200, direction: 'right' }
  bearTransitionX.value = 0
  stars.value = generateStars(15)
  score.value = 0
  level.value = 1
  starsCollected.value = 0
  starsNeeded.value = 7
  gameOver.value = false
  gameStarted.value = true
  timeLeft.value = 90
  starId.value = 0
  
  startGameLoop()
}

// Go to next level
const nextLevel = () => {
  level.value++
  starsCollected.value = 0
  starsNeeded.value += 2
  timeLeft.value += 30
  stars.value = generateStars(15 + level.value * 3)
  score.value += 100 // Level bonus
}

// Start game loop
const startGameLoop = () => {
  if (gameLoopInterval.value) {
    clearInterval(gameLoopInterval.value)
  }
  
  gameLoopInterval.value = window.setInterval(() => {
    if (!gameStarted.value || gameOver.value || !props.isActive) return
    
    // Update timer
    if (timeLeft.value <= 1) {
      endGame()
      return
    }
    timeLeft.value--
    
    // Check star collection
    checkStarCollection()
  }, 1000)
}

// End game
const endGame = () => {
  stopGameLoop()
  gameOver.value = true
  emit('gameEnd', score.value)
  props.onGameEnd(score.value)
}

// Stop game loop
const stopGameLoop = () => {
  if (gameLoopInterval.value) {
    clearInterval(gameLoopInterval.value)
    gameLoopInterval.value = null
  }
}

// Move the bear
const moveBear = (direction: 'up' | 'down' | 'left' | 'right') => {
  if (!gameStarted.value || gameOver.value) return

  // Update direction
  bear.value.direction = direction
  
  // Move bear
  switch (direction) {
    case 'up':
      bear.value.y = Math.max(0, bear.value.y - 8)
      bearTransitionX.value = 0
      break
    case 'down':
      bear.value.y = Math.min(GAME_HEIGHT - BEAR_SIZE, bear.value.y + 8)
      bearTransitionX.value = 0
      break
    case 'left':
      bear.value.x = Math.max(0, bear.value.x - 8)
      bearTransitionX.value = -8
      break
    case 'right':
      bear.value.x = Math.min(GAME_WIDTH - BEAR_SIZE, bear.value.x + 8)
      bearTransitionX.value = 8
      break
  }
  
  // Check for star collection
  checkStarCollection()
}

// Check if bear collects stars
const checkStarCollection = () => {
  stars.value = stars.value.map(star => {
    if (!star.collected &&
        bear.value.x < star.x + STAR_SIZE &&
        bear.value.x + BEAR_SIZE > star.x &&
        bear.value.y < star.y + STAR_SIZE &&
        bear.value.y + BEAR_SIZE > star.y) {
      
      // Collect star
      let points = 10
      if (star.type === 'special') points = 25
      if (star.type === 'bonus') points = 50
      
      score.value += points
      starsCollected.value++
      
      return { ...star, collected: true }
    }
    return star
  })
  
  // Check level completion
  if (starsCollected.value >= starsNeeded.value && gameStarted.value && !gameOver.value) {
    setTimeout(() => {
      nextLevel()
    }, 1000)
  }
}

// Keyboard event handlers
const handleKeyPress = (e: KeyboardEvent) => {
  if (!gameStarted.value || gameOver.value || !props.isActive) return
  
  switch (e.key) {
    case 'ArrowUp':
    case 'w':
    case 'W':
      moveBear('up')
      break
    case 'ArrowDown':
    case 's':
    case 'S':
      moveBear('down')
      break
    case 'ArrowLeft':
    case 'a':
    case 'A':
      moveBear('left')
      break
    case 'ArrowRight':
    case 'd':
    case 'D':
      moveBear('right')
      break
  }
}

// Helper methods
const getStarEmoji = (type: string) => {
  switch (type) {
    case 'special': return '🌟'
    case 'bonus': return '💫'
    default: return '⭐'
  }
}

const getStarColor = (type: string) => {
  switch (type) {
    case 'special': return 'from-star-400 to-star-600'
    case 'bonus': return 'from-purple-400 to-purple-600'
    default: return 'from-cosmic-400 to-cosmic-600'
  }
}

const getStarShadow = (type: string) => {
  switch (type) {
    case 'special': return '0 0 10px rgba(251, 191, 36, 0.8)'
    case 'bonus': return '0 0 20px rgba(147, 51, 234, 0.8)'
    default: return '0 0 10px rgba(99, 102, 241, 0.5)'
  }
}

// Watch for isActive changes
watch(() => props.isActive, (newValue) => {
  if (gameStarted.value && !gameOver.value) {
    if (newValue) {
      startGameLoop()
    } else {
      stopGameLoop()
    }
  }
})

// Lifecycle hooks
onMounted(() => {
  window.addEventListener('keydown', handleKeyPress)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyPress)
  stopGameLoop()
})
</script>

<style scoped>
.star-enter-active, 
.star-leave-active {
  transition: all 0.5s;
}

.star-enter-from {
  opacity: 0;
  transform: scale(0) rotate(0deg);
}

.star-leave-to {
  opacity: 0;
  transform: scale(0) rotate(360deg);
}

@keyframes star-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

@keyframes star-rotate {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.animate-bounce-slow {
  animation: bounce 2s infinite;
}

.animate-spin-slow {
  animation: spin 3s linear infinite;
}

@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>