<template>
  <div class="max-w-5xl mx-auto space-y-8">
    <div class="text-center mb-4">
      <h1 class="text-2xl md:text-3xl font-bold text-glow mb-2">Boss Battle Challenge</h1>
      <p class="text-cosmic-300">Conquer your most challenging flashcards!</p>
    </div>
    
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
    </div>

    <div v-else-if="challengeCards.length === 0" class="glass-card p-8 text-center">
      <Trophy class="h-16 w-16 text-star-400 mx-auto mb-4" />
      <h3 class="text-xl font-bold text-white mb-2">No Challenge Cards Found</h3>
      <p class="text-cosmic-300 mb-6">
        Great job! It looks like you don't have any challenging flashcards right now.
        Keep studying to maintain your mastery!
      </p>
      <button
        @click="$emit('close')"
        class="cosmic-button"
      >
        Return to Flashcards
      </button>
    </div>
    
    <div v-else-if="battleStatus === 'victory' || battleStatus === 'defeat'" class="glass-card p-8 text-center">
      <div class="text-6xl mb-6">
        {{ battleStatus === 'victory' ? '🏆' : '😓' }}
      </div>
      <h3 class="text-2xl font-bold text-white mb-2">
        {{ battleStatus === 'victory' ? 'Victory!' : 'Defeated!' }}
      </h3>
      <p class="text-xl text-cosmic-300 mb-4">
        {{ battleStatus === 'victory' 
          ? 'You conquered the knowledge guardian!' 
          : 'The challenge was tough, but you learned a lot!' }}
      </p>
      
      <div class="grid grid-cols-2 gap-4 mb-6">
        <div class="glass-card p-4">
          <div class="text-2xl font-bold text-cosmic-300">{{ playerStats.score }}</div>
          <div class="text-sm text-cosmic-400">Final Score</div>
        </div>
        <div class="glass-card p-4">
          <div class="text-2xl font-bold text-cosmic-300">{{ playerStats.cardsImproved }}</div>
          <div class="text-sm text-cosmic-400">Cards Improved</div>
        </div>
      </div>
      
      <div class="flex space-x-4 justify-center">
        <button
          @click="restartBattle"
          class="cosmic-button"
        >
          Try Again
        </button>
        <button
          @click="$emit('close')"
          class="nebula-button"
        >
          Exit Battle
        </button>
      </div>
    </div>

    <div v-else>
      <!-- Battle Header -->
      <div class="glass-card p-6">
        <div class="flex justify-between items-center">
          <div class="flex items-center space-x-3">
            <div class="p-2 bg-cosmic-500 rounded-full">
              <Shield class="h-5 w-5 text-white" />
            </div>
            <div>
              <div class="text-sm text-cosmic-300">Player</div>
              <div class="flex items-center space-x-2">
                <div class="w-32 h-3 bg-cosmic-900 rounded-full">
                  <div 
                    class="h-3 bg-green-500 rounded-full transition-all duration-500"
                    :style="{ width: `${playerStats.health}%` }"
                  />
                </div>
                <div class="text-xs text-green-400">{{ playerStats.health }}</div>
              </div>
            </div>
          </div>
          
          <div class="text-center">
            <div class="text-lg font-bold text-white mb-1">Boss Battle</div>
            <div class="flex items-center space-x-1">
              <Flame v-for="i in Math.min(5, playerStats.streak)" :key="i" class="h-4 w-4 text-star-400" />
              <div v-if="playerStats.streak > 0" class="text-xs text-cosmic-300 ml-1">
                Streak: {{ playerStats.streak }}
              </div>
            </div>
          </div>
          
          <div class="flex items-center space-x-3">
            <div>
              <div class="text-sm text-cosmic-300 text-right">{{ bossStats.name }}</div>
              <div class="flex items-center space-x-2">
                <div class="text-xs text-red-400">{{ bossStats.health }}</div>
                <div class="w-32 h-3 bg-cosmic-900 rounded-full">
                  <div 
                    class="h-3 bg-red-500 rounded-full transition-all duration-500"
                    :style="{ width: `${bossStats.health}%` }"
                  />
                </div>
              </div>
            </div>
            <div class="p-2 bg-red-500 rounded-full">
              <Swords class="h-5 w-5 text-white" />
            </div>
          </div>
        </div>
        
        <!-- Battle Stats -->
        <div class="grid grid-cols-3 gap-4 mt-4 text-center text-sm">
          <div>
            <div class="text-cosmic-300">Score</div>
            <div class="text-white font-bold">{{ playerStats.score }}</div>
          </div>
          <div>
            <div class="text-cosmic-300">Power-ups</div>
            <div class="text-white font-bold">
              <Zap v-for="i in playerStats.powerups" :key="i" class="inline-block h-4 w-4 text-yellow-400 mx-0.5" />
              <span v-if="playerStats.powerups === 0">None</span>
            </div>
          </div>
          <div>
            <div class="text-cosmic-300">Card</div>
            <div class="text-white font-bold">{{ currentIndex + 1 }}/{{ challengeCards.length }}</div>
          </div>
        </div>
      </div>
      
      <!-- Flashcard -->
      <div class="flex justify-center">
        <div
          class="relative w-full max-w-2xl h-64 md:h-80 cursor-pointer mx-4"
          @click="isFlipped = !isFlipped"
        >
          <Transition name="flip" mode="out-in">
            <div
              :key="isFlipped ? 'back' : 'front'"
              class="glass-card p-6 md:p-8 h-full flex flex-col justify-center items-center text-center relative overflow-hidden"
            >
              <div class="absolute inset-0 bg-gradient-to-br from-red-500/20 to-purple-500/20 opacity-30"></div>
              
              <!-- Challenge badge -->
              <div class="absolute top-3 left-3 md:top-4 md:left-4 px-2 md:px-3 py-1 rounded-full text-xs font-medium bg-gradient-to-r from-red-500 to-purple-600 text-white flex items-center space-x-1">
                <Swords class="h-3 w-3" />
                <span>Boss Challenge</span>
              </div>

              <!-- Difficulty & Confidence -->
              <div class="absolute top-3 right-3 md:top-4 md:right-4 flex items-center space-x-2">
                <div class="px-2 py-0.5 bg-white/10 rounded-full text-xs text-white">
                  {{ currentCard.difficulty }}
                </div>
                <div class="flex items-center">
                  <Star 
                    v-for="i in 5" 
                    :key="i" 
                    :class="[
                      'h-3 w-3',
                      i < currentCard.confidence_level 
                        ? `${getConfidenceColor(currentCard.confidence_level)} fill-current` 
                        : 'text-cosmic-600'
                    ]" 
                  />
                </div>
              </div>

              <div class="relative z-10">
                <div class="text-xs md:text-sm text-cosmic-400 mb-3 md:mb-4">
                  {{ isFlipped ? 'Answer' : 'Question' }}
                </div>
                
                <h2 class="text-lg md:text-xl lg:text-2xl font-bold text-white mb-3 md:mb-4 leading-relaxed px-2">
                  {{ isFlipped ? currentCard.definition : currentCard.term }}
                </h2>
                
                <div class="text-cosmic-300 text-xs md:text-sm">
                  Click to {{ isFlipped ? 'see question' : 'reveal answer' }}
                </div>
              </div>
            </div>
          </Transition>
        </div>
      </div>
      
      <!-- Hint Display -->
      <Transition>
        <div v-if="showHint" class="glass-card p-4 bg-yellow-500/10 border border-yellow-500/30">
          <div class="flex items-center text-yellow-300 mb-1">
            <Lightbulb class="h-4 w-4 mr-1" />
            <span class="font-medium">Power-up Hint:</span>
          </div>
          <div class="text-cosmic-100">{{ hint }}</div>
        </div>
      </Transition>
      
      <!-- Controls -->
      <div class="flex flex-col space-y-4">
        <!-- Answer Buttons - Only show when card is flipped -->
        <div v-if="isFlipped" class="flex justify-center gap-4">
          <button
            @click="() => handleAnswer(false)"
            class="flex-1 flex items-center justify-center space-x-2 py-3 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors"
          >
            <XCircle class="h-5 w-5" />
            <span>Didn't Know It</span>
          </button>
          
          <button
            @click="() => handleAnswer(true)"
            class="flex-1 flex items-center justify-center space-x-2 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors"
          >
            <CheckCircle class="h-5 w-5" />
            <span>Got It Right!</span>
          </button>
        </div>
        
        <!-- Power-up Buttons -->
        <div class="flex justify-center gap-4">
          <button
            @click="usePowerup"
            :disabled="playerStats.powerups <= 0 || showHint"
            class="nebula-button flex items-center justify-center space-x-2 py-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Zap class="h-5 w-5" />
            <span>Use Power-up</span>
            <span class="ml-1 text-xs">({{ playerStats.powerups }} left)</span>
          </button>
          
          <button
            @click="$emit('close')"
            class="px-4 py-2 bg-white/10 hover:bg-white/20 text-cosmic-300 hover:text-white rounded-lg transition-colors"
          >
            Exit Battle
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Swords,
  Shield, 
  Flame,
  Star, 
  CheckCircle, 
  XCircle,
  Zap,
  Lightbulb,
  Trophy
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface Flashcard {
  id: string
  term: string
  definition: string
  difficulty: 'easy' | 'medium' | 'hard'
  confidence_level: number
}

