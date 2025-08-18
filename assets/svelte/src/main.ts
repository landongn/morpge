// Main entry point for Svelte components
export { default as ThreeDCube } from '../components/3d-cube/index.svelte';
export { default as Counter } from '../components/counter/index.svelte';
export { default as HelloWorld } from '../components/hello-world/index.svelte';
export { default as WorldScene } from '../components/world-scene/index.svelte';

// Re-export types for external use
export type { ComponentProps } from './component-types';
export type { EntityData, GeometryData, WorldData } from './types';

