<script lang="ts">
  import { Canvas, T } from "@threlte/core";
  import { Grid, OrbitControls } from "@threlte/extras";
  import type { WorldData, WorldSceneProps } from "../../src/types";

  // Props with runes
  let {
    worldData,
    cameraPosition = { x: 10, y: 15, z: 10 },
    cameraTarget = { x: 0, y: 0, z: 0 },
    showGrid = true,
    showAxes = true,
    enableControls = true,
  }: WorldSceneProps = $props();

  // Default world data for demonstration
  const defaultWorldData: WorldData = {
    id: "default-world",
    name: "Demo World",
    entities: [
      {
        id: "ground-block",
        name: "Ground Block",
        type: "terrain",
        transform: {
          position: { x: 0, y: -0.5, z: 0 },
          rotation: { x: 0, y: 0, z: 0, w: 1 },
          scale: { x: 10, y: 1, z: 10 },
        },
        geometry: {
          type: "box",
          dimensions: { x: 10, y: 1, z: 10 },
          material: {
            type: "basic",
            color: "#8B4513",
            roughness: 0.8,
          },
        },
      },
      {
        id: "player-capsule",
        name: "Player Character",
        type: "player",
        transform: {
          position: { x: 0, y: 1, z: 0 },
          rotation: { x: 0, y: 0, z: 0, w: 1 },
          scale: { x: 1, y: 1, z: 1 },
        },
        geometry: {
          type: "capsule",
          dimensions: { x: 0.5, y: 2, z: 0.5 },
          material: {
            type: "phong",
            color: "#4A90E2",
            roughness: 0.3,
            metalness: 0.1,
          },
        },
      },
    ],
    environment: {
      ambientLight: {
        color: "#404040",
        intensity: 0.4,
      },
    },
    lighting: {
      directionalLights: [
        {
          color: "#ffffff",
          intensity: 0.8,
          position: { x: 10, y: 10, z: 5 },
          castShadow: true,
        },
      ],
      pointLights: [],
    },
  };

  // Use default world data if none provided
  let activeWorldData = $derived(worldData || defaultWorldData);
</script>

<div class="world-scene-container">
  <Canvas
    gl={{
      antialias: true,
      alpha: true,
      shadowMap: true,
      shadowMapType: 1, // PCFSoftShadowMap
    }}
    shadows
    class="w-full h-full"
  >
    <!-- Camera -->
    <T.PerspectiveCamera
      fov={60}
      near={0.1}
      far={1000}
      position={[cameraPosition.x, cameraPosition.y, cameraPosition.z]}
      lookAt={[cameraTarget.x, cameraTarget.y, cameraTarget.z]}
    />

    <!-- Controls -->
    {#if enableControls}
      <OrbitControls
        target={[cameraTarget.x, cameraTarget.y, cameraTarget.z]}
        enablePan={true}
        enableZoom={true}
        enableRotate={true}
        maxPolarAngle={Math.PI / 2.1}
        minPolarAngle={0.1}
        maxDistance={50}
        minDistance={2}
      />
    {/if}

    <!-- Environment -->
    <T.AmbientLight
      color={activeWorldData.environment.ambientLight.color}
      intensity={activeWorldData.environment.ambientLight.intensity}
    />

    <!-- Directional Light -->
    <T.DirectionalLight
      color={activeWorldData.lighting.directionalLights[0].color}
      intensity={activeWorldData.lighting.directionalLights[0].intensity}
      position={[
        activeWorldData.lighting.directionalLights[0].position.x,
        activeWorldData.lighting.directionalLights[0].position.y,
        activeWorldData.lighting.directionalLights[0].position.z,
      ]}
      castShadow={activeWorldData.lighting.directionalLights[0].castShadow}
      shadowMapWidth={2048}
      shadowMapHeight={2048}
      shadowCameraNear={0.5}
      shadowCameraFar={50}
      shadowCameraLeft={-10}
      shadowCameraRight={10}
      shadowCameraTop={10}
      shadowCameraBottom={-10}
    />

    <!-- Grid and Axes -->
    {#if showGrid}
      <Grid
        args={[20, 20]}
        cellSize={1}
        cellThickness={0.5}
        cellColor="#888888"
        sectionSize={5}
        sectionThickness={1}
        sectionColor="#444444"
        fadeDistance={25}
        fadeStrength={1}
        followCamera={false}
        infiniteGrid={true}
      />
    {/if}

    {#if showAxes}
      <T.Axes args={[5]} />
    {/if}

    <!-- World Entities -->
    {#each activeWorldData.entities as entity}
      {#if entity.geometry.type === "box"}
        <T.Mesh
          position={[entity.transform.position.x, entity.transform.position.y, entity.transform.position.z]}
          scale={[entity.transform.scale.x, entity.transform.scale.y, entity.transform.scale.z]}
          castShadow={entity.type === "player"}
          receiveShadow={entity.type === "terrain"}
        >
          <T.BoxGeometry
            args={[entity.geometry.dimensions.x, entity.geometry.dimensions.y, entity.geometry.dimensions.z]}
          />
          <T.MeshStandardMaterial
            color={entity.geometry.material.color}
            roughness={entity.geometry.material.roughness || 0.5}
            metalness={entity.geometry.material.metalness || 0.0}
          />
        </T.Mesh>
      {:else if entity.geometry.type === "capsule"}
        <T.Mesh
          position={[entity.transform.position.x, entity.transform.position.y, entity.transform.position.z]}
          scale={[entity.transform.scale.x, entity.transform.scale.y, entity.transform.scale.z]}
          castShadow={entity.type === "player"}
          receiveShadow={entity.type === "terrain"}
        >
          <T.CapsuleGeometry args={[entity.geometry.dimensions.x / 2, entity.geometry.dimensions.y, 4, 8]} />
          <T.MeshStandardMaterial
            color={entity.geometry.material.color}
            roughness={entity.geometry.material.roughness || 0.5}
            metalness={entity.geometry.material.metalness || 0.0}
          />
        </T.Mesh>
      {/if}
    {/each}
  </Canvas>

  <!-- Scene Info Overlay -->
  <div class="scene-info">
    <div class="info-panel">
      <h3 class="text-lg font-semibold text-white mb-2">
        {activeWorldData.name}
      </h3>
      <div class="text-sm text-gray-300 space-y-1">
        <p>Entities: {activeWorldData.entities.length}</p>
        <p>Camera: ({cameraPosition.x.toFixed(1)}, {cameraPosition.y.toFixed(1)}, {cameraPosition.z.toFixed(1)})</p>
        <p>Target: ({cameraTarget.x.toFixed(1)}, {cameraTarget.y.toFixed(1)}, {cameraTarget.z.toFixed(1)})</p>
      </div>
    </div>
  </div>
</div>

<style>
  .world-scene-container {
    position: relative;
    width: 100%;
    height: 100%;
    min-height: 400px;
    background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
    border-radius: 8px;
    overflow: hidden;
  }

  .scene-info {
    position: absolute;
    top: 16px;
    right: 16px;
    z-index: 10;
  }

  .info-panel {
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(10px);
    padding: 16px;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    min-width: 200px;
  }

  :global(.world-scene-container canvas) {
    display: block;
    width: 100% !important;
    height: 100% !important;
  }
</style>
