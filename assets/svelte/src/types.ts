// Core world and entity types
export interface Vector3 {
  x: number
  y: number
  z: number
}

export interface Quaternion {
  x: number
  y: number
  z: number
  w: number
}

export interface Transform {
  position: Vector3
  rotation: Quaternion
  scale: Vector3
}

export interface GeometryData {
  type: 'box' | 'capsule' | 'sphere' | 'cylinder' | 'plane'
  dimensions: Vector3
  material: MaterialData
}

export interface MaterialData {
  type: 'basic' | 'phong' | 'standard' | 'pbr'
  color: string | number
  opacity?: number
  transparent?: boolean
  wireframe?: boolean
  roughness?: number
  metalness?: number
}

export interface EntityData {
  id: string
  name: string
  type: 'player' | 'npc' | 'item' | 'terrain' | 'structure'
  transform: Transform
  geometry: GeometryData
  metadata?: Record<string, any>
}

export interface WorldData {
  id: string
  name: string
  entities: EntityData[]
  environment: EnvironmentData
  lighting: LightingData
}

export interface EnvironmentData {
  skybox?: string
  ambientLight: {
    color: string | number
    intensity: number
  }
  fog?: {
    color: string | number
    near: number
    far: number
  }
}

export interface LightingData {
  directionalLights: Array<{
    color: string | number
    intensity: number
    position: Vector3
    castShadow: boolean
  }>
  pointLights: Array<{
    color: string | number
    intensity: number
    position: Vector3
    distance: number
    decay: number
  }>
}

// Component-specific prop types
export interface HelloWorldProps {
  message?: string
  color?: string
}

export interface CounterProps {
  initial_value?: number
  step?: number
}

export interface ThreeDCubeProps {
  size?: number
  color?: string
  rotation_speed?: number
}

export interface WorldSceneProps {
  worldData?: WorldData
  cameraPosition?: Vector3
  cameraTarget?: Vector3
  showGrid?: boolean
  showAxes?: boolean
  enableControls?: boolean
}
