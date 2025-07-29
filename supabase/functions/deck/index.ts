import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS"
};

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders,
      status: 200
    });
  }

  try {
    // Initialize Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") || "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
    );

    // Get auth token from request header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    
    // Get the user from the token
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
    
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token or user not found" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse the URL to get the path
    const url = new URL(req.url);
    const path = url.pathname.split("/").filter(segment => segment);
    const deckId = path[1]; // Expecting /deck/{deckId}
    
    // If we have a deck ID, get the details
    if (deckId) {
      try {
        // Get deck details with relationships
        const { data: deck, error: deckError } = await supabaseClient
          .from("decks")
          .select(`
            *,
            owner:user_profiles!decks_owner_profile_fkey(username),
            members:deck_members(
              id,
              user_id,
              role,
              joined_at,
              user:user_profiles!deck_members_user_profile_fkey(username)
            ),
            events:deck_events(
              id,
              title,
              description,
              start_time,
              end_time,
              location,
              is_recurring,
              recurrence_rule
            ),
            assignments:deck_assignments(
              id, 
              title,
              description,
              due_date,
              status,
              points
            )
          `)
          .eq("id", deckId)
          .single();
          
        if (deckError) {
          throw new Error(`Failed to load deck details: ${deckError.message}`);
        }
        
        // Check if the user is authorized to view this deck
        const isOwner = deck?.owner_id === user.id;
        const isMember = deck?.members?.some(m => m.user_id === user.id);
        
        if (!isOwner && !isMember) {
          return new Response(
            JSON.stringify({ error: "You don't have access to this deck", success: false }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
        
        return new Response(
          JSON.stringify({ success: true, deck }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      } catch (error) {
        console.error("Error fetching deck:", error);
        return new Response(
          JSON.stringify({ error: "Failed to load deck details", errorDetails: error.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } else {
      try {
        // Get decks the user owns
        const { data: ownedDecks, error: ownedDecksError } = await supabaseClient
          .from("decks")
          .select("*, owner:user_profiles!decks_owner_profile_fkey(username)")
          .eq("owner_id", user.id)
          .order("created_at", { ascending: false });
        
        if (ownedDecksError) throw ownedDecksError;
        
        // Get decks the user is a member of
        const { data: memberDecks, error: memberDecksError } = await supabaseClient
          .from("deck_members")
          .select(`
            deck:deck_id(
              id, 
              name, 
              description,
              banner_url,
              color,
              owner_id,
              enrollment_code,
              is_archived,
              created_at,
              updated_at,
              owner:user_profiles!decks_owner_profile_fkey(username)
            )
          `)
          .eq("user_id", user.id)
          .order("joined_at", { ascending: false });
        
        if (memberDecksError) throw memberDecksError;
        
        // Format the member decks to match the structure of owned decks
        const formattedMemberDecks = memberDecks
          ?.map(md => md.deck)
          .filter(deck => deck && deck.id !== null && !ownedDecks?.some(od => od.id === deck.id)) || [];
        
        // Combine and return all decks
        const allDecks = [...(ownedDecks || []), ...formattedMemberDecks];
        
        return new Response(
          JSON.stringify({ success: true, decks: allDecks }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      } catch (error) {
        console.error("Error fetching decks:", error);
        return new Response(
          JSON.stringify({ error: "Failed to load decks", errorDetails: error.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }
  } catch (error) {
    console.error("Deck Function Error:", error.message);
    
    return new Response(
      JSON.stringify({ 
        error: error.message || "An unexpected error occurred",
        success: false 
      }),
      { 
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500
      }
    );
  }
});