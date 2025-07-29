<template>
  <div class="prose prose-invert prose-sm max-w-none">
    <div class="glass-card p-6 md:p-8">
      <!-- Header -->
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-bold text-white flex items-center">
          <MessageCircle class="h-5 w-5 mr-2 text-cosmic-400" />
          Interactive Learning
        </h3>
        
        <div class="flex items-center space-x-2">
          <div class="text-xs text-cosmic-300 px-2 py-1 bg-white/10 rounded-full">
            {{ flashcard.difficulty }}
          </div>
          <div class="flex">
            <Star 
              v-for="i in 5" 
              :key="i"
              class="h-4 w-4"
              :class="[
                i <= flashcard.confidence_level
                  ? `${getConfidenceColor(flashcard.confidence_level)} fill-current`
                  : 'text-cosmic-600'
              ]"
            />
          </div>
        </div>
      </div>

      <!-- Messages Container -->
      <div class="bg-white/5 rounded-lg p-4 h-80 overflow-y-auto mb-4 border border-white/10">
        <TransitionGroup name="message">
          <div 
            v-for="message in messages" 
            :key="message.id"
            :class="[
              'flex mb-3',
              message.role === 'user' ? 'justify-end' : 'justify-start'
            ]"
          >
            <div 
              :class="[
                'max-w-[80%] rounded-lg p-3',
                message.role === 'user'
                  ? 'bg-cosmic-500 text-white'
                  : 'bg-white/10 text-cosmic-100 border border-white/10'
              ]"
            >
              <div class="text-sm leading-relaxed">
                <div v-if="message.role === 'assistant'" class="prose prose-invert prose-sm max-w-none">
                  <VueMarkdown>{{ message.content }}</VueMarkdown>
                </div>
                <div v-else class="whitespace-pre-wrap">
                  {{ message.content }}
                </div>
              </div>
              
              <div v-if="message.suggestions && message.suggestions.length > 0" class="mt-3 flex flex-wrap gap-2">
                <button
                  v-for="(suggestion, index) in message.suggestions"
                  :key="index"
                  @click="handleSuggestionClick(suggestion)"
                  class="px-2 py-1 bg-white/10 hover:bg-white/20 rounded text-xs transition-colors border border-white/20"
                >
                  {{ suggestion }}
                </button>
              </div>
              
              <div class="text-xs text-cosmic-400 mt-2">
                {{ formatTimestamp(message.timestamp) }}
              </div>
            </div>
          </div>

          <div v-if="isTyping" :key="'typing'" class="flex justify-start mb-3">
            <div class="bg-white/10 rounded-lg p-3 border border-white/10">
              <div class="flex items-center space-x-1">
                <div class="w-2 h-2 bg-cosmic-400 rounded-full animate-pulse"></div>
                <div class="w-2 h-2 bg-cosmic-400 rounded-full animate-pulse delay-75"></div>
                <div class="w-2 h-2 bg-cosmic-400 rounded-full animate-pulse delay-150"></div>
              </div>
            </div>
          </div>
        </TransitionGroup>
        
        <div ref="messagesEndRef"></div>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-wrap gap-2 mb-4">
        <button
          @click="requestHint"
          class="flex items-center space-x-1 px-3 py-2 bg-white/5 hover:bg-white/10 rounded-lg text-cosmic-300 hover:text-white transition-colors text-sm"
        >
          <Lightbulb class="h-4 w-4" />
          <span>Hint</span>
        </button>
        
        <button
          @click="expressConfusion"
          class="flex items-center space-x-1 px-3 py-2 bg-white/5 hover:bg-white/10 rounded-lg text-cosmic-300 hover:text-white transition-colors text-sm"
        >
          <HelpCircle class="h-4 w-4" />
          <span>I'm confused</span>
        </button>
        
        <button
          @click="revealAnswer"
          class="flex items-center space-x-1 px-3 py-2 bg-white/5 hover:bg-white/10 rounded-lg text-cosmic-300 hover:text-white transition-colors text-sm"
        >
          <Sparkles class="h-4 w-4" />
          <span>Reveal answer</span>
        </button>

        <button
          v-if="hasAnswered"
          @click="requestNextCard"
          class="flex items-center space-x-1 px-3 py-2 bg-cosmic-500 hover:bg-cosmic-600 rounded-lg text-white transition-colors text-sm ml-auto"
        >
          <span>Next card</span>
        </button>
      </div>

      <!-- Correct/Incorrect Indicator -->
      <div 
        v-if="answered"
        :class="[
          'mb-4 p-3 rounded-lg',
          answered === 'correct' 
            ? 'bg-green-500/20 border border-green-500/50 text-green-300' 
            : 'bg-red-500/20 border border-red-500/50 text-red-300'
        ]"
      >
        <div class="flex items-center">
          <component 
            :is="answered === 'correct' ? Check : X" 
            class="h-5 w-5 mr-2" 
          />
          <span class="font-medium">
            {{ answered === 'correct' 
              ? 'Correct! Well done.' 
              : 'Not quite right. Let\'s learn from this.' 
            }}
          </span>
        </div>
      </div>

      <!-- Show full definition if needed -->
      <div v-if="showDefinition" class="mb-4 p-3 bg-cosmic-500/20 border border-cosmic-500/50 rounded-lg">
        <div class="text-sm text-cosmic-300 mb-1">Full Definition:</div>
        <div class="text-white">{{ flashcard.definition }}</div>
      </div>

      <!-- Input Area -->
      <div class="flex items-center space-x-2">
        <input
          type="text"
          v-model="input"
          @keyup.enter="sendMessage"
          placeholder="Type your answer or ask a question..."
          class="flex-1 px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
        />
        
        <button
          @click="sendMessage"
          :disabled="!input.trim() || isTyping"
          class="p-2 cosmic-button"
          :class="{'opacity-50 cursor-not-allowed': !input.trim() || isTyping}"
        >
          <Send class="h-4 w-4" />
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, nextTick } from 'vue'
import VueMarkdown from 'vue3-markdown-it'
import { 
  Star, 
  MessageCircle, 
  Send, 
  Lightbulb, 
  HelpCircle, 
  Check, 
  X,
  Sparkles
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  suggestions?: string[];
}

