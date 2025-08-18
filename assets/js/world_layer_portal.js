// WorldLayerPortal - Renders MUD world into the global Canvas via portal
// Based on Threlte portal pattern: https://threlte.xyz/docs/learn/basics/app-structure#sveltekit-setup-using-a-single-canvas

class WorldLayerPortal {
  constructor(element, worldData) {
    this.element = element;
    this.worldData = worldData || this.getDefaultWorldData();
    this.meshes = new Map();
    this.lights = new Map();
    this.controls = null;
    this.isActive = false;
    
    // Create portal snippet
    this.snippet = {
      render: this.render.bind(this),
      worldData: this.worldData
    };
    
    // Activate portal
    this.activate();
  }

  // Get default world data
  getDefaultWorldData() {
    return {
      id: "default-world",
      name: "MUD World",
      entities: [
        {
          id: "ground-block",
          name: "Ground Block",
          type: "terrain",
          transform: {
            position: { x: 0, y: -0.5, z: 0 },
            rotation: { x: 0, y: 0, z: 0, w: 1 },
            scale: { x: 10, y: 1, z: 10 }
          },
          geometry: {
            type: "box",
            dimensions: { x: 10, y: 1, z: 10 },
            material: {
              type: "basic",
              color: "#8B4513",
              roughness: 0.8
            }
          }
        },
        {
          id: "player-capsule",
          name: "Player Character",
          type: "player",
          transform: {
            position: { x: 0, y: 1, z: 0 },
            rotation: { x: 0, y: 0, z: 0, w: 1 },
            scale: { x: 1, y: 1, z: 1 }
          },
          geometry: {
            type: "capsule",
            dimensions: { x: 0.5, y: 2, z: 0.5 },
            material: {
              type: "phong",
              color: "#4A90E2",
              roughness: 0.3,
              metalness: 0.1
            }
          }
        }
      ],
      environment: {
        ambientLight: {
          color: "#404040",
          intensity: 0.4
        }
      },
      lighting: {
        directionalLights: [
          {
            color: "#ffffff",
            intensity: 0.8,
            position: { x: 10, y: 10, z: 5 },
            castShadow: true
          }
        ]
      }
    };
  }

  // Activate the portal
  activate() {
    if (!this.isActive && window.CanvasPortalTarget) {
      window.CanvasPortalTarget.addCanvasPortalSnippet(this.snippet);
      this.isActive = true;
      console.log('WorldLayerPortal activated');
    }
  }

  // Deactivate the portal
  deactivate() {
    if (this.isActive && window.CanvasPortalTarget) {
      window.CanvasPortalTarget.removeCanvasPortalSnippet(this.snippet);
      this.isActive = false;
      console.log('WorldLayerPortal deactivated');
    }
  }

  // Render the world into the scene
  render(scene, camera) {
    if (!scene || !camera) return;

    // Clear existing meshes
    this.clearMeshes(scene);

    // Create world entities
    this.createWorldEntities(scene);

    // Create lighting
    this.createLighting(scene);

    // Setup camera controls
    this.setupCameraControls(camera);
  }

  // Clear existing meshes
  clearMeshes(scene) {
    this.meshes.forEach(mesh => {
      if (mesh && mesh.parent) {
        mesh.parent.remove(mesh);
      }
    });
    this.meshes.clear();
  }

  // Create world entities
  createWorldEntities(scene) {
    this.worldData.entities.forEach(entity => {
      const mesh = this.createEntityMesh(entity);
      if (mesh) {
        scene.add(mesh);
        this.meshes.set(entity.id, mesh);
      }
    });
  }

