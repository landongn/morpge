// Flexible Surface System JavaScript Hooks

const SurfaceHooks = {
  // Hook for pane resizing and dragging
  PaneResizer: {
    mounted() {
      this.paneId = this.el.dataset.paneId;
      this.isDragging = false;
      this.isResizing = false;
      this.resizeDirection = null;
      this.startX = 0;
      this.startY = 0;
      this.startLeft = 0;
      this.startTop = 0;
      this.startWidth = 0;
      this.startHeight = 0;
      
      this.setupEventListeners();
    },

    setupEventListeners() {
      // Dragging
      this.el.addEventListener('mousedown', (e) => {
        if (e.target.closest('.pane-header') || e.target.closest('.pane-controls')) {
          this.startDragging(e);
        }
      });

      // Resizing
      const resizeHandles = this.el.querySelectorAll('.resize-handle');
      resizeHandles.forEach(handle => {
        handle.addEventListener('mousedown', (e) => {
          e.stopPropagation();
          this.startResizing(e, handle.dataset.direction);
        });
      });

      // Global mouse events
      document.addEventListener('mousemove', (e) => {
        if (this.isDragging) {
          this.handleDragging(e);
        } else if (this.isResizing) {
          this.handleResizing(e);
        }
      });

      document.addEventListener('mouseup', () => {
        this.stopDragging();
        this.stopResizing();
      });
    },

    startDragging(e) {
      this.isDragging = true;
      this.startX = e.clientX;
      this.startY = e.clientY;
      
      const rect = this.el.getBoundingClientRect();
      this.startLeft = rect.left;
      this.startTop = rect.top;
      
      this.el.style.cursor = 'grabbing';
      document.body.style.cursor = 'grabbing';
      document.body.style.userSelect = 'none';
    },

    handleDragging(e) {
      if (!this.isDragging) return;
      
      const deltaX = e.clientX - this.startX;
      const deltaY = e.clientY - this.startY;
      
      const newLeft = this.startLeft + deltaX;
      const newTop = this.startTop + deltaY;
      
      // Constrain to viewport bounds
      const maxLeft = window.innerWidth - this.el.offsetWidth;
      const maxTop = window.innerHeight - this.el.offsetHeight;
      
      const constrainedLeft = Math.max(0, Math.min(newLeft, maxLeft));
      const constrainedTop = Math.max(0, Math.min(newTop, maxTop));
      
      this.el.style.left = `${constrainedLeft}px`;
      this.el.style.top = `${constrainedTop}px`;
    },

    stopDragging() {
      if (!this.isDragging) return;
      
      this.isDragging = false;
      this.el.style.cursor = 'move';
      document.body.style.cursor = 'default';
      document.body.style.userSelect = '';
      
      // Update pane position in LiveView
      const rect = this.el.getBoundingClientRect();
      this.pushEvent('move_pane', {
        pane_id: this.paneId,
        x: Math.round(rect.left),
        y: Math.round(rect.top)
      });
    },

    startResizing(e, direction) {
      this.isResizing = true;
      this.resizeDirection = direction;
      this.startX = e.clientX;
      this.startY = e.clientY;
      
      const rect = this.el.getBoundingClientRect();
      this.startLeft = rect.left;
      this.startTop = rect.top;
      this.startWidth = rect.width;
      this.startHeight = rect.height;
      
      document.body.style.userSelect = 'none';
    },

    handleResizing(e) {
      if (!this.isResizing) return;
      
      const deltaX = e.clientX - this.startX;
      const deltaY = e.clientY - this.startY;
      
      let newLeft = this.startLeft;
      let newTop = this.startTop;
      let newWidth = this.startWidth;
      let newHeight = this.startHeight;
      
      // Handle different resize directions
      switch (this.resizeDirection) {
        case 'nw':
          newLeft = this.startLeft + deltaX;
          newTop = this.startTop + deltaY;
          newWidth = this.startWidth - deltaX;
          newHeight = this.startHeight - deltaY;
          break;
        case 'ne':
          newTop = this.startTop + deltaY;
          newWidth = this.startWidth + deltaX;
          newHeight = this.startHeight - deltaY;
          break;
        case 'sw':
          newLeft = this.startLeft + deltaX;
          newWidth = this.startWidth - deltaX;
          newHeight = this.startHeight + deltaY;
          break;
        case 'se':
          newWidth = this.startWidth + deltaX;
          newHeight = this.startHeight + deltaY;
          break;
        case 'n':
          newTop = this.startTop + deltaY;
          newHeight = this.startHeight - deltaY;
          break;
        case 's':
          newHeight = this.startHeight + deltaY;
          break;
        case 'e':
          newWidth = this.startWidth + deltaX;
          break;
        case 'w':
          newLeft = this.startLeft + deltaX;
          newWidth = this.startWidth - deltaX;
          break;
      }
      
      // Minimum size constraints
      const minWidth = 200;
      const minHeight = 150;
      
      if (newWidth >= minWidth && newHeight >= minHeight) {
        // Constrain to viewport bounds
        const maxLeft = window.innerWidth - newWidth;
        const maxTop = window.innerHeight - newHeight;
        
        newLeft = Math.max(0, Math.min(newLeft, maxLeft));
        newTop = Math.max(0, Math.min(newTop, maxTop));
        
        this.el.style.left = `${newLeft}px`;
        this.el.style.top = `${newTop}px`;
        this.el.style.width = `${newWidth}px`;
        this.el.style.height = `${newHeight}px`;
      }
    },

    stopResizing() {
      if (!this.isResizing) return;
      
      this.isResizing = false;
      document.body.style.userSelect = '';
      
      // Update pane size in LiveView
      const rect = this.el.getBoundingClientRect();
      this.pushEvent('resize_pane', {
        pane_id: this.paneId,
        width: Math.round(rect.width),
        height: Math.round(rect.height)
      });
    }
  },

  // Hook for chat scrolling
  ChatScroll: {
    mounted() {
      this.autoScroll = this.el.dataset.autoScroll === 'true';
      this.setupAutoScroll();
    },

    setupAutoScroll() {
      if (this.autoScroll) {
        this.scrollToBottom();
      }
      
      // Watch for new messages
      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === 'childList' && this.autoScroll) {
            this.scrollToBottom();
          }
        });
      });
      
      observer.observe(this.el, { childList: true });
    },

    scrollToBottom() {
      this.el.scrollTop = this.el.scrollHeight;
    }
  }
};