interface Props {
  flashcard: {
    id: string;
    term: string;
    definition: string;
    difficulty: 'easy' | 'medium' | 'hard';
    confidence_level: number;
    ai_generated?: boolean;
  };
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'complete', isCorrect: boolean): void
  (e: 'hintRequested'): void
  (e: 'next'): void
}>()

// Auth store
const authStore = useAuthStore()

// State
const messages = ref<Message[]>([])
const input = ref('')
const isTyping = ref(false)
const showDefinition = ref(false)
const hasAnswered = ref(false)
const answered = ref<'correct' | 'incorrect' | null>(null)
const messagesEndRef = ref<HTMLElement | null>(null)

// When component mounts
onMounted(() => {
  // Start with initial question
  const initialQuestion = {
    id: Date.now().toString(),
    role: 'assistant' as const,
    content: `Let's review this flashcard. ${props.flashcard.term}`,
    timestamp: new Date()
  }
  messages.value = [initialQuestion]
  
  // If the card is a question, add some explanation
  if (props.flashcard.term.includes('?')) {
    setTimeout(() => {
      isTyping.value = true
      setTimeout(() => {
        messages.value.push({
          id: Date.now().toString(),
          role: 'assistant',
          content: 'Take your time to think about this. You can type your answer, ask for a hint, or request more information.',
          timestamp: new Date()
        })
        isTyping.value = false
      }, 1000)
    }, 500)
  }
})

// Watch for changes
watch(
  () => props.flashcard,
  () => {
    // Reset state when flashcard changes
    messages.value = []
    input.value = ''
    showDefinition.value = false
    hasAnswered.value = false
    answered.value = null
    
    // Start with initial question
    const initialQuestion = {
      id: Date.now().toString(),
      role: 'assistant' as const,
      content: `Let's review this flashcard. ${props.flashcard.term}`,
      timestamp: new Date()
    }
    messages.value = [initialQuestion]
    
    // If the card is a question, add some explanation
    if (props.flashcard.term.includes('?')) {
      setTimeout(() => {
        isTyping.value = true
        setTimeout(() => {
          messages.value.push({
            id: Date.now().toString(),
            role: 'assistant',
            content: 'Take your time to think about this. You can type your answer, ask for a hint, or request more information.',
            timestamp: new Date()
          })
          isTyping.value = false
        }, 1000)
      }, 500)
    }
  }
)

// Watch messages and scroll to bottom
watch(messages, () => {
  nextTick(() => {
    scrollToBottom()
  })
})

