<template>
  <div class="glass-card p-6 max-w-2xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-xl font-bold text-white flex items-center">
        <Lightbulb class="h-5 w-5 mr-2 text-yellow-400" />
        AI Memory Aid Generator
      </h2>
      <button
        @click="$emit('close')"
        class="text-cosmic-400 hover:text-white"
      >
        ×
      </button>
    </div>

    <!-- Preferences Step -->
    <div v-if="step === 'preferences'" class="space-y-6">
      <div>
        <h3 class="text-white font-medium mb-3">Your Interests</h3>
        <p class="text-cosmic-300 text-sm mb-4">
          Select interests to personalize your memory aids:
        </p>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="interest in interestOptions"
            :key="interest"
            @click="toggleInterest(interest)"
            :class="[
              'px-3 py-1.5 rounded-full text-sm transition-all',
              preferences.interests.includes(interest)
                ? 'bg-cosmic-500 text-white'
                : 'bg-white/10 text-cosmic-300 hover:bg-white/20'
            ]"
          >
            {{ interest }}
          </button>
        </div>
      </div>

      <div>
        <h3 class="text-white font-medium mb-3">Mnemonic Types</h3>
        <p class="text-cosmic-300 text-sm mb-4">
          Select which types of mnemonics you prefer:
        </p>
        <div class="grid grid-cols-2 md:grid-cols-5 gap-2">
          <button
            v-for="option in mnemonicTypeOptions" 
            :key="option.id"
            @click="toggleMnemonicType(option.id)"
            :class="[
              'p-3 rounded-lg flex flex-col items-center text-center transition-all',
              preferences.preferredTypes.includes(option.id)
                ? 'bg-cosmic-500/30 border border-cosmic-400 text-white'
                : 'bg-white/5 border border-white/10 text-cosmic-300 hover:bg-white/10'
            ]"
          >
            <component :is="option.icon" class="h-6 w-6 mb-2" />
            <span class="text-sm">{{ option.label }}</span>
          </button>
        </div>
      </div>

      <button
        @click="generateMnemonics"
        class="w-full cosmic-button py-3 flex items-center justify-center space-x-2"
      >
        <BrainCircuit class="h-5 w-5" />
        <span>Generate Personalized Mnemonics</span>
      </button>
    </div>
    
    <!-- Generating Step -->
    <div v-else-if="step === 'generating'" class="flex flex-col items-center justify-center py-16">
      <div class="w-16 h-16 flex items-center justify-center rounded-full bg-gradient-to-r from-cosmic-500 to-nebula-500 mb-4 animate-spin">
        <BrainCircuit class="h-8 w-8 text-white" />
      </div>
      <h3 class="text-xl font-bold text-white mb-2">Generating Mnemonics</h3>
      <p class="text-cosmic-300 text-center max-w-md">
        Creating personalized memory aids based on your preferences and the flashcard content...
      </p>
    </div>
    
    <!-- Results Step -->
    <div v-else-if="step === 'results'" class="space-y-6">
      <div class="p-4 bg-cosmic-500/10 border border-cosmic-500/30 rounded-lg">
        <div class="text-sm font-medium text-cosmic-300 mb-1">Flashcard Term:</div>
        <div class="text-white font-medium">{{ flashcard.term }}</div>
      </div>

      <div class="space-y-4">
        <div
          v-for="mnemonic in mnemonics"
          :key="mnemonic.type"
          :class="[
            'glass-card p-4 transition-all',
            selectedMnemonic?.type === mnemonic.type 
              ? 'border-cosmic-400 ring-2 ring-cosmic-400/30' 
              : 'hover:border-cosmic-400/50'
          ]"
        >
          <div class="flex justify-between items-start mb-3">
            <div class="flex items-center">
              <component 
                :is="getMnemonicIcon(mnemonic.type)" 
                class="h-5 w-5 text-cosmic-400 mr-2" 
              />
              <div class="font-medium text-white capitalize">{{ mnemonic.type }}</div>
            </div>
            <div class="flex space-x-1">
              <button
                @click="regenerateMnemonic(mnemonic.type)"
                class="p-1.5 text-cosmic-300 hover:text-white hover:bg-white/10 rounded transition-colors"
                title="Generate new version"
              >
                <RefreshCw class="h-4 w-4" />
              </button>
              <button
                @click="saveMnemonic(mnemonic)"
                :class="[
                  'p-1.5 rounded transition-colors',
                  selectedMnemonic?.type === mnemonic.type
                    ? 'text-green-400'
                    : 'text-cosmic-300 hover:text-green-400 hover:bg-white/10'
                ]"
                :title="selectedMnemonic?.type === mnemonic.type ? 'Saved' : 'Save to flashcard'"
              >
                <Check class="h-4 w-4" />
              </button>
            </div>
          </div>
          
          <VueMarkdown class="text-cosmic-100">{{ mnemonic.content }}</VueMarkdown>
          
          <div class="mt-2 text-xs text-cosmic-400">{{ mnemonic.description }}</div>
        </div>
      </div>

      <div class="flex space-x-3">
        <button
          @click="step = 'preferences'"
          class="nebula-button flex-1 py-2"
        >
          Adjust Preferences
        </button>
        <button
          @click="$emit('close')"
          class="cosmic-button flex-1 py-2"
        >
          Done
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import VueMarkdown from 'vue3-markdown-it'
import { 
  BrainCircuit, 
  RefreshCw, 
  Check,
  Sparkles,
  Lightbulb,
  AlignLeft,
  BookAIcon,
  Music,
  BrainCog
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

interface Mnemonic {
  type: 'acronym' | 'story' | 'visualization' | 'rhyme' | 'association'
  content: string
  description: string
}

interface Props {
  flashcard: {
    id: string
    term: string
    definition: string
    difficulty: string
  }
}

// Props and emits
const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'close'): void
}>()

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const mnemonics = ref<Mnemonic[]>([])
const isGenerating = ref(false)
const selectedMnemonic = ref<Mnemonic | null>(null)
const preferences = ref({
  interests: [] as string[],
  preferredTypes: ['acronym', 'story', 'visualization', 'rhyme', 'association'] as string[]
})
const step = ref<'preferences' | 'generating' | 'results'>('preferences')

