<template>
  <div class="flex flex-col items-center space-y-4">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-xl font-bold text-white mb-2">👑 Cassiopeia's Royal Puzzles</h3>
      <p class="text-cosmic-300 text-sm mb-4">Connect the stars in the correct order to complete each constellation!</p>
      <div class="flex items-center justify-center space-x-6 text-cosmic-300">
        <div>Score: <span class="text-white font-bold">{{ score }}</span></div>
        <div>Time: <span class="text-white font-bold">{{ timeLeft }}s</span></div>
        <div>Puzzle: <span class="text-white font-bold">{{ currentPuzzle + 1 }}/{{ PUZZLES.length }}</span></div>
      </div>
    </div>

    <!-- Puzzle Title -->
    <div class="text-center">
      <h4 class="text-lg font-bold text-star-400">{{ PUZZLES[currentPuzzle]?.name }}</h4>
      <p class="text-cosmic-300 text-sm">{{ PUZZLES[currentPuzzle]?.description }}</p>
    </div>

    <!-- Game Board -->
    <div 
      class="relative bg-gradient-to-br from-space-900 to-cosmic-900 rounded-lg border-2 border-cosmic-500/50"
      style="width: 500px; height: 300px"
    >
      <!-- Background stars -->
      <div class="absolute inset-0 constellation-bg opacity-30"></div>

      <!-- Connection lines -->
      <svg class="absolute inset-0 w-full h-full">
        <line
          v-for="(starId, index) in connectedStars"
          v-if="index > 0"
          :key="`line-${connectedStars[index-1]}-${starId}`"
          :x1="getConnectedStar(connectedStars[index-1]).x + 12"
          :y1="getConnectedStar(connectedStars[index-1]).y + 12"
          :x2="getConnectedStar(starId).x + 12"
          :y2="getConnectedStar(starId).y + 12"
          stroke="url(#starGradient)"
          stroke-width="3"
          stroke-linecap="round"
          class="line-transition"
        />
        <defs>
          <linearGradient id="starGradient" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#fbbf24" />
            <stop offset="100%" stop-color="#f59e0b" />
          </linearGradient>
        </defs>
      </svg>

      <!-- Stars -->
      <TransitionGroup name="star">
        <button
          v-for="star in stars"
          :key="star.id"
          @click="handleStarClick(star.id)"
          :class="[
            'absolute w-6 h-6 rounded-full bg-gradient-to-r shadow-lg transition-all duration-200 flex items-center justify-center',
            getStarColor(star)
          ]"
          :style="{
            left: `${star.x}px`,
            top: `${star.y}px`,
            boxShadow: star.connected ? '0 0 20px rgba(251, 191, 36, 0.8)' : '0 0 10px rgba(99, 102, 241, 0.5)'
          }"
        >
          <span v-if="star.connected" class="text-xs font-bold text-white">{{ star.order }}</span>
          <div v-else class="w-2 h-2 bg-white rounded-full animate-pulse"></div>
        </button>
      </TransitionGroup>

      <!-- Puzzle Complete Animation -->
      <Transition>
        <div 
          v-if="puzzleComplete" 
          class="absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg"
        >
          <div class="text-center">
            <div class="text-6xl mb-4 animate-spin-slow">
              👑
            </div>
            <div class="text-white font-bold text-xl">Constellation Complete!</div>
            <div class="text-star-400">+{{ 100 + timeLeft * 2 }} points</div>
          </div>
        </div>
      </Transition>

      <!-- Game Over Overlay -->
      <div v-if="gameOver" class="absolute inset-0 bg-black/80 flex items-center justify-center rounded-lg">
        <div class="text-center">
          <div class="text-4xl mb-2">🌟</div>
          <div class="text-white font-bold mb-2">Royal Quest Complete!</div>
          <div class="text-cosmic-300 mb-4">Final Score: {{ score }}</div>
          <button
            @click="resetGame"
            class="cosmic-button"
          >
            New Quest
          </button>
        </div>
      </div>

      <!-- Start Game Overlay -->
      <div v-if="!gameStarted" class="absolute inset-0 bg-black/80 flex items-center justify-center rounded-lg">
        <div class="text-center">
          <div class="text-4xl mb-2">👑</div>
          <div class="text-white font-bold mb-2">Ready for the Royal Challenge?</div>
          <div class="text-cosmic-300 mb-4">
            Click stars in order to connect them
          </div>
          <button
            @click="resetGame"
            class="cosmic-button"
          >
            Begin Quest
          </button>
        </div>
      </div>
    </div>

    <div class="text-center text-cosmic-400 text-xs max-w-md">
      Click the stars in the correct sequence to form each constellation. Complete all puzzles before time runs out!
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue'

interface Star {
  id: number
  x: number
  y: number
  connected: boolean
  order?: number
}

interface Props {
  onGameEnd: (score: number) => void
  isActive: boolean
}

// Props and emits
const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'gameEnd', score: number): void
}>()

// Define the puzzle patterns
const CASSIOPEIA_PATTERN = [
  { x: 50, y: 150 },
  { x: 150, y: 100 },
  { x: 250, y: 50 },
  { x: 350, y: 100 },
  { x: 450, y: 150 }
]

