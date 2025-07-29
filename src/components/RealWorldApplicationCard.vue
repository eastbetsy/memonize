<template>
  <div class="glass-card p-6 md:p-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-bold text-white flex items-center">
        <Globe class="h-5 w-5 mr-2 text-cosmic-400" />
        Real-World Application
      </h3>
      
      <div class="flex items-center space-x-2">
        <div class="text-xs text-cosmic-300 px-2 py-1 bg-white/10 rounded-full">
          {{ flashcard.difficulty }}
        </div>
        <div class="flex">
          <Star 
            v-for="i in 5" 
            :key="i"
            :class="[
              'h-4 w-4',
              i < flashcard.confidence_level
                ? `${getConfidenceColor(flashcard.confidence_level)} fill-current`
                : 'text-cosmic-600'
            ]" 
          />
        </div>
      </div>
    </div>

    <!-- Concept -->
    <div class="bg-white/5 border border-white/10 rounded-lg p-4 mb-4">
      <div class="text-sm text-cosmic-300 mb-1 flex items-center">
        <FileText class="h-4 w-4 mr-1" />
        <span>Concept:</span>
      </div>
      <div class="text-white">
        <strong>{{ flashcard.term.replace(/\?$/, '') }}</strong>
      </div>
    </div>

    <!-- Application Scenario -->
    <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4 mb-4">
      <div class="text-sm text-cosmic-300 mb-2 flex items-center">
        <Globe class="h-4 w-4 mr-1" />
        <span>Real-World Application Scenario:</span>
      </div>
      
      <div v-if="isLoading" class="flex items-center justify-center py-4">
        <div class="w-6 h-6 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
      
      <div v-else class="text-cosmic-100">{{ applicationScenario }}</div>
    </div>

    <!-- Response Area -->
    <div v-if="isAnswering" class="space-y-4">
      <div class="text-sm text-cosmic-300 mb-1">
        Explain how the concept applies to this scenario:
      </div>
      <textarea
        v-model="userAnswer"
        placeholder="Type your explanation here..."
        class="w-full h-32 px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
      ></textarea>
      <div class="flex justify-between">
        <button
          @click="generateApplicationScenario"
          class="flex items-center space-x-2 px-3 py-2 bg-white/5 hover:bg-white/10 text-cosmic-300 hover:text-white rounded-lg transition-colors"
        >
          <RotateCcw class="h-4 w-4" />
          <span>New Scenario</span>
        </button>
        <button
          @click="handleSubmitAnswer"
          :disabled="!userAnswer.trim() || isLoading"
          class="cosmic-button flex items-center space-x-2 px-4 py-2"
          :class="{ 'opacity-50 cursor-not-allowed': !userAnswer.trim() || isLoading }"
        >
          <Send class="h-4 w-4" />
          <span>Submit</span>
        </button>
      </div>
    </div>

    <div v-else class="space-y-4">
      <!-- User Answer -->
      <div class="bg-white/5 border border-white/10 rounded-lg p-4">
        <div class="text-sm text-cosmic-300 mb-1">Your Response:</div>
        <div class="text-white text-sm">{{ userAnswer }}</div>
      </div>

      <!-- Feedback -->
      <div 
        :class="[
          'p-4 rounded-lg',
          feedback === 'correct' 
            ? 'bg-green-500/20 border border-green-500/30 text-green-300' 
            : 'bg-red-500/20 border border-red-500/30 text-red-300'
        ]"
      >
        <div class="flex items-center mb-2">
          <component 
            :is="feedback === 'correct' ? CheckCircle : Lightbulb" 
            class="h-5 w-5 mr-2" 
          />
          <span class="font-medium">
            {{ feedback === 'correct' 
              ? 'Great application of the concept!' 
              : 'Consider these additional insights:'}}
          </span>
        </div>
        <div class="text-sm">{{ aiSuggestion }}</div>
      </div>

      <!-- Next Card Button -->
      <div class="flex justify-between">
        <button
          @click="resetCard"
          class="flex items-center space-x-2 px-3 py-2 bg-white/5 hover:bg-white/10 text-cosmic-300 hover:text-white rounded-lg transition-colors"
        >
          <RotateCcw class="h-4 w-4" />
          <span>Try Again</span>
        </button>
        <button
          @click="handleNextCard"
          class="cosmic-button flex items-center space-x-2 px-4 py-2"
        >
          <ArrowRight class="h-4 w-4" />
          <span>Next Card</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { 
  Globe, 
  Lightbulb, 
  CheckCircle, 
  RotateCcw,
  Send,
  Star,
  ArrowRight,
  FileText
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'

interface Props {
  flashcard: {
    id: string
    term: string
    definition: string
    difficulty: 'easy' | 'medium' | 'hard'
    confidence_level: number
    content_source?: string
  }
  onAnswered?: (isCorrect: boolean) => void
}

// Props and emits
const props = withDefaults(defineProps<Props>(), {
  onAnswered: undefined
})

const emit = defineEmits<{
  (e: 'answered', isCorrect: boolean): void
  (e: 'next'): void
}>()

// Composables
const authStore = useAuthStore()
const toast = useToast()

// State
const applicationScenario = ref('')
const userAnswer = ref('')
const isAnswering = ref(true)
const isLoading = ref(true)
const feedback = ref<'correct' | 'incorrect' | null>(null)
const aiSuggestion = ref('')
const keyPoints = ref<string[]>([])

// Watch for flashcard changes
watch(() => props.flashcard, () => {
  generateApplicationScenario()
})

// Lifecycle hooks
onMounted(() => {
  generateApplicationScenario()
})

// Methods
const generateApplicationScenario = () => {
  isLoading.value = true
  isAnswering.value = true
  userAnswer.value = ''
  feedback.value = null
  
  // In a real implementation, this would call an API to generate a scenario
  // For this demo, we'll simulate AI-generated content
  setTimeout(() => {
    const scenario = generateScenarioForConcept(
      props.flashcard.term,
      props.flashcard.definition,
      props.flashcard.difficulty
    )
    applicationScenario.value = scenario.scenario
    keyPoints.value = scenario.keyPoints
    isLoading.value = false
  }, 1500)
}

const handleSubmitAnswer = () => {
  if (!userAnswer.value.trim()) {
    toast.error('Please enter your answer')
    return
  }

  isAnswering.value = false
  
  // Simulate AI evaluation of answer
  // In a real implementation, this would use more sophisticated
  // evaluation based on the key points of a good answer
  const hasKeywords = keyPoints.value.some(point => 
    userAnswer.value.toLowerCase().includes(point.toLowerCase())
  )
  
  const isCorrect = hasKeywords || userAnswer.value.length > 100
  
  feedback.value = isCorrect ? 'correct' : 'incorrect'
  
  // Generate AI suggestion/feedback
  const suggestion = isCorrect
    ? getPositiveFeedback(props.flashcard.term, userAnswer.value)
    : getImprovementFeedback(props.flashcard.term, keyPoints.value)

  // Award XP for applying concepts to real-world scenarios
  if (isCorrect) {
    authStore.addExperience(35, "Applied Concept to Real-World Scenario")
  } else {
    // Award smaller amount for attempting application
    authStore.addExperience(10, "Practiced Real-World Application")
  }
  
  aiSuggestion.value = suggestion
  
  // Notify parent component
  if (props.onAnswered) {
    props.onAnswered(isCorrect)
  }
  emit('answered', isCorrect)
}

const resetCard = () => {
  userAnswer.value = ''
  isAnswering.value = true
  feedback.value = null
  aiSuggestion.value = ''
}

const handleNextCard = () => {
  emit('next')
  resetCard()
}

const getConfidenceColor = (level: number) => {
  if (level >= 4) return 'text-green-400'
  if (level >= 3) return 'text-star-400'
  return 'text-red-400'
}

// Helper functions to simulate AI-generated content

function generateScenarioForConcept(term: string, definition: string, difficulty: string): { scenario: string; keyPoints: string[] } {
  // Extract the key concept
  const conceptMatch = term.match(/what is (.+?)\??$/i) || 
                       term.match(/define (.+?)\??$/i) ||
                       term.match(/explain (.+?)\??$/i)
  
  const concept = conceptMatch ? conceptMatch[1].trim() : term.replace('?', '').trim()
  
  // Generate an appropriate scenario based on the concept
  // In a real implementation, this would use an AI model
  
  // Physics concepts
  if (concept.includes('force') || concept.includes('motion') || concept.includes('gravity')) {
    return {
      scenario: `You're designing a roller coaster for an amusement park. The park owner wants an exciting ride with multiple loops and steep drops, but is concerned about safety. Explain how ${concept} applies to your roller coaster design and how understanding this concept helps ensure both an exhilarating and safe experience.`,
      keyPoints: ['safety', 'acceleration', 'velocity', 'inertia', 'centripetal', 'potential energy', 'kinetic energy']
    }
  }
  
  // Biology concepts
  if (concept.includes('cell') || concept.includes('DNA') || concept.includes('enzyme') || concept.includes('mitosis')) {
    return {
      scenario: `A pharmaceutical company is developing a new drug to treat a rare genetic disease. The drug needs to interact with specific cells in the human body. Explain how understanding ${concept} would help the researchers design an effective treatment with minimal side effects.`,
      keyPoints: ['target cells', 'specificity', 'mechanism', 'interaction', 'drug delivery', 'genetic']
    }
  }
  
  // Math concepts
  if (concept.includes('calculus') || concept.includes('equation') || concept.includes('function') || concept.includes('theorem')) {
    return {
      scenario: `You're part of a team designing a navigation app for smartphones. Your task is to calculate the most efficient route between two points in a city with variable traffic conditions. Explain how ${concept} would be applied to create an algorithm that finds optimal routes in real-time.`,
      keyPoints: ['algorithm', 'optimization', 'variables', 'constraints', 'efficiency', 'calculation']
    }
  }
  
  // Chemistry concepts
  if (concept.includes('reaction') || concept.includes('molecule') || concept.includes('acid') || concept.includes('compound')) {
    return {
      scenario: `You're a food scientist working for a company that produces baking ingredients. You need to create a new type of baking powder that works faster at lower temperatures. Explain how your understanding of ${concept} guides your development process and testing methods.`,
      keyPoints: ['reaction rate', 'temperature', 'catalyst', 'pH levels', 'formulation', 'testing']
    }
  }
  
  // Computer Science concepts
  if (concept.includes('algorithm') || concept.includes('programming') || concept.includes('data structure')) {
    return {
      scenario: `You're developing a recommendation system for a streaming platform that suggests movies and shows based on viewing history. Explain how ${concept} would be applied to create personalized recommendations that improve user satisfaction and engagement.`,
      keyPoints: ['user data', 'pattern recognition', 'performance', 'implementation', 'optimization', 'accuracy']
    }
  }
  
  // Economics concepts
  if (concept.includes('supply') || concept.includes('demand') || concept.includes('market') || concept.includes('economic')) {
    return {
      scenario: `You're advising a small local business that sells handcrafted furniture during a period of rising inflation and supply chain disruptions. Explain how your understanding of ${concept} helps you develop strategies for pricing, inventory management, and business growth in these challenging conditions.`,
      keyPoints: ['pricing strategy', 'consumer behavior', 'market factors', 'competition', 'optimization', 'forecasting']
    }
  }
  
  // Default for other concepts
  return {
    scenario: `You're giving a presentation to high school students about careers in your field. A student asks for a concrete example of how ${concept} is used in the real world. Provide a clear explanation with a specific scenario where this concept is applied in a professional setting or everyday situation.`,
    keyPoints: ['practical application', 'example', 'relevance', 'impact', 'everyday use']
  }
}

function getPositiveFeedback(concept: string, userAnswer: string): string {
  const positiveFeedback = [
    `Excellent application! You've clearly connected the theoretical aspects of ${concept} to practical scenarios. Your explanation demonstrates a deep understanding of the concept's real-world implications.`,
    
    `Great work! Your response effectively bridges the gap between classroom theory and real-world application. This kind of practical understanding is exactly what makes knowledge valuable.`,
    
    `Well done! You've articulated the practical value of ${concept} very effectively. This kind of thinking helps solidify your understanding and makes the knowledge more memorable and useful.`,
    
    `Perfect! Your explanation shows how ${concept} isn't just an abstract idea but a practical tool with real-world impact. This connection is crucial for deep understanding.`
  ]
  
  return positiveFeedback[Math.floor(Math.random() * positiveFeedback.length)]
}

function getImprovementFeedback(concept: string, keyPoints: string[]): string {
  // Select 2-3 key points at random to mention
  const shuffled = [...keyPoints].sort(() => 0.5 - Math.random())
  const selectedPoints = shuffled.slice(0, Math.min(3, shuffled.length))
  
  const pointsList = selectedPoints.map(point => `- Consider how ${point} relates to the scenario\n`).join('')
  
  const improvementFeedback = [
    `Your answer contains some good elements, but could be strengthened by making more explicit connections between ${concept} and the practical scenario. Consider these aspects:\n\n${pointsList}\nThink about specific mechanisms and causality in your explanation.`,
    
    `You're on the right track! To enhance your answer, focus more on how ${concept} directly impacts the outcomes in this scenario. Key considerations include:\n\n${pointsList}\nTry to be more specific about the practical implications.`,
    
    `Good start! To strengthen the application, consider explaining:\n\n${pointsList}\nRemember that real-world applications often involve multiple factors working together.`
  ]
  
  return improvementFeedback[Math.floor(Math.random() * improvementFeedback.length)]
}
</script>