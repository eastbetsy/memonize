<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-glow mb-2">Learning Decks</h1>
        <p class="text-cosmic-300">Create and manage decks for organized study</p>
      </div>
      
      <button
        v-if="authStore.isAuthenticated"
        @click="showCreateDeckForm = true"
        class="cosmic-button flex items-center space-x-2"
      >
        <Plus class="h-5 w-5" />
        <span>New Deck</span>
      </button>
    </div>

    <!-- Authentication Required -->
    <div v-if="!authStore.isAuthenticated" class="text-center py-20">
      <FileText class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h2 class="text-2xl font-bold text-white mb-4">Sign in to access Decks</h2>
      <p class="text-cosmic-300">Create an account to organize your studies with decks</p>
    </div>

    <!-- Loading State -->
    <div v-else-if="loading" class="flex items-center justify-center py-20">
      <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="decks.length === 0" class="text-center py-20">
      <FileText class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h3 class="text-xl font-bold text-white mb-2">No decks yet</h3>
      <p class="text-cosmic-300 mb-6">Create your first deck to organize your studies</p>
      <button
        @click="showCreateDeckForm = true"
        class="cosmic-button"
      >
        Create First Deck
      </button>
    </div>

    <!-- Decks Grid -->
    <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="deck in decks" 
        :key="deck.id"
        class="glass-card p-6 hover:border-cosmic-400/50 transition-all duration-300 group cursor-pointer"
        @click="viewDeck(deck)"
      >
        <div class="h-32 mb-4 rounded-lg bg-gradient-to-br from-cosmic-500/20 to-cosmic-700/20 flex items-center justify-center overflow-hidden">
          <component :is="getRandomIcon()" class="h-16 w-16 text-cosmic-400 opacity-70" />
        </div>

        <h3 class="text-lg font-bold text-white group-hover:text-glow transition-all mb-2">
          {{ deck.name }}
        </h3>
        
        <p class="text-cosmic-300 text-sm mb-3 line-clamp-2">
          {{ deck.description || 'No description' }}
        </p>
        
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-2 text-cosmic-400 text-sm">
            <Users class="h-4 w-4" />
            <span>{{ getDeckMemberCount(deck.id) }} members</span>
          </div>
          
          <div class="text-xs text-cosmic-400">
            {{ formatDate(deck.created_at) }}
          </div>
        </div>
      </div>
    </div>

    <!-- Create Deck Form -->
    <Transition>
      <div v-if="showCreateDeckForm" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
        <div @click.stop class="relative w-full max-w-md">
          <div class="glass-card p-6">
            <h3 class="text-xl font-bold text-white mb-4">Create New Deck</h3>
            
            <div class="space-y-4">
              <div>
                <label class="block text-cosmic-200 font-medium mb-2">Deck Name</label>
                <input
                  type="text"
                  v-model="newDeck.name"
                  class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
                  placeholder="Enter deck name..."
                />
              </div>
              
              <div>
                <label class="block text-cosmic-200 font-medium mb-2">Description</label>
                <textarea
                  v-model="newDeck.description"
                  rows="3"
                  class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
                  placeholder="Describe this deck..."
                ></textarea>
              </div>
              
              <div>
                <label class="block text-cosmic-200 font-medium mb-2">Color Theme</label>
                <div class="grid grid-cols-4 gap-3">
                  <button 
                    v-for="color in colorOptions" 
                    :key="color.id"
                    @click="newDeck.color = color.id"
                    class="w-full h-12 rounded-lg transition-all"
                    :class="[color.class, newDeck.color === color.id ? 'ring-2 ring-white' : '']"
                  ></button>
                </div>
              </div>
              
              <div class="flex gap-3 pt-2">
                <button
                  @click="createDeck"
                  class="cosmic-button flex-1"
                  :disabled="!newDeck.name"
                >
                  Create Deck
                </button>
                <button
                  @click="showCreateDeckForm = false"
                  class="nebula-button flex-1"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useToast } from 'vue-toastification'
