<template>
  <div class="glass-card p-6">
    <h3 class="text-xl font-bold text-white mb-4 flex items-center">
      <Sparkles class="h-5 w-5 mr-2 text-cosmic-400" />
      AI Flashcard Generator
    </h3>
    
    <div class="space-y-6">
      <!-- Input Methods Tabs -->
      <div class="flex space-x-2 border-b border-white/10">
        <button 
          v-for="tab in inputTabs" 
          :key="tab.id"
          @click="activeInputMethod = tab.id"
          :class="[
            'px-4 py-2 transition-colors',
            activeInputMethod === tab.id 
              ? 'text-white border-b-2 border-cosmic-500' 
              : 'text-cosmic-300 hover:text-white'
          ]"
        >
          <div class="flex items-center space-x-2">
            <component :is="tab.icon" class="h-4 w-4" />
            <span>{{ tab.label }}</span>
          </div>
        </button>
      </div>

      <!-- Text Input -->
      <div v-if="activeInputMethod === 'text'" class="space-y-4">
        <textarea
          v-model="textInput"
          placeholder="Paste text or type content to generate flashcards from..."
          rows="6"
          class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
        ></textarea>

        <div class="flex items-center justify-between text-sm">
          <div class="text-cosmic-300">
            <span v-if="textInput.length > 0">{{ textInput.length }} characters</span>
            <span v-else>Enter at least 50 characters for best results</span>
          </div>
          <div class="text-cosmic-300">
            Estimated cards: {{ estimateCardCount('text') }}
          </div>
        </div>
      </div>

      <!-- File Upload Input -->
      <div v-else-if="activeInputMethod === 'file'" class="space-y-4">
        <div 
          class="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-cosmic-500/50 transition-all"
          @dragover.prevent="dragOver = true"
          @dragleave.prevent="dragOver = false"
          @drop.prevent="handleFileDrop"
          :class="{ 'border-cosmic-500/50 bg-cosmic-500/5': dragOver }"
        >
          <div v-if="!selectedFile">
            <Upload class="h-12 w-12 text-cosmic-400 mx-auto mb-4" />
            <p class="text-cosmic-300 mb-2">Drag & drop a file or click to browse</p>
            <p class="text-cosmic-400 text-sm mb-4">Supports PDF, images, audio, and video</p>
            <label class="cosmic-button cursor-pointer">
              <span>Select File</span>
              <input 
                type="file" 
                class="hidden" 
                @change="handleFileSelect"
                accept="image/*,application/pdf,audio/*,video/*"
              >
            </label>
          </div>
          <div v-else>
            <div class="flex items-center justify-center mb-4">
              <component :is="getFileIcon(selectedFile.type)" class="h-10 w-10 text-cosmic-400" />
            </div>
            <p class="text-white font-medium mb-1">{{ selectedFile.name }}</p>
            <p class="text-cosmic-300 text-sm mb-4">{{ formatFileSize(selectedFile.size) }}</p>
            <div class="flex space-x-3 justify-center">
              <button 
                @click="selectedFile = null"
                class="text-cosmic-300 hover:text-white"
              >
                Remove
              </button>
              <button 
                class="cosmic-button text-sm"
              >
                Process File
              </button>
            </div>
          </div>
        </div>
        <p class="text-cosmic-400 text-xs text-center">
          Files are processed securely using AI to extract key concepts and generate flashcards
        </p>
      </div>

      <!-- URL Input -->
      <div v-else-if="activeInputMethod === 'url'" class="space-y-4">
        <div class="relative">
          <Globe class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-cosmic-400" />
          <input
            type="url"
            v-model="urlInput"
            placeholder="Enter article or webpage URL..."
            class="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
          />
        </div>
        <p class="text-cosmic-400 text-xs">
          The AI will analyze the content and generate flashcards from key concepts and information
        </p>
      </div>

      <!-- AI Chat Input -->
      <div v-else-if="activeInputMethod === 'ai'" class="space-y-4">
        <div class="bg-white/5 border border-white/10 rounded-lg p-4">
          <p class="text-cosmic-300 mb-3">Ask Draco AI to create flashcards for any topic or concept</p>
          <div class="relative">
            <input
              type="text"
              v-model="aiPrompt"
              placeholder="e.g., Generate flashcards about quantum physics..."
              class="w-full pl-4 pr-10 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
            />
            <Send class="absolute right-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-cosmic-400" />
          </div>
        </div>
        <div class="flex flex-wrap gap-2">
          <button 
            v-for="(suggestion, index) in aiSuggestions" 
            :key="index"
            @click="aiPrompt = suggestion"
            class="text-xs bg-cosmic-500/20 text-cosmic-300 px-3 py-1 rounded-full hover:bg-cosmic-500/30 transition-colors"
          >
            {{ suggestion }}
          </button>
        </div>
      </div>

      <!-- Generated Flashcards Preview -->
      <div v-if="generatedFlashcards.length > 0" class="space-y-4">
        <h4 class="font-bold text-white border-b border-white/10 pb-2">Preview Generated Flashcards</h4>
        <div class="max-h-60 overflow-y-auto space-y-2">
          <div 
            v-for="(card, index) in generatedFlashcards" 
            :key="index"
            class="p-3 bg-white/5 border border-white/10 rounded-lg"
          >
            <div class="flex items-center justify-between mb-1">
              <span class="text-cosmic-300 text-sm">Card {{ index + 1 }}</span>
              <span 
                class="text-xs px-2 py-0.5 rounded-full"
                :class="[
                  card.difficulty === 'easy' ? 'bg-green-500/20 text-green-300' :
                  card.difficulty === 'hard' ? 'bg-red-500/20 text-red-300' :
                  'bg-yellow-500/20 text-yellow-300'
                ]"
              >
                {{ card.difficulty }}
              </span>
            </div>
            <div class="text-white font-medium">{{ card.term }}</div>
            <div class="text-cosmic-300 text-sm mt-1">{{ card.definition }}</div>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-col sm:flex-row gap-3">
        <button
          @click="generateFlashcards"
          class="cosmic-button flex items-center justify-center space-x-2"
          :disabled="isGenerating || !hasValidInput()"
        >
          <Sparkles v-if="!isGenerating" class="h-4 w-4" />
          <div v-else class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
          <span>{{ isGenerating ? 'Generating...' : 'Generate Flashcards' }}</span>
        </button>
        
        <button
          v-if="generatedFlashcards.length > 0"
          @click="saveFlashcards"
          class="nebula-button flex items-center justify-center space-x-2"
        >
          <Save class="h-4 w-4" />
          <span>Save Flashcards</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Sparkles, 
  FileText, 
  Image, 
  Upload, 
  Globe, 
  Bot, 
  FileImage, 
  FileAudio, 
  FileVideo, 
  FilePlus, 
  Send,
  Save
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface Props {
  userId: string
}

