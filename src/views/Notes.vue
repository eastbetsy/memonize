<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-glow mb-2">Notebook</h1>
        <p class="text-cosmic-300">Capture knowledge from across the universe</p>
      </div>
      
      <button
        @click="isCreating = true"
        class="cosmic-button flex items-center space-x-2"
      >
        <Plus class="h-5 w-5" />
        <span>New Note</span>
      </button>
    </div>

    <!-- Search -->
    <div class="relative">
      <Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-cosmic-400" />
      <input
        type="text"
        placeholder="Search through your cosmic knowledge..."
        v-model="searchTerm"
        class="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
      />
    </div>

    <!-- Create Note Form -->
    <Transition>
      <div v-if="isCreating" class="glass-card p-6">
        <h3 class="text-xl font-bold text-white mb-4 flex items-center">
          <Sparkles class="h-5 w-5 mr-2 text-cosmic-400" />
          Create New Note
        </h3>
        
        <div class="space-y-4">
          <input
            type="text"
            placeholder="Note title..."
            v-model="newNote.title"
            class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
          />
          
          <textarea
            placeholder="Start writing your cosmic thoughts... (Markdown supported)"
            v-model="newNote.content"
            rows="6"
            class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
          ></textarea>
          
          <div class="flex gap-3">
            <button
              @click="createNote"
              class="cosmic-button flex items-center space-x-2"
            >
              <Brain class="h-4 w-4" />
              <span>Create & Generate Flashcards</span>
            </button>
            <button
              @click="isCreating = false"
              class="px-4 py-2 text-cosmic-300 hover:text-white transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Edit Note Form -->
    <Transition>
      <div v-if="editingNote" class="glass-card p-6">
        <h3 class="text-xl font-bold text-white mb-4 flex items-center">
          <Edit3 class="h-5 w-5 mr-2 text-cosmic-400" />
          Edit Note
        </h3>
        
        <div class="space-y-4">
          <input
            type="text"
            v-model="editingNote.title"
            class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all"
          />
          
          <textarea
            v-model="editingNote.content"
            rows="6"
            placeholder="Write your content... (Markdown supported)"
            class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-cosmic-400 focus:border-cosmic-500 focus:ring-2 focus:ring-cosmic-500/20 transition-all resize-none"
          ></textarea>
          
          <div class="flex gap-3">
            <button
              @click="updateNote" 
              class="cosmic-button"
            >
              Save Changes
            </button>
            <button
              @click="editingNote = null"
              class="px-4 py-2 text-cosmic-300 hover:text-white transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <div v-if="loading" class="flex items-center justify-center py-20">
      <div class="w-8 h-8 border-2 border-cosmic-500 border-t-transparent rounded-full animate-spin"></div>
    </div>

    <div v-else-if="!authStore.isAuthenticated" class="text-center py-20">
      <BookOpen class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h2 class="text-2xl font-bold text-white mb-4">Sign in to access your notes</h2>
      <p class="text-cosmic-300">Create an account to start taking AI-powered notes</p>
    </div>

    <div v-else-if="filteredNotes.length === 0" class="text-center py-20">
      <FileText class="h-16 w-16 text-cosmic-400 mx-auto mb-4" />
      <h3 class="text-xl font-bold text-white mb-2">
        {{ searchTerm ? 'No notes found' : 'No notes yet' }}
      </h3>
      <p class="text-cosmic-300">
        {{ searchTerm ? 'Try a different search term' : 'Create your first note to get started' }}
      </p>
    </div>

    <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="note in filteredNotes" 
        :key="note.id"
        class="glass-card p-6 hover:border-cosmic-400/50 transition-all duration-300 group cursor-pointer"
        @click="viewingNote = note"
      >
        <div class="flex items-start justify-between mb-4">
          <h3 class="font-bold text-white group-hover:text-glow transition-all line-clamp-2">
            {{ note.title }}
          </h3>
          <div class="flex items-center space-x-1">
            <button
              @click.stop="toggleFavorite(note)"
              :class="[
                'p-1 rounded transition-colors',
                note.is_favorite 
                  ? 'text-star-400' 
                  : 'text-cosmic-400 hover:text-star-400'
              ]"
            >
              <Star :class="['h-4 w-4', note.is_favorite ? 'fill-current' : '']" />
            </button>
            <div class="opacity-0 group-hover:opacity-100 transition-opacity">
              <Eye class="h-4 w-4 text-cosmic-400" />
            </div>
          </div>
        </div>
        
        <p class="text-cosmic-300 text-sm mb-4 line-clamp-3">
          {{ note.content || 'No content yet...' }}
        </p>
        
        <div class="relative">
          <div class="flex items-center justify-between text-xs text-cosmic-400">
            <span>
              {{ new Date(note.updated_at).toLocaleDateString() }}
            </span>
            <div class="flex items-center space-x-2">
              <button
                @click.stop="editingNote = {...note}"
                class="p-1 hover:text-cosmic-300 transition-colors"
              >
                <Edit3 class="h-4 w-4" />
              </button>
              <button
                @click.stop="confirmDeleteNote(note.id)"
                class="p-1 hover:text-red-400 transition-colors"
              >
                <Trash2 class="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Note Viewing Modal -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="viewingNote" class="fixed inset-0 z-50 flex items-center justify-center p-4">
          <!-- Backdrop -->
          <div 
            class="absolute inset-0 bg-black/50 backdrop-blur-sm" 
            @click="viewingNote = null"
          ></div>

          <!-- Modal -->
          <div 
            class="relative w-full max-w-4xl max-h-[80vh] overflow-hidden"
            @click.stop
          >
            <div class="glass-card relative">
              <!-- Background effects -->
              <div class="absolute inset-0 bg-gradient-to-br from-cosmic-600/10 to-nebula-600/10"></div>
              <div class="absolute top-0 right-0 w-32 h-32 bg-cosmic-500/20 rounded-full blur-3xl"></div>
              <div class="absolute bottom-0 left-0 w-24 h-24 bg-nebula-500/20 rounded-full blur-2xl"></div>

              <div class="relative z-10">
                <!-- Header -->
                <div class="flex items-center justify-between p-6 border-b border-white/10">
                  <div class="flex items-center space-x-3 flex-1 min-w-0">
                    <div class="p-2 bg-gradient-to-r from-cosmic-500 to-nebula-500 rounded-lg">
                      <FileText class="h-5 w-5 text-white" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <h2 class="text-xl font-bold text-glow truncate">
                        {{ viewingNote.title }}
                      </h2>
                      <p class="text-cosmic-300 text-sm">
                        {{ new Date(viewingNote.updated_at).toLocaleDateString() }} • 
                        {{ new Date(viewingNote.updated_at).toLocaleTimeString() }}
                      </p>
                    </div>
                  </div>
                  
                  <div class="flex items-center space-x-2">
                    <button
                      @click.stop="toggleFavorite(viewingNote)"
                      :class="[
                        'p-2 rounded-lg transition-colors',
                        viewingNote.is_favorite 
                          ? 'text-star-400 hover:text-star-300' 
                          : 'text-cosmic-400 hover:text-star-400'
                      ]"
                    >
                      <Star :class="['h-5 w-5', viewingNote.is_favorite ? 'fill-current' : '']" />
                    </button>
                    
                    <button
                      @click.stop="editingNote = {...viewingNote}; viewingNote = null"
                      class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                    >
                      <Edit3 class="h-5 w-5" />
                    </button>
                    
                    <button
                      @click="viewingNote = null"
                      class="p-2 text-cosmic-300 hover:text-white transition-colors rounded-lg hover:bg-white/10"
                    >
                      <X class="h-5 w-5" />
                    </button>
                  </div>
                </div>

                <!-- Content -->
                <div class="p-6 overflow-y-auto max-h-[60vh]">
                  <div v-if="viewingNote.content" class="prose prose-invert prose-cosmic max-w-none">
                    <VueMarkdown :source="viewingNote.content" />
                  </div>
                  <div v-else class="text-center py-12">
                    <FileText class="h-12 w-12 text-cosmic-400 mx-auto mb-4" />
                    <p class="text-cosmic-300">This note is empty</p>
                    <button
                      @click="editingNote = {...viewingNote}; viewingNote = null"
                      class="cosmic-button mt-4"
                    >
                      Add Content
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- AI Assistant -->
    <AIAssistant
      :isOpen="showAIAssistant"
      @close="showAIAssistant = false"
      :context="{
        currentPage: 'notes',
        selectedText: selectedText,
        recentActivity: []
      }"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import { 
  BookOpen, 
  Search, 
  FileText, 
  Edit3, 
  Trash2, 
  Star,
  Plus,
  Sparkles,
  Brain,
  X,
  Eye
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import AIAssistant from '@/components/AIAssistant.vue'