interface Props {
  userId: string
  onComplete: (score: number, cardsImproved: number) => void
}

// Props and emits
const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'close'): void
  (e: 'complete', score: number, cardsImproved: number): void
}>()

// State
const challengeCards = ref<Flashcard[]>([])
const currentIndex = ref(0)
const isFlipped = ref(false)
const loading = ref(true)
const playerStats = ref({
  health: 100,
  score: 0,
  streak: 0,
  powerups: 2,
  cardsImproved: 0
})
const bossStats = ref({
  health: 100,
  name: 'Knowledge Guardian'
})
const battleStatus = ref<'active' | 'victory' | 'defeat'>('active')
const showHint = ref(false)
const hint = ref('')

// Composables
const toast = useToast()
const authStore = useAuthStore()

// Computed
const currentCard = computed<Flashcard>(() => {
  if (challengeCards.value.length === 0) {
    return {
      id: '',
      term: '',
      definition: '',
      difficulty: 'medium',
      confidence_level: 0
    }
  }
  return challengeCards.value[currentIndex.value]
})

// Lifecycle hooks
onMounted(() => {
  fetchChallengingCards()
})

// Methods
const fetchChallengingCards = async () => {
  try {
    // In a real application, this would be a more sophisticated query
    // that identifies the user's most challenging cards based on:
    // - Low confidence levels
    // - Incorrect answer history
    // - Cards marked as difficult
    // - Cards that haven't been reviewed in a while
    
    const { data, error } = await supabase
      .from('flashcards')
      .select('*')
      .eq('user_id', props.userId)
      .or('confidence_level.lt.3,difficulty.eq.hard')
      .order('confidence_level', { ascending: true })
      .limit(10)

    if (error) throw error
    
    if (!data || data.length === 0) {
      // If no challenging cards found, get some random cards
      const { data: fallbackData, error: fallbackError } = await supabase
        .from('flashcards')
        .select('*')
        .eq('user_id', props.userId)
        .order('created_at', { ascending: false })
        .limit(10)
        
      if (fallbackError) throw fallbackError
      challengeCards.value = fallbackData || []
    } else {
      challengeCards.value = data
    }
    
    // Set boss name based on the challenging topics
    if (data && data.length > 0) {
      const topics = extractTopics(data)
      if (topics.length > 0) {
        bossStats.value.name = `${topics[0]} Guardian`
      }
    }
  } catch (error) {
    console.error('Failed to fetch challenging cards:', error)
    toast.error('Failed to load challenge cards')
  } finally {
    loading.value = false
  }
}