interface FlashcardPreview {
  term: string
  definition: string
  difficulty: 'easy' | 'medium' | 'hard'
}

// Props
const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
  (e: 'flashcardsGenerated'): void
}>()

// Composables
const toast = useToast()
const authStore = useAuthStore()

// Computed
const hasValidInput = computed(() => {
  switch (activeInputMethod.value) {
    case 'text':
      return textInput.value.trim().length >= 50;
    case 'url':
      return urlInput.value.trim().length > 0;
    case 'ai':
      return aiPrompt.value.trim().length > 0;
    case 'file':
      return selectedFile.value !== null;
    default:
      return false;
  }
})

// State
const activeInputMethod = ref('text')
const textInput = ref('')
const urlInput = ref('')
const aiPrompt = ref('')
const selectedFile = ref<File | null>(null)
const dragOver = ref(false)
const isGenerating = ref(false)
const generatedFlashcards = ref<FlashcardPreview[]>([])

// Input tabs
const inputTabs = [
  { id: 'text', label: 'Text', icon: FileText },
  { id: 'file', label: 'File Upload', icon: Upload },
  { id: 'url', label: 'URL', icon: Globe },
  { id: 'ai', label: 'AI Chat', icon: Bot }
]

// AI suggestions
const aiSuggestions = [
  'Generate flashcards about quantum physics',
  'Create cards explaining neural networks',
  'Make flashcards for organic chemistry reactions',
  'Create history timeline flashcards for World War II'
]

