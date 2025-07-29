<template>
  <div class="glass-card p-6 md:p-8 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h3 class="text-lg font-bold text-white flex items-center">
        <Bot class="h-5 w-5 mr-2 text-cosmic-400" />
        Teach It to the AI
      </h3>
      
      <div class="text-xs text-cosmic-300 px-2 py-1 bg-white/10 rounded-full">
        {{ flashcard.difficulty }}
      </div>
    </div>
    
    <!-- Instruction -->
    <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4">
      <div class="flex items-center text-cosmic-300 mb-2">
        <Brain class="h-4 w-4 mr-2" />
        <span class="font-medium">Concept to Explain:</span>
      </div>
      <div class="text-white font-medium">{{ flashcard.term }}</div>
      <div v-if="showDefinition" class="mt-2 pt-2 border-t border-white/10">
        <div class="text-xs text-cosmic-400 mb-1">Reference Definition:</div>
        <div class="text-cosmic-300 text-sm">{{ flashcard.definition }}</div>
      </div>
    </div>
    
    <!-- Explanation Input -->
    <div v-if="!isSubmitted" class="space-y-4">
      <div>
        <div class="flex justify-between mb-2">
          <div class="text-sm text-cosmic-300">
            Explain this concept in your own words:
          </div>
          <button 
            @click="showDefinition = !showDefinition"
            class="text-xs text-cosmic-400 hover:text-cosmic-300 flex items-center"
          >
            <Lightbulb class="h-3 w-3 mr-1" />
            {{ showDefinition ? 'Hide Definition' : 'Show Definition' }}
          </button>
        </div>
        <textarea
          v-model="explanation"
          placeholder="Explain the concept as if you're teaching it to someone else..."
          class="w-full h-40 px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
        ></textarea>
      </div>
      
      <div class="flex justify-between items-center">
        <div class="text-xs text-cosmic-400">
          <Lightbulb class="inline-block h-3 w-3 mr-1" />
          Teaching a concept is one of the best ways to learn it
        </div>
        <button
          @click="handleSubmit"
          :disabled="!explanation.trim()"
          class="cosmic-button px-4 py-2 flex items-center space-x-2"
          :class="{ 'opacity-50 cursor-not-allowed': !explanation.trim() }"
        >
          <Send class="h-4 w-4" />
          <span>Submit Explanation</span>
        </button>
      </div>
    </div>

    <div v-else class="space-y-4">
      <!-- User's Explanation -->
      <div class="glass-card p-4">
        <div class="text-sm text-cosmic-300 mb-2 flex items-center">
          <MessageCircle class="h-4 w-4 mr-1" />
          <span>Your Explanation:</span>
        </div>
        <div class="text-white text-sm">{{ explanation }}</div>
      </div>
      
      <!-- AI's Evaluation -->
      <div class="glass-card p-4 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-cosmic-600/10 to-nebula-600/10"></div>
        <div class="relative z-10">
          <div class="text-sm text-cosmic-300 mb-3 flex items-center">
            <Bot class="h-4 w-4 mr-1" />
            <span>AI Evaluation:</span>
            
            <div v-if="!isEvaluating" class="ml-auto flex items-center">
              <span :class="['text-lg font-bold', getScoreColor(score)]">
                {{ getScoreEmoji(score) }} {{ score }}
              </span>
              <span class="text-cosmic-400 text-xs ml-1">/100</span>
            </div>
          </div>
          
          <div v-if="isEvaluating" class="flex items-center justify-center py-6">
            <div class="w-10 h-10 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
          
          <div v-else class="prose prose-invert prose-sm max-w-none">
            <VueMarkdown>{{ aiResponse }}</VueMarkdown>
          </div>
        </div>
      </div>
      
      <!-- Action Buttons -->
      <div v-if="!isEvaluating" class="flex space-x-4 justify-end">
        <button
          @click="resetExercise"
          class="px-4 py-2 flex items-center space-x-2 bg-white/10 hover:bg-white/15 text-white rounded-lg transition-colors"
        >
          <Brain class="h-4 w-4" />
          <span>Try Again</span>
        </button>
        
        <button
          @click="$emit('next')"
          class="cosmic-button px-4 py-2 flex items-center space-x-2"
        >
          <ArrowRight class="h-4 w-4" />
          <span>Next Card</span>
        </button>
      </div>
    </div>
    
    <div class="text-xs text-cosmic-400 border-t border-white/10 pt-4">
      <div class="flex items-center">
        <Bot class="h-3 w-3 mr-1" />
        <span>Teaching concepts back to the AI helps identify gaps in your understanding and reinforces learning.</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import VueMarkdown from 'vue3-markdown-it'
import { 
  Bot, 
  MessageCircle, 
  Brain, 
  Lightbulb, 
  ArrowRight, 
  Send
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

interface Props {
  flashcard: {
    id: string
    term: string
    definition: string
    difficulty: string
    confidence_level: number
  }
}

// Props
const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
  (e: 'complete', score: number): void
  (e: 'next'): void
}>()

// Composables
const authStore = useAuthStore()

// State
const explanation = ref('')
const aiResponse = ref('')
const isSubmitted = ref(false)
const isEvaluating = ref(false)
const score = ref(0)
const showDefinition = ref(false)