  // Create entity mesh
  createEntityMesh(entity) {
    // Import Three.js dynamically
    return import('three').then(({ 
      Mesh, 
      BoxGeometry, 
      CapsuleGeometry, 
      MeshStandardMaterial,
      Vector3,
      Quaternion
    }) => {
      let geometry, material;

      // Create geometry based on type
      switch (entity.geometry.type) {
        case 'box':
          geometry = new BoxGeometry(
            entity.geometry.dimensions.x,
            entity.geometry.dimensions.y,
            entity.geometry.dimensions.z
          );
          break;
        case 'capsule':
          geometry = new CapsuleGeometry(
            entity.geometry.dimensions.x / 2,
            entity.geometry.dimensions.y,
            4, 8
          );
          break;
        default:
          console.warn(`Unknown geometry type: ${entity.geometry.type}`);
          return null;
      }

      // Create material
      material = new MeshStandardMaterial({
        color: entity.geometry.material.color,
        roughness: entity.geometry.material.roughness || 0.5,
        metalness: entity.geometry.material.metalness || 0.0
      });

      // Create mesh
      const mesh = new Mesh(geometry, material);

      // Set transform
      const pos = entity.transform.position;
      const rot = entity.transform.rotation;
      const scale = entity.transform.scale;

      mesh.position.set(pos.x, pos.y, pos.z);
      mesh.quaternion.set(rot.x, rot.y, rot.z, rot.w);
      mesh.scale.set(scale.x, scale.y, scale.z);

      // Set shadow properties
      mesh.castShadow = entity.type === 'player';
      mesh.receiveShadow = entity.type === 'terrain';

      return mesh;
    }).catch(error => {
      console.error('Failed to create entity mesh:', error);
      return null;
    });
  }

  // Create lighting
  createLighting(scene) {
    // Import Three.js dynamically
    import('three').then(({ 
      AmbientLight, 
      DirectionalLight,
      Color
    }) => {
      // Clear existing lights
      this.lights.forEach(light => {
        if (light && light.parent) {
          light.parent.remove(light);
        }
      });
      this.lights.clear();

      // Ambient light
      const ambientLight = new AmbientLight(
        new Color(this.worldData.environment.ambientLight.color),
        this.worldData.environment.ambientLight.intensity
      );
      scene.add(ambientLight);
      this.lights.set('ambient', ambientLight);

      // Directional lights
      this.worldData.lighting.directionalLights.forEach((lightData, index) => {
        const directionalLight = new DirectionalLight(
          new Color(lightData.color),
          lightData.intensity
        );
        
        directionalLight.position.set(
          lightData.position.x,
          lightData.position.y,
          lightData.position.z
        );
        
        directionalLight.castShadow = lightData.castShadow;
        
        if (lightData.castShadow) {
          directionalLight.shadow.mapSize.width = 2048;
          directionalLight.shadow.mapSize.height = 2048;
          directionalLight.shadow.camera.near = 0.5;
          directionalLight.shadow.camera.far = 50;
          directionalLight.shadow.camera.left = -10;
          directionalLight.shadow.camera.right = 10;
          directionalLight.shadow.camera.top = 10;
          directionalLight.shadow.camera.bottom = -10;
        }
        
        scene.add(directionalLight);
        this.lights.set(`directional-${index}`, directionalLight);
      });
    });
  }

  // Setup camera controls
  setupCameraControls(camera) {
    // This would integrate with OrbitControls or similar
    // For now, just ensure camera is positioned correctly
    if (this.worldData.cameraPosition) {
      camera.position.set(
        this.worldData.cameraPosition.x,
        this.worldData.cameraPosition.y,
        this.worldData.cameraPosition.z
      );
    }
    
    if (this.worldData.cameraTarget) {
      camera.lookAt(
        this.worldData.cameraTarget.x,
        this.worldData.cameraTarget.y,
        this.worldData.cameraTarget.z
      );
    }
  }

  // Update world data
  updateWorldData(newWorldData) {
    this.worldData = { ...this.worldData, ...newWorldData };
    this.snippet.worldData = this.worldData;
    
    // Force re-render
    if (window.fullScreenCanvas) {
      window.fullScreenCanvas.renderPortalSnippets();
    }
  }

  // Update entity
  updateEntity(entityId, updates) {
    const entity = this.worldData.entities.find(e => e.id === entityId);
    if (entity) {
      Object.assign(entity, updates);
      
      // Update mesh if it exists
      const mesh = this.meshes.get(entityId);
      if (mesh) {
        // Update transform
        if (updates.transform) {
          const pos = updates.transform.position;
          const rot = updates.transform.rotation;
          const scale = updates.transform.scale;
          
          if (pos) mesh.position.set(pos.x, pos.y, pos.z);
          if (rot) mesh.quaternion.set(rot.x, rot.y, rot.z, rot.w);
          if (scale) mesh.scale.set(scale.x, scale.y, scale.z);
        }
      }
    }
  }

  // Destroy the portal
  destroy() {
    this.deactivate();
    this.clearMeshes();
    this.element = null;
    this.worldData = null;
    this.snippet = null;
  }
}

// Export for use in other modules
window.WorldLayerPortal = WorldLayerPortal;
export default WorldLayerPortal;