import { 
  FileText, 
  Plus, 
  Users,
  BookOpen, 
  Brain, 
  Sparkles, 
  Target, 
  Star, 
  Lightbulb,
  Crown,
  ChevronLeft,
  Settings,
  PlusCircle,
  CalendarIcon
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

// State
const decks = ref<any[]>([])
const deckDetail = ref<any>(null)
const deckMembers = ref<{ deck_id: string, count: number }[]>([])
const deckMemberships = ref<any[]>([]);
const loading = ref(true)
const showCreateDeckForm = ref(false)
const newDeck = ref({
  name: '',
  description: '',
  color: 'cosmic'
})
const activeTab = ref('materials')
const isOwner = computed(() => deckDetail.value?.owner_id === authStore.user?.id)
const isTeacher = computed(() => {
  const membership = deckMemberships.value.find(m => m.user_id === authStore.user?.id)
  return membership?.role === 'teacher' || membership?.role === 'assistant'
})

// Composables
const toast = useToast()
const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()

// Methods
const fetchDecks = async () => {
  loading.value = true
  deckDetail.value = null
  
  try {
    // Get the token for authorization
    const { data: sessionData } = await supabase.auth.getSession();
    const token = sessionData.session?.access_token;
    
    if (!token) {
      throw new Error('Not authenticated');
    }

    // Use the deck function to get decks
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/deck`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Failed to fetch decks');
    }
    
    const data = await response.json();
    
    if (!data.success) {
      throw new Error(data.error || 'Unknown error fetching decks');
    }
    
    // Set the decks with their member counts
    decks.value = data.decks || [];
  } catch (error) {
    console.error('Error fetching decks:', error)
    toast.error('Failed to load decks')
  } finally {
    loading.value = false
  }
}

const fetchDeckDetail = async (deckId: string) => {
  loading.value = true
  try {
    // Get the token for authorization
    const { data: sessionData } = await supabase.auth.getSession();
    const token = sessionData.session?.access_token;
    
    if (!token) {
      throw new Error('Not authenticated');
    }

    // Use the deck function to get deck details
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/deck/${deckId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Failed to fetch deck details');
    }
    
    const data = await response.json();
    
    if (!data.success) {
      throw new Error(data.error || 'Unknown error fetching deck details');
    }
    
    // Set the deck details
    deckDetail.value = data.deck;
    
    // Extract memberships from the deck data
    if (data.deck && data.deck.members) {
      deckMemberships.value = data.deck.members;
    }
  } catch (error) {
    console.error('Error fetching deck detail:', error)
    toast.error('Failed to load deck details')
    router.push('/decks')
  } finally {
    loading.value = false
  }
}

// Watch for route parameter changes
watch(() => route.params.deckId, (newDeckId) => {
  if (newDeckId && typeof newDeckId === 'string') {
    fetchDeckDetail(newDeckId)
  } else {
    deckDetail.value = null
    fetchDecks()
  }
}, { immediate: true })

// Color options
const colorOptions = [
  { id: 'cosmic', class: 'bg-gradient-to-r from-cosmic-500 to-cosmic-600' },
  { id: 'nebula', class: 'bg-gradient-to-r from-nebula-500 to-nebula-600' },
  { id: 'star', class: 'bg-gradient-to-r from-star-500 to-star-600' },
  { id: 'emerald', class: 'bg-gradient-to-r from-green-500 to-green-600' },
  { id: 'azure', class: 'bg-gradient-to-r from-blue-500 to-blue-600' },
  { id: 'amethyst', class: 'bg-gradient-to-r from-purple-500 to-purple-600' },
  { id: 'ruby', class: 'bg-gradient-to-r from-red-500 to-red-600' },
  { id: 'amber', class: 'bg-gradient-to-r from-yellow-500 to-yellow-600' }
]

// Available icons for random selection
const deckIcons = [BookOpen, Brain, Sparkles, Target, Star, Lightbulb]

// Get random icon function
const getRandomIcon = () => {
  return deckIcons[Math.floor(Math.random() * deckIcons.length)]
}

// Lifecycle
onMounted(() => {
  if (authStore.isAuthenticated) {
    // Check if we're on a detail page
    const deckId = route.params.deckId
    if (deckId && typeof deckId === 'string') {
      fetchDeckDetail(deckId)
    } else {
      fetchDecks()
    }
  }
})

const createDeck = async () => {
  if (!newDeck.value.name.trim()) {
    toast.error('Please enter a deck name')
    return
  }

  try {
    const { data, error } = await supabase
      .from('decks')
      .insert([{
        name: newDeck.value.name,
        description: newDeck.value.description,
        color: newDeck.value.color,
        owner_id: authStore.user?.id
      }])
      .select()
      .single()

    if (error) throw error
    
    // Add creator as a member with teacher role
    const { error: memberError } = await supabase
      .from('deck_members')
      .insert([{
        deck_id: data.id,
        user_id: authStore.user?.id,
        role: 'teacher'
      }])

    if (memberError) throw memberError
    
    decks.value = [data, ...decks.value]
    
    // Award XP
    authStore.addExperience(30, "Created Learning Deck")
    
    newDeck.value = {
      name: '',
      description: '',
      color: 'cosmic'
    }
    showCreateDeckForm.value = false
    
    toast.success('Deck created successfully!')
  } catch (error) {
    console.error('Failed to create deck:', error)
    toast.error('Failed to create deck')
  }
}

const viewDeck = async (deck: any) => {
  // Navigate to the deck detail view
  router.push(`/decks/${deck.id}`);
}

const formatDate = (dateString: string): string => {
  return new Date(dateString).toLocaleDateString()
}

const getDeckMemberCount = (deckId: string): number => {
  const memberData = deckMembers.value.find(item => item.deck_id === deckId)
  return memberData ? memberData.count : 1 // Default to 1 (the owner)
}

// Join a deck by enrollment code
const joinDeckByCode = async (code: string) => {
  try {
    const { data, error } = await supabase.rpc('join_deck_by_code', {
      enrollment_code: code
    });
    
    if (error) throw error;
    
    if (data.success) {
      toast.success(data.message);
      fetchDecks();
    } else {
      toast.error(data.message);
    }
  } catch (error) {
    console.error('Error joining deck:', error);
    toast.error('Failed to join deck');
  }
}
</script>

<style scoped>
.v-enter-active,
.v-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.v-enter-from,
.v-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>