const PUZZLES = [
  {
    name: "Cassiopeia's Crown",
    pattern: CASSIOPEIA_PATTERN,
    description: "Connect the stars to form the Queen's constellation"
  },
  {
    name: "The Royal Scepter",
    pattern: [
      { x: 200, y: 50 },
      { x: 200, y: 100 },
      { x: 200, y: 150 },
      { x: 180, y: 200 },
      { x: 220, y: 200 }
    ],
    description: "Trace the Queen's scepter"
  },
  {
    name: "Crown Jewels",
    pattern: [
      { x: 150, y: 100 },
      { x: 200, y: 80 },
      { x: 250, y: 60 },
      { x: 300, y: 80 },
      { x: 350, y: 100 },
      { x: 250, y: 150 }
    ],
    description: "Arrange the precious jewels"
  }
]

// State
const currentPuzzle = ref(0)
const stars = ref<Star[]>([])
const connectedStars = ref<number[]>([])
const score = ref(0)
const gameOver = ref(false)
const gameStarted = ref(false)
const puzzleComplete = ref(false)
const timeLeft = ref(60)
const timerInterval = ref<number | null>(null)

// Initialize the puzzle
const initializePuzzle = () => {
  const puzzle = PUZZLES[currentPuzzle.value]
  const shuffledStars = puzzle.pattern
    .map((pos, index) => ({
      id: index,
      x: pos.x + (Math.random() - 0.5) * 40, // Add some randomness
      y: pos.y + (Math.random() - 0.5) * 40,
      connected: false
    }))
    .sort(() => Math.random() - 0.5) // Shuffle the array

  stars.value = shuffledStars
  connectedStars.value = []
  puzzleComplete.value = false
}

// Reset the game
const resetGame = () => {
  currentPuzzle.value = 0
  score.value = 0
  gameOver.value = false
  gameStarted.value = true
  timeLeft.value = 60
  initializePuzzle()
  startTimer()
}

// Handle star click
const handleStarClick = (starId: number) => {
  if (!gameStarted.value || gameOver.value || puzzleComplete.value) return

  const star = stars.value.find(s => s.id === starId)
  if (!star || star.connected) return

  // Add to connected stars
  const newConnectedStars = [...connectedStars.value, starId]
  connectedStars.value = newConnectedStars

  // Update star state
  stars.value = stars.value.map(s => 
    s.id === starId ? { ...s, connected: true, order: newConnectedStars.length } : s
  )

  // Check if puzzle is complete
  if (newConnectedStars.length === stars.value.length) {
    puzzleComplete.value = true
    score.value += 100 + timeLeft.value * 2
    
    // Move to next puzzle after a delay
    setTimeout(() => {
      if (currentPuzzle.value < PUZZLES.length - 1) {
        currentPuzzle.value++
        initializePuzzle()
        timeLeft.value = 60
      } else {
        gameOver.value = true
        stopTimer()
        emit('gameEnd', score.value)
      }
    }, 2000)
  }
}

// Get star color based on state
const getStarColor = (star: Star) => {
  if (star.connected) {
    return 'from-star-400 to-star-600'
  }
  return 'from-cosmic-400 to-cosmic-600'
}

// Get a connected star by ID
const getConnectedStar = (starId: number): Star => {
  const star = stars.value.find(s => s.id === starId)
  return star || { id: -1, x: 0, y: 0, connected: false }
}

// Start the game timer
const startTimer = () => {
  if (timerInterval.value) clearInterval(timerInterval.value)
  
  timerInterval.value = window.setInterval(() => {
    if (timeLeft.value <= 1) {
      gameOver.value = true
      stopTimer()
      emit('gameEnd', score.value)
    } else {
      timeLeft.value--
    }
  }, 1000)
}

// Stop the timer
const stopTimer = () => {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
    timerInterval.value = null
  }
}

// Watch for changes
watch(() => currentPuzzle.value, () => {
  if (currentPuzzle.value < PUZZLES.length) {
    initializePuzzle()
  }
})

watch(() => gameOver.value, (newValue) => {
  if (newValue) {
    emit('gameEnd', score.value)
  }
})

watch(() => props.isActive, (isActive) => {
  if (!gameStarted.value || gameOver.value || puzzleComplete.value || !isActive) {
    stopTimer()
  } else if (gameStarted.value && !gameOver.value && !puzzleComplete.value && isActive) {
    startTimer()
  }
})

// Lifecycle hooks
onMounted(() => {
  if (currentPuzzle.value < PUZZLES.length) {
    initializePuzzle()
  }
})

onUnmounted(() => {
  stopTimer()
})
</script>

<style scoped>
.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.animate-spin-slow {
  animation: spin 2s linear infinite;
}

.line-transition {
  stroke-dasharray: 1000;
  stroke-dashoffset: 1000;
  animation: dash 0.5s ease-in-out forwards;
}

@keyframes dash {
  to {
    stroke-dashoffset: 0;
  }
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.5;
    transform: scale(1.1);
  }
}

.star-enter-active, 
.star-leave-active {
  transition: all 0.5s ease;
}

.star-enter-from, 
.star-leave-to {
  opacity: 0;
  transform: scale(0);
}
</style>