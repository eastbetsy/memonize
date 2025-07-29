<template>
  <Transition>
    <div v-if="isOpen" class="fixed bottom-4 right-4 w-96 max-w-[calc(100vw-2rem)] z-50">
      <div class="glass-card overflow-hidden relative">
        <!-- Background effects -->
        <div class="absolute inset-0 bg-gradient-to-br from-cosmic-600/10 to-nebula-600/10"></div>
        <div class="absolute top-0 right-0 w-32 h-32 bg-cosmic-500/20 rounded-full blur-3xl"></div>

        <!-- Header -->
        <div class="relative z-10 flex items-center justify-between p-4 border-b border-white/10">
          <div class="flex items-center space-x-3">
            <div 
              class="p-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-lg"
              :class="{'animate-spin-slow': isTyping}"
            >
              <Bot class="h-5 w-5 text-white" />
            </div>
            <div>
              <h3 class="font-bold text-white text-glow">Draco AI</h3>
              <p class="text-xs text-cosmic-300">Your Cosmic Dragon Guide</p>
            </div>
          </div>
          
          <div class="flex items-center space-x-2">
            <button
              @click="isMinimized = !isMinimized"
              class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
            >
              <component :is="isMinimized ? Maximize2 : Minimize2" class="h-4 w-4" />
            </button>
            <button
              @click="$emit('close')"
              class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
            >
              <X class="h-4 w-4" />
            </button>
          </div>
        </div>

        <div v-if="!isMinimized">
          <!-- Messages -->
          <div class="relative z-10 h-96 overflow-y-auto p-4 space-y-4">
            <TransitionGroup name="message">
              <div 
                v-for="message in messages" 
                :key="message.id"
                :class="[
                  'flex',
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
            </TransitionGroup>

            <div v-if="isTyping" class="flex justify-start">
              <div class="bg-white/10 rounded-lg p-3 border border-white/10">
                <div class="flex items-center space-x-2">
                  <Sparkles class="h-4 w-4 text-cosmic-400 animate-pulse" />
                  <span class="text-cosmic-300 text-sm">Draco is channeling cosmic wisdom...</span>
                </div>
              </div>
            </div>
            
            <div ref="messagesEndRef"></div>
          </div>

          <!-- Input -->
          <div class="relative z-10 p-4 border-t border-white/10">
            <div class="flex items-center space-x-2">
              <input
                type="text"
                v-model="input"
                @keyup.enter="sendMessage"
                placeholder="Ask Draco anything about your studies..."
                class="flex-1 px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all text-sm"
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
            
            <div class="flex items-center justify-center mt-2 text-xs text-cosmic-400">
              <Brain class="h-3 w-3 mr-1" />
              Powered by Draconic Cosmic Intelligence
            </div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, nextTick } from 'vue'
import VueMarkdown from 'vue3-markdown-it'
import { 
  Bot, 
  Send, 
  Sparkles, 
  Brain, 
  X,
  Minimize2,
  Maximize2,
  Lightbulb,
  HelpCircle
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

// Types
interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
  suggestions?: string[]
}

// Props
interface Props {
  isOpen: boolean
  context?: {
    currentPage?: string
    selectedText?: string
    recentActivity?: any[]
    studyGoals?: string[]
  }
}

const props = withDefaults(defineProps<Props>(), {
  context: () => ({})
})

const emit = defineEmits<{
  (e: 'close'): void
}>()

// Auth store
const authStore = useAuthStore()

// State
const messages = ref<Message[]>([])
const input = ref('')
const isTyping = ref(false)
const isMinimized = ref(false)
const messagesEndRef = ref<HTMLElement | null>(null)

// Watch for changes
watch(() => props.isOpen, (newVal) => {
  if (newVal && messages.value.length === 0) {
    // Start with initial question
    const initialQuestion: Message = {
      id: Date.now().toString(),
      role: 'assistant',
      content: getWelcomeMessage(),
      timestamp: new Date(),
      suggestions: getInitialSuggestions()
    }
    messages.value.push(initialQuestion)
    
    // If context includes selected text, acknowledge it
    if (props.context?.selectedText) {
      setTimeout(() => {
        isTyping.value = true
        setTimeout(() => {
          messages.value.push({
            id: Date.now().toString(),
            role: 'assistant',
            content: `I see you've selected some text: "${props.context?.selectedText}". How can I help you understand or work with this content?`,
            timestamp: new Date(),
            suggestions: [
              'Explain this concept',
              'Create flashcards from this',
              'Give me study tips for this',
              'Find related resources'
            ]
          })
          isTyping.value = false
        }, 1500)
      }, 500)
    }
  }
})

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

  // Simulate AI response
  setTimeout(() => {
    const aiResponse = generateAIResponse(userMessage.content)
    const assistantMessage: Message = {
      id: (Date.now() + 1).toString(),
      role: 'assistant',
      content: aiResponse.content,
      timestamp: new Date(),
      suggestions: aiResponse.suggestions
    }
    messages.value.push(assistantMessage)
    isTyping.value = false
  }, 1500 + Math.random() * 1000)
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

