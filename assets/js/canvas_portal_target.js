// CanvasPortalTarget - Manages portal snippets for global Canvas
// Based on Threlte portal pattern: https://threlte.xyz/docs/learn/basics/app-structure#sveltekit-setup-using-a-single-canvas

class CanvasPortalTarget {
  constructor() {
    this.snippets = new Set();
    this.renderCallbacks = new Set();
  }

  // Add a new portal snippet
  addCanvasPortalSnippet(snippet) {
    this.snippets.add(snippet);
    this.notifyRenderCallbacks();
  }

  // Remove a portal snippet
  removeCanvasPortalSnippet(snippet) {
    this.snippets.delete(snippet);
    this.notifyRenderCallbacks();
  }

  // Get all active snippets
  getSnippets() {
    return Array.from(this.snippets);
  }

  // Register render callback
  onRender(callback) {
    this.renderCallbacks.add(callback);
    return () => this.renderCallbacks.delete(callback);
  }

  // Notify all render callbacks
  notifyRenderCallbacks() {
    this.renderCallbacks.forEach(callback => callback());
  }

  // Clear all snippets
  clear() {
    this.snippets.clear();
    this.notifyRenderCallbacks();
  }
}

// Global instance
window.CanvasPortalTarget = new CanvasPortalTarget();

// Export for use in other modules
export { CanvasPortalTarget };
export default window.CanvasPortalTarget;
