#!/usr/bin/env node

import { svelte } from '@sveltejs/vite-plugin-svelte'
import { dirname, resolve } from 'path'
import { fileURLToPath } from 'url'
import { build } from 'vite'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const componentName = process.argv[2]

if (!componentName) {
  console.error('Usage: node build-component.js <component-name>')
  process.exit(1)
}

const componentPath = resolve(__dirname, 'components', componentName)
const outputPath = resolve(__dirname, 'dist', `${componentName}.js`)

console.log(`Building component: ${componentName}`)
console.log(`Input: ${componentPath}`)
console.log(`Output: ${outputPath}`)

try {
  await build({
    configFile: false, // Don't use vite.config.js
    plugins: [
      svelte({
        compilerOptions: {
          runes: true
        }
      })
    ],
    build: {
      target: 'esnext',
      lib: {
        entry: resolve(componentPath, 'index.svelte'),
        name: componentName.charAt(0).toUpperCase() + componentName.slice(1),
        fileName: componentName
      },
      outDir: resolve(__dirname, 'dist', componentName),
      rollupOptions: {
        external: ['svelte', 'three', '@threlte/core', '@threlte/extras'],
        output: {
          globals: { 
            svelte: 'Svelte',
            three: 'THREE',
            '@threlte/core': 'ThrelteCore',
            '@threlte/extras': 'ThrelteExtras'
          },
          entryFileNames: `${componentName}.js`
        }
      }
    }
  })

  console.log(`✅ Successfully built ${componentName}`)
} catch (error) {
  console.error(`❌ Failed to build ${componentName}:`, error)
  process.exit(1)
}
