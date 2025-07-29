<template>
  <div class="glass-card p-6">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-bold text-white flex items-center">
        <Network class="h-5 w-5 mr-2 text-cosmic-400" />
        Connected Concepts
      </h3>
      
      <div class="flex space-x-2 text-sm">
        <select 
          v-model="connectionType"
          class="px-2 py-1 bg-white/5 border border-white/10 rounded text-cosmic-300"
        >
          <option value="both">All Connections</option>
          <option value="semantic">Conceptual</option>
          <option value="keyword">Keyword</option>
        </select>
        
        <select
          v-model="connectionStrength"
          class="px-2 py-1 bg-white/5 border border-white/10 rounded text-cosmic-300"
        >
          <option value="strong">Strong Only</option>
          <option value="moderate">Moderate+</option>
          <option value="all">All Related</option>
        </select>
      </div>
    </div>
    
    <div v-if="loading" class="flex items-center justify-center py-8">
      <div class="w-6 h-6 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
    </div>
    
    <div v-else-if="relatedCards.length > 0" class="space-y-4">
      <div 
        v-for="card in relatedCards" 
        :key="card.id"
        class="glass-card p-4 hover:border-cosmic-400/50 transition-all cursor-pointer"
        @click="$emit('selectRelated', card)"
      >
        <div class="flex items-start justify-between">
          <div>
            <div class="text-white font-medium mb-1">{{ card.term }}</div>
            <div class="text-cosmic-300 text-sm line-clamp-2">{{ card.definition }}</div>
          </div>
          
          <div class="flex flex-col items-end space-y-2">
            <div class="flex items-center">
              <Star 
                v-for="i in 5" 
                :key="i"
                :class="[
                  'h-3 w-3',
                  i < card.confidence_level
                    ? `${getConfidenceColor(card.confidence_level)} fill-current`
                    : 'text-cosmic-600'
                ]" 
              />
            </div>
            
            <div class="text-xs text-cosmic-400 flex items-center">
              <ArrowRight class="h-3 w-3 mr-1" />
              <span>View Card</span>
            </div>
          </div>
        </div>
        
        <div v-if="card.sharedKeywords && card.sharedKeywords.length > 0" class="mt-2 text-xs">
          <span class="text-cosmic-400">Connected by: </span>
          <span class="text-cosmic-300">
            {{ card.sharedKeywords.slice(0, 3).join(', ') }}
            <span v-if="card.sharedKeywords.length > 3">...</span>
          </span>
        </div>
      </div>
    </div>
    
    <div v-else class="text-center py-8 space-y-3">
      <Lightbulb class="h-8 w-8 text-cosmic-400/50 mx-auto" />
      <p class="text-cosmic-300">No closely related flashcards found</p>
      <p class="text-xs text-cosmic-400">Create more flashcards to build connections</p>
    </div>
    
    <div class="mt-4 pt-4 border-t border-white/10">
      <div class="text-xs text-cosmic-400 flex items-center">
        <Lightbulb class="h-3 w-3 mr-1" />
        <span>AI analyzes your flashcard collection to build knowledge connections across different subjects.</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  Network, 
  ArrowRight, 
  Lightbulb, 
  Star 
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'

interface Flashcard {
  id: string
  term: string
  definition: string
  difficulty: 'easy' | 'medium' | 'hard'
  confidence_level: number
  content_source?: string
  relationScore?: number
  sharedKeywords?: string[]
}

// Props
defineProps<{
  currentCard: Flashcard
  userId: string
}>()

// Emits
const emit = defineEmits<{
  (e: 'selectRelated', card: Flashcard): void
}>()

// State
const relatedCards = ref<Flashcard[]>([])
const loading = ref(true)
const connectionType = ref<'semantic' | 'keyword' | 'both'>('both')
const connectionStrength = ref<'strong' | 'moderate' | 'all'>('moderate')

// Composables
const toast = useToast()

// Watch for changes
watch([() => props.currentCard, connectionType, connectionStrength], () => {
  if (props.currentCard) {
    fetchRelatedCards()
  }
})