interface Note {
  id: string
  title: string
  content: string
  created_at: string
  updated_at: string
  is_favorite: boolean
}

// Composables
const toast = useToast()
const authStore = useAuthStore()

// State
const notes = ref<Note[]>([])
const loading = ref(true)
const searchTerm = ref('')
const isCreating = ref(false)
const editingNote = ref<Note | null>(null)
const viewingNote = ref<Note | null>(null)
const newNote = ref({ title: '', content: '' })
const selectedText = ref('')
const showAIAssistant = ref(false)
const selectionPosition = ref<{top: number, left: number} | null>(null)

// Computed
const filteredNotes = computed(() => {
  return notes.value.filter(note =>
    note.title.toLowerCase().includes(searchTerm.value.toLowerCase()) ||
    note.content.toLowerCase().includes(searchTerm.value.toLowerCase())
  )
})

// Lifecycle
onMounted(() => {
  if (authStore.isAuthenticated) {
    fetchNotes()
    document.addEventListener('mouseup', handleTextSelection)
    document.addEventListener('touchend', handleTextSelection)
  }
})

// Methods
const fetchNotes = async () => {
  try {
    const { data, error } = await supabase
      .from('notes')
      .select('*')
      .eq('user_id', authStore.user?.id)
      .order('updated_at', { ascending: false })

    if (error) throw error
    notes.value = data || []
  } catch (error) {
    console.error('Error fetching notes:', error)
    toast.error('Failed to fetch notes')
  } finally {
    loading.value = false
  }
}