// Options
const interestOptions = [
  'Sports', 'Music', 'Gaming', 'Movies', 'Travel', 
  'Cooking', 'Art', 'Technology', 'Nature', 'Literature'
]

const mnemonicTypeOptions = [
  { id: 'acronym', label: 'Acronyms', icon: BookAIcon },
  { id: 'story', label: 'Stories', icon: AlignLeft },
  { id: 'visualization', label: 'Visual Imagery', icon: BrainCircuit },
  { id: 'rhyme', label: 'Rhymes & Songs', icon: Music },
  { id: 'association', label: 'Associations', icon: BrainCog }
]

// Methods
const toggleInterest = (interest: string) => {
  if (preferences.value.interests.includes(interest)) {
    preferences.value.interests = preferences.value.interests.filter(i => i !== interest)
  } else {
    preferences.value.interests.push(interest)
  }
}

const toggleMnemonicType = (type: string) => {
  if (preferences.value.preferredTypes.includes(type)) {
    if (preferences.value.preferredTypes.length > 1) {
      preferences.value.preferredTypes = preferences.value.preferredTypes.filter(t => t !== type)
    }
  } else {
    preferences.value.preferredTypes.push(type)
  }
}

const generateMnemonics = () => {
  step.value = 'generating'
  isGenerating.value = true
  
  // In a real implementation, this would call an API to generate the mnemonics
  // based on the flashcard content and user preferences
  setTimeout(() => {
    const generatedMnemonics: Mnemonic[] = [
      createAcronym(props.flashcard.term, props.flashcard.definition, preferences.value.interests),
      createStory(props.flashcard.term, props.flashcard.definition, preferences.value.interests),
      createVisualization(props.flashcard.term, props.flashcard.definition, preferences.value.interests),
      createRhyme(props.flashcard.term, props.flashcard.definition, preferences.value.interests),
      createAssociation(props.flashcard.term, props.flashcard.definition, preferences.value.interests)
    ].filter(m => preferences.value.preferredTypes.includes(m.type));
    
    mnemonics.value = generatedMnemonics
    isGenerating.value = false
    step.value = 'results'
  }, 2000)
}

