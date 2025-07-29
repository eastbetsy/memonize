/*
  # Add AI Flashcard Features

  1. New Columns for Flashcards
    - `content_source` (text, content type that generated this flashcard)
    - `source_file_url` (text, optional URL to stored media file)
    - `ocr_confidence` (real, confidence score for OCR/transcription)
    - `ai_generated` (boolean, whether the flashcard was AI-generated)
    - `media_timestamp` (integer, for video/audio position references)
  
  2. New Function 
    - Create `generate_flashcards_from_text` function
*/

-- Add new columns to flashcards table for AI features
DO $$
BEGIN
  -- Add content_source column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'content_source') THEN
    ALTER TABLE flashcards ADD COLUMN content_source text;
  END IF;
  
  -- Add source_file_url column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'source_file_url') THEN
    ALTER TABLE flashcards ADD COLUMN source_file_url text;
  END IF;
  
  -- Add ocr_confidence column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'ocr_confidence') THEN
    ALTER TABLE flashcards ADD COLUMN ocr_confidence real;
  END IF;
  
  -- Add ai_generated column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'ai_generated') THEN
    ALTER TABLE flashcards ADD COLUMN ai_generated boolean DEFAULT false;
  END IF;
  
  -- Add media_timestamp column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'flashcards' AND column_name = 'media_timestamp') THEN
    ALTER TABLE flashcards ADD COLUMN media_timestamp integer;
  END IF;
END $$;

-- Create a function to generate flashcards from text
CREATE OR REPLACE FUNCTION generate_flashcards_from_text(
  input_text text,
  user_id uuid,
  source_note_id uuid DEFAULT NULL,
  content_source text DEFAULT 'text'
)
RETURNS SETOF flashcards AS $$
DECLARE
  flashcard_record flashcards;
  paragraph_text text;
  term_text text;
  definition_text text;
  sentences text[];
  i integer;
  card_count integer := 0;
  difficulty text;
BEGIN
  -- Split into paragraphs
  FOR paragraph_text IN 
    SELECT regexp_split_to_table(input_text, E'\\n\\n+')
  LOOP
    -- Skip short paragraphs
    IF length(paragraph_text) < 20 THEN
      CONTINUE;
    END IF;
    
    -- Split paragraph into sentences
    sentences := regexp_split_to_array(paragraph_text, E'\\. ');
    
    -- Skip paragraphs with too few sentences
    IF array_length(sentences, 1) < 2 THEN
      CONTINUE;
    END IF;
    
    -- Set term as first sentence or "What is..." question
    term_text := 'What is ' || regexp_replace(sentences[1], '(^|\s)[A-Z]\w+', '\1', 'g') || '?';
    
    -- Combine remaining sentences for definition
    definition_text := '';
    FOR i IN 2..array_length(sentences, 1) LOOP
      definition_text := definition_text || sentences[i];
      IF i < array_length(sentences, 1) THEN
        definition_text := definition_text || '. ';
      END IF;
    END LOOP;
    
    -- Determine difficulty based on definition length and complexity
    IF length(definition_text) < 100 THEN
      difficulty := 'easy';
    ELSIF length(definition_text) > 300 THEN
      difficulty := 'hard';
    ELSE
      difficulty := 'medium';
    END IF;
    
    -- Create flashcard record
    flashcard_record := (
      gen_random_uuid(),  -- id
      user_id,            -- user_id
      term_text,          -- term
      definition_text,    -- definition
      difficulty,         -- difficulty
      1,                  -- confidence_level
      source_note_id,     -- source_note_id
      NULL,               -- last_reviewed
      0,                  -- review_count
      now(),              -- created_at
      2.5,                -- ease_factor
      1,                  -- interval_days
      CURRENT_DATE,       -- next_review_date
      'new',              -- learning_state
      content_source,     -- content_source
      NULL,               -- source_file_url
      NULL,               -- ocr_confidence
      true,               -- ai_generated
      NULL                -- media_timestamp
    );
    
    -- Return the flashcard
    RETURN NEXT flashcard_record;
    
    -- Limit to 10 cards per text
    card_count := card_count + 1;
    IF card_count >= 10 THEN
      EXIT;
    END IF;
  END LOOP;
  
  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission to authenticated users
GRANT EXECUTE ON FUNCTION generate_flashcards_from_text(text, uuid, uuid, text) TO authenticated;

-- Create index on ai_generated for filtering
CREATE INDEX IF NOT EXISTS flashcards_ai_generated_idx ON flashcards(ai_generated);