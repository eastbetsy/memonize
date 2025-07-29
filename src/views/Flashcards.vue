<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-glow mb-2">AI-Enhanced Flashcards</h1>
        <p class="text-cosmic-300">Master knowledge through spaced repetition and AI generation</p>
      </div>
      
      <div class="flex items-center space-x-3">
        <button
          @click="showAIGenerator = !showAIGenerator"
          class="star-button flex items-center space-x-2 px-4 py-2"
          :title="showAIGenerator ? 'Hide AI Generator' : 'Generate flashcards from text, images, audio, or handwritten notes'"
        >
          <Sparkles class="h-4 w-4" />
          <span>AI Generator</span>
        </button>
        
        <button
          @click="togglePerformanceAnalytics"
          :class="[
            showPerformanceAnalytics ? 'nebula-button' : 'cosmic-button',
            'flex items-center space-x-2 px-4 py-2'
          ]"
          title="View detailed performance analytics"
        >
          <BarChart2 class="h-4 w-4" />
          <span>Analytics</span>
        </button>
      </div>
    </div>

    <!-- Actions Bar -->
    <div class="overflow-x-auto pb-2">
      <div class="flex flex-wrap justify-center items-center gap-2">
        <!-- Study Mode Button -->
        <button
          @click="studyMode = !studyMode"
          :class="[
            studyMode ? 'nebula-button' : 'cosmic-button',
            'flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs'
          ]"
        >
          <component :is="studyMode ? Pause : Play" class="h-3 w-3" />
          <span>{{ studyMode ? 'Exit Study' : 'Study Mode' }}</span>
        </button>

        <!-- Conversation Mode Button -->
        <button
          @click="toggleConversationMode"
          :class="[
            conversationMode ? 'nebula-button' : 'cosmic-button',
            'flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs'
          ]"
        >
          <MessageCircle class="h-3 w-3" />
          <span>Interactive</span>
        </button>

        <!-- Teach Mode Button -->
        <button
          @click="toggleTeachMode"
          :class="[
            teachMode ? 'nebula-button' : 'cosmic-button',
            'flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs'
          ]"
        >
          <Bot class="h-3 w-3" />
          <span>Teach It</span>
        </button>
        
        <!-- Real World Application Button -->
        <button
          @click="toggleApplicationMode"
          :class="[
            applicationMode ? 'nebula-button' : 'cosmic-button',
            'flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs'
          ]"
        >
          <Globe class="h-3 w-3" />
          <span>Apply It</span>
        </button>
        
        <!-- Show Connections Button -->
        <button
          @click="showRelatedCards = !showRelatedCards"
          :class="[
            showRelatedCards ? 'nebula-button' : 'cosmic-button',
            'flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs'
          ]"
        >
          <ArrowLeftRight class="h-3 w-3" />
          <span>Connections</span>
        </button>
        
        <!-- Boss Battle Button -->
        <button
          @click="toggleBossBattleMode"
          class="flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs cosmic-button"
        >
          <Swords class="h-3 w-3" />
          <span>Boss Battle</span>
        </button>
        
        <!-- Memory Aids Button -->
        <button
          @click="showMnemonicGenerator = !showMnemonicGenerator"
          :class="[
            showMnemonicGenerator ? 'star-button' : 'cosmic-button',
            'flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs'
          ]"
        >
          <Lightbulb class="h-3 w-3" />
          <span>Memory Aids</span>
        </button>
        
        <!-- Sample Cards Button -->
        <button
          @click="createSampleFlashcards"
          class="flex items-center space-x-1 px-2 py-1.5 rounded-lg transition-all text-xs bg-white/10 hover:bg-white/20 text-white"
          title="Create sample flashcards to explore the features"
        >
          <Plus class="h-3 w-3" />
          <span>Samples</span>
        </button>
      </div>
    </div>

    <!-- AI Generator -->
    <Transition>
      <div v-if="showAIGenerator" class="overflow-hidden">
        <AIFlashcardGenerator 
          :userId="authStore.user?.id || ''" 
          @flashcardsGenerated="fetchFlashcards"
        />
      </div>
    </Transition>

    <div v-if="loading" class="flex items-center justify-center py-20">
      <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
    </div>

    <div v-else-if="!authStore.isAuthenticated" class="text-center py-20">
      <CreditCard class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h2 class="text-2xl font-bold text-white mb-4">Sign in to access flashcards</h2>
      <p class="text-cosmic-300">Create an account to start studying with AI-generated flashcards</p>
    </div>

    <div v-else-if="flashcards.length === 0" class="text-center py-20">
      <CreditCard class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h3 class="text-xl font-bold text-white mb-2">No flashcards yet</h3>
      <p class="text-cosmic-300 mb-6">Create some notes to automatically generate flashcards</p>
      <button
        @click="createSampleFlashcards"
        class="cosmic-button"
      >
        Create Sample Flashcards
      </button>
    </div>

    <div v-else>
      <!-- Study Stats - Show in both study mode and conversation mode -->
      <Transition>
        <div v-if="(studyMode || conversationMode || teachMode || applicationMode) && studyStats.total > 0" class="glass-card p-6 text-center">
          <div class="grid grid-cols-4 gap-4">
            <div>
              <div class="text-2xl font-bold text-green-400">{{ studyStats.correct }}</div>
              <div class="text-cosmic-300">Correct</div>
            </div>
            <div>
              <div class="text-2xl font-bold text-red-400">{{ studyStats.incorrect }}</div>
              <div class="text-cosmic-300">Incorrect</div>
            </div>
            <div>
              <div class="text-2xl font-bold text-cosmic-300">
                {{ studyStats.total > 0 ? Math.round((studyStats.correct / studyStats.total) * 100) : 0 }}%
              </div>
              <div class="text-cosmic-300">Accuracy</div>
            </div>
            <div>
              <div class="text-2xl font-bold text-cosmic-300">{{ studyStats.hints }}</div>
              <div class="text-cosmic-300">Hints Used</div>
            </div>
          </div>
        </div>
      </Transition>

      <!-- Card Counter -->
      <div class="text-center text-cosmic-300 text-sm md:text-base">
        Card {{ currentIndex + 1 }} of {{ flashcards.length }}
      </div>

      <!-- Main Flashcard Display -->
      <div class="flex justify-center">
        <div class="w-full max-w-4xl">
          <Transition mode="out-in">
            <!-- Conversation Mode -->
            <ConversationalFlashcard 
              v-if="conversationMode"
              :flashcard="currentCard" 
              @complete="handleStudyResponse"
              @hintRequested="handleHintRequested"
              @next="nextCard"
            />
            
            <!-- Teach Mode -->
            <TeachToAIMode
              v-else-if="teachMode"
              :flashcard="currentCard"
              @complete="handleTeachModeComplete"
              @next="nextCard"
            />
            
            <!-- Application Mode -->
            <RealWorldApplicationCard
              v-else-if="applicationMode"
              :flashcard="currentCard"
              @answered="handleApplicationResponse"
              @next="nextCard"
            />
            
            <!-- Boss Battle Mode -->
            <BossBattleDeck
              v-else-if="bossBattleMode"
              :userId="authStore.user?.id || ''"
              :onComplete="handleBossBattleComplete"
            />
            
            <!-- Standard Flashcard Mode -->
            <div 
              v-else
              class="relative w-full max-w-2xl h-64 md:h-80 cursor-pointer mx-4"
              @click="isFlipped = !isFlipped"
            >
            <Transition name="card-flip" mode="out-in">
              <div
                :key="isFlipped ? 'back' : 'front'"
                class="glass-card p-6 md:p-8 h-full flex flex-col justify-center items-center text-center relative overflow-hidden"
              >
                <div 
                  class="absolute inset-0 bg-gradient-to-br opacity-10"
                  :class="getDifficultyColor(currentCard.difficulty)"
                ></div>
                
                <!-- Difficulty badge -->
                <div 
                  class="absolute top-3 left-3 md:top-4 md:left-4 px-2 md:px-3 py-1 rounded-full text-xs font-medium bg-gradient-to-r text-white"
                  :class="getDifficultyColor(currentCard.difficulty)"
                > 
                  {{ currentCard.difficulty }}
                </div>

                <!-- Confidence indicator -->
                <div class="absolute top-3 right-3 md:top-4 md:right-4 flex items-center space-x-2">
                  <div class="flex items-center space-x-1">
                    <Star 
                      v-for="i in 5" 
                      :key="i"
                      class="h-3 w-3 md:h-4 md:w-4"
                      :class="[
                        i <= currentCard.confidence_level 
                          ? `${getConfidenceColor(currentCard.confidence_level)} fill-current` 
                          : 'text-cosmic-600'
                      ]" 
                    />
                  </div>
                  
                  <!-- AI Generated indicator -->
                  <div 
                    v-if="currentCard.ai_generated"
                    title="AI-generated flashcard"
                    class="flex items-center px-2 py-0.5 bg-cosmic-500/20 text-cosmic-300 rounded-full text-xs"
                  >
                    <Sparkles class="h-3 w-3 mr-1" />
                    <span class="hidden md:inline">AI</span>
                  </div>
                </div>

                <div class="relative z-10">
                  <div class="text-xs md:text-sm text-cosmic-400 mb-3 md:mb-4">
                    <div v-if="isFlipped" class="flex justify-between items-center">
                      <span>Answer</span>
                      <button 
                        @click.stop="handleAskDraco(currentCard.definition)"
                        class="text-cosmic-300 hover:text-cosmic-400 transition-colors"
                      >
                        <MessageCircle class="h-4 w-4" />
                      </button>
                    </div>
                    <div v-else class="flex justify-between items-center">
                      <span>Question</span>
                      <button 
                        @click.stop="handleAskDraco(currentCard.term)"
                        class="text-cosmic-300 hover:text-cosmic-400 transition-colors"
                      >
                        <MessageCircle class="h-4 w-4" />
                      </button>
                    </div>
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
          </Transition>
        </div>
      </div>
      
      <!-- Related Flashcards -->
      <div v-if="showRelatedCards && !studyMode && !conversationMode && !teachMode && !applicationMode && !bossBattleMode" class="mt-6">
        <RelatedFlashcards
          :currentCard="currentCard"
          :userId="authStore.user?.id || ''"
          @selectRelated="handleRelatedCardSelect"
        />
      </div>

      <!-- Study Mode Buttons -->
      <Transition>
        <div v-if="studyMode && isFlipped" class="flex justify-center gap-3 px-4 mt-4">
          <button
            @click="() => handleStudyResponse(false)"
            class="flex items-center justify-center space-x-2 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors"
          >
            <XCircle class="h-5 w-5" />
            <span>Incorrect</span>
          </button>
          
          <button
            @click="() => handleStudyResponse(true)"
            class="flex items-center justify-center space-x-2 px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors"
          >
            <CheckCircle class="h-5 w-5" />
            <span>Correct</span>
          </button>
        </div>
      </Transition>

      <!-- Mnemonic Suggestion -->
      <div 
        v-if="!conversationMode && !studyMode && !showMnemonicGenerator && currentCard.difficulty === 'hard'"
        class="text-center mt-4 mb-6"
      >
        <button
          @click="showMnemonicGenerator = true"
          class="text-cosmic-300 hover:text-cosmic-200 text-sm inline-flex items-center space-x-1 px-3 py-1 bg-cosmic-500/20 rounded-full transition-colors"
        >
          <Lightbulb class="h-3 w-3" />
          <span>This concept seems challenging. Generate a memory aid?</span>
        </button>
      </div>

      <!-- Navigation Controls -->
      <div v-if="!studyMode && !conversationMode" class="flex justify-center gap-3 px-4 mt-4">
        <button
          @click="prevCard"
          class="cosmic-button px-4 py-2"
        >
          ← Previous
        </button>
        
        <button
          @click="shuffleCards"
          class="nebula-button flex items-center space-x-2 px-4 py-2"
        >
          <Shuffle class="h-4 w-4" />
          <span>Shuffle</span>
        </button>
        
        <button
          @click="nextCard"
          class="cosmic-button px-4 py-2"
        >
          Next →
        </button>
      </div>
      
      <!-- Progress Bar -->
      <div class="w-full bg-cosmic-900/50 rounded-full h-2 mt-6">
        <div 
          class="bg-gradient-to-r from-cosmic-500 to-nebula-500 h-2 rounded-full transition-all duration-300"
          :style="{ width: `${((currentIndex + 1) / flashcards.length) * 100}%` }"
        ></div>
      </div>
    </div>

    <!-- Mnemonic Generator -->
    <div v-if="showMnemonicGenerator">
      <MnemonicGenerator :flashcard="currentCard" @close="showMnemonicGenerator = false" />
    </div>

    <!-- AI Assistant Modal -->
    <AIAssistant
      :isOpen="showAIAssistant"
      @close="showAIAssistant = false"
      :context="{
        currentPage: 'flashcards',
        selectedText: selectedCardText,
        recentActivity: [],
        studyGoals: []
      }"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useToast } from 'vue-toastification'