const regenerateMnemonic = (type: 'acronym' | 'story' | 'visualization' | 'rhyme' | 'association') => {
  // In a real implementation, this would regenerate just the specific mnemonic type
  const newMnemonic = type === 'acronym' 
    ? createAcronym(props.flashcard.term, props.flashcard.definition, preferences.value.interests)
    : type === 'story'
    ? createStory(props.flashcard.term, props.flashcard.definition, preferences.value.interests)
    : type === 'visualization'
    ? createVisualization(props.flashcard.term, props.flashcard.definition, preferences.value.interests)
    : type === 'rhyme'
    ? createRhyme(props.flashcard.term, props.flashcard.definition, preferences.value.interests)
    : createAssociation(props.flashcard.term, props.flashcard.definition, preferences.value.interests)
  
  mnemonics.value = mnemonics.value.map(m => m.type === type ? newMnemonic : m)
}

const saveMnemonic = (mnemonic: Mnemonic) => {
  // In a real implementation, this would save the mnemonic to the database
  // For now, we'll just show a success toast and award XP
  toast.success('Mnemonic saved to flashcard!')
  selectedMnemonic.value = mnemonic
  
  // Award XP for using learning strategies
  authStore.addExperience(20, "Created Memory Aid")
}

const getMnemonicIcon = (type: string) => {
  switch (type) {
    case 'acronym': return BookAIcon
    case 'story': return AlignLeft
    case 'visualization': return BrainCircuit
    case 'rhyme': return Music
    case 'association': return BrainCog
    default: return Lightbulb
  }
}

// Mock mnemonic generation functions - in a real app these would be much more sophisticated
// and would likely use an AI service
function createAcronym(term: string, definition: string, interests: string[]): Mnemonic {
  // Extract keywords from the definition
  const keywords = definition.split(/\s+/).filter(word => word.length > 4)
  
  let acronym = ''
  if (keywords.length >= 4) {
    // Take first letters of several keywords
    acronym = keywords.slice(0, 4).map(word => word[0].toUpperCase()).join('')
  } else {
    // Fallback to extract words that start with different letters
    const uniqueFirstLetters = new Set()
    const selectedWords = []
    
    for (const word of definition.split(/\s+/)) {
      if (word.length > 3 && !uniqueFirstLetters.has(word[0].toUpperCase())) {
        uniqueFirstLetters.add(word[0].toUpperCase())
        selectedWords.push(word)
        if (selectedWords.length >= 4) break
      }
    }
    
    acronym = selectedWords.map(word => word[0].toUpperCase()).join('')
  }
  
  // Create a sentence from the acronym
  const words = []
  for (let i = 0; i < acronym.length; i++) {
    const letter = acronym[i]
    const validWords = getWordStartingWithLetter(letter, interests)
    words.push(validWords)
  }
  
  const explanation = `This acronym ${acronym} represents key elements from the concept. Each letter stands for an important component, making it easier to recall the complete information.`
  
  return {
    type: 'acronym',
    content: `**${acronym}**: ${words.join(' ')}`,
    description: explanation
  }
}

