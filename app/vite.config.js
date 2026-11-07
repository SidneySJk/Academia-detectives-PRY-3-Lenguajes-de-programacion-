import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Las peticiones a /api se reenvian al puente Express (server/index.js).
    proxy: {
      '/api': 'http://127.0.0.1:3001',
    },
  },
})