import VueMarkdown from 'vue3-markdown-it'
import { 
  CreditCard, 
  Shuffle, 
  BarChart2,
  Bot,
  Globe,
  Swords,
  Network,
  ArrowLeftRight,
  Star,
  CheckCircle,
  XCircle,
  Play,
  Pause,
  Plus,
  Sparkles,
  MessageCircle,
  Lightbulb
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

import AIAssistant from '@/components/AIAssistant.vue'
import ConversationalFlashcard from '@/components/ConversationalFlashcard.vue'
import AIFlashcardGenerator from '@/components/AIFlashcardGenerator.vue'
import TeachToAIMode from '@/components/TeachToAIMode.vue'
import RealWorldApplicationCard from '@/components/RealWorldApplicationCard.vue'
import RelatedFlashcards from '@/components/RelatedFlashcards.vue'
import BossBattleDeck from '@/components/BossBattleDeck.vue'
import MnemonicGenerator from '@/components/MnemonicGenerator.vue'

interface Flashcard {
  id: string
  term: string
  definition: string
  difficulty: 'easy' | 'medium' | 'hard'
  created_at: string
  confidence_level: number
  ai_generated?: boolean
  content_source?: string
}

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const flashcards = ref<Flashcard[]>([])
const currentIndex = ref(0)
const isFlipped = ref(false)
const loading = ref(true)
const studyMode = ref(false)
const bossBattleMode = ref(false)
const studyStats = ref({
  correct: 0,
  incorrect: 0, 
  total: 0,
  hints: 0
})
const showAIGenerator = ref(false)
const conversationMode = ref(false)
const showMnemonicGenerator = ref(false)
const showRelatedCards = ref(false)
const applicationMode = ref(false)
const teachMode = ref(false)
const showPerformanceAnalytics = ref(false)
const showAIAssistant = ref(false)
const selectedCardText = ref('')

// Computed
const currentCard = computed<Flashcard>(() => {
  if (flashcards.value.length === 0) {
    return {
      id: '',
      term: '',
      definition: '',
      difficulty: 'medium',
      created_at: '',
      confidence_level: 0
    }
  }
  return flashcards.value[currentIndex.value]
})

// Lifecycle
onMounted(() => {
  if (authStore.isAuthenticated) {
    fetchFlashcards()
  }
})

// Methods
  const fetchFlashcards = async () => {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('flashcards')
      .select('*')
      .eq('user_id', authStore.user?.id)
      .order('created_at', { ascending: false })

    if (error) throw error
    
    // If no flashcards exist, create some sample ones
    if (!data || data.length === 0) {
      await createSampleFlashcards()
      return
    }
    
    flashcards.value = data
  } catch (error) {
    toast.error('Failed to fetch flashcards')
    console.error('Failed to fetch flashcards:', error)
  } finally {
    loading.value = false
  }
}