function createStory(term: string, definition: string, interests: string[]): Mnemonic {
  // Extract main concept name
  const conceptName = term.replace(/what is |define |explain /i, '').replace(/\?/g, '').trim()
  
  // Extract a few keywords
  const keywords = definition.split(/\s+/).filter(word => word.length > 4).slice(0, 3)
  
  // Create a simple story incorporating the concept and keywords
  let storyContext = 'a cosmic journey'
  if (interests.includes('Sports')) storyContext = 'a championship game'
  else if (interests.includes('Music')) storyContext = 'a concert performance'
  else if (interests.includes('Gaming')) storyContext = 'an epic quest'
  else if (interests.includes('Movies')) storyContext = 'a blockbuster film'
  else if (interests.includes('Cooking')) storyContext = 'preparing a masterpiece dish'
  
  const story = `Imagine ${conceptName} as a character in ${storyContext}. ${
    keywords.length > 0 
      ? `They encounter ${keywords.join(', ')}, which represent the key aspects of the concept.`
      : `They journey through the different aspects of this concept, making each element memorable.`
  } The hero's journey mirrors the process of ${conceptName.toLowerCase()}, creating a memorable narrative for recall.`
  
  return {
    type: 'story',
    content: story,
    description: 'Stories leverage our natural affinity for narrative to make abstract concepts concrete and memorable.'
  }
}

function createVisualization(term: string, definition: string, interests: string[]): Mnemonic {
  // Extract main concept name
  const conceptName = term.replace(/what is |define |explain /i, '').replace(/\?/g, '').trim()
  
  // Create a visual image incorporating user interests
  let visualContext = 'a cosmic landscape'
  if (interests.includes('Sports')) visualContext = 'a stadium'
  else if (interests.includes('Music')) visualContext = 'a concert stage'
  else if (interests.includes('Gaming')) visualContext = 'a video game level'
  else if (interests.includes('Travel')) visualContext = 'a famous landmark'
  else if (interests.includes('Nature')) visualContext = 'a forest scene'
  
  const visualization = `Visualize ${conceptName} as ${visualContext}. Picture each component brightly colored and animated, interacting with each other. See ${
    definition.split(/\s+/).filter(word => word.length > 4).slice(0, 2).join(' and ')
  } as central elements in this mental image. The more vivid and unusual you make this image, the more memorable it becomes.`
  
  return {
    type: 'visualization',
    content: visualization,
    description: 'Visual imagery leverages your brain\'s powerful visual processing systems for better recall.'
  }
}

function createRhyme(term: string, definition: string, interests: string[]): Mnemonic {
  // Extract main concept
  const conceptName = term.replace(/what is |define |explain /i, '').replace(/\?/g, '').trim()
  
  // Extract some keywords
  const keywords = definition.split(/\s+/).filter(word => word.length > 3).slice(0, 3)
  
  // Create a simple rhyming couplet
  const rhyme = `Remember ${conceptName} with this rhyme in time,\nIt's all about ${keywords.join(', ')}, which is truly sublime!`
  
  return {
    type: 'rhyme',
    content: rhyme,
    description: 'Rhymes engage auditory memory and are particularly effective for verbal/auditory learners.'
  }
}

function createAssociation(term: string, definition: string, interests: string[]): Mnemonic {
  // Extract main concept
  const conceptName = term.replace(/what is |define |explain /i, '').replace(/\?/g, '').trim()
  
  // Create associations based on user interests
  let association = `Link ${conceptName} to something familiar in your daily life.`
  
  if (interests.includes('Sports')) {
    association = `Think of ${conceptName} like a sports play: the components work together like team members, each with a specific role to achieve the goal of ${
      definition.split(/\s+/).slice(0, 3).join(' ')
    }.`
  } else if (interests.includes('Music')) {
    association = `Associate ${conceptName} with your favorite song. The main components are like different instruments playing together to create the harmony of ${
      definition.split(/\s+/).slice(0, 3).join(' ')
    }.`
  } else if (interests.includes('Gaming')) {
    association = `Imagine ${conceptName} as a video game level. Each element is like a game character with unique abilities that contribute to the overall quest of ${
      definition.split(/\s+/).slice(0, 3).join(' ')
    }.`
  } else if (interests.includes('Cooking')) {
    association = `Think of ${conceptName} as a recipe. The different elements are ingredients that blend together to create the dish of ${
      definition.split(/\s+/).slice(0, 3).join(' ')
    }.`
  } else if (interests.includes('Technology')) {
    association = `Compare ${conceptName} to a computer system. Each component is like a hardware part working together to run the program of ${
      definition.split(/\s+/).slice(0, 3).join(' ')
    }.`
  }
  
  return {
    type: 'association',
    content: association,
    description: 'Personal associations leverage existing knowledge networks, making new information easier to integrate and recall.'
  }
}

