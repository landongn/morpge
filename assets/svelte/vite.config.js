import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [svelte()],
  build: {
    lib: {
      entry: './src/main.js',
      name: 'MoreSvelteComponents',
      fileName: 'more-svelte'
    },
    rollupOptions: {
      external: ['svelte'],
      output: {
        globals: { svelte: 'Svelte' }
      }
    }
  }
})
