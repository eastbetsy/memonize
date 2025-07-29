<template>
  <div class="flex flex-col items-center space-y-4">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-xl font-bold text-white mb-2">🐉 Draco's Cosmic Journey</h3>
      <p class="text-cosmic-300 text-sm mb-4">Guide the cosmic dragon to collect stardust!</p>
      <div class="text-cosmic-300">Score: <span class="text-white font-bold">{{ score }}</span></div>
    </div>

    <!-- Game Board -->
    <div 
      class="relative bg-space-gradient rounded-lg border-2 border-cosmic-500/50"
      :style="{ 
        width: `${GRID_SIZE * 16}px`, 
        height: `${GRID_SIZE * 16}px`,
        backgroundImage: 'radial-gradient(circle at 25% 25%, rgba(99, 102, 241, 0.1) 0%, transparent 50%), radial-gradient(circle at 75% 75%, rgba(217, 70, 239, 0.1) 0%, transparent 50%)'
      }"
    >
      <!-- Snake -->
      <Transition v-for="(segment, index) in snake" :key="index" appear>
        <div
          class="absolute rounded-sm"
          :class="[
            index === 0 
              ? 'bg-gradient-to-r from-cosmic-400 to-cosmic-600 shadow-lg shadow-cosmic-500/50' 
              : 'bg-gradient-to-r from-cosmic-600 to-cosmic-800'
          ]"
          :style="{
            left: `${segment.x * 16}px`,
            top: `${segment.y * 16}px`,
            width: '14px',
            height: '14px',
            transform: index === 0 && direction.x === -1 ? 'scaleX(-1)' : ''
          }"
        >
          <div v-if="index === 0" class="text-xs text-center leading-3">🐲</div>
        </div>
      </Transition>

      <!-- Food -->
      <div
        class="absolute bg-gradient-to-r from-star-400 to-star-600 rounded-full shadow-lg shadow-star-500/50 animate-pulse"
        :style="{
          left: `${food.x * 16 + 2}px`,
          top: `${food.y * 16 + 2}px`,
          width: '10px',
          height: '10px'
        }"
      ></div>

      <!-- Game Over Overlay -->
      <div v-if="gameOver" class="absolute inset-0 bg-black/80 flex items-center justify-center rounded-lg">
        <div class="text-center">
          <div class="text-4xl mb-2">💫</div>
          <div class="text-white font-bold mb-2">Journey Complete!</div>
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
          <div class="text-4xl mb-2">🐉</div>
          <div class="text-white font-bold mb-2">Ready to Explore?</div>
          <div class="text-cosmic-300 mb-4">Use arrow keys to guide Draco</div>
          <button
            @click="resetGame"
            class="cosmic-button"
          >
            Start Journey
          </button>
        </div>
      </div>
    </div>

    <div class="text-center text-cosmic-400 text-xs">
      Use arrow keys to navigate • Collect stardust to grow longer
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'

interface Position {
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

// Emits
const emit = defineEmits<{
  (e: 'gameEnd', score: number): void
}>()

// Constants
const GRID_SIZE = 20
const INITIAL_SNAKE = [{ x: 10, y: 10 }]
const INITIAL_DIRECTION = { x: 0, y: -1 }

// State
const snake = ref<Position[]>(INITIAL_SNAKE)
const food = ref<Position>({ x: 15, y: 15 })
const direction = ref<Position>(INITIAL_DIRECTION)
const score = ref(0)
const gameOver = ref(false)
const gameStarted = ref(false)
const gameInterval = ref<number | null>(null)

// Generate random food position
const generateFood = () => {
  return {
    x: Math.floor(Math.random() * GRID_SIZE),
    y: Math.floor(Math.random() * GRID_SIZE)
  }
}

// Reset game state
const resetGame = () => {
  snake.value = INITIAL_SNAKE
  direction.value = INITIAL_DIRECTION
  food.value = generateFood()
  score.value = 0
  gameOver.value = false
  gameStarted.value = true
  startGameLoop()
}

// Move the snake
const moveSnake = () => {
  if (!gameStarted.value || gameOver.value || !props.isActive) return

  // Create new snake by copying current one
  const newSnake = [...snake.value]
  const head = { ...newSnake[0] }
  
  // Move head in current direction
  head.x += direction.value.x
  head.y += direction.value.y

  // Check wall collision
  if (head.x < 0 || head.x >= GRID_SIZE || head.y < 0 || head.y >= GRID_SIZE) {
    endGame()
    return
  }

  // Check self collision
  if (newSnake.some(segment => segment.x === head.x && segment.y === head.y)) {
    endGame()
    return
  }

  // Add new head to snake
  newSnake.unshift(head)

  // Check food collision
  if (head.x === food.value.x && head.y === food.value.y) {
    // Eat food - increase score and generate new food
    score.value += 10
    food.value = generateFood()
  } else {
    // Remove tail if no food eaten
    newSnake.pop()
  }

  // Update snake
  snake.value = newSnake
}

// Start the game loop
const startGameLoop = () => {
  if (gameInterval.value) {
    clearInterval(gameInterval.value)
  }
  gameInterval.value = window.setInterval(moveSnake, 150)
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

// Handle keyboard input
const handleKeyPress = (e: KeyboardEvent) => {
  if (!gameStarted.value || gameOver.value) return

  switch (e.key) {
    case 'ArrowUp':
      if (direction.value.y === 0) direction.value = { x: 0, y: -1 }
      break
    case 'ArrowDown':
      if (direction.value.y === 0) direction.value = { x: 0, y: 1 }
      break
    case 'ArrowLeft':
      if (direction.value.x === 0) direction.value = { x: -1, y: 0 }
      break
    case 'ArrowRight':
      if (direction.value.x === 0) direction.value = { x: 1, y: 0 }
      break
  }
}

// Watch for changes in isActive
watch(() => props.isActive, (newValue) => {
  if (gameStarted.value && !gameOver.value) {
    if (newValue && !gameInterval.value) {
      startGameLoop()
    } else if (!newValue && gameInterval.value) {
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
.v-enter-active {
  transition: all 0.2s ease-out;
}

.v-enter-from {
  opacity: 0;
  transform: scale(0);
}

@keyframes pulse {
  0%, 100% { 
    transform: scale(1); 
    opacity: 1;
  }
  50% { 
    transform: scale(1.2); 
    opacity: 0.8;
  }
}

.animate-pulse {
  animation: pulse 2s infinite;
}
</style>