// Methods
const handleSubmit = () => {
  if (!explanation.value.trim()) {
    return
  }
  
  isSubmitted.value = true
  isEvaluating.value = true
  
  // Simulate AI evaluation delay
  setTimeout(() => {
    const { feedback, calculatedScore } = evaluateExplanation(explanation.value, props.flashcard.definition)
    aiResponse.value = feedback
    score.value = calculatedScore
    
    // Award XP based on explanation quality
    if (calculatedScore >= 85) {
      authStore.addExperience(50, "Excellent Concept Explanation")
    } else if (calculatedScore >= 70) {
      authStore.addExperience(30, "Good Concept Explanation")
    } else if (calculatedScore >= 50) {
      authStore.addExperience(15, "Attempted Concept Explanation")
    } else {
      authStore.addExperience(5, "Learning Through Teaching")
    }
    
    isEvaluating.value = false
    emit('complete', calculatedScore)
  }, 1500)
}

const evaluateExplanation = (userExplanation: string, definition: string) => {
  // This is a simplistic evaluation simulation
  // A real implementation would use a more sophisticated algorithm or API
  
  // Extract key terms from the definition
  const definitionKeywords = extractKeywords(definition)
  const explanationKeywords = extractKeywords(userExplanation)
  
  // Calculate the coverage of key concepts
  const matchedKeywords = definitionKeywords.filter(keyword => 
    explanationKeywords.some(exKeyword => 
      exKeyword.includes(keyword) || keyword.includes(exKeyword)
    )
  )
  
  const coverageScore = Math.min(100, (matchedKeywords.length / definitionKeywords.length) * 100)
  
  // Check explanation length/effort
  const lengthScore = Math.min(100, (userExplanation.length / 50) * 100)
  
  // Calculate final score (0-100)
  const calculatedScore = Math.round((coverageScore * 0.7) + (lengthScore * 0.3))
  
  // Generate appropriate feedback
  let feedback = ""
  
  if (calculatedScore >= 85) {
    feedback = `# Excellent explanation! 🌟\n\nYou've demonstrated a thorough understanding of the concept. Your explanation covered the key elements:\n\n${matchedKeywords.map(k => `- ${k.charAt(0).toUpperCase() + k.slice(1)}`).join('\n')}\n\nYou articulated the concept clearly and accurately. Teaching a concept to others is one of the best ways to solidify your own understanding!`
  } else if (calculatedScore >= 70) {
    feedback = `# Good explanation! 👍\n\nYou've covered many important aspects of this concept. I noticed these key elements in your explanation:\n\n${matchedKeywords.map(k => `- ${k.charAt(0).toUpperCase() + k.slice(1)}`).join('\n')}\n\nTo improve, you might also want to mention:\n\n${definitionKeywords.filter(k => !matchedKeywords.includes(k)).slice(0, 3).map(k => `- ${k.charAt(0).toUpperCase() + k.slice(1)}`).join('\n')}\n\nExplaining concepts in your own words is a powerful learning technique!`
  } else if (calculatedScore >= 50) {
    feedback = `# Good start! 🔍\n\nYou've touched on some aspects of the concept, including:\n\n${matchedKeywords.map(k => `- ${k.charAt(0).toUpperCase() + k.slice(1)}`).join('\n')}\n\nHowever, there are several important elements you didn't cover:\n\n${definitionKeywords.filter(k => !matchedKeywords.includes(k)).slice(0, 4).map(k => `- ${k.charAt(0).toUpperCase() + k.slice(1)}`).join('\n')}\n\nTry reviewing the definition and explaining it again for better retention.`
  } else {
    feedback = `# Let's review this together 📚\n\nYour explanation touched on a few points, but there are many key concepts that weren't addressed. The main elements to include are:\n\n${definitionKeywords.slice(0, 5).map(k => `- ${k.charAt(0).toUpperCase() + k.slice(1)}`).join('\n')}\n\nTrying to explain a concept in your own words reveals gaps in understanding. This is valuable! I recommend reviewing the definition and trying again.`
  }
  
  return { feedback, calculatedScore }
}

const extractKeywords = (text: string): string[] => {
  // Split the text into words
  const words = text.toLowerCase().split(/\s+/)
  
  // Common words to exclude
  const commonWords = ['a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'as', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'shall', 'should', 'can', 'could', 'may', 'might', 'must', 'that', 'this', 'these', 'those', 'then', 'than', 'when', 'where', 'which', 'who', 'whom', 'whose', 'what', 'how', 'why', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'their', 'them', 'his', 'her', 'its', 'our', 'your', 'my', 'mine', 'yours', 'hers', 'ours', 'theirs']
  
  // Filter out common words and short words
  const keywords = words
    .filter(word => word.length > 3 && !commonWords.includes(word))
    .map(word => word.replace(/[.,;:!?]/g, ''))
      
  // Remove duplicates and return
  return [...new Set(keywords)]
}

const getScoreColor = (score: number) => {
  if (score >= 85) return 'text-green-400'
  if (score >= 70) return 'text-star-400'
  if (score >= 50) return 'text-yellow-400'
  return 'text-red-400'
}

const getScoreEmoji = (score: number) => {
  if (score >= 85) return '🎯'
  if (score >= 70) return '👍'
  if (score >= 50) return '🔍'
  return '📚'
}

const resetExercise = () => {
  explanation.value = ''
  aiResponse.value = ''
  isSubmitted.value = false
  score.value = 0
  showDefinition.value = false
}
</script>