// Register all hooks
Object.entries(SurfaceHooks).forEach(([name, hook]) => {
  window.Hooks = window.Hooks || {};
  window.Hooks[name] = hook;
});

// Global surface utilities
window.SurfaceUtils = {
  // Create a new pane programmatically
  createPane: function(paneConfig) {
    const event = new CustomEvent('create_pane', { 
      detail: { pane_config: paneConfig } 
    });
    document.dispatchEvent(event);
  },

  // Set surface background
  setBackground: function(background) {
    const event = new CustomEvent('set_background', { 
      detail: { background: background } 
    });
    document.dispatchEvent(event);
  },

  // Add background effect
  addEffect: function(effect) {
    const effectsContainer = document.querySelector('.surface-effects');
    if (effectsContainer) {
      const effectElement = document.createElement('div');
      effectElement.className = 'surface-effect';
      effectElement.style.cssText = effect.styles;
      effectElement.innerHTML = effect.content;
      effectsContainer.appendChild(effectElement);
      
      // Auto-remove effect after duration
      if (effect.duration) {
        setTimeout(() => {
          effectElement.remove();
        }, effect.duration);
      }
    }
  },

  // Create particle effect
  createParticles: function(config) {
    const effectsContainer = document.querySelector('.surface-effects');
    if (!effectsContainer) return;
    
    const particleCount = config.count || 50;
    const duration = config.duration || 3000;
    
    for (let i = 0; i < particleCount; i++) {
      setTimeout(() => {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.cssText = `
          position: absolute;
          width: ${config.size || 2}px;
          height: ${config.size || 2}px;
          background-color: ${config.color || '#4CAF50'};
          border-radius: 50%;
          pointer-events: none;
          animation: particle-fade ${duration}ms ease-out forwards;
        `;
        
        // Random position
        particle.style.left = Math.random() * 100 + '%';
        particle.style.top = Math.random() * 100 + '%';
        
        effectsContainer.appendChild(particle);
        
        // Remove particle after animation
        setTimeout(() => {
          particle.remove();
        }, duration);
      }, i * (duration / particleCount));
    }
  }
};

// Add CSS animations for effects
const style = document.createElement('style');
style.textContent = `
  @keyframes particle-fade {
    0% {
      opacity: 1;
      transform: scale(1);
    }
    100% {
      opacity: 0;
      transform: scale(0);
    }
  }
  
  .surface-effect {
    position: absolute;
    pointer-events: none;
  }
  
  .particle {
    position: absolute;
    pointer-events: none;
  }
`;
document.head.appendChild(style);