const extractTopics = (cards: Flashcard[]): string[] => {
  // This is a simple implementation - in a real app you would use
  // more sophisticated topic extraction
  const topics = new Set<string>()
  const commonWords = ['a', 'an', 'the', 'in', 'on', 'at', 'by', 'for', 'with', 'about']
  
  cards.forEach(card => {
    const term = card.term.toLowerCase()
      .replace(/what is|what are|define|explain/gi, '')
      .replace(/\?/g, '')
      .trim()
    
    const words = term.split(' ')
    if (words.length > 0) {
      // Get the first significant word
      const topic = words.find(word => 
        word.length > 3 && !commonWords.includes(word.toLowerCase())
      )
      if (topic) topics.add(topic.charAt(0).toUpperCase() + topic.slice(1))
    }
  })
  
  return Array.from(topics)
}

const handleAnswer = (isCorrect: boolean) => {
  if (battleStatus.value !== 'active') return
  
  let playerDamage = 0
  let bossDamage = 0
  
  if (isCorrect) {
    // Player damages boss
    const damage = 10 + (playerStats.value.streak * 2)
    bossDamage = Math.min(damage, bossStats.value.health)
    
    // Update player stats
    playerStats.value = {
      ...playerStats.value,
      score: playerStats.value.score + (damage * 10),
      streak: playerStats.value.streak + 1,
    }

    // Award XP for correct answers during boss battle - scaled by streak
    const streakMultiplier = Math.min(playerStats.value.streak + 1, 5) // Cap at 5x
    authStore.addExperience(10 * streakMultiplier, "Boss Battle Correct Answer")
    
    // Update boss health
    bossStats.value.health = Math.max(0, bossStats.value.health - damage)
    
    toast.success(`+${damage * 10} points! Great attack!`)
    
    // Update card confidence level
    updateCardConfidence(currentCard.value.id, true)
  } else {
    // Boss damages player
    playerDamage = 15
    
    // Update player stats
    playerStats.value = {
      ...playerStats.value,
      health: Math.max(0, playerStats.value.health - playerDamage),
      streak: 0
    }
    
    // Small consolation XP for attempting
    authStore.addExperience(3, "Boss Battle Learning Opportunity")
    
    toast.error(`Ouch! -${playerDamage} health!`)
    
    // Update card confidence level
    updateCardConfidence(currentCard.value.id, false)
  }
  
  // Check for battle end conditions
  if (bossStats.value.health <= 0) {
    battleStatus.value = 'victory'
    emit('complete', playerStats.value.score + (bossDamage * 10), playerStats.value.cardsImproved)
  } else if (playerStats.value.health <= 0) {
    battleStatus.value = 'defeat'
    emit('complete', playerStats.value.score, playerStats.value.cardsImproved)
  } else {
    // Move to next card
    setTimeout(() => {
      if (currentIndex.value < challengeCards.value.length - 1) {
        currentIndex.value++
        isFlipped.value = false
        showHint.value = false
      } else {
        // Loop back to beginning if we've gone through all cards
        currentIndex.value = 0
        isFlipped.value = false
        showHint.value = false
      }
    }, 1500)
  }
}