function getWordStartingWithLetter(letter: string, interests: string[]): string {
  // Dictionary of words by starting letter
  const wordDictionary: {[key: string]: string[]} = {
    'A': ['Amazing', 'Awesome', 'Abundant', 'Athletic', 'Artistic'],
    'B': ['Brilliant', 'Brave', 'Bold', 'Balanced', 'Bright'],
    'C': ['Creative', 'Cosmic', 'Critical', 'Careful', 'Clever'],
    'D': ['Dynamic', 'Detailed', 'Deep', 'Diverse', 'Dedicated'],
    'E': ['Exciting', 'Engaging', 'Effective', 'Energetic', 'Essential'],
    'F': ['Focused', 'Fast', 'Fundamental', 'Flowing', 'Famous'],
    'G': ['Great', 'Glowing', 'Graceful', 'Gradual', 'Genuine'],
    'H': ['Helpful', 'Harmonious', 'Historic', 'Healthy', 'Huge'],
    'I': ['Interesting', 'Important', 'Innovative', 'Incredible', 'Intense'],
    'J': ['Joyful', 'Jovial', 'Jumping', 'Justified', 'Judgmental'],
    'K': ['Kind', 'Keen', 'Knowledgeable', 'Key', 'Kinetic'],
    'L': ['Logical', 'Lively', 'Learning', 'Lasting', 'Limitless'],
    'M': ['Magical', 'Meaningful', 'Magnificent', 'Modern', 'Methodical'],
    'N': ['Natural', 'Notable', 'Necessary', 'Nurturing', 'Novel'],
    'O': ['Outstanding', 'Optimal', 'Original', 'Organized', 'Obvious'],
    'P': ['Powerful', 'Precise', 'Perfect', 'Practical', 'Profound'],
    'Q': ['Quick', 'Quiet', 'Quality', 'Quantifiable', 'Questioning'],
    'R': ['Remarkable', 'Resilient', 'Rapid', 'Revolutionary', 'Robust'],
    'S': ['Stunning', 'Strategic', 'Systematic', 'Sustainable', 'Symbolic'],
    'T': ['Thoughtful', 'Thorough', 'Transformative', 'Timely', 'Technical'],
    'U': ['Unique', 'Useful', 'Understanding', 'Universal', 'Unwavering'],
    'V': ['Valuable', 'Vibrant', 'Versatile', 'Victorious', 'Vivid'],
    'W': ['Wonderful', 'Wise', 'Wholesome', 'Worthy', 'Winning'],
    'X': ['Xenial', 'Xeric', 'Xenophilic', 'X-factor', 'Xylographic'],
    'Y': ['Yearning', 'Yielding', 'Youthful', 'Yellow', 'Yearly'],
    'Z': ['Zealous', 'Zenith', 'Zestful', 'Zippy', 'Zen-like']
  }

  // Get words for this letter
  const words = wordDictionary[letter.toUpperCase()] || ['Magnificent']
  
  // If user has interests, try to adapt word choice
  if (interests.length > 0) {
    if (interests.includes('Sports') && letter.toUpperCase() === 'A') return 'Athletic'
    if (interests.includes('Music') && letter.toUpperCase() === 'M') return 'Musical'
    if (interests.includes('Gaming') && letter.toUpperCase() === 'G') return 'Gaming'
    if (interests.includes('Art') && letter.toUpperCase() === 'A') return 'Artistic'
    if (interests.includes('Technology') && letter.toUpperCase() === 'T') return 'Technological'
  }
  
  // Return a random word from the options
  return words[Math.floor(Math.random() * words.length)]
}
</script>