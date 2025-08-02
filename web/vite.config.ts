import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react({
      // Optimize React rendering
      fastRefresh: true,
    }),
  ],
  base: './',
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    // Optimize build performance
    target: 'esnext',
    minify: 'esbuild',
    cssMinify: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          mantine: ['@mantine/core', '@mantine/hooks', '@mantine/notifications', '@mantine/form'],
          icons: ['@tabler/icons-react'],
          animation: ['framer-motion']
        }
      }
    },
    // Enable compression and optimization
    assetsInlineLimit: 4096,
    chunkSizeWarningLimit: 1000,
  },
  server: {
    port: 3000,
    host: true,
    hmr: {
      overlay: false, // Better performance in dev
    },
  },
  // Enable esbuild optimization
  esbuild: {
    drop: process.env.NODE_ENV === 'production' ? ['console', 'debugger'] : [],
  },
})