const createSampleFlashcards = async () => {
  const sampleCards = [
    {
      term: "What is the constellation Draco known for?",
      definition: "Draco is a large constellation representing a dragon, wrapped around the north celestial pole",
      difficulty: "medium",
      user_id: authStore.user?.id
    },
    {
      term: "How many stars make up the Big Dipper?",
      definition: "Seven bright stars form the Big Dipper asterism",
      difficulty: "easy",
      user_id: authStore.user?.id
    },
    {
      term: "What is spaced repetition?",
      definition: "A learning technique that involves reviewing information at increasing intervals to improve long-term retention",
      difficulty: "medium",
      user_id: authStore.user?.id
    },
    {
      term: "Which constellation is known as the Hunter?",
      definition: "Orion is known as the Hunter constellation",
      difficulty: "easy",
      user_id: authStore.user?.id
    },
    {
      term: "What is the brightest star in our night sky?",
      definition: "Sirius, also known as the Dog Star, is the brightest star visible from Earth",
      difficulty: "hard",
      user_id: authStore.user?.id
    }
  ]

  try {
    const { data, error } = await supabase
      .from('flashcards')
      .insert(sampleCards)
      .select()

    if (error) throw error
    flashcards.value = data
    toast.success('Sample flashcards created!')
  } catch (error) {
    console.error('Failed to create sample flashcards:', error)
    toast.error('Failed to create sample flashcards')
  } finally {
    loading.value = false
  }
}

