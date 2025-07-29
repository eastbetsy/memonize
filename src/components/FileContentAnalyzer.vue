<template>
  <div class="glass-card p-6">
    <div class="flex items-center space-x-4 mb-4">
      <component :is="getFileTypeIcon()" class="h-8 w-8 text-cosmic-400" />
      <div>
        <h3 class="text-lg font-bold text-white">{{ file.name }}</h3>
        <p class="text-sm text-cosmic-300">
          {{ (file.size / 1024 / 1024).toFixed(2) }} MB • {{ file.type || 'Unknown type' }}
        </p>
      </div>
    </div>
    
    <div class="space-y-4">
      <button
        v-if="status === 'idle'"
        @click="analyzeFile"
        class="w-full cosmic-button flex items-center justify-center space-x-2"
      >
        <Edit3 class="h-5 w-5" />
        <span>Analyze Content</span>
      </button>
      
      <div v-else-if="status === 'analyzing'" class="space-y-4">
        <div class="flex items-center justify-between mb-2">
          <span class="text-cosmic-300">Analyzing content...</span>
          <span class="text-cosmic-300">{{ Math.round(progress) }}%</span>
        </div>
        <div class="w-full h-2 bg-white/10 rounded-full">
          <div 
            class="h-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-full transition-all duration-300"
            :style="{ width: `${progress}%` }"
          ></div>
        </div>
        
        <div class="space-y-2 max-h-40 overflow-y-auto">
          <div 
            v-for="(step, index) in analysisSteps" 
            :key="index" 
            class="flex items-center space-x-2 text-sm"
          >
            <component 
              :is="index === analysisSteps.length - 1 ? Loader : CheckCircle" 
              :class="[
                'h-4 w-4',
                index === analysisSteps.length - 1 ? 'text-cosmic-400 animate-spin' : 'text-green-400'
              ]"
            />
            <span class="text-cosmic-300">{{ step }}</span>
          </div>
        </div>
      </div>
      
      <div v-else-if="status === 'error'" class="text-center p-4 bg-red-500/20 border border-red-500/30 rounded-lg">
        <AlertCircle class="h-8 w-8 text-red-400 mx-auto mb-2" />
        <p class="text-red-300">Analysis failed. Please try again with a different file.</p>
        <button
          @click="status = 'idle'"
          class="mt-4 text-cosmic-300 hover:text-white"
        >
          Try Again
        </button>
      </div>
      
      <div v-else-if="status === 'complete'" class="text-center p-4 bg-green-500/20 border border-green-500/30 rounded-lg">
        <CheckCircle class="h-8 w-8 text-green-400 mx-auto mb-2" />
        <p class="text-green-300">Analysis complete! Ready to generate flashcards.</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { 
  FileText, 
  Image, 
  Headphones, 
  Video, 
  Edit3,
  AlertCircle,
  Loader,
  CheckCircle
} from 'lucide-vue-next'

interface AnalysisResult {
  content: string
  metadata: {
    type: string
    confidence: number
    duration?: number
    dimensions?: { width: number, height: number }
    wordCount?: number
  }
}

interface Props {
  file: File
  onAnalysisComplete: (result: AnalysisResult) => void
  onError: (error: string) => void
}

// Props
const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
  (e: 'analysisComplete', result: AnalysisResult): void
  (e: 'error', error: string): void
}>()

// State
const progress = ref(0)
const status = ref<'idle' | 'analyzing' | 'complete' | 'error'>('idle')
const analysisSteps = ref<string[]>([])