// Helper functions for AI messages
function getWelcomeMessage(): string {
  const greetings = [
    "🐉 Greetings, cosmic explorer! I'm **Draco**, your AI study companion from the constellation of knowledge. How can I help you navigate the universe of learning today?",
    "🚀 Welcome back to your learning odyssey! I'm **Draco**, here to help you optimize your study sessions and reach new stellar heights of understanding.",
    "✨ Hello, knowledge seeker! I'm **Draco**, your cosmic dragon guide. Ready to unlock the mysteries of learning together? What shall we explore today?"
  ]
  return greetings[Math.floor(Math.random() * greetings.length)]
}

function getInitialSuggestions(): string[] {
  const baseSuggestions = [
    "Analyze my study patterns",
    "Create a study plan",
    "Generate quiz questions",
    "Suggest study techniques"
  ]

  if (props.context?.currentPage === 'notes') {
    return [
      "Help me organize these notes",
      "Suggest flashcards from my notes",
      "Create a summary",
      "Find knowledge gaps"
    ]
  } else if (props.context?.currentPage === 'flashcards') {
    return [
      "Optimize my review schedule",
      "Create practice tests",
      "Identify weak areas",
      "Suggest mnemonics"
    ]
  }

  return baseSuggestions
}

// This would be replaced by a real AI implementation
function generateAIResponse(userInput: string): { content: string, suggestions?: string[] } {
  const lower = userInput.toLowerCase()

  if (lower.includes('study pattern') || lower.includes('analyze')) {
    return {
      content: `## 📊 Study Pattern Analysis

I've analyzed your cosmic learning patterns with my draconic wisdom:

### 🌟 Peak Performance Window
- **Best Study Time**: Evening sessions (7-9 PM)
- **Completion Rate**: 78% success rate
- **Optimal Session Length**: 25-minute Pomodoro intervals

### 📚 Subject Mastery Levels
| Subject | Strength Level | Focus Needed |
|---------|---------------|--------------|
| Physics | ⭐⭐⭐⭐ | Maintenance |
| Mathematics | ⭐⭐⭐⭐ | Maintenance |
| Chemistry | ⭐⭐ | **High Priority** |

**Draco's Recommendation**: Focus your dragon energy on Chemistry fundamentals, particularly during your peak evening hours.`,
      suggestions: [
        "Create optimized schedule",
        "Focus on weak subjects",
        "Suggest study techniques",
        "Set learning goals"
      ]
    }
  }

  if (lower.includes('study plan') || lower.includes('schedule')) {
    return {
      content: `## 🎯 Draco's Personalized Cosmic Study Plan

### 📅 Week 1-2: Foundation Building Phase

#### 🔬 Subject Schedule
- **Physics**: 3 sessions/week *(focus on mechanics)*
- **Chemistry**: 4 sessions/week *(priority catch-up)*
- **Mathematics**: 2 sessions/week *(maintenance mode)*

#### 🧠 Draco's Study Methods
1. **Active Recall** - Test yourself without looking at notes
2. **Spaced Repetition** - Review formulas at increasing intervals
3. **Daily Practice** - Solve problems consistently
4. **Dragon Technique** - Explain concepts as if teaching a young dragon

### ⚡ Power-Up Sessions
- **Monday**: Chemistry fundamentals
- **Wednesday**: Physics problem-solving
- **Friday**: Math integration practice

Would you like me to breathe some fire into this plan and create calendar events?`,
      suggestions: [
        "Create calendar events",
        "Adjust difficulty",
        "Add more subjects",
        "Set reminders"
      ]
    }
  }

  // Default response
  return {
    content: `## 🌌 Draco's Analysis\n\nI'm here to help with any study-related questions. What specific area would you like to explore together?`,
    suggestions: [
      "Break down a topic",
      "Find learning resources",
      "Create an action plan",
      "Practice exercises"
    ]
  }
}
</script>

<style scoped>
.v-enter-active,
.v-leave-active {
  transition: all 0.3s ease;
}

.v-enter-from,
.v-leave-to {
  opacity: 0;
  transform: scale(0.9) translateX(100px);
}

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

.animate-spin-slow {
  animation: spin 2s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>