const updateCardConfidence = async (cardId: string, wasCorrect: boolean) => {
  try {
    const card = challengeCards.value.find(c => c.id === cardId)
    if (!card) return
    
    const newConfidence = Math.max(1, Math.min(5, 
      card.confidence_level + (wasCorrect ? 1 : -0.5)
    ))
    
    // Only count as improved if confidence went up
    const improved = wasCorrect && newConfidence > card.confidence_level
    
    if (improved) {
      playerStats.value.cardsImproved++
      
      // Award XP for improving a challenging card
      authStore.addExperience(15, "Mastered Challenging Flashcard")
    }
    
    // Update in the database
    await supabase
      .from('flashcards')
      .update({ 
        confidence_level: newConfidence,
        last_reviewed: new Date().toISOString()
      })
      .eq('id', cardId)
    
    // Update local state
    challengeCards.value = challengeCards.value.map(c => 
      c.id === cardId 
        ? { ...c, confidence_level: newConfidence }
        : c
    )
  } catch (error) {
    console.error('Failed to update card confidence:', error)
  }
}

const usePowerup = () => {
  if (playerStats.value.powerups <= 0) {
    toast.error('No power-ups remaining!')
    return
  }
  
  playerStats.value.powerups--
  
  // Generate hint
  const card = currentCard.value
  hint.value = generateHint(card.term, card.definition)
  showHint.value = true
  
  toast('Power-up activated! Hint revealed.', {
    icon: '⚡',
  })
}

const generateHint = (term: string, definition: string): string => {
  // In a real app, this would be more sophisticated and use AI
  // For now, we'll create a simple hint by:
  // 1. Extracting key words from the definition
  // 2. Providing the first few words of the definition
  
  const keywords = definition.split(/\s+/)
    .filter(word => word.length > 5)
    .slice(0, 2)
  
  if (keywords.length > 0) {
    return `This concept is related to ${keywords.join(' and ')}. The first few words of the definition are: "${definition.split(' ').slice(0, 4).join(' ')}..."`;
  } else {
    return `The definition begins with: "${definition.split(' ').slice(0, 5).join(' ')}..."`;
  }
}

const restartBattle = () => {
  // Shuffle the cards
  challengeCards.value = [...challengeCards.value].sort(() => Math.random() - 0.5)
  currentIndex.value = 0
  isFlipped.value = false
  showHint.value = false
  playerStats.value = {
    health: 100,
    score: 0,
    streak: 0,
    powerups: 2,
    cardsImproved: 0
  }
  bossStats.value = {
    health: 100,
    name: bossStats.value.name
  }
  battleStatus.value = 'active'
}

const getConfidenceColor = (level: number) => {
  if (level >= 4) return 'text-green-400'
  if (level >= 3) return 'text-star-400'
  return 'text-red-400'
}
</script>

<style scoped>
.flip-enter-active,
.flip-leave-active {
  transition: transform 0.3s, opacity 0.3s;
}

.flip-enter-from,
.flip-leave-to {
  transform: rotateY(90deg);
  opacity: 0;
}
</style>