const nextCard = () => {
  currentIndex.value = (currentIndex.value + 1) % flashcards.value.length
  isFlipped.value = false
}

const prevCard = () => {
  currentIndex.value = (currentIndex.value - 1 + flashcards.value.length) % flashcards.value.length
  isFlipped.value = false
}

const shuffleCards = () => {
  const shuffled = [...flashcards.value].sort(() => Math.random() - 0.5)
  flashcards.value = shuffled
  currentIndex.value = 0
  isFlipped.value = false
  toast.success('Cards shuffled!')
}

const toggleConversationMode = () => {
  conversationMode.value = !conversationMode.value
  if (studyMode.value) studyMode.value = false
  if (applicationMode.value) applicationMode.value = false
  if (teachMode.value) teachMode.value = false
  if (bossBattleMode.value) bossBattleMode.value = false
  if (showMnemonicGenerator.value) showMnemonicGenerator.value = false
  isFlipped.value = false
}

const toggleBossBattleMode = () => {
  bossBattleMode.value = !bossBattleMode.value
  if (studyMode.value) studyMode.value = false
  if (conversationMode.value) conversationMode.value = false
  if (teachMode.value) teachMode.value = false
  if (applicationMode.value) applicationMode.value = false
  if (showMnemonicGenerator.value) showMnemonicGenerator.value = false
  isFlipped.value = false
}

