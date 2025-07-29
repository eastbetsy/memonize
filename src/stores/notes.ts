import { defineStore } from 'pinia';
import { ref } from 'vue';
import { useToast } from 'vue-toastification';
import { notesApi } from '@/lib/api';

interface Note {
  id: string;
  title: string;
  content: string;
  is_favorite: boolean;
  created_at: string;
  updated_at: string;
  ai_summary?: string;
  key_concepts?: string[];
}

export const useNotesStore = defineStore('notes', () => {
  // State
  const notes = ref<Note[]>([]);
  const loading = ref(false);
  const toast = useToast();

  // Actions
  const fetchNotes = async () => {
    loading.value = true;
    try {
      const data = await notesApi.getAll();
      notes.value = data;
    } catch (error: any) {
      console.error('Error fetching notes:', error);
      toast.error(error.message || 'Failed to fetch notes');
    } finally {
      loading.value = false;
    }
  };

  const createNote = async (noteData: { title: string; content: string; is_favorite?: boolean }) => {
    loading.value = true;
    try {
      const newNote = await notesApi.create(noteData);
      notes.value = [newNote, ...notes.value];
      toast.success('Note created successfully!');
      return newNote;
    } catch (error: any) {
      console.error('Error creating note:', error);
      toast.error(error.message || 'Failed to create note');
      throw error;
    } finally {
      loading.value = false;
    }
  };

  const updateNote = async (id: string, noteData: { title: string; content: string; is_favorite?: boolean }) => {
    loading.value = true;
    try {
      const updatedNote = await notesApi.update(id, noteData);
      notes.value = notes.value.map(note => 
        note.id === id ? updatedNote : note
      );
      toast.success('Note updated successfully!');
      return updatedNote;
    } catch (error: any) {
      console.error('Error updating note:', error);
      toast.error(error.message || 'Failed to update note');
      throw error;
    } finally {
      loading.value = false;
    }
  };

  const deleteNote = async (id: string) => {
    loading.value = true;
    try {
      await notesApi.delete(id);
      notes.value = notes.value.filter(note => note.id !== id);
      toast.success('Note deleted successfully!');
    } catch (error: any) {
      console.error('Error deleting note:', error);
      toast.error(error.message || 'Failed to delete note');
      throw error;
    } finally {
      loading.value = false;
    }
  };

  const generateFlashcards = async (noteId: string) => {
    loading.value = true;
    try {
      const result = await notesApi.generateFlashcards(noteId);
      toast.success(`Generated ${result.flashcards?.length || 0} flashcards`);
      return result;
    } catch (error: any) {
      console.error('Error generating flashcards:', error);
      toast.error(error.message || 'Failed to generate flashcards');
      throw error;
    } finally {
      loading.value = false;
    }
  };

  return {
    notes,
    loading,
    fetchNotes,
    createNote,
    updateNote,
    deleteNote,
    generateFlashcards
  };
});