<template>
  <div class="max-w-6xl mx-auto space-y-8">
    <!-- Header -->
    <div class="text-center">
      <div class="mb-6">
        <h1 class="text-2xl md:text-3xl lg:text-4xl font-bold text-glow mb-2">MemoQuest</h1>
        <p class="text-cosmic-300">Embark on epic study adventures through the galaxy</p>
      </div>

      <!-- Timer Display -->
      <div 
        v-if="gameSession.isActive"
        class="glass-card p-4 md:p-6 mb-6 md:mb-8 relative overflow-hidden mx-4"
      >
        <div 
          class="absolute inset-0" 
          :class="gameSession.breakTime ? 'bg-green-500/10' : 'bg-cosmic-500/10'"
        ></div>
        <div class="relative z-10">
          <div class="flex items-center justify-center space-x-2 md:space-x-4 mb-3 md:mb-4">
            <Clock class="h-6 w-6 text-cosmic-400" />
            <div class="text-2xl md:text-3xl font-bold text-white">
              {{ formatTime(gameSession.timeRemaining) }}
            </div>
          </div>
          <div class="text-sm md:text-base text-cosmic-300">
            {{ gameSession.breakTime ? '🧘 Break Time - Relax your mind' : '🚀 Focus Session - Maximum learning power!' }}
          </div>
          <div v-if="!gameSession.breakTime" class="grid grid-cols-3 gap-2 md:gap-4 mt-3 md:mt-4 text-center">
            <div>
              <div class="text-lg md:text-2xl font-bold text-cosmic-300">{{ gameSession.score }}</div>
              <div class="text-xs md:text-sm text-cosmic-400">Score</div>
            </div>
            <div>
              <div class="text-lg md:text-2xl font-bold text-cosmic-300">{{ gameSession.correctAnswers }}</div>
              <div class="text-xs md:text-sm text-cosmic-400">Correct</div>
            </div>
            <div>
              <div class="text-lg md:text-2xl font-bold text-cosmic-300">
                {{ gameSession.questionsAnswered > 0 
                  ? Math.round((gameSession.correctAnswers / gameSession.questionsAnswered) * 100) 
                  : 0 }}%
              </div>
              <div class="text-xs md:text-sm text-cosmic-400">Accuracy</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="!authStore.isAuthenticated" class="text-center py-20">
      <Rocket class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h2 class="text-2xl font-bold text-white mb-4">Sign in to access MemoQuest</h2>
      <p class="text-cosmic-300">Create an account to embark on your cosmic learning adventure</p>
    </div>

    <div v-else-if="!gameSession.isActive && !showResults">
      <div class="space-y-8">
        <!-- Ship Selection -->
        <div class="glass-card p-6 md:p-8 mx-4">
          <h2 class="text-xl md:text-2xl font-bold text-white mb-4 md:mb-6 flex items-center">
            <Rocket class="h-6 w-6 mr-2 text-cosmic-400" />
            Choose Your Constellation Ship
          </h2>
          
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
            <div
              v-for="ship in spaceships"
              :key="ship.id"
              class="glass-card p-4 md:p-6 cursor-pointer transition-all duration-300 relative overflow-hidden"
              :class="[
                selectedShip.id === ship.id 
                  ? 'border-cosmic-400 ring-2 ring-cosmic-400/50' 
                  : ship.unlocked 
                    ? 'hover:border-cosmic-400/50' 
                    : 'opacity-50 cursor-not-allowed'
              ]"
              @click="ship.unlocked && setSelectedShip(ship)"
            >
              <div v-if="!ship.unlocked" class="absolute inset-0 bg-black/50 flex items-center justify-center z-10">
                <div class="text-white font-bold">LOCKED</div>
              </div>
              
              <div class="text-center space-y-4">
                <div class="text-4xl">🚀</div>
                <h3 class="text-sm md:text-base font-bold text-white">{{ ship.name }}</h3>
                <p class="text-cosmic-300 text-xs md:text-sm">{{ ship.constellation }}</p>
                
                <div class="space-y-2">
                  <div class="flex items-center justify-between text-xs md:text-sm">
                    <span class="text-cosmic-400">Speed</span>
                    <div class="flex items-center space-x-1 text-xs md:text-sm">
                      <Zap class="h-4 w-4 text-star-400" />
                      <span class="text-white">{{ ship.speed }}</span>
                    </div>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-cosmic-400 text-sm">Defense</span>
                    <div class="flex items-center space-x-1">
                      <Shield class="h-4 w-4 text-cosmic-400" />
                      <span class="text-white">{{ ship.defense }}</span>
                    </div>
                  </div>
                </div>
                
                <div class="text-star-300 text-xs md:text-sm font-medium">
                  Special: {{ ship.special }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Game Settings -->
        <div class="glass-card p-6 md:p-8 mx-4">
          <h2 class="text-xl md:text-2xl font-bold text-white mb-4 md:mb-6 flex items-center">
            <Target class="h-6 w-6 mr-2 text-cosmic-400" />
            Mission Configuration
          </h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-8">
            <div>
              <label class="block text-cosmic-200 font-medium mb-2 md:mb-3">Mission Type</label>
              <div class="space-y-2">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="radio"
                    name="gameMode"
                    value="traditional"
                    :checked="gameMode === 'traditional'"
                    @change="gameMode = $event.target.value"
                    class="text-cosmic-500"
                  />
                  <span class="text-white">Traditional Study</span>
                </label>
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="radio"
                    name="gameMode"
                    value="browser_game"
                    :checked="gameMode === 'browser_game'"
                    @change="gameMode = $event.target.value"
                    class="text-cosmic-500"
                  />
                  <span class="text-white">Constellation Game</span>
                </label>
              </div>
            </div>

            <div>
              <label class="block text-cosmic-200 font-medium mb-2 md:mb-3">Study Mode</label>
              <div class="space-y-2">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="radio"
                    name="mode"
                    value="flashcards"
                    :checked="gameSession.mode === 'flashcards'"
                    @change="gameSession.mode = $event.target.value"
                    :disabled="gameMode === 'browser_game'"
                    class="text-cosmic-500"
                  />
                  <span class="text-white">Flashcard Review</span>
                </label>
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="radio"
                    name="mode"
                    value="mcq"
                    :checked="gameSession.mode === 'mcq'"
                    @change="gameSession.mode = $event.target.value"
                    :disabled="gameMode === 'browser_game'"
                    class="text-cosmic-500"
                  />
                  <span class="text-white">Multiple Choice Quiz</span>
                </label>
              </div>
            </div>
          </div>

          <div v-if="gameMode === 'traditional'" class="mt-4 md:mt-6">
            <label class="block text-cosmic-200 font-medium mb-2 md:mb-3">Difficulty Level</label>
            <div class="flex flex-wrap gap-4">
              <label 
                v-for="diff in ['easy', 'medium', 'hard']" 
                :key="diff" 
                class="flex items-center space-x-3 cursor-pointer"
              >
                <input
                  type="radio"
                  name="difficulty"
                  :value="diff"
                  :checked="gameSession.difficulty === diff"
                  @change="gameSession.difficulty = $event.target.value"
                  class="text-cosmic-500"
                />
                <span 
                  class="px-2 py-1 rounded text-xs font-medium bg-gradient-to-r text-white"
                  :class="getDifficultyColor(diff)"
                >
                  {{ diff.toUpperCase() }}
                </span>
              </label>
            </div>
          </div>

          <div class="mt-6 md:mt-8 text-center">
            <button
              @click="gameMode === 'browser_game' ? startBrowserGame() : startSession()"
              class="cosmic-button text-base md:text-lg px-6 md:px-8 py-3 md:py-4 flex items-center space-x-2 mx-auto w-full sm:w-auto"
            >
              <Play class="h-5 w-5" />
              <span>{{ gameMode === 'browser_game' ? 'Launch Game' : 'Launch Mission' }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Active Game Session -->
    <div v-else-if="browserGameActive" class="space-y-6 mx-4">
      <!-- Game Controls -->
      <div class="flex flex-col sm:flex-row justify-center gap-3 sm:gap-4">
        <button
          @click="endSession"
          class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg transition-colors flex items-center justify-center space-x-2 w-full sm:w-auto"
        >
          <RotateCcw class="h-4 w-4" />
          <span>End Game</span>
        </button>
      </div>

      <!-- Browser Game -->
      <component 
        :is="getBrowserGameComponent()"
        :onGameEnd="handleGameEnd" 
        :isActive="gameSession.isActive" 
      />
    </div>

    <div v-else-if="gameSession.isActive && !gameSession.breakTime" class="space-y-6 mx-4">
      <!-- Game Controls -->
      <div class="flex flex-col sm:flex-row justify-center gap-3 sm:gap-4">
        <button
          @click="pauseSession"
          class="nebula-button flex items-center justify-center space-x-2 w-full sm:w-auto"
        >
          <component :is="gameSession.isActive ? Pause : Play" class="h-4 w-4" />
          <span>{{ gameSession.isActive ? 'Pause' : 'Resume' }}</span>
        </button>
        <button
          @click="endSession"
          class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg transition-colors flex items-center justify-center space-x-2 w-full sm:w-auto"
        >
          <RotateCcw class="h-4 w-4" />
          <span>End Mission</span>
        </button>
      </div>

      <!-- Question Display -->
      <div v-if="gameSession.mode === 'mcq' && !browserGameActive" class="glass-card p-6 md:p-8">
        <div class="mb-4 md:mb-6">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-4 gap-2">
            <span class="text-cosmic-400 text-sm md:text-base">
              Question {{ currentQuestion + 1 }} of {{ sampleQuestions.length }}
            </span>
            <span 
              class="px-3 py-1 rounded-full text-xs font-medium bg-gradient-to-r text-white"
              :class="getDifficultyColor(sampleQuestions[currentQuestion].difficulty)"
            >
              {{ sampleQuestions[currentQuestion].difficulty }}
            </span>
          </div>
            
          <h3 class="text-lg md:text-xl font-bold text-white mb-4 md:mb-6">
            {{ sampleQuestions[currentQuestion].question }}
          </h3>
        </div>

        <div class="space-y-3">
          <button
            v-for="(option, index) in sampleQuestions[currentQuestion].options"
            :key="index"
            @click="answerQuestion(index)"
            :disabled="selectedAnswer !== null"
            :class="[
              'w-full p-4 text-left rounded-lg transition-all',
              selectedAnswer === null
                ? 'bg-white/5 border border-white/10 hover:bg-white/10 hover:border-cosmic-400/50 text-white'
                : selectedAnswer === index
                  ? index === sampleQuestions[currentQuestion].correct
                    ? 'bg-green-500/20 border-green-500 text-green-300'
                    : 'bg-red-500/20 border-red-500 text-red-300'
                  : index === sampleQuestions[currentQuestion].correct
                    ? 'bg-green-500/20 border-green-500 text-green-300'
                    : 'bg-white/5 border-white/10 text-cosmic-400'
            ]"
          >
            {{ option }}
          </button>
        </div>
      </div>
    </div>

    <!-- Break Time -->
    <div v-else-if="gameSession.isActive && gameSession.breakTime" class="text-center py-12 md:py-20 mx-4">
      <div class="text-6xl mb-6">🧘‍♀️</div>
      <h2 class="text-2xl md:text-3xl font-bold text-green-400 mb-4">Break Time!</h2>
      <p class="text-cosmic-300 mb-6 md:mb-8">Rest your mind and prepare for the next learning session</p>
      <div class="text-xl md:text-2xl font-bold text-white">
        {{ formatTime(gameSession.timeRemaining) }}
      </div>
    </div>

    <!-- Results Screen -->
    <div v-else-if="showResults" class="glass-card p-6 md:p-8 text-center mx-4">
      <!-- Level Up Animation -->
      <Transition>
        <div 
          v-if="levelUp" 
          class="absolute inset-0 flex items-center justify-center bg-black/50 rounded-xl z-10"
        >
          <div class="text-center">
            <div class="text-8xl mb-4 animate-spin-slow">
              🌟
            </div>
            <div class="text-3xl font-bold text-star-400 mb-2">LEVEL UP!</div>
            <div class="text-cosmic-300">You've reached a new cosmic level!</div>
          </div>
        </div>
      </Transition>
      
      <Trophy class="h-16 w-16 text-star-400 mx-auto mb-6" />
      <h2 class="text-2xl md:text-3xl font-bold text-white mb-4 md:mb-6">Mission Complete!</h2>
      
      <!-- Enhanced Results -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 md:gap-6 mb-6 md:mb-8">
        <div class="glass-card p-4 md:p-6">
          <Star class="h-8 w-8 text-star-400 mx-auto mb-2" />
          <div class="text-xl md:text-2xl font-bold text-white">{{ gameSession.score }}</div>
          <div class="text-sm md:text-base text-cosmic-300">Total Score</div>
        </div>
        <div class="glass-card p-4 md:p-6">
          <Target class="h-8 w-8 text-cosmic-400 mx-auto mb-2" />
          <div class="text-xl md:text-2xl font-bold text-white">{{ gameSession.correctAnswers }}</div>
          <div class="text-sm md:text-base text-cosmic-300">Correct Answers</div>
        </div>
        <div class="glass-card p-4 md:p-6">
          <Trophy class="h-8 w-8 text-nebula-400 mx-auto mb-2" />
          <div class="text-xl md:text-2xl font-bold text-white">
            {{ gameSession.questionsAnswered > 0 
              ? Math.round((gameSession.correctAnswers / gameSession.questionsAnswered) * 100) 
              : 0 }}%
          </div>
          <div class="text-sm md:text-base text-cosmic-300">Accuracy</div>
        </div>
        <div class="glass-card p-4 md:p-6">
          <Sparkles class="h-8 w-8 text-green-400 mx-auto mb-2" />
          <div class="text-xl md:text-2xl font-bold text-white">+{{ experienceGained }}</div>
          <div class="text-sm md:text-base text-cosmic-300">Experience</div>
        </div>
      </div>
      
      <!-- Achievements -->
      <div v-if="achievements.length > 0" class="mb-6">
        <h3 class="text-lg font-bold text-white mb-3">🏆 Achievements Unlocked!</h3>
        <div class="flex flex-wrap justify-center gap-2">
          <div
            v-for="(achievement, index) in achievements"
            :key="index"
            class="px-3 py-1 bg-star-500/20 text-star-300 rounded-full text-sm font-medium"
          >
            {{ achievement }}
          </div>
        </div>
      </div>
      
      <button
        @click="resetResults"
        class="cosmic-button text-base md:text-lg px-6 md:px-8 py-3 md:py-4 w-full sm:w-auto"
      >
        New Mission
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch, h } from 'vue'
import { 
  Rocket, 
  Play, 
  Pause, 
  RotateCcw, 
  Star, 
  Clock,
  Trophy,
  Target,
  Zap,
  Shield,
  Sparkles
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

// Placeholder for components that would be imported when built
const DracoSnakeGame = defineComponent({})
const OrionShooterGame = defineComponent({})
const CassiopeiaPuzzleGame = defineComponent({})
const UrsaMajorCollectorGame = defineComponent({})

function defineComponent(options = {}) {
  return {
    render() {
      return h('div', { class: 'text-center py-10' }, [
        h('p', { class: 'text-cosmic-300 mb-3' }, 'Game component placeholder'),
        h('p', { class: 'text-cosmic-400 text-sm' }, 'Full game implementation coming soon')
      ])
    }
  }
}

interface Spaceship {
  id: string
  name: string
  constellation: string
  speed: number
  defense: number
  special: string
  unlocked: boolean
}

interface GameSession {
  isActive: boolean
  mode: 'flashcards' | 'mcq'
  difficulty: 'easy' | 'medium' | 'hard'
  timeRemaining: number
  breakTime: boolean
  score: number
  questionsAnswered: number
  correctAnswers: number
}

// Auth store
const authStore = useAuthStore()

// State
const spaceships = ref<Spaceship[]>([
  {
    id: 'draco',
    name: 'Dragon Star',
    constellation: 'Draco',
    speed: 85,
    defense: 90,
    special: 'Cosmic Journey',
    unlocked: true
  },
  {
    id: 'orion',
    name: 'Hunter\'s Pride',
    constellation: 'Orion',
    speed: 95,
    defense: 75,
    special: 'Stellar Hunt',
    unlocked: true
  },
  {
    id: 'cassiopeia',
    name: 'Queen\'s Grace',
    constellation: 'Cassiopeia',
    speed: 80,
    defense: 95,
    special: 'Royal Puzzles',
    unlocked: true
  },
  {
    id: 'ursa_major',
    name: 'Bear Claw',
    constellation: 'Ursa Major',
    speed: 70,
    defense: 100,
    special: 'Star Collection',
    unlocked: true
  }
])

const selectedShip = ref<Spaceship>(spaceships.value[0])
const gameSession = ref<GameSession>({
  isActive: false,
  mode: 'flashcards',
  difficulty: 'medium',
  timeRemaining: 25 * 60, // 25 minutes in seconds
  breakTime: false,
  score: 0,
  questionsAnswered: 0,
  correctAnswers: 0
})
const currentQuestion = ref(0)
const showResults = ref(false)
const selectedAnswer = ref<number | null>(null)
const gameMode = ref<'traditional' | 'browser_game'>('traditional')
const browserGameActive = ref(false)
const achievements = ref<string[]>([])
const experienceGained = ref(0)
const levelUp = ref(false)
const timerInterval = ref<number | null>(null)

const sampleQuestions = [
  {
    question: "What is the constellation Draco known for?",
    options: ["A dragon wrapped around the celestial pole", "A hunter with a belt", "A queen sitting on a throne", "A great bear"],
    correct: 0,
    difficulty: "medium"
  },
  {
    question: "How many stars form the Big Dipper?",
    options: ["5", "6", "7", "8"],
    correct: 2,
    difficulty: "easy"
  },
  {
    question: "What is spaced repetition?",
    options: ["Repeating words quickly", "Learning at increasing intervals", "Studying for long periods", "Taking frequent breaks"],
    correct: 1,
    difficulty: "medium"
  },
  {
    question: "Which is the brightest star in the night sky?",
    options: ["Polaris", "Vega", "Sirius", "Arcturus"],
    correct: 2,
    difficulty: "hard"
  }
]

// Computed properties
const currentShipComponent = computed(() => {
  switch (selectedShip.value.id) {
    case 'draco': return DracoSnakeGame
    case 'orion': return OrionShooterGame
    case 'cassiopeia': return CassiopeiaPuzzleGame
    case 'ursa_major': return UrsaMajorCollectorGame
    default: return DracoSnakeGame
  }
})

// Methods
function setSelectedShip(ship: Spaceship) {
  selectedShip.value = ship
}

function startSession() {
  gameSession.value = {
    isActive: true,
    mode: gameSession.value.mode,
    difficulty: gameSession.value.difficulty,
    timeRemaining: 25 * 60,
    breakTime: false,
    score: 0,
    questionsAnswered: 0,
    correctAnswers: 0
  }
  currentQuestion.value = 0
  showResults.value = false
  startTimer()
}

function pauseSession() {
  if (gameSession.value.isActive) {
    gameSession.value.isActive = false
    stopTimer()
  } else {
    gameSession.value.isActive = true
    startTimer()
  }
}

function endSession() {
  stopTimer()
  gameSession.value.isActive = false
  browserGameActive.value = false
  showResults.value = true
}

function startBrowserGame() {
  browserGameActive.value = true
  gameSession.value = {
    isActive: true,
    mode: gameSession.value.mode,
    difficulty: gameSession.value.difficulty,
    timeRemaining: 25 * 60,
    breakTime: false,
    score: 0,
    questionsAnswered: 0,
    correctAnswers: 0
  }
  startTimer()
}

function handleGameEnd(gameScore: number) {
  // Calculate experience and achievements
  const baseExp = Math.floor(gameScore / 10)
  const bonusExp = gameSession.value.timeRemaining > 0 ? 50 : 0
  const totalExp = baseExp + bonusExp
  
  // Award XP through auth context
  authStore.addExperience(totalExp, "Completed MemoQuest Gaming Session")

  experienceGained.value = totalExp
  
  // Check for achievements
  const newAchievements = []
  if (gameScore > 1000) newAchievements.push('High Scorer')
  if (gameSession.value.timeRemaining > 300) newAchievements.push('Speed Demon')
  if (gameScore > 0) newAchievements.push('First Victory')
  
  achievements.value = newAchievements
  
  // Check for level up (simplified)
  if (totalExp > 100) {
    levelUp.value = true
    setTimeout(() => {
      levelUp.value = false
    }, 3000)
  }
  
  gameSession.value.score += gameScore + bonusExp
  gameSession.value.questionsAnswered += 1
  gameSession.value.correctAnswers += 1 // Browser games always count as correct
  
  browserGameActive.value = false
  
  // Continue session or end based on time
  if (gameSession.value.timeRemaining <= 0) {
    endSession()
  }
}

function answerQuestion(answerIndex: number) {
  selectedAnswer.value = answerIndex
  const isCorrect = answerIndex === sampleQuestions[currentQuestion.value].correct

  // Award XP for correct answers in MemoQuest
  if (isCorrect) {
    const xpAmount = 10 * (currentQuestion.value + 1) // More XP for later questions
    authStore.addExperience(xpAmount, "Correct MemoQuest Answer")
  }

  setTimeout(() => {
    gameSession.value.questionsAnswered += 1
    gameSession.value.correctAnswers += isCorrect ? 1 : 0
    gameSession.value.score += isCorrect ? 10 : 0
    
    currentQuestion.value = (currentQuestion.value + 1) % sampleQuestions.length
    selectedAnswer.value = null
  }, 1500)
}

function formatTime(seconds: number) {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

function getDifficultyColor(difficulty: string) {
  switch (difficulty) {
    case 'easy': return 'from-green-500 to-green-600'
    case 'medium': return 'from-star-500 to-star-600'
    case 'hard': return 'from-red-500 to-red-600'
    default: return 'from-cosmic-500 to-cosmic-600'
  }
}

function getBrowserGameComponent() {
  switch (selectedShip.value.id) {
    case 'draco': return DracoSnakeGame
    case 'orion': return OrionShooterGame
    case 'cassiopeia': return CassiopeiaPuzzleGame
    case 'ursa_major': return UrsaMajorCollectorGame
    default: return DracoSnakeGame
  }
}

function resetResults() {
  showResults.value = false
  achievements.value = []
  experienceGained.value = 0
  levelUp.value = false
}

function startTimer() {
  if (timerInterval.value) clearInterval(timerInterval.value)
  
  timerInterval.value = window.setInterval(() => {
    if (gameSession.value.timeRemaining <= 0) {
      handleSessionComplete()
    } else {
      gameSession.value.timeRemaining -= 1
    }
  }, 1000)
}

function stopTimer() {
  if (timerInterval.value) {
    clearInterval(timerInterval.value)
    timerInterval.value = null
  }
}

function handleSessionComplete() {
  stopTimer()
  
  if (gameSession.value.breakTime) {
    // End break, start new work session
    gameSession.value.timeRemaining = 25 * 60
    gameSession.value.breakTime = false
    startTimer()
  } else {
    // End work, start break
    gameSession.value.timeRemaining = 5 * 60
    gameSession.value.breakTime = true
    startTimer()
  }
}

// Lifecycle hooks
onMounted(() => {
  // Clear any existing intervals first
  if (timerInterval.value) clearInterval(timerInterval.value)
})

onUnmounted(() => {
  // Clean up timer when component is destroyed
  if (timerInterval.value) clearInterval(timerInterval.value)
})
</script>