// Methods
const fetchRelatedCards = async () => {
  loading.value = true

  try {
    // In a real implementation, this would use a more sophisticated 
    // algorithm or API call to find semantically related cards
    // For now, we'll simulate it with keyword matching

    // Extract keywords from current card
    const termKeywords = extractKeywords(props.currentCard.term)
    const defKeywords = extractKeywords(props.currentCard.definition)
    const allKeywords = [...new Set([...termKeywords, ...defKeywords])]

    // Fetch all user's flashcards
    const { data, error } = await supabase
      .from('flashcards')
      .select('*')
      .eq('user_id', props.userId)
      .neq('id', props.currentCard.id) // Exclude current card
      .order('created_at', { ascending: false })

    if (error) throw error
    
    if (!data || data.length === 0) {
      relatedCards.value = []
      loading.value = false
      return
    }

    // Find related cards by checking for shared keywords
    const related = data.map(card => {
      const cardTermKeywords = extractKeywords(card.term)
      const cardDefKeywords = extractKeywords(card.definition)
      const cardAllKeywords = [...new Set([...cardTermKeywords, ...cardDefKeywords])]
      
      // Calculate semantic similarity score (0-100)
      const semanticScore = calculateSemanticSimilarity(
        props.currentCard.term + ' ' + props.currentCard.definition,
        card.term + ' ' + card.definition
      )
      
      // Calculate keyword overlap score (0-100)
      const sharedKeywords = allKeywords.filter(keyword => 
        cardAllKeywords.includes(keyword)
      )
      const keywordScore = (sharedKeywords.length / Math.max(1, allKeywords.length)) * 100
      
      // Combined score based on connection type preference
      let score = 0
      if (connectionType.value === 'semantic') {
        score = semanticScore
      } else if (connectionType.value === 'keyword') {
        score = keywordScore
      } else {
        score = (semanticScore + keywordScore) / 2
      }
      
      return {
        ...card,
        relationScore: score,
        sharedKeywords
      }
    })
    .filter(card => {
      // Filter based on connection strength
      if (connectionStrength.value === 'strong') return card.relationScore! >= 50
      if (connectionStrength.value === 'moderate') return card.relationScore! >= 30
      return card.relationScore! > 0 // 'all'
    })
    .sort((a, b) => b.relationScore! - a.relationScore!)
    .slice(0, 3) // Limit to top 3 related cards
    
    relatedCards.value = related
  } catch (error) {
    console.error('Error fetching related cards:', error)
  } finally {
    loading.value = false
  }
}

const extractKeywords = (text: string): string[] => {
  // Remove common words and extract important keywords
  // This is a simplified version - a real implementation would use NLP
  const words = text.toLowerCase().split(/\s+/)
  const commonWords = ['a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'but', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'what', 'which', 'who', 'where', 'when', 'how', 'why', 'this', 'that', 'these', 'those']
  
  return words
    .filter(word => word.length > 3 && !commonWords.includes(word))
    .map(word => word.replace(/[.,;:!?]/g, ''))
}

const calculateSemanticSimilarity = (text1: string, text2: string): number => {
  // This is a simplified simulation of semantic similarity
  // In a real implementation, this would use an embedding model or API
  
  // Convert texts to term frequency vectors
  const words1 = text1.toLowerCase().split(/\s+/)
  const words2 = text2.toLowerCase().split(/\s+/)
  
  const uniqueWords = [...new Set([...words1, ...words2])]
  
  // Calculate term frequencies
  const termFreq1: {[key: string]: number} = {}
  const termFreq2: {[key: string]: number} = {}
  
  uniqueWords.forEach(word => {
    termFreq1[word] = words1.filter(w => w === word).length / words1.length
    termFreq2[word] = words2.filter(w => w === word).length / words2.length
  })
  
  // Calculate cosine similarity
  let dotProduct = 0
  let magnitude1 = 0
  let magnitude2 = 0
  
  uniqueWords.forEach(word => {
    dotProduct += termFreq1[word] * termFreq2[word]
    magnitude1 += Math.pow(termFreq1[word], 2)
    magnitude2 += Math.pow(termFreq2[word], 2)
  })
  
  magnitude1 = Math.sqrt(magnitude1)
  magnitude2 = Math.sqrt(magnitude2)
  
  const similarity = dotProduct / (magnitude1 * magnitude2) || 0
  
  // Convert to a 0-100 scale
  return similarity * 100
}

const handleRelatedCardSelect = (card: Flashcard) => {
  // Find the index of the selected card and navigate to it
  const index = flashcards.value.findIndex(c => c.id === card.id)
  emit('selectRelated', card)
}

const togglePerformanceAnalytics = () => {
  showPerformanceAnalytics.value = !showPerformanceAnalytics.value
}

const getConfidenceColor = (level: number) => {
  if (level >= 4) return 'text-green-400'
  if (level >= 3) return 'text-star-400'
  return 'text-red-400'
}
</script>