const createNote = async () => {
  if (!newNote.value.title.trim()) {
    toast.error('Please enter a title')
    return
  }

  try {
    const { data, error } = await supabase
      .from('notes')
      .insert([
        {
          title: newNote.value.title,
          content: newNote.value.content,
          user_id: authStore.user?.id
        }
      ])
      .select()
      .single()

    if (error) throw error

    notes.value = [data, ...notes.value]
    newNote.value = { title: '', content: '' }
    isCreating.value = false
    toast.success('Note created successfully!')
    
    // Generate flashcards from the new note
    generateFlashcardsFromNote(data)
    
    // Award XP for creating a note
    authStore.addExperience(30, "Created New Note")
  } catch (error) {
    console.error('Error creating note:', error)
    toast.error('Failed to create note')
  }
}

const updateNote = async () => {
  if (!editingNote.value || !editingNote.value.title.trim()) return

  try {
    const { data, error } = await supabase
      .from('notes')
      .update({
        title: editingNote.value.title,
        content: editingNote.value.content,
        updated_at: new Date().toISOString()
      })
      .eq('id', editingNote.value.id)
      .select()
      .single()

    if (error) throw error

    notes.value = notes.value.map(note => note.id === editingNote.value?.id ? data : note)
    editingNote.value = null
    toast.success('Note updated successfully!')
    
    // Award XP for significant updates (if content length increased by at least 20%)
    const originalNote = notes.value.find(n => n.id === editingNote.value?.id)
    if (originalNote && data.content.length > originalNote.content.length * 1.2) {
      authStore.addExperience(15, "Expanded Note Content")
    }
  } catch (error) {
    console.error('Error updating note:', error)
    toast.error('Failed to update note') 
  }
}

const deleteNote = async (id: string) => {
  try {
    const { error } = await supabase
      .from('notes')
      .delete()
      .eq('id', id)

    if (error) throw error

    notes.value = notes.value.filter(note => note.id !== id)
    viewingNote.value = null
    toast.success('Note deleted successfully!')
  } catch (error) {
    console.error('Error deleting note:', error)
    toast.error('Failed to delete note')
  }
}

const confirmDeleteNote = (id: string) => {
  if (confirm('Are you sure you want to delete this note?')) {
    deleteNote(id)
  }
}

const toggleFavorite = async (note: Note) => {
  try {
    const { data, error } = await supabase
      .from('notes')
      .update({ is_favorite: !note.is_favorite })
      .eq('id', note.id)
      .select()
      .single()

    if (error) throw error

    notes.value = notes.value.map(n => n.id === note.id ? data : n)
    if (viewingNote.value && viewingNote.value.id === note.id) {
      viewingNote.value = data
    }
  } catch (error) {
    console.error('Error toggling favorite:', error)
    toast.error('Failed to update favorite')
  }
}

const generateFlashcardsFromNote = async (note: Note) => {
  try {
    // Call the RPC function to generate flashcards
    const { data, error } = await supabase.rpc(
      'generate_flashcards_from_text',
      {
        input_text: note.content,
        user_id: authStore.user?.id,
        source_note_id: note.id
      }
    )
    
    if (error) throw error
    
    // Award XP for flashcard generation if successful
    if (data && data.length > 0) {
      authStore.addExperience(20, `Generated ${data.length} Flashcards`)
      toast.success(`Generated ${data.length} flashcards from your note!`)
    }
  } catch (error) {
    console.error('Failed to generate flashcards:', error)
  }
}

const handleTextSelection = () => {
  const selection = window.getSelection()
  if (selection && selection.toString().trim().length > 0) {
    selectedText.value = selection.toString().trim()
    
    // Calculate position for the popup
    const range = selection.getRangeAt(0)
    const rect = range.getBoundingClientRect()
    
    selectionPosition.value = {
      top: rect.bottom + window.scrollY,
      left: rect.left + window.scrollX
    }
  } else {
    selectedText.value = ''
    selectionPosition.value = null
  }
}

</script>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>