// Methods
const sendMessage = () => {
  if (!input.value.trim()) return

  // Add user message
  const userMessage: Message = {
    id: Date.now().toString(),
    role: 'user',
    content: input.value,
    timestamp: new Date()
  }

  messages.value.push(userMessage)
  input.value = ''
  isTyping.value = true

  // Check if the answer is correct
  // This is a simple check - in a real app, you might use more sophisticated
  // text comparison methods, AI-based similarity checks, or keyword extraction
  const isCorrect = checkAnswer(userMessage.content, props.flashcard.definition)

  // Generate AI response based on user input
  setTimeout(() => {
    let response = '';
    let followUp = '';
    
    if (!hasAnswered.value) {
      if (isCorrect) {
        response = `That's correct! Great job.`;
        followUp = generateFollowUpQuestion();
        answered.value = 'correct';
        hasAnswered.value = true;
        emit('complete', true);
      } else if (isHintRequest(userMessage.content)) {
        response = generateHint();
        emit('hintRequested');
      } else if (isConfusedRequest(userMessage.content)) {
        response = `Let me help clarify. The question is about ${extractKeyTerm()}. Try thinking about ${generateAnalogy()}.`;
      } else if (isGiveUpRequest(userMessage.content)) {
        response = `The answer is: ${props.flashcard.definition}`;
        followUp = `Let's break this down to make sure you understand:`;
        showDefinition.value = true;
        hasAnswered.value = true;
        answered.value = 'incorrect';
        emit('complete', false);
      } else {
        // Answer is incorrect or unclear
        response = `That's not quite right. Let me help guide you in the right direction.`;
        followUp = generateHint();
      }
    } else {
      // User has already answered correctly or given up
      if (isCorrect) {
        response = `Yes, that's another good way to think about it!`;
      } else if (isNextRequest(userMessage.content)) {
        response = `Moving to the next card.`;
        emit('next');
        return;
      } else {
        response = `Let's think more about this concept. ${generateRelatedConcept()}`;
      }
    }

    const assistantMessage: Message = {
      id: Date.now().toString(),
      role: 'assistant',
      content: response,
      timestamp: new Date()
    }
    
    messages.value.push(assistantMessage)
    
    // Add follow-up if there is one
    if (followUp) {
      setTimeout(() => {
        messages.value.push({
          id: Date.now().toString(),
          role: 'assistant',
          content: followUp,
          timestamp: new Date()
        })
      }, 1000)
    }
    
    isTyping.value = false
  }, 1000 + Math.random() * 500)
}

const requestHint = () => {
  input.value = "Can you give me a hint?"
  sendMessage()
}

const expressConfusion = () => {
  input.value = "I'm confused about this question."
  sendMessage()
}

const revealAnswer = () => {
  input.value = "Show me the answer."
  sendMessage()
}

const requestNextCard = () => {
  input.value = "Next flashcard please."
  sendMessage()
}

const handleSuggestionClick = (suggestion: string) => {
  input.value = suggestion
}

const scrollToBottom = () => {
  if (messagesEndRef.value) {
    messagesEndRef.value.scrollIntoView({ behavior: 'smooth' })
  }
}