const toggleApplicationMode = () => {
  applicationMode.value = !applicationMode.value
  if (studyMode.value) studyMode.value = false
  if (conversationMode.value) conversationMode.value = false
  if (teachMode.value) teachMode.value = false
  if (bossBattleMode.value) bossBattleMode.value = false
  if (showMnemonicGenerator.value) showMnemonicGenerator.value = false
  isFlipped.value = false
}

const toggleTeachMode = () => {
  teachMode.value = !teachMode.value
  if (studyMode.value) studyMode.value = false
  if (conversationMode.value) conversationMode.value = false
  if (bossBattleMode.value) bossBattleMode.value = false
  if (applicationMode.value) applicationMode.value = false
  if (showMnemonicGenerator.value) showMnemonicGenerator.value = false
  isFlipped.value = false
}

const handleTeachModeComplete = (score: number) => {
  // Update stats and give XP based on teaching quality
  studyStats.value = {
    ...studyStats.value,
    total: studyStats.value.total + 1,
    correct: studyStats.value.correct + (score >= 70 ? 1 : 0),
    incorrect: studyStats.value.incorrect + (score >= 70 ? 0 : 1)
  }
}

const handleApplicationResponse = (isCorrect: boolean) => {
  // Update stats for real-world application
  studyStats.value = {
    ...studyStats.value,
    total: studyStats.value.total + 1,
    correct: studyStats.value.correct + (isCorrect ? 1 : 0),
    incorrect: studyStats.value.incorrect + (isCorrect ? 0 : 1)
  }
}

