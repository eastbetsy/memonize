<template>
  <div class="flex flex-col items-center space-y-4">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-xl font-bold text-white mb-2">🏹 Orion's Hunt</h3>
      <p class="text-cosmic-300 text-sm mb-4">Hunt down cosmic asteroids with stellar precision!</p>
      <div class="text-cosmic-300">Score: <span class="text-white font-bold">{{ score }}</span></div>
    </div>

    <!-- Game Board -->
    <div 
      class="relative bg-gradient-to-b from-space-900 to-cosmic-900 rounded-lg border-2 border-cosmic-500/50 overflow-hidden"
      style="width: 400px; height: 500px"
    >
      <!-- Stars background -->
      <div class="absolute inset-0 constellation-bg opacity-50"></div>

      <!-- Player Ship -->
      <div
        class="absolute"
        :style="{
          left: `${playerPos.x}px`,
          top: `${playerPos.y}px`,
          width: `${PLAYER_WIDTH}px`,
          height: `${PLAYER_HEIGHT}px`,
          transform: `translateX(${playerTransitionX}px)`,
          transition: 'transform 0.1s'
        }"
      >
        <div class="text-2xl">🚀</div>
      </div>

      <!-- Bullets -->
      <TransitionGroup name="bullets">
        <div
          v-for="bullet in bullets"
          :key="bullet.id"
          class="absolute w-1 h-3 bg-gradient-to-t from-star-400 to-star-600 rounded-full shadow-lg shadow-star-500/50"
          :style="{
            left: `${bullet.x}px`,
            top: `${bullet.y}px`
          }"
        ></div>
      </TransitionGroup>

      <!-- Asteroids -->
      <TransitionGroup name="asteroids">
        <div
          v-for="asteroid in asteroids"
          :key="asteroid.id"
          class="absolute bg-gradient-to-br from-gray-400 to-gray-600 rounded-full shadow-lg"
          :style="{
            left: `${asteroid.x}px`,
            top: `${asteroid.y}px`,
            width: `${asteroid.size}px`,
            height: `${asteroid.size}px`,
            transform: 'rotate(0deg)',
            animation: 'rotate 2s linear infinite'
          }"
        >
          <div class="text-center leading-none" :style="{ fontSize: `${asteroid.size / 3}px` }">
            ☄️
          </div>
        </div>
      </TransitionGroup>

      <!-- Game Over Overlay -->
      <div v-if="gameOver" class="absolute inset-0 bg-black/80 flex items-center justify-center">
        <div class="text-center">
          <div class="text-4xl mb-2">🎯</div>
          <div class="text-white font-bold mb-2">Hunt Complete!</div>
          <div class="text-cosmic-300 mb-4">Final Score: {{ score }}</div>
          <button
            @click="resetGame"
            class="cosmic-button"
          >
            New Hunt
          </button>
        </div>
      </div>

      <!-- Start Game Overlay -->
      <div v-if="!gameStarted" class="absolute inset-0 bg-black/80 flex items-center justify-center">
        <div class="text-center">
          <div class="text-4xl mb-2">🏹</div>
          <div class="text-white font-bold mb-2">Ready to Hunt?</div>
          <div class="text-cosmic-300 mb-4">
            Arrow keys to move • Space to shoot
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

    <div class="text-center text-cosmic-400 text-xs">
      Use A/D or ← → to move • Space to shoot • Avoid asteroids!
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'

interface Asteroid {
  id: number
  x: number
  y: number
  speed: number
  size: number
}