const formatTimestamp = (date: Date) => {
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

const getConfidenceColor = (level: number) => {
  if (level >= 4) return 'text-green-400'
  if (level >= 3) return 'text-star-400'
  return 'text-red-400'
}

// Helper functions
function checkAnswer(userAnswer: string, correctAnswer: string): boolean {
  // Convert both to lowercase for comparison
  const userLower = userAnswer.toLowerCase()
  const correctLower = correctAnswer.toLowerCase()
  
  // Simple keyword check
  // In a real app, you would use more sophisticated methods like semantic similarity
  const keywords = extractKeywords(correctLower)
  return keywords.some(keyword => userLower.includes(keyword)) ||
          calculateSimilarity(userLower, correctLower) > 0.5
}

function extractKeywords(text: string): string[] {
  // Remove common words and extract important keywords
  const words = text.split(/\s+/)
  const commonWords = ['a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'but', 'is', 'are', 'was', 'were', 'be', 'been', 'being']
  return words
    .filter(word => word.length > 3 && !commonWords.includes(word))
    .map(word => word.replace(/[.,;:!?]/g, ''))
}

function calculateSimilarity(str1: string, str2: string): number {
  // Simple Jaccard similarity between the two strings
  // In a real app, you would use more sophisticated methods
  const words1 = new Set(str1.split(/\s+/))
  const words2 = new Set(str2.split(/\s+/))
  const intersection = new Set([...words1].filter(x => words2.has(x)))
  const union = new Set([...words1, ...words2])
  return intersection.size / union.size
}

function isHintRequest(text: string): boolean {
  const lowerText = text.toLowerCase()
  return (
    lowerText.includes('hint') ||
    lowerText.includes('help') ||
    lowerText.includes('clue') ||
    lowerText.includes('not sure') ||
    lowerText.includes('give me a hint')
  )
}

function isConfusedRequest(text: string): boolean {
  const lowerText = text.toLowerCase()
  return (
    lowerText.includes('confused') ||
    lowerText.includes('don\'t understand') ||
    lowerText.includes('what do you mean') ||
    lowerText.includes('unclear')
  )
}

function isGiveUpRequest(text: string): boolean {
  const lowerText = text.toLowerCase()
  return (
    lowerText.includes('give up') ||
    lowerText.includes('tell me the answer') ||
    lowerText.includes('i don\'t know') ||
    lowerText.includes('reveal answer') ||
    lowerText.includes('show me the answer')
  )
}

function isNextRequest(text: string): boolean {
  const lowerText = text.toLowerCase()
  return (
    lowerText.includes('next') ||
    lowerText.includes('next card') ||
    lowerText.includes('next question') ||
    lowerText.includes('skip') ||
    lowerText.includes('another')
  )
}

function generateHint(): string {
  // Extract the definition to generate a hint
  const definition = props.flashcard.definition
  const keywords = extractKeywords(definition)
  
  // In a real app, you would use more sophisticated methods to generate hints
  if (keywords.length > 2) {
    // Give a hint with a few keywords
    const selectedKeywords = keywords.slice(0, 2)
    return `Think about concepts related to ${selectedKeywords.join(' and ')}. This might help you remember.`
  } else if (definition.length > 100) {
    // For long definitions, give the first part as a hint
    return `Here's a hint: The answer starts with "${definition.substring(0, 30)}..."`
  } else {
    // For shorter definitions, give a general hint
    return `Think about the key characteristics or functions related to this concept.`
  }
}

function extractKeyTerm(): string {
  // Simplify the question to extract key terms
  // Remove common question phrases
  return props.flashcard.term
    .replace(/what is/i, '')
    .replace(/what are/i, '')
    .replace(/define/i, '')
    .replace(/describe/i, '')
    .replace(/explain/i, '')
    .replace(/\?/g, '')
    .trim()
}

function generateAnalogy(): string {
  // Generate a simple analogy based on the flashcard content
  // In a real app, this would be more sophisticated and context-aware
  const analogies = [
    "comparing it to something familiar in everyday life",
    "thinking about it as a system with inputs and outputs",
    "visualizing it as a process with steps",
    "relating it to a similar concept you already know",
    "breaking it down into smaller components"
  ]
  
  return analogies[Math.floor(Math.random() * analogies.length)]
}

function generateFollowUpQuestion(): string {
  // Generate follow-up questions to deepen understanding
  // In a real app, this would be more sophisticated and context-aware
  const keyTerm = extractKeyTerm()
  const followUps = [
    `Can you explain how ${keyTerm} relates to other concepts in this topic?`,
    `What's an example of ${keyTerm} in a real-world context?`,
    `Why is understanding ${keyTerm} important?`,
    `Can you think of any potential applications of this concept?`,
    `How would you explain ${keyTerm} to someone who's never heard of it before?`
  ]
  
  return followUps[Math.floor(Math.random() * followUps.length)]
}

function generateRelatedConcept(): string {
  // Generate related concepts to expand understanding
  // In a real app, this would use knowledge graphs and semantic relationships
  const keywords = extractKeywords(props.flashcard.definition)
  if (keywords.length > 0) {
    const keyword = keywords[Math.floor(Math.random() * keywords.length)]
    return `Let's explore how "${keyword}" connects to the broader topic.`
  } else {
    return `Let's think about how this concept fits into the bigger picture.`
  }
}
</script>

<style scoped>
.message-enter-active,
.message-leave-active {
  transition: all 0.5s ease;
}

.message-enter-from {
  opacity: 0;
  transform: translateY(10px);
}

.message-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>