// Methods
const handleFileSelect = (event: Event) => {
  const input = event.target as HTMLInputElement
  if (input.files && input.files.length > 0) {
    selectedFile.value = input.files[0]
  }
}

const handleFileDrop = (event: DragEvent) => {
  dragOver.value = false
  if (!event.dataTransfer?.files.length) return
  selectedFile.value = event.dataTransfer.files[0]
}

const getFileIcon = (fileType: string) => {
  if (fileType.startsWith('image/')) return FileImage
  if (fileType.startsWith('audio/')) return FileAudio
  if (fileType.startsWith('video/')) return FileVideo
  return FilePlus
}

const formatFileSize = (bytes: number) => {
  if (bytes < 1024) return bytes + ' bytes'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(2) + ' MB'
}

const estimateCardCount = (source: string) => {
  switch (source) {
    case 'text':
      // Rough estimate based on text length
      return Math.max(0, Math.floor(textInput.value.length / 150))
    case 'file':
      // Placeholder estimate
      return selectedFile.value ? 5 : 0
    case 'url':
      // Placeholder estimate
      return urlInput.value.trim() ? 8 : 0
    case 'ai':
      // Placeholder estimate
      return aiPrompt.value.trim() ? 6 : 0
    default:
      return 0
  }
}

const generateFlashcards = async () => {
  if (isGenerating.value) return
  
  let source = activeInputMethod.value
  let content = '', contentSource = source
  
  switch (source) {
    case 'text':
      if (textInput.value.trim().length < 50) {
        toast.error('Please enter at least 50 characters')
        return
      }
      content = textInput.value
      break
    case 'url':
      if (!urlInput.value.trim()) {
        toast.error('Please enter a valid URL')
        return
      }
      content = urlInput.value
      break
    case 'ai':
      if (!aiPrompt.value.trim()) {
        toast.error('Please enter a prompt for the AI')
        return
      }
      content = aiPrompt.value
      break
    case 'file':
      if (!selectedFile.value) {
        toast.error('Please select a file')
        return
      }
      // File upload would require a different approach
      // For demo purposes, we'll just use the file name
      content = selectedFile.value.name
      contentSource = selectedFile.value.type.split('/')[0] // image, audio, etc.
      break
  }
  
  isGenerating.value = true
  
  try {
    if (source === 'text' || source === 'ai') {
      // Call the Supabase RPC function to generate flashcards from text
      const { data, error } = await supabase.rpc(
        'generate_flashcards_from_text',
        {
          input_text: content,
          user_id: props.userId,
          content_source: contentSource
        }
      )

      if (error) {
        throw error
      }

      if (data && Array.isArray(data)) {
        generatedFlashcards.value = data.map(card => ({
          term: card.term,
          definition: card.definition,
          difficulty: card.difficulty
        }))
      } else {
        // If no cards were generated, show empty state
        generatedFlashcards.value = []
        toast.info("Couldn't generate flashcards from this content. Try providing more detailed text.")
      }
    } else {
      // For file and URL sources, we need a different approach
      // For now, simulate with mock data until backend is ready
      generatedFlashcards.value = generateMockFlashcards(content, source)
      toast.info("File and URL processing will be available soon. Using simulated data for now.")
    }

    if (generatedFlashcards.value.length > 0) {
      isGenerating.value = false
      toast.success(`Generated ${generatedFlashcards.value.length} flashcards!`)
    } else {
      isGenerating.value = false
    }
  } catch (error) {
    console.error('Error generating flashcards:', error)
    toast.error('Failed to generate flashcards. Please try again.')
    isGenerating.value = false
  }
}

