import { defineStore } from 'pinia';
import { ref } from 'vue';
import { useToast } from 'vue-toastification';
import { flashcardsApi } from '@/lib/api';

interface Flashcard {
  id: string;
  term: string;
  definition: string;
  difficulty: 'easy' | 'medium' | 'hard';
  confidence_level: number;
  source_note_id?: string;
  last_reviewed?: string;
  review_count: number;
  created_at: string;
  ai_generated?: boolean;
  content_source?: string;
}

export const useFlashcardsStore = defineStore('flashcards', () => {
  // State
  const flashcards = ref<Flashcard[]>([]);
  const loading = ref(false);
  const toast = useToast();

  // Actions
  const fetchFlashcards = async () => {
    loading.value = true;
    try {
      const data = await flashcardsApi.getAll();
      flashcards.value = data;
    } catch (error: any) {
      console.error('Error fetching flashcards:', error);
      toast.error(error.message || 'Failed to fetch flashcards');
    } finally {
      loading.value = false;
    }
  };

  const createFlashcard = async (flashcardData: {
    term: string;
    definition: string;
    difficulty: string;
    confidence_level?: number;
    source_note_id?: string;
  }) => {
    loading.value = true;
    try {
      const newFlashcard = await flashcardsApi.create(flashcardData);
      flashcards.value = [newFlashcard, ...flashcards.value];
      toast.success('Flashcard created successfully!');
      return newFlashcard;
    } catch (error: any) {
      console.error('Error creating flashcard:', error);
      toast.error(error.message || 'Failed to create flashcard');
      throw error;
    } finally {
      loading.value = false;
    }
  };

  const updateFlashcard = async (id: string, flashcardData: {
    term: string;
    definition: string;
    difficulty: string;
    confidence_level?: number;
    source_note_id?: string;
  }) => {
    loading.value = true;
    try {
      const updatedFlashcard = await flashcardsApi.update(id, flashcardData);
      flashcards.value = flashcards.value.map(flashcard => 
        flashcard.id === id ? updatedFlashcard : flashcard
      );
      toast.success('Flashcard updated successfully!');
      return updatedFlashcard;
    } catch (error: any) {
      console.error('Error updating flashcard:', error);
      toast.error(error.message || 'Failed to update flashcard');
      throw error;
    } finally {
      loading.value = false;
    }
  };

  const deleteFlashcard = async (id: string) => {
    loading.value = true;
    try {
      await flashcardsApi.delete(id);
      flashcards.value = flashcards.value.filter(flashcard => flashcard.id !== id);
      toast.success('Flashcard deleted successfully!');
    } catch (error: any) {
      console.error('Error deleting flashcard:', error);
      toast.error(error.message || 'Failed to delete flashcard');
      throw error;
    } finally {
      loading.value = false;
    }
  };

  return {
    flashcards,
    loading,
    fetchFlashcards,
    createFlashcard,
    updateFlashcard,
    deleteFlashcard
  };
});