// CanvasPortal - Allows components to render into the global Canvas
// Based on Threlte portal pattern: https://threlte.xyz/docs/learn/basics/app-structure#sveltekit-setup-using-a-single-canvas

class CanvasPortal {
  constructor(element, snippet) {
    this.element = element;
    this.snippet = snippet;
    this.isActive = false;
    
    // Register with global portal target
    this.activate();
  }

  // Activate the portal
  activate() {
    if (!this.isActive && window.CanvasPortalTarget) {
      window.CanvasPortalTarget.addCanvasPortalSnippet(this.snippet);
      this.isActive = true;
    }
  }

  // Deactivate the portal
  deactivate() {
    if (this.isActive && window.CanvasPortalTarget) {
      window.CanvasPortalTarget.removeCanvasPortalSnippet(this.snippet);
      this.isActive = false;
    }
  }

  // Update the portal snippet
  updateSnippet(newSnippet) {
    if (this.isActive) {
      this.deactivate();
    }
    this.snippet = newSnippet;
    this.activate();
  }

  // Destroy the portal
  destroy() {
    this.deactivate();
    this.element = null;
    this.snippet = null;
  }
}

// Export for use in other modules
window.CanvasPortal = CanvasPortal;
export default CanvasPortal;