const handleBossBattleComplete = (score: number, cardsImproved: number) => {
  // Update stats based on boss battle results
  toast.success(`Boss battle complete! Score: ${score}, Cards improved: ${cardsImproved}`)
  studyStats.value = {
    ...studyStats.value,
    total: studyStats.value.total + cardsImproved,
    correct: studyStats.value.correct + cardsImproved
  }
  
  bossBattleMode.value = false
}

const handleRelatedCardSelect = (card: Flashcard) => {
  // Find the index of the selected card and navigate to it
  const index = flashcards.value.findIndex(c => c.id === card.id)
  if (index !== -1) {
    currentIndex.value = index
    isFlipped.value = false
    toast.info(`Navigated to related card: ${card.term}`)
  }
}

const togglePerformanceAnalytics = () => {
  showPerformanceAnalytics.value = !showPerformanceAnalytics.value
}

const handleStudyResponse = async (correct: boolean) => {
  const newStats = {
    total: studyStats.value.total + 1,
    correct: studyStats.value.correct + (correct ? 1 : 0),
    incorrect: studyStats.value.incorrect + (correct ? 0 : 1),
    hints: studyStats.value.hints
  }
  studyStats.value = newStats
  
  // Award XP for correct answers
  if (correct) {
    const xpAmount = 15 // Base XP for correct flashcard
    authStore.addExperience(xpAmount, "Correct Flashcard Answer")
  }

  // Update confidence level
  const currentCardValue = currentCard.value
  const newConfidence = Math.max(1, Math.min(5, 
    currentCardValue.confidence_level + (correct ? 1 : -1)
  ))

  try {
    await supabase
      .from('flashcards')
      .update({ 
        confidence_level: newConfidence,
        last_reviewed: new Date().toISOString()
      })
      .eq('id', currentCardValue.id)

    // Update local state
    flashcards.value = flashcards.value.map(card => 
      card.id === currentCardValue.id 
        ? { ...card, confidence_level: newConfidence }
        : card
    )
  } catch (error) {
    console.error('Failed to update confidence:', error)
  }

  nextCard()
}

const handleHintRequested = () => {
  studyStats.value = {
    ...studyStats.value,
    hints: studyStats.value.hints + 1
  }
  
  // Award small XP for using hints (learning strategy)
  if (studyStats.value.hints === 1) {
    // Only award XP for the first hint use per session
    authStore.addExperience(5, "Used Learning Strategy")
  }
}

const handleAskDraco = (content: string) => {
  selectedCardText.value = content
  showAIAssistant.value = true
}

const getDifficultyColor = (difficulty: string) => {
  switch (difficulty) {
    case 'easy': return 'from-green-500 to-green-600'
    case 'medium': return 'from-star-500 to-star-600'
    case 'hard': return 'from-red-500 to-red-600'
    default: return 'from-cosmic-500 to-cosmic-600'
  }
}

const getConfidenceColor = (level: number) => {
  if (level >= 4) return 'text-green-400'
  if (level >= 3) return 'text-star-400'
  return 'text-red-400'
}
</script>

<style scoped>
.card-flip-enter-active,
.card-flip-leave-active {
  transition: all 0.3s ease;
}

.card-flip-enter-from,
.card-flip-leave-to {
  transform: rotateY(90deg);
  opacity: 0;
}
</style>