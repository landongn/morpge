// Component prop types and utilities
import type {
  CounterProps,
  HelloWorldProps,
  ThreeDCubeProps,
  WorldSceneProps
} from './types';

export type ComponentProps = 
  | HelloWorldProps 
  | CounterProps 
  | ThreeDCubeProps 
  | WorldSceneProps

export type ComponentType = 
  | 'hello-world'
  | 'counter'
  | '3d-cube'
  | 'world-scene'

// Component registry types
export interface ComponentDefinition {
  type: ComponentType
  name: string
  description: string
  props: Record<string, {
    type: 'string' | 'number' | 'boolean' | 'object'
    default: any
    required: boolean
    description: string
  }>
}

export interface ComponentInstance {
  id: string
  type: ComponentType
  props: ComponentProps
  createdAt: Date
  status: 'loading' | 'ready' | 'error'
}

// Build system types
export interface BuildResult {
  success: boolean
  componentName: string
  outputPath: string
  errors: string[]
  warnings: string[]
  buildTime: number
}

export interface ComponentWatcher {
  componentPath: string
  onChange: (event: 'add' | 'change' | 'unlink') => void
}
