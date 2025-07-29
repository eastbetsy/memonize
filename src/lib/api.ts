import axios from 'axios';
import { supabase } from './supabase';
const isSupabaseFunction = (url: string): boolean => url.includes('/functions/v1/');

// Base URL - will be determined based on environment
const BASE_API_URL = import.meta.env.VITE_SUPABASE_URL || '';

// Create an axios instance for API calls
const api = axios.create({
  baseURL: BASE_API_URL,
  headers: {
    'Content-Type': 'application/json',
  }
});

// Add authentication interceptor
api.interceptors.request.use(async (config) => {
  try {
    const { data } = await supabase.auth.getSession();
    
    if (data.session?.access_token) {
      config.headers.Authorization = `Bearer ${data.session.access_token}`;
    }
    
    // Special handling for Supabase Functions
    if (isSupabaseFunction(config.url || '')) {
      // Ensure the URL is properly formatted for Supabase Functions
      if (!config.url?.startsWith('/functions/v1/')) {
        config.url = `/functions/v1/${config.url?.replace(/^\//, '')}`;
      }
    }
  } catch (error) {
    console.error('Auth session error in API interceptor:', error);
  }
  
  return config;
});

// XP API
export const xpApi = {
  awardXp: async (amount: number, action: string) => {
    try {
      // Get current session token
      const { data } = await supabase.auth.getSession();
      const token = data.session?.access_token;
      
      if (!token) {
        throw new Error('No authentication token available');
      }

      // Call the Supabase Edge Function
      const functionsUrl = `${BASE_API_URL}/functions/v1/xp`;
      const response = await fetch(functionsUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ amount, action })
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to award XP');
      }
      
      return await response.json();
    } catch (error) {
      console.error('XP API error:', error);
      throw error;
    }
  }
};

// Legacy API implementations that should be migrated to Supabase Functions
export const legacyApi = {
  // Notes API (to be migrated)
  notesApi: {
    getAll: async () => {
      const { data, error } = await supabase
        .from('notes')
        .select('*')
        .order('updated_at', { ascending: false });

      if (error) throw error;
      return data;
    },
    
    getById: async (id: string) => {
      const { data, error } = await supabase
        .from('notes')
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;
      return data;
    },
    
    create: async (noteData: { title: string; content: string; is_favorite?: boolean }) => {
      const { data, error } = await supabase
        .from('notes')
        .insert([{...noteData, user_id: (await supabase.auth.getUser()).data.user?.id}])
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    
    update: async (id: string, noteData: { title: string; content: string; is_favorite?: boolean }) => {
      const { data, error } = await supabase
        .from('notes')
        .update(noteData)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    
    delete: async (id: string) => {
      const { error } = await supabase
        .from('notes')
        .delete()
        .eq('id', id);

      if (error) throw error;
      return { message: "Note deleted successfully" };
    },
    
    generateFlashcards: async (noteId: string) => {
      const { data, error } = await supabase.rpc(
        'generate_flashcards_from_text',
        { 
          input_text: "",  // Will be extracted from the note
          user_id: (await supabase.auth.getUser()).data.user?.id,
          source_note_id: noteId 
        }
      );

      if (error) throw error;
      return { message: `Generated ${data?.length || 0} flashcards`, flashcards: data };
    }
  },
  
  // Flashcards API (to be migrated)
  flashcardsApi: {
    getAll: async () => {
      const { data, error } = await supabase
        .from('flashcards')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data;
    },
    
    create: async (flashcardData: { 
      term: string; 
      definition: string; 
      difficulty: string;
      confidence_level?: number;
      source_note_id?: string;
    }) => {
      const { data, error } = await supabase
        .from('flashcards')
        .insert([{...flashcardData, user_id: (await supabase.auth.getUser()).data.user?.id}])
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    
    update: async (id: string, flashcardData: {
      term: string; 
      definition: string; 
      difficulty: string;
      confidence_level?: number;
      source_note_id?: string;
    }) => {
      const { data, error } = await supabase
        .from('flashcards')
        .update(flashcardData)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    
    delete: async (id: string) => {
      const { error } = await supabase
        .from('flashcards')
        .delete()
        .eq('id', id);

      if (error) throw error;
      return { message: "Flashcard deleted successfully" };
    }
  }
};

// For backward compatibility
export const notesApi = legacyApi.notesApi;
export const flashcardsApi = legacyApi.flashcardsApi;

export const awardXp = async (amount: number, action: string) => {
  try {
    const response = await xpApi.awardXp(amount, action);
    return response;
  } catch (error) {
    console.error('Error awarding XP:', error);
    throw error;
  }
};

export default api;

// API utilities
export function getSupabaseHeaders() {
  return supabase.auth.getSession().then(res => ({
    'Authorization': `Bearer ${res.data.session?.access_token || ''}`,
    'Content-Type': 'application/json'
  }));
}

export async function callFunction(functionName: string, data: any) {
  const { data: session } = await supabase.auth.getSession();
  const token = session.session?.access_token;

  if (!token) {
    throw new Error('No authentication token available');
  }

  // Form the URL properly
  let url = functionName;
  if (!url.startsWith('/functions/v1/') && !url.startsWith('functions/v1/')) {
    url = `functions/v1/${url}`;
  }
  
  if (!url.startsWith('/')) {
    url = `/${url}`;
  }

  const functionsUrl = `${BASE_API_URL}${url}`;
  
  // Determine request method and prepare request options
  const method = data ? 'POST' : 'GET';
  const requestInit: RequestInit = {
    method,
    headers: {
      'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     }
  };
  
  // Add body for POST requests
  if (method === 'POST' && data) {
    requestInit.body = JSON.stringify(data);
  }
  
  // Add body for POST requests
  if (method === 'POST' && data) {
    requestInit.body = JSON.stringify(data);
  }
  
  // Make the request
  const response = await fetch(functionsUrl, requestInit);

  if (!response.ok) {
    let errorMessage = `Failed to call function: ${functionName}`;
    try {
      const errorData = await response.json();
      errorMessage = errorData.error || errorMessage;
    } catch (e) {
      // If we can't parse JSON, use the status text
      errorMessage = response.statusText || errorMessage;
    }
    throw new Error(errorMessage);
  }

  return await response.json();
}

// For decks and pomodoro rooms
export const deckApi = {
  getDecks: async () => {
    return callFunction('deck', null);
  },
  
  getDeck: async (deckId: string) => {
    return callFunction(`deck/${deckId}`, null);
  },
  
  joinDeck: async (deckId: string) => {
    return callFunction(`deck/${deckId}/join`, null);
  }
};

export const pomodoroApi = {
  getRooms: async () => {
    return callFunction('pomodoro', null);
  },
  
  getRoom: async (roomId: string) => {
    return callFunction(`pomodoro/${roomId}`, null);
  },
  
  joinRoom: async (roomId: string): Promise<{ success: boolean; error?: string }> => {
    try {
      // Get the token for authorization
      const { data: sessionData } = await supabase.auth.getSession();
      const token = sessionData.session?.access_token;
      
      if (!token) {
        throw new Error('Not authenticated');
      }
      
      // Call the function to join the room
      const response = await fetch(`${BASE_API_URL}/functions/v1/pomodoro/${roomId}/join`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ join: true })
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to join room');
      }
      
      const data = await response.json();
      return { success: true, ...data };
    } catch (error) {
      console.error('Error joining room:', error);
      return { success: false, error: error.message };
    }
  }
};