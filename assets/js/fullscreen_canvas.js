// FullScreenCanvas - Single WebGL context for the entire app
// Based on Threlte portal pattern: https://threlte.xyz/docs/learn/basics/app-structure#sveltekit-setup-using-a-single-canvas

import { CanvasPortalTarget } from './canvas_portal_target.js';

class FullScreenCanvas {
  constructor() {
    this.canvas = null;
    this.renderer = null;
    this.scene = null;
    this.camera = null;
    this.portalTarget = null;
    this.isInitialized = false;
    this.animationFrameId = null;
    
    this.init();
  }

  // Initialize the Canvas
  init() {
    // Create canvas element
    this.canvas = document.createElement('canvas');
    this.canvas.id = 'threlte-canvas';
    this.canvas.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      z-index: -1;
      pointer-events: none;
    `;

    // Add to DOM
    document.body.appendChild(this.canvas);

    // Initialize Three.js
    this.initThreeJS();
    
    // Initialize portal system
    this.initPortalSystem();
    
    // Start render loop
    this.startRenderLoop();
    
    this.isInitialized = true;
  }

  // Initialize Three.js components
  initThreeJS() {
    // Import Three.js dynamically
    import('three').then(({ Scene, PerspectiveCamera, WebGLRenderer, Color }) => {
      // Create scene
      this.scene = new Scene();
      this.scene.background = new Color(0x1a1a2e);

      // Create camera
      this.camera = new PerspectiveCamera(
        75, // FOV
        window.innerWidth / window.innerHeight, // Aspect ratio
        0.1, // Near
        1000 // Far
      );
      this.camera.position.set(10, 15, 10);
      this.camera.lookAt(0, 0, 0);

      // Create renderer
      this.renderer = new WebGLRenderer({
        canvas: this.canvas,
        antialias: true,
        alpha: true
      });
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      this.renderer.setPixelRatio(window.devicePixelRatio);
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = 2; // PCFSoftShadowMap

      // Handle window resize
      window.addEventListener('resize', this.onWindowResize.bind(this));
    });
  }

  // Initialize portal system
  initPortalSystem() {
    this.portalTarget = new CanvasPortalTarget();
    window.CanvasPortalTarget = this.portalTarget;
  }

  // Window resize handler
  onWindowResize() {
    if (this.camera && this.renderer) {
      this.camera.aspect = window.innerWidth / window.innerHeight;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(window.innerWidth, window.innerHeight);
    }
  }

  // Start render loop
  startRenderLoop() {
    const animate = () => {
      this.animationFrameId = requestAnimationFrame(animate);
      
      if (this.scene && this.camera && this.renderer) {
        // Render all portal snippets
        this.renderPortalSnippets();
        
        // Render the scene
        this.renderer.render(this.scene, this.camera);
      }
    };
    
    animate();
  }

  // Render portal snippets
  renderPortalSnippets() {
    if (this.portalTarget) {
      const snippets = this.portalTarget.getSnippets();
      snippets.forEach(snippet => {
        if (snippet && typeof snippet.render === 'function') {
          snippet.render(this.scene, this.camera);
        }
      });
    }
  }

  // Get the scene for external use
  getScene() {
    return this.scene;
  }

  // Get the camera for external use
  getCamera() {
    return this.camera;
  }

  // Get the renderer for external use
  getRenderer() {
    return this.renderer;
  }

  // Destroy the canvas
  destroy() {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
    }
    
    if (this.renderer) {
      this.renderer.dispose();
    }
    
    if (this.canvas && this.canvas.parentNode) {
      this.canvas.parentNode.removeChild(this.canvas);
    }
    
    this.isInitialized = false;
  }
}

// Initialize global canvas when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.fullScreenCanvas = new FullScreenCanvas();
});

// Export for use in other modules
window.FullScreenCanvas = FullScreenCanvas;
export default FullScreenCanvas;
