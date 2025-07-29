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
    // Initialize Supabase client with anon key for auth validation
    const supabaseAuth = createClient(
      Deno.env.get("SUPABASE_URL") || "",
      Deno.env.get("SUPABASE_ANON_KEY") || ""
    );

    // Initialize Supabase client with service role key for database operations
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
    
    // Get the user from the token using anon key client
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
    const roomId = path[1]; // Expecting /pomodoro/{roomId}
    
    // Ensure user profile exists
    await ensureUserProfile(supabaseClient, user.id, user.user_metadata?.username || 'User');
    
    // If we have a room ID, get the details
    if (roomId) {
      // Get room details with relationships
      const { data: room, error: roomError } = await supabaseClient
        .from("pomodoro_rooms")
        .select(`
          *,
          owner:user_profiles(username),
          participants:room_participants(
            id,
            user_id,
            joined_at,
            is_admin,
            is_muted,
            focus_score,
            user:user_id(username, level)
          )
        `)
        .eq("id", roomId)
        .single();
        
      if (roomError) {
        console.error("Error fetching room:", roomError);
        return new Response(
          JSON.stringify({ error: "Failed to load room details", errorDetails: roomError.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      
      return new Response(
        JSON.stringify({ success: true, room }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      // Get all rooms
      const { data: rooms, error: roomsError } = await supabaseClient
        .from("pomodoro_rooms")
        .select("*, owner:user_profiles(username)")
        .order("created_at", { ascending: false });
        
      if (roomsError) {
        console.error("Error fetching rooms:", roomsError);
        return new Response(
          JSON.stringify({ error: "Failed to load rooms", errorDetails: roomsError.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      
      // Get participant counts for each room
      const roomsWithCounts = await Promise.all(rooms.map(async (room) => {
        const { count } = await supabaseClient
          .from("room_participants")
          .select("*", { count: "exact", head: true })
          .eq("room_id", room.id);
        
        return {
          ...room,
          participantCount: count || 0
        };
      }));
      
      return new Response(
        JSON.stringify({ success: true, rooms: roomsWithCounts }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("Pomodoro Function Error:", error.message);
    
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

// Helper function to ensure user profile exists
async function ensureUserProfile(supabase, userId, username) {
  try {
    // Check if profile exists
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('id', userId)
      .single();
    
    if (!profile) {
      // Create user profile
      await supabase.rpc('create_user_profile_safe', {
        user_id: userId,
        username: username
      });
    }
    
    return true;
  } catch (error) {
    console.error('Error ensuring user profile exists:', error);
    return false;
  }
}