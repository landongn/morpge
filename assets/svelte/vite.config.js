import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vite'
import dts from 'vite-plugin-dts'

export default defineConfig({
  plugins: [
    svelte({
      compilerOptions: {
        runes: true
      }
    }),
    dts({
      insertTypesEntry: true,
      rollupTypes: true
    })
  ],
  build: {
    target: 'esnext',
    lib: {
      entry: './src/main.ts',
      name: 'MoreSvelteComponents',
      fileName: 'more-svelte'
    },
    rollupOptions: {
      external: ['svelte', '@threlte/core', '@threlte/extras', 'three'],
      output: {
        globals: { 
          svelte: 'Svelte',
          '@threlte/core': 'ThrelteCore',
          '@threlte/extras': 'ThrelteExtras',
          three: 'THREE'
        }
      }
    }
  },
  resolve: {
    alias: {
      '@': '/src'
    }
  }
})
