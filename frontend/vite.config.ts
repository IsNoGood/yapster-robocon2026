import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import type { ViteDevServer } from 'vite'
import type { IncomingMessage, ServerResponse } from 'http'

const healthPlugin = () => {
  return {
    name: 'health-endpoint',
    configureServer(server: ViteDevServer) {
      server.middlewares.use('/health', (_req: IncomingMessage, res: ServerResponse) => {
        res.setHeader('Content-Type', 'text/plain')
        res.end('Hello From Frontend: ok')
      })
    }
  }
}

export default defineConfig({
  plugins: [react(), healthPlugin()],
  server: {
    port: 5173,
    strictPort: true,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      },
      '/health-backend': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        rewrite: () => '/health'
      }
    }
  }
})