const generateMockFlashcards = (content: string, source: string): FlashcardPreview[] => {
  // For demo purposes, we'll generate some mock flashcards based on input content
  const cards: FlashcardPreview[] = []
  
  // Generate different cards based on input method
  if (source === 'text') {
    // Extract potential terms and definitions from text
    const sentences = content.split(/[.!?]/).filter(s => s.trim().length > 10)
    
    for (let i = 0; i < Math.min(5, sentences.length); i++) {
      const sentence = sentences[i].trim()
      const words = sentence.split(' ')
      
      if (words.length > 5) {
        // Create term as a question
        const keyTerm = words.slice(0, 3).join(' ')
        const term = `What is ${keyTerm}?`
        const definition = sentence
        
        cards.push({
          term,
          definition,
          difficulty: ['easy', 'medium', 'hard'][Math.floor(Math.random() * 3)] as 'easy' | 'medium' | 'hard'
        })
      }
    }
  } else if (source === 'ai') {
    // For AI prompt, generate thematic cards
    const topics = [
      'quantum mechanics',
      'neural networks',
      'organic chemistry',
      'World War II'
    ]
    
    const matchedTopic = topics.find(topic => content.toLowerCase().includes(topic.toLowerCase()))
    
    if (matchedTopic === 'quantum mechanics') {
      cards.push(
        { term: "What is Schrödinger's equation?", definition: "A linear partial differential equation that describes the wave function of a quantum-mechanical system", difficulty: "hard" },
        { term: "What is quantum entanglement?", definition: "A physical phenomenon that occurs when a pair of particles interact in ways such that the quantum state of each particle cannot be described independently of the state of the others", difficulty: "hard" },
        { term: "What is the uncertainty principle?", definition: "A principle in quantum mechanics that states that the position and velocity of an object cannot both be measured exactly at the same time", difficulty: "medium" }
      )
    } else if (matchedTopic === 'neural networks') {
      cards.push(
        { term: "What is a neural network?", definition: "A computational system modeled after the human brain that consists of interconnected nodes (neurons) organized in layers", difficulty: "medium" },
        { term: "What is backpropagation?", definition: "An algorithm used to train neural networks by calculating gradients and adjusting weights to minimize error", difficulty: "hard" },
        { term: "What is an activation function?", definition: "A mathematical function that determines the output of a neural network node given a set of inputs", difficulty: "medium" }
      )
    } else {
      // Generic cards
      cards.push(
        { term: "What are the key concepts in " + content + "?", definition: "The main principles include fundamental theories, practical applications, and historical context.", difficulty: "medium" },
        { term: "Who are the pioneering figures in " + content + "?", definition: "Several key researchers and theorists have contributed to this field, each adding significant advancements.", difficulty: "easy" },
        { term: "How is " + content + " applied in modern contexts?", definition: "This concept is widely used across various industries and scientific fields for solving complex problems.", difficulty: "hard" }
      )
    }
  } else {
    // For URL or file, generate generic cards
    cards.push(
      { term: "What is the main concept discussed in this resource?", definition: "The resource covers key principles and applications related to the subject matter.", difficulty: "medium" },
      { term: "What are the supporting theories mentioned?", definition: "Several theoretical frameworks are presented to explain the phenomena.", difficulty: "hard" },
      { term: "How does this relate to practical applications?", definition: "The concepts can be applied to solve real-world problems across multiple domains.", difficulty: "medium" }
    )
  }
  
  return cards
}

const saveFlashcards = async () => {
  if (generatedFlashcards.value.length === 0) {
    toast.error('No flashcards to save')
    return
  }
  
  try {
    // Prepare flashcards with user ID
    const flashcardsToSave = generatedFlashcards.value.map((card: any) => ({
      ...card,
      user_id: authStore.user?.id,
      content_source: activeInputMethod.value,
      ai_generated: true
    }))
    
    // Insert flashcards into database
    const { data, error } = await supabase
      .from('flashcards')
      .insert(flashcardsToSave)
      .select('*')
    
    if (error) throw error
    
    // Notify parent component
    emit('flashcardsGenerated')
    
    // Award XP for generating flashcards
    authStore.addExperience(15 * flashcardsToSave.length, `Generated ${flashcardsToSave.length} Flashcards with AI`)
    
    toast.success(`${flashcardsToSave.length} flashcards saved successfully!`)
    
    generatedFlashcards.value = []
    
    // Reset form
    resetForm()
  } catch (error) {
    console.error('Error saving flashcards:', error)
    toast.error('Failed to save flashcards')
  }
}

const resetForm = () => {
  textInput.value = ''
  urlInput.value = ''
  aiPrompt.value = ''
  selectedFile.value = null
  generatedFlashcards.value = []
  activeInputMethod.value = 'text'
}
</script>