interface Bullet {
  id: number
  x: number
  y: number
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

// Emit events
const emit = defineEmits<{
  (e: 'gameEnd', score: number): void
}>()

// Constants
const GAME_WIDTH = 400
const GAME_HEIGHT = 500
const PLAYER_WIDTH = 40
const PLAYER_HEIGHT = 40

// State
const playerPos = ref({ x: GAME_WIDTH / 2 - PLAYER_WIDTH / 2, y: GAME_HEIGHT - 60 })
const playerTransitionX = ref(0)
const bullets = ref<Bullet[]>([])
const asteroids = ref<Asteroid[]>([])
const score = ref(0)
const gameOver = ref(false)
const gameStarted = ref(false)
const bulletId = ref(0)
const asteroidId = ref(0)
const gameInterval = ref<number | null>(null)
const keys = ref({ left: false, right: false, space: false })

// Reset game state
const resetGame = () => {
  playerPos.value = { x: GAME_WIDTH / 2 - PLAYER_WIDTH / 2, y: GAME_HEIGHT - 60 }
  playerTransitionX.value = 0
  bullets.value = []
  asteroids.value = []
  score.value = 0
  gameOver.value = false
  gameStarted.value = true
  bulletId.value = 0
  asteroidId.value = 0
  startGameLoop()
}

// Shoot bullet
const shoot = () => {
  if (!gameStarted.value || gameOver.value) return
  
  bullets.value.push({
    id: bulletId.value,
    x: playerPos.value.x + PLAYER_WIDTH / 2 - 2,
    y: playerPos.value.y
  })
  bulletId.value++
}

// Spawn asteroid
const spawnAsteroid = () => {
  if (!gameStarted.value || gameOver.value) return

  const size = Math.random() * 20 + 15
  asteroids.value.push({
    id: asteroidId.value,
    x: Math.random() * (GAME_WIDTH - size),
    y: -size,
    speed: Math.random() * 3 + 2,
    size
  })
  asteroidId.value++
}

// Start the game loop
const startGameLoop = () => {
  if (gameInterval.value) {
    clearInterval(gameInterval.value)
  }
  
  gameInterval.value = window.setInterval(() => {
    if (!gameStarted.value || gameOver.value || !props.isActive) return
    
    // Move bullets
    bullets.value = bullets.value
      .map(bullet => ({ ...bullet, y: bullet.y - 8 }))
      .filter(bullet => bullet.y > -10)

    // Move asteroids and check collisions
    const newAsteroids = [] as Asteroid[]
    
    // Check for player collision
    for (const asteroid of asteroids.value) {
      const newY = asteroid.y + asteroid.speed
      
      // Check collision with player
      if (
        newY + asteroid.size > playerPos.value.y &&
        asteroid.x < playerPos.value.x + PLAYER_WIDTH &&
        asteroid.x + asteroid.size > playerPos.value.x
      ) {
        endGame()
        return
      }
      
      // Keep asteroid if still on screen
      if (newY < GAME_HEIGHT + asteroid.size) {
        newAsteroids.push({
          ...asteroid,
          y: newY
        })
      }
    }
    
    asteroids.value = newAsteroids
    
    // Check bullet-asteroid collisions
    const remainingBullets = [] as Bullet[]
    
    // Track asteroids to remove
    const hitAsteroidIds = new Set<number>()
    
    for (const bullet of bullets.value) {
      let hit = false
      
      // Check if bullet hits any asteroid
      for (const asteroid of asteroids.value) {
        if (hitAsteroidIds.has(asteroid.id)) continue
        
        if (
          bullet.x >= asteroid.x && 
          bullet.x <= asteroid.x + asteroid.size &&
          bullet.y >= asteroid.y && 
          bullet.y <= asteroid.y + asteroid.size
        ) {
          hitAsteroidIds.add(asteroid.id)
          score.value += Math.floor(asteroid.size)
          hit = true
          break
        }
      }
      
      // Keep bullet if no hit
      if (!hit) {
        remainingBullets.push(bullet)
      }
    }
    
    // Update bullets and asteroids
    bullets.value = remainingBullets
    asteroids.value = asteroids.value.filter(a => !hitAsteroidIds.has(a.id))
    
    // Spawn new asteroids randomly
    if (Math.random() < 0.03) {
      spawnAsteroid()
    }
    
    // Move player based on keys
    if (keys.value.left && playerPos.value.x > 0) {
      playerPos.value.x = Math.max(0, playerPos.value.x - 5)
      playerTransitionX.value = -5
    } else if (keys.value.right && playerPos.value.x < GAME_WIDTH - PLAYER_WIDTH) {
      playerPos.value.x = Math.min(GAME_WIDTH - PLAYER_WIDTH, playerPos.value.x + 5)
      playerTransitionX.value = 5
    } else {
      playerTransitionX.value = 0
    }
    
    // Shoot if space is pressed
    if (keys.value.space) {
      shoot()
      keys.value.space = false // Reset space to prevent continuous shooting
    }
  }, 16)
}

// End the game
const endGame = () => {
  gameOver.value = true
  stopGameLoop()
  emit('gameEnd', score.value)
  props.onGameEnd(score.value)
}

// Stop the game loop
const stopGameLoop = () => {
  if (gameInterval.value) {
    clearInterval(gameInterval.value)
    gameInterval.value = null
  }
}

// Handle key down events
const handleKeyDown = (e: KeyboardEvent) => {
  switch (e.code) {
    case 'ArrowLeft':
    case 'KeyA':
      keys.value.left = true
      break
    case 'ArrowRight':
    case 'KeyD':
      keys.value.right = true
      break
    case 'Space':
      e.preventDefault()
      keys.value.space = true
      break
  }
}

// Handle key up events
const handleKeyUp = (e: KeyboardEvent) => {
  switch (e.code) {
    case 'ArrowLeft':
    case 'KeyA':
      keys.value.left = false
      break
    case 'ArrowRight':
    case 'KeyD':
      keys.value.right = false
      break
    case 'Space':
      keys.value.space = false
      break
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

// Setup event listeners
onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
  window.addEventListener('keyup', handleKeyUp)
})

// Clean up
onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
  window.removeEventListener('keyup', handleKeyUp)
  stopGameLoop()
})
</script>

<style scoped>
.bullets-enter-active,
.bullets-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.bullets-enter-from {
  opacity: 0;
  transform: scale(0);
}

.bullets-leave-to {
  opacity: 0;
  transform: scale(0);
}

.asteroids-enter-active,
.asteroids-leave-active {
  transition: opacity 0.5s, transform 0.5s;
}

.asteroids-enter-from {
  opacity: 0;
  transform: scale(0) rotate(0deg);
}

.asteroids-leave-to {
  opacity: 0;
  transform: scale(0) rotate(360deg);
}

@keyframes rotate {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>