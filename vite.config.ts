import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    },
  },
  server: {
    port: 5173,
    host: true,
    proxy: {
      // Add proxy for Supabase Edge Functions
      '/api': {
        target: process.env.SUPABASE_API_URL || 'https://gdzwtrtepvyhhqbcbxbd.supabase.co',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
        secure: false
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
})