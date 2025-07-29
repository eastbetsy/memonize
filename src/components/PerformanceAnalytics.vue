<template>
  <div class="glass-card p-6 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-2">
      <h2 class="text-xl font-bold text-white flex items-center">
        <BarChart2 class="h-5 w-5 mr-2 text-cosmic-400" />
        Deep Performance Analytics
      </h2>
      <button 
        @click="$emit('close')"
        class="text-cosmic-400 hover:text-white"
      >
        ×
      </button>
    </div>

    <!-- Overall Stats -->
    <div class="grid grid-cols-5 gap-3">
      <div v-for="(stat, index) in overallStats" :key="index" class="glass-card p-3 text-center">
        <div class="text-xl font-bold text-cosmic-300">{{ stat.value }}</div>
        <div class="text-xs text-cosmic-400">{{ stat.label }}</div>
      </div>
    </div>
    
    <!-- Tabs -->
    <div class="flex border-b border-white/10">
      <button
        v-for="tab in tabs" 
        :key="tab.id"
        @click="activeTab = tab.id"
        :class="[
          'flex items-center space-x-2 px-3 py-3 transition-all',
          activeTab === tab.id
            ? 'text-white border-b-2 border-cosmic-500'
            : 'text-cosmic-400 hover:text-cosmic-300'
        ]"
      >
        <component :is="tab.icon" class="h-4 w-4" />
        <span>{{ tab.label }}</span>
      </button>
    </div>

    <!-- Tab Content -->
    <div class="min-h-[400px]">
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="w-10 h-10 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
      
      <div v-else>
        <!-- Error Patterns Tab -->
        <div v-if="activeTab === 'patterns'" class="space-y-4">
          <div v-if="errorPatterns.length > 0">
            <div v-for="(pattern, index) in errorPatterns" :key="index" class="glass-card p-4 relative overflow-hidden">
              <div class="absolute inset-0 bg-red-500/5"></div>
              
              <div class="relative z-10">
                <div class="flex items-center justify-between mb-2">
                  <div class="flex items-center">
                    <TrendingDown class="h-5 w-5 mr-2 text-red-400" />
                    <h3 class="font-bold text-white">{{ pattern.pattern }}</h3>
                  </div>
                  <div class="text-sm text-red-400">
                    {{ pattern.occurrence }} occurrences
                  </div>
                </div>
                
                <p class="text-cosmic-300 text-sm mb-3">{{ pattern.description }}</p>
                
                <div v-if="pattern.relatedTerms.length > 0" class="mb-3">
                  <div class="text-sm text-cosmic-300 mb-1">Affected Terms:</div>
                  <div class="flex flex-wrap gap-2">
                    <span 
                      v-for="(term, i) in pattern.relatedTerms" 
                      :key="i" 
                      class="px-2 py-1 bg-white/5 text-cosmic-300 rounded text-xs"
                    >
                      {{ term }}
                    </span>
                  </div>
                </div>
                
                <div class="bg-yellow-500/10 border border-yellow-500/30 rounded px-3 py-2 text-sm">
                  <div class="flex items-start">
                    <Lightbulb class="h-4 w-4 mt-0.5 mr-2 text-yellow-500 shrink-0" />
                    <span class="text-yellow-300">{{ pattern.recommendation }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div v-else class="text-center py-8">
            <AlertCircle class="h-12 w-12 text-cosmic-400 mx-auto mb-3 opacity-50" />
            <h3 class="text-lg font-medium text-cosmic-300 mb-1">No Error Patterns Detected Yet</h3>
            <p class="text-cosmic-400 text-sm">
              Complete more study sessions to generate pattern insights
            </p>
          </div>
        </div>

        <!-- Topic Mastery Tab -->
        <div v-else-if="activeTab === 'topics'" class="space-y-4">
          <div v-if="subTopics.length > 0">
            <div v-for="(topic, index) in subTopics" :key="index" class="glass-card p-4">
              <div class="flex items-center justify-between mb-2">
                <div class="flex items-center">
                  <BookOpen class="h-5 w-5 mr-2 text-cosmic-400" />
                  <h3 class="font-bold text-white">{{ topic.topic }}</h3>
                </div>
                <div class="flex items-center space-x-2 text-sm">
                  <component 
                    :is="topic.trend === 'improving' ? TrendingUp : 
                        topic.trend === 'declining' ? TrendingDown : 
                        Target" 
                    :class="[
                      'h-4 w-4', 
                      topic.trend === 'improving' ? 'text-green-400' : 
                      topic.trend === 'declining' ? 'text-red-400' : 
                      'text-cosmic-400'
                    ]" 
                  />
                  <span :class="[
                    topic.trend === 'improving' ? 'text-green-400' : 
                    topic.trend === 'declining' ? 'text-red-400' : 
                    'text-cosmic-300'
                  ]">
                    {{ topic.trend === 'improving' ? 'Improving' : 
                      topic.trend === 'declining' ? 'Needs focus' : 
                      'Stable' }}
                  </span>
                </div>
              </div>
              
              <div class="grid grid-cols-3 gap-2 mb-3 text-sm">
                <div>
                  <div class="text-cosmic-400 text-xs">Mastery</div>
                  <div class="text-white font-medium">
                    {{ Math.round(topic.mastery * 20) }}%
                  </div>
                </div>
                <div>
                  <div class="text-cosmic-400 text-xs">Reviews</div>
                  <div class="text-white font-medium">
                    {{ topic.reviewCount }} cards
                  </div>
                </div>
                <div>
                  <div class="text-cosmic-400 text-xs">Last Review</div>
                  <div class="text-white font-medium">
                    {{ topic.lastReviewed }}
                  </div>
                </div>
              </div>
              
              <div class="w-full h-2 bg-cosmic-900 rounded-full mb-3">
                <div 
                  :class="[
                    'h-2 rounded-full',
                    topic.mastery >= 4 ? 'bg-green-500' :
                    topic.mastery >= 3 ? 'bg-yellow-500' :
                    'bg-red-500'
                  ]"
                  :style="{ width: `${Math.min(100, topic.mastery * 20)}%` }"
                ></div>
              </div>
              
              <div class="text-xs text-cosmic-300 flex items-start">
                <Lightbulb class="h-3 w-3 mt-0.5 mr-1 text-cosmic-400 shrink-0" />
                <span>{{ topic.recommendation }}</span>
              </div>
            </div>
          </div>
          
          <div v-else class="text-center py-8">
            <Brain class="h-12 w-12 text-cosmic-400 mx-auto mb-3 opacity-50" />
            <h3 class="text-lg font-medium text-cosmic-300 mb-1">No Topic Insights Yet</h3>
            <p class="text-cosmic-400 text-sm">
              Create more flashcards to generate topic-based analytics
            </p>
          </div>
        </div>

        <!-- Similar Terms Tab -->
        <div v-else-if="activeTab === 'similar'" class="space-y-4">
          <div v-if="similarTerms.length > 0">
            <div class="text-sm text-cosmic-300 mb-4">
              AI analysis has identified these pairs of terms you frequently confuse:
            </div>
            
            <div v-for="(pair, index) in similarTerms" :key="index" class="glass-card p-4 mb-4 relative overflow-hidden">
              <div class="absolute inset-0 bg-yellow-500/5"></div>
              
              <div class="relative z-10">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="font-bold text-white flex items-center">
                    <Repeat class="h-5 w-5 mr-2 text-yellow-500" />
                    <span>Term Confusion Detected</span>
                  </h3>
                  <div class="text-sm text-yellow-500">
                    {{ pair.confusionFrequency }} occurrences
                  </div>
                </div>
                
                <div class="flex items-center justify-between mb-4">
                  <div class="px-3 py-2 bg-white/5 rounded-lg border border-white/10 flex-1 mr-2">
                    <div class="text-xs text-cosmic-400 mb-1">Term 1:</div>
                    <div class="text-white">{{ pair.term1 }}</div>
                  </div>
                  
                  <Webhook class="h-5 w-5 text-cosmic-400 mx-2" />
                  
                  <div class="px-3 py-2 bg-white/5 rounded-lg border border-white/10 flex-1 ml-2">
                    <div class="text-xs text-cosmic-400 mb-1">Term 2:</div>
                    <div class="text-white">{{ pair.term2 }}</div>
                  </div>
                </div>
                
                <div class="mb-3">
                  <div class="text-sm text-cosmic-300 mb-1">Similarity:</div>
                  <div class="w-full h-2 bg-cosmic-900 rounded-full">
                    <div 
                      class="h-2 bg-yellow-500 rounded-full" 
                      :style="{ width: `${Math.round(pair.similarityScore)}%` }"
                    ></div>
                  </div>
                  <div class="flex justify-between text-xs text-cosmic-400 mt-1">
                    <span>Low</span>
                    <span>Similarity: {{ Math.round(pair.similarityScore) }}%</span>
                    <span>High</span>
                  </div>
                </div>
                
                <div class="bg-yellow-500/10 border border-yellow-500/30 rounded px-3 py-2 text-sm">
                  <div class="flex items-start">
                    <Lightbulb class="h-4 w-4 mt-0.5 mr-2 text-yellow-500 shrink-0" />
                    <span class="text-yellow-300">
                      Create a comparison card that explicitly highlights the differences between these terms. 
                      Study them together to strengthen your ability to distinguish between them.
                    </span>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="text-xs text-cosmic-400 flex items-center mt-4">
              <AlertTriangle class="h-3 w-3 mr-1" />
              <span>Similar-looking or related terms are common sources of errors in spaced repetition learning.</span>
            </div>
          </div>
          
          <div v-else class="text-center py-8">
            <Network class="h-12 w-12 text-cosmic-400 mx-auto mb-3 opacity-50" />
            <h3 class="text-lg font-medium text-cosmic-300 mb-1">No Similar Terms Detected</h3>
            <p class="text-cosmic-400 text-sm">
              This analysis requires more study history to identify term confusion
            </p>
          </div>
        </div>
        
        <!-- Knowledge Gaps Tab -->
        <div v-else-if="activeTab === 'gaps'" class="space-y-4">
          <div v-if="knowledgeGaps.length > 0">
            <div class="text-sm text-cosmic-300 mb-4">
              AI has identified these knowledge gaps in your flashcard collection:
            </div>
            
            <div v-for="(gap, index) in knowledgeGaps" :key="index" class="glass-card p-4 mb-4 relative overflow-hidden">
              <div class="absolute inset-0 bg-red-500/5"></div>
              
              <div class="relative z-10">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="font-bold text-white flex items-center">
                    <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
                    <span>{{ gap.topic }} Knowledge Gap</span>
                  </h3>
                  <div class="px-2 py-1 bg-red-500/20 text-red-400 text-xs rounded-full">
                    {{ gap.priority }} priority
                  </div>
                </div>
                
                <div class="mb-3">
                  <div class="text-cosmic-300 mb-2">{{ gap.missingKnowledge }}</div>
                  
                  <div v-if="gap.conceptsToReview.length > 0" class="mb-2">
                    <div class="text-sm text-cosmic-300 mb-1">Current concepts:</div>
                    <div class="flex flex-wrap gap-2">
                      <span 
                        v-for="(concept, i) in gap.conceptsToReview" 
                        :key="i" 
                        class="px-2 py-1 bg-white/5 text-cosmic-300 rounded text-xs"
                      >
                        {{ concept }}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div v-if="gap.recommendedResources" class="bg-cosmic-500/10 border border-cosmic-500/30 rounded px-3 py-2 text-sm mb-2">
                  <div class="text-xs text-cosmic-300 mb-1">Recommended resources:</div>
                  <ul class="list-disc list-inside text-cosmic-200 text-sm">
                    <li v-for="(resource, i) in gap.recommendedResources" :key="i">{{ resource }}</li>
                  </ul>
                </div>
                
                <div class="bg-green-500/10 border border-green-500/30 rounded px-3 py-2 text-sm">
                  <div class="flex items-start">
                    <Lightbulb class="h-4 w-4 mt-0.5 mr-2 text-green-500 shrink-0" />
                    <span class="text-green-300">
                      Create flashcards covering the missing concepts to build a more comprehensive understanding of {{ gap.topic }}.
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div v-else class="text-center py-8">
            <Activity class="h-12 w-12 text-cosmic-400 mx-auto mb-3 opacity-50" />
            <h3 class="text-lg font-medium text-cosmic-300 mb-1">No Knowledge Gaps Detected</h3>
            <p class="text-cosmic-400 text-sm">
              Create more related flashcards to enable knowledge gap analysis
            </p>
          </div>
        </div>
        
        <!-- Time Insights Tab -->
        <div v-else-if="activeTab === 'time'" class="space-y-6">
          <div v-if="timeInsight">
            <div class="glass-card p-4">
              <h3 class="font-bold text-white mb-3 flex items-center">
                <Clock class="h-5 w-5 mr-2 text-cosmic-400" />
                {{ timeInsight.title }}
              </h3>
              <p class="text-cosmic-300 text-sm mb-4">{{ timeInsight.description }}</p>
              
              <div class="h-40 flex items-end space-x-2 mb-2">
                <div 
                  v-for="(value, index) in timeInsight.data" 
                  :key="index" 
                  class="flex-1 flex flex-col items-center"
                >
                  <div
                    :class="[
                      'w-full bg-gradient-to-t rounded-t min-h-[4px]',
                      value >= 80 ? 'from-green-500 to-green-400' :
                      value >= 65 ? 'from-yellow-500 to-yellow-400' :
                      'from-red-500 to-red-400'
                    ]"
                    :style="{ height: `${(value / 100) * 100}%` }"
                  ></div>
                  <div class="text-xs text-cosmic-400 mt-1">{{ timeInsight.labels[index] }}</div>
                </div>
              </div>
              
              <div class="flex justify-between text-xs text-cosmic-400">
                <span>Lower Recall</span>
                <span>Higher Recall</span>
              </div>
              
              <div class="mt-4 bg-blue-500/10 border border-blue-500/30 rounded px-3 py-2 text-sm">
                <div class="flex items-start">
                  <Calendar class="h-4 w-4 mt-0.5 mr-2 text-blue-500 shrink-0" />
                  <span class="text-blue-300">{{ timeInsight.recommendation }}</span>
                </div>
              </div>
            </div>
            
            <div class="glass-card p-4 mt-4">
              <h3 class="font-bold text-white mb-3">Response Time Analysis</h3>
              <p class="text-cosmic-300 text-sm mb-4">
                Your average response times reveal patterns in your knowledge confidence:
              </p>
              
              <div class="space-y-3 mb-4">
                <div>
                  <div class="flex justify-between text-sm mb-1">
                    <span class="text-cosmic-300">Quick Answers (&lt;5s)</span>
                    <span class="text-white">32%</span>
                  </div>
                  <div class="w-full h-2 bg-cosmic-900 rounded-full">
                    <div class="bg-green-500 h-2 rounded-full" style="width: 32%"></div>
                  </div>
                  <div class="text-xs text-cosmic-400 mt-1">High confidence knowledge</div>
                </div>
                
                <div>
                  <div class="flex justify-between text-sm mb-1">
                    <span class="text-cosmic-300">Moderate Time (5-10s)</span>
                    <span class="text-white">45%</span>
                  </div>
                  <div class="w-full h-2 bg-cosmic-900 rounded-full">
                    <div class="bg-yellow-500 h-2 rounded-full" style="width: 45%"></div>
                  </div>
                  <div class="text-xs text-cosmic-400 mt-1">Partial recall requiring effort</div>
                </div>
                
                <div>
                  <div class="flex justify-between text-sm mb-1">
                    <span class="text-cosmic-300">Delayed Response (&gt;10s)</span>
                    <span class="text-white">23%</span>
                  </div>
                  <div class="w-full h-2 bg-cosmic-900 rounded-full">
                    <div class="bg-red-500 h-2 rounded-full" style="width: 23%"></div>
                  </div>
                  <div class="text-xs text-cosmic-400 mt-1">Knowledge gaps requiring focus</div>
                </div>
              </div>
              
              <div class="bg-yellow-500/10 border border-yellow-500/30 rounded px-3 py-2 text-sm">
                <div class="flex items-start">
                  <Zap class="h-4 w-4 mt-0.5 mr-2 text-yellow-500 shrink-0" />
                  <span class="text-yellow-300">
                    Spend more time studying cards with delayed responses. The time you take to answer is a strong indicator of knowledge retention.
                  </span>
                </div>
              </div>
            </div>
          </div>
          
          <div v-else class="text-center py-8">
            <Clock class="h-12 w-12 text-cosmic-400 mx-auto mb-3 opacity-50" />
            <h3 class="text-lg font-medium text-cosmic-300 mb-1">No Time Insights Yet</h3>
            <p class="text-cosmic-400 text-sm">
              Complete more timed study sessions to unlock time-based insights
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Insight Summary -->
    <div class="bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg p-4">
      <div class="flex items-center mb-2">
        <Brain class="h-5 w-5 mr-2 text-cosmic-400" />
        <h3 class="font-bold text-white">AI Learning Coach Insight</h3>
      </div>
      <p class="text-cosmic-300 text-sm mb-3">
        Based on your performance patterns, AI has identified key areas for improvement:
      </p>
      <div class="space-y-2">
        <div v-if="errorPatterns.length > 0" class="flex items-start space-x-2 text-sm">
          <ArrowRight class="h-4 w-4 mt-0.5 text-cosmic-400 shrink-0" />
          <span class="text-cosmic-200">
            Focus on resolving the <span class="text-white">{{ errorPatterns[0].pattern }}</span> pattern which affects {{ errorPatterns[0].occurrence }} of your challenging cards.
          </span>
        </div>
        
        <div v-if="similarTerms.length > 0" class="flex items-start space-x-2 text-sm">
          <ArrowRight class="h-4 w-4 mt-0.5 text-cosmic-400 shrink-0" />
          <span class="text-cosmic-200">
            You frequently confuse <span class="text-white">{{ similarTerms[0].term1 }}</span> with <span class="text-white">{{ similarTerms[0].term2 }}</span>. Create a comparison card to clarify the differences.
          </span>
        </div>
        
        <div v-if="subTopics.length > 0" class="flex items-start space-x-2 text-sm">
          <ArrowRight class="h-4 w-4 mt-0.5 text-cosmic-400 shrink-0" />
          <span class="text-cosmic-200">
            Your weakest topic is <span class="text-white">{{ sortedTopicsByMastery[0].topic }}</span> with only {{ Math.round(sortedTopicsByMastery[0].mastery * 20) }}% mastery.
          </span>
        </div>
        
        <div v-if="timeInsight" class="flex items-start space-x-2 text-sm">
          <ArrowRight class="h-4 w-4 mt-0.5 text-cosmic-400 shrink-0" />
          <span class="text-cosmic-200">
            Schedule important study sessions on {{ timeInsight.labels[bestTimeIndex] }} when your recall performance peaks.
          </span>
        </div>
        
        <div v-if="knowledgeGaps.length > 0" class="flex items-start space-x-2 text-sm">
          <ArrowRight class="h-4 w-4 mt-0.5 text-cosmic-400 shrink-0" />
          <span class="text-cosmic-200">
            You have a knowledge gap in <span class="text-white">{{ knowledgeGaps[0].topic }}</span>. Create flashcards for the missing concepts.
          </span>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="text-xs text-cosmic-400 border-t border-white/10 pt-4 flex items-center">
      <BarChart2 class="h-3 w-3 mr-1" />
      <span>
        Deep Performance Analytics uses advanced AI to identify specific patterns in your learning behavior, 
        helping you focus your study efforts where they'll be most effective.
      </span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { 
  BarChart2, 
  TrendingDown, 
  TrendingUp, 
  Clock, 
  AlertCircle, 
  Target,
  Brain,
  BookOpen,
  ArrowRight,
  Calendar,
  Zap,
  Lightbulb,
  Network,
  Activity,
  AlertTriangle,
  Repeat,
  Webhook
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface ErrorPattern {
  pattern: string
  description: string
  occurrence: number
  relatedTerms: string[]
  recommendation: string
  examples?: Array<{term: string, confusion: string}>
}

interface SubTopicPerformance {
  topic: string
  mastery: number
  reviewCount: number
  lastReviewed: string
  trend: 'improving' | 'declining' | 'stable'
  recommendation: string
}

interface TimeBasedInsight {
  title: string
  description: string
  data: number[]
  labels: string[]
  recommendation: string
}

interface SimilarTermsPair {
  term1: string
  term2: string
  similarityScore: number
  confusionFrequency: number
}

interface LearningGap {
  topic: string
  conceptsToReview: string[]
  missingKnowledge: string
  recommendedResources?: string[]
  priority: 'high' | 'medium' | 'low'
}

// Props
const props = defineProps<{
  userId: string
}>()

// Emits
const emit = defineEmits<{
  (e: 'close'): void
}>()

// State
const loading = ref(true)
const errorPatterns = ref<ErrorPattern[]>([])
const subTopics = ref<SubTopicPerformance[]>([])
const timeInsight = ref<TimeBasedInsight | null>(null)
const similarTerms = ref<SimilarTermsPair[]>([])
const knowledgeGaps = ref<LearningGap[]>([])
const activeTab = ref<'patterns' | 'topics' | 'time' | 'gaps' | 'similar'>('patterns')
const overallStats = ref({
  totalCards: { label: 'Total Cards', value: 0 },
  reviewedCards: { label: 'Reviewed', value: 0 },
  averageConfidence: { label: 'Avg. Confidence', value: 0 },
  weakCards: { label: 'Weak Cards', value: 0, color: 'text-red-400' },
  strongCards: { label: 'Strong Cards', value: 0, color: 'text-green-400' }
})

// Tabs definitions
const tabs = [
  { id: 'patterns', label: 'Error Patterns', icon: TrendingDown },
  { id: 'topics', label: 'Topic Mastery', icon: BookOpen },
  { id: 'time', label: 'Time', icon: Clock },
  { id: 'similar', label: 'Confusion', icon: Network },
  { id: 'gaps', label: 'Gaps', icon: AlertTriangle }
]

// Computed
const sortedTopicsByMastery = computed(() => {
  return [...subTopics.value].sort((a, b) => a.mastery - b.mastery)
})

const bestTimeIndex = computed(() => {
  if (!timeInsight.value) return 0
  return timeInsight.value.data.indexOf(Math.max(...timeInsight.value.data))
})

// Lifecycle hooks
onMounted(() => {
  fetchAnalytics()
})

// Methods
const fetchAnalytics = async () => {
  loading.value = true
  try {
    // In a real implementation, this would call a backend API to get sophisticated analytics
    // For now, we'll simulate these analytics with mock data

    // 1. Fetch some basic stats about the user's flashcards
    const { data: flashcardsData, error } = await supabase
      .from('flashcards')
      .select('id, term, definition, difficulty, confidence_level, last_reviewed')
      .eq('user_id', props.userId)
    
    if (error) throw error

    const flashcards = flashcardsData || []
    
    // Calculate basic stats
    const reviewedCards = flashcards.filter(card => card.last_reviewed).length
    const totalConfidence = flashcards.reduce((sum, card) => sum + (card.confidence_level || 0), 0)
    const averageConfidence = flashcards.length > 0 ? totalConfidence / flashcards.length : 0
    const weakCards = flashcards.filter(card => card.confidence_level <= 2).length
    const strongCards = flashcards.filter(card => card.confidence_level >= 4).length

    overallStats.value = {
      totalCards: { label: 'Total Cards', value: flashcards.length },
      reviewedCards: { label: 'Reviewed', value: reviewedCards },
      averageConfidence: { label: 'Avg. Confidence', value: averageConfidence.toFixed(1) },
      weakCards: { label: 'Weak Cards', value: weakCards, color: 'text-red-400' },
      strongCards: { label: 'Strong Cards', value: strongCards, color: 'text-green-400' }
    }

    // 2. Analyze error patterns (simulated)
    errorPatterns.value = generateErrorPatterns(flashcards)
    
    // 3. Generate sub-topic performance (simulated)
    subTopics.value = generateSubTopicPerformance(flashcards)
    
    // 4. Generate time-based insights (simulated)
    timeInsight.value = generateTimeBasedInsight(flashcards)

    // 5. Generate similar terms analysis
    similarTerms.value = generateSimilarTermsAnalysis(flashcards)
    
    // 6. Identify knowledge gaps
    knowledgeGaps.value = identifyKnowledgeGaps(flashcards)
  } catch (error) {
    console.error('Error fetching analytics:', error)
  } finally {
    loading.value = false
  }
}

// Helper functions to generate simulated analytics data
function generateErrorPatterns(flashcards: any[]): ErrorPattern[] {
  // In a real implementation, this would analyze study history and error patterns
  // Here we're simulating common patterns based on the flashcards content
  
  const weakCards = flashcards.filter(card => card.confidence_level <= 2)
  if (weakCards.length === 0) return []
  
  const patterns: ErrorPattern[] = [
    {
      pattern: 'Similar Term Confusion',
      description: 'You frequently confuse terms that sound similar or have related meanings',
      occurrence: Math.round(weakCards.length * 0.4),
      relatedTerms: extractSimilarTerms(weakCards),
      recommendation: 'Create compare/contrast flashcards that explicitly highlight the differences between similar terms'
    },
    {
      pattern: 'Definition Precision',
      description: 'Your answers often include the general concept but miss specific details',
      occurrence: Math.round(weakCards.length * 0.3),
      relatedTerms: weakCards.slice(0, 2).map(c => c.term),
      recommendation: 'Break complex definitions into bullet points and ensure you can recall each point'
    },
    {
      pattern: 'Application Difficulty',
      description: 'You understand definitions but struggle to apply concepts in different contexts',
      occurrence: Math.round(weakCards.length * 0.2),
      relatedTerms: weakCards.slice(2, 4).map(c => c.term),
      recommendation: 'Use the "Apply It" feature to practice using concepts in different scenarios'
    }
  ]
  
  return patterns.filter(p => p.occurrence > 0)
}

function extractSimilarTerms(cards: any[]): string[] {
  // This is a simplified simulation - in a real implementation, 
  // this would use more sophisticated NLP techniques
  if (cards.length <= 1) return []
  
  // Just take some terms from the weak cards
  return cards.slice(0, Math.min(3, cards.length)).map(c => c.term)
}

function generateSubTopicPerformance(flashcards: any[]): SubTopicPerformance[] {
  // In a real implementation, this would analyze flashcard content to identify topics
  // Here we're generating simulated sub-topics
  
  if (flashcards.length < 3) return []
  
  // Group cards by extracting keywords that might represent topics
  const possibleTopics = extractPossibleTopics(flashcards)
  
  return possibleTopics.map(topic => ({
    topic: topic.name,
    mastery: topic.averageConfidence,
    reviewCount: topic.count,
    lastReviewed: topic.lastReviewed ? new Date(topic.lastReviewed).toLocaleDateString() : 'Never',
    trend: getTrendForTopic(topic.averageConfidence),
    recommendation: getRecommendationForTopic(topic.averageConfidence, topic.count)
  }))
}

function extractPossibleTopics(cards: any[]) {
  // In a real implementation, this would use NLP to extract topics
  // This is a simplified simulation
  
  // Extract words that might represent topics
  const topicWords = new Map<string, {
    count: number,
    cards: any[],
    confidences: number[],
    lastReviewed: string | null
  }>()
  
  cards.forEach(card => {
    const words = card.term.toLowerCase().split(/\s+/)
    words.forEach(word => {
      if (word.length > 4 && !commonWords.includes(word)) {
        if (!topicWords.has(word)) {
          topicWords.set(word, {
            count: 0,
            cards: [],
            confidences: [],
            lastReviewed: null
          })
        }
        
        const topicData = topicWords.get(word)!
        topicData.count++
        topicData.cards.push(card)
        topicData.confidences.push(card.confidence_level || 0)
        
        if (card.last_reviewed) {
          if (!topicData.lastReviewed || new Date(card.last_reviewed) > new Date(topicData.lastReviewed)) {
            topicData.lastReviewed = card.last_reviewed
          }
        }
      }
    })
  })
  
  // Filter to topics with at least 2 cards
  const filteredTopics = Array.from(topicWords.entries())
    .filter(([_, data]) => data.count >= 2)
    .map(([word, data]) => ({
      name: word.charAt(0).toUpperCase() + word.slice(1),
      count: data.count,
      averageConfidence: data.confidences.reduce((sum, val) => sum + val, 0) / data.confidences.length,
      lastReviewed: data.lastReviewed
    }))
    .sort((a, b) => b.count - a.count)
  
  return filteredTopics.slice(0, 5) // Return top 5 topics
}

const commonWords = [
  'what', 'which', 'when', 'where', 'who', 'whom', 'whose', 'why', 'how',
  'the', 'and', 'that', 'have', 'this', 'from', 'they', 'will', 'would',
  'there', 'their', 'these', 'those', 'with', 'about'
]

function getTrendForTopic(confidence: number): 'improving' | 'declining' | 'stable' {
  // In a real implementation, this would analyze historical data
  // This is a simplified simulation
  if (confidence > 3.5) return 'improving'
  if (confidence < 2.5) return 'declining'
  return 'stable'
}

function getRecommendationForTopic(confidence: number, count: number): string {
  if (confidence < 2.5) {
    return 'This topic needs significant review. Set aside dedicated study time focusing only on these cards.'
  } else if (confidence < 3.5) {
    return 'Use spaced repetition to strengthen your recall. Review these cards daily for the next week.'
  } else {
    return count < 5
      ? 'Your mastery is good. Consider creating more cards on this topic to expand your knowledge.'
      : 'You\'re doing well with this topic. Maintain with periodic review.';
  }
}

function generateTimeBasedInsight(flashcards: any[]): TimeBasedInsight | null {
  // In a real implementation, this would analyze study times and performance
  // This is a simplified simulation
  
  if (flashcards.length < 5) return null
  
  const timeData: number[] = [65, 72, 58, 80, 75, 68, 85]
  const dayLabels: string[] = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  
  return {
    title: 'Weekly Performance Trends',
    description: 'Your recall accuracy varies throughout the week. Here\'s how your performance changes:',
    data: timeData,
    labels: dayLabels,
    recommendation: 'Your peak performance days are Thursday and Sunday. Schedule difficult topics for these days when your recall is strongest.'
  }
}

// Generate data about similar terms that might be confused
function generateSimilarTermsAnalysis(flashcards: any[]): SimilarTermsPair[] {
  if (flashcards.length < 4) return []
  
  // In a real implementation, this would use embeddings or other NLP techniques
  // to find truly similar terms that are being confused
  const pairs: SimilarTermsPair[] = []
  
  // Find cards with low confidence
  const weakCards = flashcards.filter(card => card.confidence_level <= 3)
  
  // For each weak card, try to find a similar term
  weakCards.forEach(weakCard => {
    const otherCards = flashcards.filter(card => card.id !== weakCard.id)
    
    // Find the most similar card based on term similarity
    let mostSimilarCard = null
    let highestSimilarity = 0
    
    for (const card of otherCards) {
      // Simple word overlap similarity
      const similarity = calculateTermSimilarity(weakCard.term, card.term)
      if (similarity > highestSimilarity && similarity > 0.2) {
        highestSimilarity = similarity
        mostSimilarCard = card
      }
    }
    
    if (mostSimilarCard && highestSimilarity > 0.2) {
      // Check if this pair or a similar one already exists
      const exists = pairs.some(pair => 
        (pair.term1 === weakCard.term && pair.term2 === mostSimilarCard.term) ||
        (pair.term1 === mostSimilarCard.term && pair.term2 === weakCard.term)
      )
      
      if (!exists) {
        pairs.push({
          term1: weakCard.term,
          term2: mostSimilarCard.term,
          similarityScore: highestSimilarity * 100,
          confusionFrequency: Math.floor(Math.random() * 5) + 1 // Simulated frequency
        })
      }
    }
  })
  
  // Sort by confusion frequency
  return pairs.sort((a, b) => b.confusionFrequency - a.confusionFrequency).slice(0, 3)
}

function calculateTermSimilarity(term1: string, term2: string): number {
  // Clean up the terms
  const clean1 = term1.toLowerCase().replace(/what is|define|explain|\?/gi, '').trim()
  const clean2 = term2.toLowerCase().replace(/what is|define|explain|\?/gi, '').trim()
  
  // Split into words
  const words1 = clean1.split(/\s+/).filter(w => w.length > 3)
  const words2 = clean2.split(/\s+/).filter(w => w.length > 3)
  
  if (words1.length === 0 || words2.length === 0) return 0
  
  // Count shared words
  const shared = words1.filter(word => words2.includes(word)).length
  
  // Calculate Jaccard similarity
  return shared / (words1.length + words2.length - shared)
}

// Identify knowledge gaps
function identifyKnowledgeGaps(flashcards: any[]): LearningGap[] {
  if (flashcards.length < 5) return []
  
  // In a real implementation, this would analyze the content and structure
  // of the flashcards to identify missing concepts and relationships
  
  // Group flashcards by potential topics
  const topics = extractPossibleTopics(flashcards)
  
  // Identify gaps within topics
  const gaps: LearningGap[] = []
  
  topics.forEach(topic => {
    // Only consider topics with low confidence as potential gaps
    if (topic.averageConfidence < 3.5) {
      // Simulate finding missing concepts within this topic
      const relatedConcepts = getSimulatedRelatedConcepts(topic.name)
      
      // Check which concepts are in flashcards vs. which are missing
      const coveredConcepts = flashcards
        .filter(card => card.term.toLowerCase().includes(topic.name.toLowerCase()))
        .map(card => extractMainConcept(card.term))
      
      const missingConcepts = relatedConcepts.filter(concept => 
        !coveredConcepts.some(covered => 
          covered.toLowerCase().includes(concept.toLowerCase()) || 
          concept.toLowerCase().includes(covered.toLowerCase())
        )
      )
      
      if (missingConcepts.length > 0) {
        gaps.push({
          topic: topic.name,
          conceptsToReview: coveredConcepts.slice(0, 2),
          missingKnowledge: `Missing key ${topic.name} concepts: ${missingConcepts.join(', ')}`,
          recommendedResources: generateRecommendedResources(topic.name),
          priority: topic.averageConfidence < 2.5 ? 'high' : 'medium'
        })
      }
    }
  })
  
  return gaps.slice(0, 3) // Return top 3 gaps
}

function extractMainConcept(term: string): string {
  // Clean up the term to get the main concept
  return term.toLowerCase()
    .replace(/what is|define|explain|\?/gi, '')
    .trim()
    .split(/\s+/)
    .filter(w => w.length > 3)
    .slice(0, 3)
    .join(' ')
}

function getSimulatedRelatedConcepts(topic: string): string[] {
  // This would normally use a knowledge graph or AI to generate related concepts
  // For simulation, we'll use some common related terms for certain topics
  const conceptMap: {[key: string]: string[]} = {
    'cell': ['membrane', 'mitochondria', 'nucleus', 'cytoplasm', 'organelles'],
    'atom': ['electron', 'proton', 'neutron', 'nucleus', 'orbital'],
    'protein': ['amino acids', 'folding', 'structure', 'function', 'synthesis'],
    'derivative': ['function', 'rate of change', 'differentiation', 'limit', 'slope'],
    'neuron': ['axon', 'dendrite', 'synapse', 'action potential', 'myelin'],
    'dna': ['replication', 'transcription', 'translation', 'nucleotides', 'base pairs'],
    'planet': ['orbit', 'solar system', 'gravity', 'atmosphere', 'rotation'],
    'triangle': ['angles', 'sides', 'area', 'congruence', 'similarity'],
    'democracy': ['voting', 'representation', 'constitution', 'branches', 'rights']
  }
  
  // Try to find direct match
  const lowerTopic = topic.toLowerCase()
  for (const [key, concepts] of Object.entries(conceptMap)) {
    if (lowerTopic.includes(key)) {
      return concepts
    }
  }
  
  // Default to generic concepts
  return [
    `${topic} principles`, 
    `${topic} applications`, 
    `${topic} examples`,
    `${topic} types`,
    `${topic} characteristics`
  ]
}

function generateRecommendedResources(topic: string): string[] {
  // This would normally recommend actual resources
  return [
    `"Understanding ${topic}" chapter in textbook`,
    `Interactive ${topic} visualization`,
    `Practice problems on ${topic} fundamentals`
  ]
}
</script>