// Methods
const analyzeFile = async () => {
  status.value = 'analyzing'
  progress.value = 0
  analysisSteps.value = []
  
  try {
    // Determine file type
    const fileType = props.file.type.split('/')[0]
    let analysisResult: AnalysisResult
    
    // Simulate progressive analysis steps based on file type
    switch (fileType) {
      case 'image':
        simulateAnalysisSteps([
          'Initializing vision model...',
          'Detecting text and visual elements...',
          'Identifying labels and components...',
          'Analyzing relationships between elements...',
          'Structuring content for flashcards...'
        ])
        
        analysisResult = {
          content: "The image contains a detailed cell diagram with the following labeled parts: 1) Cell membrane, 2) Cytoplasm, 3) Nucleus, 4) Mitochondria, 5) Endoplasmic Reticulum, 6) Golgi Apparatus, 7) Lysosome. The diagram shows the spatial relationships between these components.",
          metadata: {
            type: 'diagram',
            confidence: 0.94,
            dimensions: { width: 800, height: 600 }
          }
        }
        break
        
      case 'audio':
        simulateAnalysisSteps([
          'Initializing audio transcription model...',
          'Converting audio to waveform...',
          'Transcribing speech to text...',
          'Detecting speakers and segments...',
          'Extracting key concepts and terminology...'
        ])
        
        analysisResult = {
          content: "SPEAKER 1: Today we're going to discuss the carbon cycle. Carbon is constantly moving through the Earth's system in various forms. SPEAKER 2: What are the main carbon reservoirs? SPEAKER 1: The main carbon reservoirs are the atmosphere, oceans, soil and sediments, and living organisms. Carbon dioxide in the atmosphere is absorbed by plants during photosynthesis...",
          metadata: {
            type: 'lecture',
            confidence: 0.89,
            duration: 435 // seconds
          }
        }
        break
        
      case 'video':
        simulateAnalysisSteps([
          'Initializing video processing...',
          'Extracting audio track...',
          'Transcribing speech content...',
          'Analyzing visual elements frame by frame...',
          'Identifying key demonstrations and examples...',
          'Combining audio and visual information...'
        ])
        
        analysisResult = {
          content: "VIDEO LECTURE: BASIC TRIGONOMETRY\n\nTimestamp 00:15 - Introduction to sine, cosine, and tangent\nTimestamp 01:30 - Demonstration of the unit circle and how trigonometric functions relate to it\nTimestamp 03:45 - Examples of calculating sine and cosine values\nTimestamp 05:20 - Practical application: Finding heights using trigonometry\nTimestamp 07:10 - Common trigonometric identities explained with visual diagrams",
          metadata: {
            type: 'educational-video',
            confidence: 0.92,
            duration: 545 // seconds
          }
        }
        break
        
      default:
        // Handle handwritten notes or other text content
        simulateAnalysisSteps([
          'Initializing OCR processing...',
          'Detecting handwriting style...',
          'Converting handwriting to digital text...',
          'Correcting OCR errors...',
          'Structuring content into topics...'
        ])
        
        analysisResult = {
          content: "TOPIC: THERMODYNAMICS LAWS\n\n1st Law: Energy cannot be created or destroyed, only transformed from one form to another.\n\n2nd Law: The entropy of an isolated system always increases over time.\n\n3rd Law: As temperature approaches absolute zero, the entropy of a system approaches a constant minimum.\n\nApplications:\n- Heat engines\n- Refrigeration\n- Energy conversion efficiency",
          metadata: {
            type: 'notes',
            confidence: 0.86,
            wordCount: 178
          }
        }
    }
    
    // Simulate completion
    setTimeout(() => {
      progress.value = 100
      status.value = 'complete'
      emit('analysisComplete', analysisResult)
    }, 1000)
    
  } catch (error) {
    console.error('Analysis error:', error)
    status.value = 'error'
    emit('error', 'Failed to analyze file content')
  }
}

const simulateAnalysisSteps = (steps: string[]) => {
  let stepIndex = 0
  
  const interval = setInterval(() => {
    if (stepIndex < steps.length) {
      analysisSteps.value.push(steps[stepIndex])
      progress.value = Math.min(100, ((stepIndex + 1) / steps.length) * 90)
      stepIndex++
    } else {
      clearInterval(interval)
    }
  }, 800)
}

const getFileTypeIcon = () => {
  const fileType = props.file.type.split('/')[0]
  
  switch (fileType) {
    case 'image': return Image
    case 'audio': return Headphones
    case 'video': return Video
    default: return FileText
  }
}
</script>