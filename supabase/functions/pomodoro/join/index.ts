import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS"
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

    // Parse the URL to get the roomId
    const url = new URL(req.url);
    const path = url.pathname.split("/").filter(segment => segment);
    const roomId = path[1]; // Expecting /pomodoro/{roomId}/join
    
    // Handle JSON request body
    const requestData = req.method === 'POST' ? await req.json() : {};
    
    if (!roomId) {
      return new Response(
        JSON.stringify({ error: "Room ID is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if the room exists
    const { data: room, error: roomError } = await supabaseClient
      .from("pomodoro_rooms")
      .select("*")
      .eq("id", roomId)
      .single();
      
    if (roomError || !room) {
      return new Response(
        JSON.stringify({ error: "Room not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    
    // Try both methods to ensure profile exists
    try {
      // Direct check using service role
      const { data: profileCheck } = await supabaseClient
        .from('user_profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
      
      if (!profileCheck) {
        // Try to create profile with RPC
        await supabaseClient.rpc(
          'create_user_profile_safe',
          { 
            user_id: user.id, 
            username: user.user_metadata?.username || 'User'
          }
        );
      }
    } catch (profileError) {
      // Log but continue - not critical for join operation
      console.warn('Profile check/create error:', profileError);
    }

    // Check if user is already a participant
    const { data: existingParticipant, error: participantError } = await supabaseClient
      .from("room_participants")
      .select("*")
      .eq("room_id", roomId)
      .eq("user_id", user.id)
      .maybeSingle();

    // If already a participant, just return success
    if (existingParticipant) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "Already a participant", 
          alreadyJoined: true 
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    
    // If not a participant and room is full, return error
    if (room.current_participants >= room.max_participants) {
      return new Response(
        JSON.stringify({ error: "Room is full" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    
    // Join as new participant
    const { data, error } = await supabaseClient
      .from("room_participants")
      .insert([{
        room_id: roomId,
        user_id: user.id,
        is_admin: false
      }])
      .select()
      .single();
      
    if (error) {
      console.error("Error joining room:", error);
      return new Response(
        JSON.stringify({ error: "Failed to join room" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    
    // Return success
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Successfully joined room",
        participant: data
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Join Room Error:", error.message);
    
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