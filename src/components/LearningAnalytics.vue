<template>
  <div class="space-y-8">
    <!-- Header with Controls -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h2 class="text-2xl font-bold text-glow mb-2">Learning Analytics</h2>
        <p class="text-cosmic-300">Discover patterns and optimize your cosmic learning journey</p>
      </div>
      
      <div class="flex items-center space-x-4">
        <!-- Timeframe Selector -->
        <div class="flex bg-white/5 rounded-lg p-1">
          <button
            v-for="period in ['week', 'month', 'quarter']"
            :key="period"
            @click="timeframe = period"
            :class="[
              'px-3 py-1 rounded text-sm capitalize transition-all',
              timeframe === period
                ? 'bg-cosmic-500 text-white'
                : 'text-cosmic-300 hover:text-white'
            ]"
          >
            {{ period }}
          </button>
        </div>

        <!-- Metric Selector -->
        <div class="flex bg-white/5 rounded-lg p-1">
          <button
            v-for="metric in metrics"
            :key="metric.key"
            @click="selectedMetric = metric.key"
            :class="[
              'flex items-center space-x-1 px-3 py-1 rounded text-sm transition-all',
              selectedMetric === metric.key
                ? 'bg-cosmic-500 text-white'
                : 'text-cosmic-300 hover:text-white'
            ]"
          >
            <component :is="metric.icon" class="h-4 w-4" />
            <span>{{ metric.label }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Key Metrics Overview -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div
        v-for="(metric, index) in keyMetrics"
        :key="metric.label"
        class="glass-card p-4"
      >
        <div class="flex items-center justify-between mb-2">
          <div :class="['p-2 rounded-lg bg-gradient-to-r', metric.color]">
            <component :is="metric.icon" class="h-4 w-4 text-white" />
          </div>
          <component :is="getTrendIcon(metric.trend)" />
        </div>
        <div class="text-xl font-bold text-white mb-1">{{ metric.value }}</div>
        <div class="text-sm text-cosmic-300 mb-1">{{ metric.label }}</div>
        <div :class="[
          'text-xs',
          metric.trend === 'up' ? 'text-green-400' : 'text-red-400'
        ]">
          {{ metric.change }}
        </div>
      </div>
    </div>

    <!-- Main Chart -->
    <div class="glass-card p-6">
      <div class="flex items-center justify-between mb-6">
        <h3 class="text-lg font-bold text-white">{{ getMetricLabel() }} Trend</h3>
        <div class="text-sm text-cosmic-300">Last {{ timeframe }}</div>
      </div>
      
      <div class="relative h-64">
        <div class="absolute inset-0 flex items-end justify-between space-x-2">
          <div
            v-for="(value, index) in getCurrentData()"
            :key="index" 
            class="flex-1 flex flex-col items-center"
          >
            <div
              class="w-full bg-gradient-to-t rounded-t min-h-[4px] relative group"
              :class="getMetricColor()"
              :style="{ height: `${(value / maxValue) * 100}%` }"
            >
              <!-- Tooltip -->
              <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <div class="bg-black/80 text-white text-xs px-2 py-1 rounded whitespace-nowrap">
                  {{ value }}{{ selectedMetric === 'time' ? 'min' : '%' }}
                </div>
              </div>
            </div>
            <div class="text-xs text-cosmic-400 mt-2">{{ learningData.dates[index] }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Subject Breakdown -->
    <div class="glass-card p-6">
      <h3 class="text-lg font-bold text-white mb-6">Subject Analysis</h3>
      
      <div class="space-y-4">
        <div
          v-for="(subject, index) in subTopics"
          :key="subject.topic"
          class="bg-white/5 rounded-lg p-4"
        >
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-3">
              <h4 class="font-bold text-white">{{ subject.topic }}</h4>
              <component :is="getTrendIcon(subject.trend)" />
            </div>
            <div class="text-sm text-cosmic-300">
              {{ subject.timeSpent }}h this week
            </div>
          </div>
          
          <div class="grid md:grid-cols-3 gap-4">
            <div>
              <div class="flex items-center justify-between text-sm mb-1">
                <span class="text-cosmic-300">Progress</span>
                <span class="text-white">{{ subject.progress }}%</span>
              </div>
              <div class="w-full bg-cosmic-900/50 rounded-full h-2">
                <div
                  class="bg-gradient-to-r from-cosmic-500 to-cosmic-600 h-2 rounded-full"
                  :style="{ width: `${subject.progress}%` }"
                ></div>
              </div>
            </div>
            
            <div>
              <div class="text-sm text-cosmic-300 mb-1">Accuracy</div>
              <div 
                :class="[
                  'text-lg font-bold',
                  subject.accuracy >= 85 ? 'text-green-400' : 
                  subject.accuracy >= 70 ? 'text-star-400' : 'text-red-400'
                ]"
              >
                {{ subject.accuracy }}%
              </div>
            </div>
            
            <div>
              <div class="text-sm text-cosmic-300 mb-1">Focus Areas</div>
              <div class="flex flex-wrap gap-1">
                <span 
                  v-for="(area, i) in subject.weakAreas" 
                  :key="i" 
                  class="text-xs bg-red-500/20 text-red-300 px-2 py-1 rounded"
                >
                  {{ area }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- AI Insights -->
    <div class="glass-card p-6">
      <h3 class="text-lg font-bold text-white mb-6 flex items-center">
        <Brain class="h-5 w-5 mr-2 text-cosmic-400" />
        AI-Powered Insights
      </h3>
      
      <div class="grid md:grid-cols-2 gap-4">
        <div
          v-for="(insight, index) in insights"
          :key="index"
          :class="[
            'rounded-lg p-4 border',
            getInsightColor(insight.type)
          ]"
        >
          <div class="flex items-start space-x-3">
            <div class="flex-shrink-0 mt-1">
              <component :is="getInsightIcon(insight.type)" />
            </div>
            <div class="flex-1">
              <h4 class="font-bold text-white mb-2">{{ insight.title }}</h4>
              <p class="text-cosmic-300 text-sm mb-3">{{ insight.description }}</p>
              <button class="text-xs cosmic-button">
                {{ insight.action }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Study Session Breakdown -->
    <div class="grid md:grid-cols-2 gap-6">
      <div class="glass-card p-6">
        <h3 class="text-lg font-bold text-white mb-6">Activity Distribution</h3>
        
        <div class="space-y-4">
          <div v-for="(item, index) in activityDistribution" :key="item.activity" class="space-y-2">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-2">
                <component :is="item.icon" class="h-4 w-4 text-cosmic-400" />
                <span class="text-white text-sm">{{ item.activity }}</span>
              </div>
              <span class="text-cosmic-300 text-sm">{{ item.time }}h</span>
            </div>
            <div class="w-full bg-cosmic-900/50 rounded-full h-2">
              <div
                :class="['bg-gradient-to-r h-2 rounded-full', item.color]"
                :style="{ width: `${(item.time / 25) * 100}%` }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <div class="glass-card p-6">
        <h3 class="text-lg font-bold text-white mb-6">Performance Metrics</h3>
        
        <div class="space-y-4">
          <div v-for="(item, index) in performanceMetrics" :key="item.metric" class="space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-white text-sm">{{ item.metric }}</span>
              <div class="flex items-center space-x-2">
                <span :class="[
                  'text-sm font-bold',
                  item.value >= item.target ? 'text-green-400' : 'text-star-400'
                ]">
                  {{ item.value }}{{ item.unit }}
                </span>
                <component 
                  :is="item.value >= item.target ? ArrowUp : Target" 
                  :class="[
                    'h-3 w-3',
                    item.value >= item.target ? 'text-green-400' : 'text-star-400'
                  ]" 
                />
              </div>
            </div>
            <div class="w-full bg-cosmic-900/50 rounded-full h-2">
              <div
                :class="[
                  'h-2 rounded-full',
                  item.value >= item.target 
                    ? 'bg-gradient-to-r from-green-500 to-green-600'
                    : 'bg-gradient-to-r from-star-500 to-star-600'
                ]"
                :style="{ width: `${(item.value / 100) * 100}%` }"
              ></div>
            </div>
            <div class="text-xs text-cosmic-400">
              Target: {{ item.target }}{{ item.unit }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { 
  TrendingUp, 
  TrendingDown, 
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
  Webhook,
  Minus,
  ArrowUp,
  ArrowDown,
  BarChart2,
  CreditCard,
  Gamepad2,
  Users,
  Timer
} from 'lucide-vue-next'

// Reactive state
const timeframe = ref<'week' | 'month' | 'quarter'>('week')
const selectedMetric = ref<'time' | 'accuracy' | 'retention'>('time')
const learningData = ref({
  studyTime: [120, 140, 95, 180, 160, 200, 175],
  accuracy: [78, 82, 75, 88, 85, 91, 89],
  engagement: [85, 88, 80, 92, 89, 95, 93],
  retention: [72, 76, 70, 84, 82, 88, 86],
  dates: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
})
const subTopics = ref([
  {
    topic: 'Physics',
    progress: 78,
    timeSpent: 45,
    accuracy: 85,
    trend: 'up' as 'up' | 'down' | 'stable',
    weakAreas: ['Quantum Mechanics', 'Thermodynamics'],
    strengths: ['Classical Mechanics', 'Electromagnetism']
  },
  {
    topic: 'Mathematics',
    progress: 92,
    timeSpent: 60,
    accuracy: 94,
    trend: 'up' as 'up' | 'down' | 'stable',
    weakAreas: ['Differential Equations'],
    strengths: ['Calculus', 'Linear Algebra', 'Statistics']
  },
  {
    topic: 'Chemistry',
    progress: 65,
    timeSpent: 30,
    accuracy: 72,
    trend: 'down' as 'up' | 'down' | 'stable',
    weakAreas: ['Organic Chemistry', 'Chemical Bonding'],
    strengths: ['Periodic Table', 'Basic Reactions']
  },
  {
    topic: 'Biology',
    progress: 83,
    timeSpent: 40,
    accuracy: 89,
    trend: 'stable' as 'up' | 'down' | 'stable',
    weakAreas: ['Genetics'],
    strengths: ['Cell Biology', 'Ecology', 'Evolution']
  }
])
const insights = ref([
  {
    type: 'improvement',
    title: 'Study Pattern Optimization',
    description: 'You study most effectively between 7-9 PM. Consider scheduling important topics during this peak performance window.',
    action: 'Optimize Schedule',
    impact: 'high'
  },
  {
    type: 'concern',
    title: 'Chemistry Performance Drop',
    description: 'Your chemistry accuracy has decreased by 15% this week. Focus on organic chemistry fundamentals.',
    action: 'Create Study Plan',
    impact: 'medium'
  },
  {
    type: 'achievement',
    title: 'Mathematics Mastery',
    description: 'Excellent progress in mathematics! You\'ve maintained 90%+ accuracy for 2 weeks straight.',
    action: 'Advance to Next Level',
    impact: 'high'
  },
  {
    type: 'opportunity',
    title: 'Flashcard Efficiency',
    description: 'Using flashcards increases your retention by 23%. Consider creating more cards for weak subjects.',
    action: 'Generate Flashcards',
    impact: 'medium'
  }
])

// Metric options
const metrics = [
  { key: 'time', label: 'Time', icon: Clock },
  { key: 'accuracy', label: 'Accuracy', icon: Target },
  { key: 'retention', label: 'Retention', icon: Brain }
]

// Key metrics data
const keyMetrics = [
  { 
    label: 'Total Study Time', 
    value: '24.5h', 
    change: '+12%', 
    trend: 'up' as const,
    icon: Clock,
    color: 'from-cosmic-500 to-cosmic-600'
  },
  { 
    label: 'Average Accuracy', 
    value: '87%', 
    change: '+5%', 
    trend: 'up' as const,
    icon: Target,
    color: 'from-green-500 to-green-600'
  },
  { 
    label: 'Retention Rate', 
    value: '82%', 
    change: '+8%', 
    trend: 'up' as const,
    icon: Brain,
    color: 'from-purple-500 to-purple-600'
  },
  { 
    label: 'Learning Streak', 
    value: '12 days', 
    change: 'New record!', 
    trend: 'up' as const,
    icon: Star,
    color: 'from-star-500 to-star-600'
  }
]

// Activity distribution data
const activityDistribution = [
  { activity: 'Notes', time: 8.5, icon: BookOpen, color: 'from-cosmic-500 to-cosmic-600' },
  { activity: 'Flashcards', time: 6.2, icon: CreditCard, color: 'from-nebula-500 to-nebula-600' },
  { activity: 'MemoQuest', time: 4.8, icon: Gamepad2, color: 'from-star-500 to-star-600' },
  { activity: 'Study Groups', time: 3.5, icon: Users, color: 'from-green-500 to-green-600' },
  { activity: 'Pomodoro', time: 2.0, icon: Timer, color: 'from-red-500 to-red-600' }
]

// Performance metrics data
const performanceMetrics = [
  { metric: 'Focus Score', value: 89, target: 90, unit: '' },
  { metric: 'Consistency', value: 76, target: 80, unit: '%' },
  { metric: 'Goal Achievement', value: 92, target: 85, unit: '%' },
  { metric: 'Knowledge Retention', value: 84, target: 85, unit: '%' }
]

// Computed
const maxValue = computed(() => Math.max(...getCurrentData()))

// Methods
const getCurrentData = () => {
  switch (selectedMetric.value) {
    case 'accuracy': return learningData.value.accuracy
    case 'retention': return learningData.value.retention
    default: return learningData.value.studyTime
  }
}

const getMetricLabel = () => {
  switch (selectedMetric.value) {
    case 'accuracy': return 'Accuracy %'
    case 'retention': return 'Retention %'
    default: return 'Study Time (min)'
  }
}

const getMetricColor = () => {
  switch (selectedMetric.value) {
    case 'accuracy': return 'from-green-500 to-green-600'
    case 'retention': return 'from-purple-500 to-purple-600'
    default: return 'from-cosmic-500 to-cosmic-600'
  }
}

const getTrendIcon = (trend: 'up' | 'down' | 'stable') => {
  switch (trend) {
    case 'up': return ArrowUp
    case 'down': return ArrowDown
    default: return Minus
  }
}

const getInsightIcon = (type: string) => {
  switch (type) {
    case 'improvement': return TrendingUp
    case 'concern': return AlertTriangle
    case 'achievement': return Award
    case 'opportunity': return Zap
    default: return Brain
  }
}

const getInsightColor = (type: string) => {
  switch (type) {
    case 'improvement': return 'border-green-400/50 bg-green-400/10'
    case 'concern': return 'border-red-400/50 bg-red-400/10'
    case 'achievement': return 'border-star-400/50 bg-star-400/10'
    case 'opportunity': return 'border-cosmic-400/50 bg-cosmic-400/10'
    default: return 'border-white/10 bg-white/5'
  }
}
</script>