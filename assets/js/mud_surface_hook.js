const MudSurfaceComponent = {
  mounted() {
    this.componentId = this.el.dataset.componentId;
    this.componentType = this.el.dataset.componentType;
    this.componentProps = JSON.parse(this.el.dataset.componentProps || '{}');
    this.componentPosition = JSON.parse(this.el.dataset.componentPosition || '{"x": 0, "y": 0}');
    this.componentSize = JSON.parse(this.componentSize || '{"width": 300, "height": 200}');
    this.componentZIndex = parseInt(this.el.dataset.componentZIndex || '1');

    this.isDragging = false;
    this.isResizing = false;
    this.dragOffset = { x: 0, y: 0 };
    this.resizeHandle = null;
    this.worldPortal = null;

    this.initializeComponent();
    this.setupEventListeners();
  },

  destroyed() {
    this.cleanupEventListeners();
    if (this.worldPortal) {
      this.worldPortal.destroy();
    }
  },

  initializeComponent() {
    // Set initial position and size
    this.el.style.left = `${this.componentPosition.x}px`;
    this.el.style.top = `${this.componentPosition.y}px`;
    this.el.style.width = `${this.componentSize.width}px`;
    this.el.style.height = `${this.componentSize.height}px`;
    this.el.style.zIndex = this.componentZIndex;

    // Render the component based on type
    this.renderComponent();
  },

  renderComponent() {
    // Clear existing content
    this.el.innerHTML = '';

    // Create component header with drag handle
    const header = document.createElement('div');
    header.className = 'component-header bg-gray-700 px-3 py-2 border-b border-gray-600 flex items-center justify-between cursor-move';
    header.innerHTML = `
      <span class="text-sm font-medium text-gray-300">${this.componentType}</span>
      <div class="flex items-center space-x-2">
        <button class="text-gray-400 hover:text-white text-xs" onclick="this.closest('.mud-component').__mudHook.toggleMinimize()">−</button>
        <button class="text-gray-400 hover:text-white text-xs" onclick="this.closest('.mud-component').__mudHook.toggleMaximize()">□</button>
        <button class="text-red-400 hover:text-red-300 text-xs" onclick="this.closest('.mud-component').__mudHook.closeComponent()">×</button>
      </div>
    `;

    // Create component content
    const content = document.createElement('div');
    content.className = 'component-content flex-1 p-3';
    content.innerHTML = this.getComponentContent();

    // Create resize handle
    const resizeHandle = document.createElement('div');
    resizeHandle.className = 'resize-handle absolute bottom-0 right-0 w-4 h-4 cursor-se-resize';
    resizeHandle.innerHTML = '⋮⋮';

    // Assemble component
    this.el.appendChild(header);
    this.el.appendChild(content);
    this.el.appendChild(resizeHandle);

    // Store reference to hook for button callbacks
    this.el.__mudHook = this;

    // Store resize handle reference
    this.resizeHandle = resizeHandle;

    // Initialize world portal for world-scene components
    if (this.componentType === 'world-scene') {
      this.initializeWorldPortal();
    }
  },

  // Initialize world portal for 3D rendering
  initializeWorldPortal() {
    if (window.WorldLayerPortal) {
      // Create world portal with component props
      this.worldPortal = new window.WorldLayerPortal(this.el, {
        cameraPosition: this.componentProps.cameraPosition,
        cameraTarget: this.componentProps.cameraTarget,
        showGrid: this.componentProps.showGrid,
        showAxes: this.componentProps.showAxes,
        enableControls: this.componentProps.enableControls
      });
      
      console.log('WorldLayerPortal initialized for component:', this.componentId);
    } else {
      console.warn('WorldLayerPortal not available');
    }
  },

  getComponentContent() {
    switch (this.componentType) {
      case 'world-scene':
        return `
          <div class="world-scene-container w-full h-full">
            <div class="world-scene-info bg-black bg-opacity-50 text-white p-2 rounded text-xs">
              <div class="flex items-center justify-between">
                <span>🌍 3D World Scene</span>
                <span class="text-green-400">● Active</span>
              </div>
              <div class="mt-1 text-gray-300">
                Camera: (${this.componentProps.cameraPosition?.x || 10}, ${this.componentProps.cameraPosition?.y || 15}, ${this.componentProps.cameraPosition?.z || 10})
              </div>
              <div class="mt-1 text-gray-300">
                Target: (${this.componentProps.cameraTarget?.x || 0}, ${this.componentProps.cameraTarget?.y || 0}, ${this.componentProps.cameraTarget?.z || 0})
              </div>
            </div>
            <div class="world-scene-controls mt-2 space-y-1">
              <label class="flex items-center text-xs text-gray-300">
                <input type="checkbox" checked="${this.componentProps.showGrid}" onchange="this.closest('.mud-component').__mudHook.toggleGrid()" class="mr-2">
                Show Grid
              </label>
              <label class="flex items-center text-xs text-gray-300">
                <input type="checkbox" checked="${this.componentProps.showAxes}" onchange="this.closest('.mud-component').__mudHook.toggleAxes()" class="mr-2">
                Show Axes
              </label>
            </div>
          </div>
        `;

      case 'world-chat':
        return `
          <div class="chat-component h-full">
            <div class="chat-messages flex-1 overflow-y-auto space-y-2">
              ${this.componentProps.messages?.map(msg => `
                <div class="chat-message ${msg.type === 'system' ? 'text-yellow-400' : 'text-white'} text-sm">
                  <span class="timestamp text-gray-500">[${new Date(msg.timestamp).toLocaleTimeString()}]</span>
                  ${msg.author ? `<span class="author text-blue-400">${msg.author}:</span>` : ''}
                  <span class="content">${msg.content}</span>
                </div>
              `).join('') || ''}
            </div>
            <div class="chat-input mt-2">
              <input type="text" placeholder="Type message..." class="w-full bg-gray-600 border border-gray-500 rounded px-2 py-1 text-white text-sm">
            </div>
          </div>
        `;

      case 'local-chat':
        return `
          <div class="chat-component h-full">
            <div class="chat-messages flex-1 overflow-y-auto space-y-2">
              ${this.componentProps.messages?.map(msg => `
                <div class="chat-message ${msg.type === 'system' ? 'text-yellow-400' : 'text-white'} text-sm">
                  <span class="timestamp text-gray-500">[${new Date(msg.timestamp).toLocaleTimeString()}]</span>
                  ${msg.author ? `<span class="author text-blue-400">${msg.author}:</span>` : ''}
                  <span class="content">${msg.content}</span>
                </div>
              `).join('') || ''}
            </div>
            <div class="chat-input mt-2">
              <input type="text" placeholder="Local message..." class="w-full bg-gray-600 border border-gray-500 rounded px-2 py-1 text-white text-sm">
            </div>
          </div>
        `;

      case 'system-chat':
        return `
          <div class="chat-component h-full">
            <div class="chat-messages flex-1 overflow-y-auto space-y-2">
              ${this.componentProps.messages?.map(msg => `
                <div class="chat-message ${msg.type === 'system' ? 'text-yellow-400' : 'text-white'} text-sm">
                  <span class="timestamp text-gray-500">[${new Date(msg.timestamp).toLocaleTimeString()}]</span>
                  <span class="content">${msg.content}</span>
                </div>
              `).join('') || ''}
            </div>
          </div>
        `;

      case 'player-status':
        return `
          <div class="player-status-component h-full">
            <div class="text-center mb-4">
              <div class="text-lg font-bold text-white">Player Name</div>
              <div class="text-sm text-gray-400">Level ${this.componentProps.level || 1}</div>
            </div>
            
            <div class="space-y-3">
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span class="text-red-400">Health</span>
                  <span class="text-white">${this.componentProps.health || 100}/${this.componentProps.maxHealth || 100}</span>
                </div>
                <div class="status-bar">
                  <div class="health-bar" style="width: ${((this.componentProps.health || 100) / (this.componentProps.maxHealth || 100)) * 100}%"></div>
                </div>
              </div>
              
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span class="text-blue-400">Mana</span>
                  <span class="text-white">${this.componentProps.mana || 50}/${this.componentProps.maxMana || 100}</span>
                </div>
                <div class="status-bar">
                  <div class="mana-bar" style="width: ${((this.componentProps.mana || 50) / (this.componentProps.maxMana || 100)) * 100}%"></div>
                </div>
              </div>
              
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span class="text-green-400">Stamina</span>
                  <span class="text-white">${this.componentProps.stamina || 75}/${this.componentProps.maxStamina || 100}</span>
                </div>
                <div class="status-bar">
                  <div class="stamina-bar" style="width: ${((this.componentProps.stamina || 75) / (this.componentProps.maxStamina || 100)) * 100}%"></div>
                </div>
              </div>
            </div>
          </div>
        `;

      case 'command-input':
        return `
          <div class="command-input-component h-full">
            <div class="command-history mb-2 text-xs text-gray-400">
              ${this.componentProps.commandHistory?.slice(-3).map(cmd => `
                <div class="command-item">> ${cmd}</div>
              `).join('') || ''}
            </div>
            <div class="command-input-field">
              <input type="text" placeholder="${this.componentProps.placeholder || 'Enter command...'}" 
                     class="w-full bg-gray-600 border border-gray-500 rounded px-3 py-2 text-white">
            </div>
          </div>
        `;

      default:
        return `
          <div class="text-center text-gray-400 py-8">
            <div class="text-lg mb-2">❓</div>
            <div>Unknown component type: ${this.componentType}</div>
          </div>
        `;
    }
  },

  // World scene control methods
  toggleGrid() {
    if (this.worldPortal) {
      this.componentProps.showGrid = !this.componentProps.showGrid;
      this.worldPortal.updateWorldData({ showGrid: this.componentProps.showGrid });
      this.updateComponentDisplay();
    }
  },

  toggleAxes() {
    if (this.worldPortal) {
      this.componentProps.showAxes = !this.componentProps.showAxes;
      this.worldPortal.updateWorldData({ showAxes: this.componentProps.showAxes });
      this.updateComponentDisplay();
    }
  },

  setupEventListeners() {
    // Drag functionality
    this.el.addEventListener('mousedown', this.handleMouseDown.bind(this));
    document.addEventListener('mousemove', this.handleMouseMove.bind(this));
    document.addEventListener('mouseup', this.handleMouseUp.bind(this));

    // Resize functionality
    this.resizeHandle.addEventListener('mousedown', this.handleResizeStart.bind(this));
  },

  cleanupEventListeners() {
    this.el.removeEventListener('mousedown', this.handleMouseDown.bind(this));
    document.removeEventListener('mousemove', this.handleMouseMove.bind(this));
    document.removeEventListener('mouseup', this.handleMouseUp.bind(this));
    
    if (this.resizeHandle) {
      this.resizeHandle.removeEventListener('mousedown', this.handleResizeStart.bind(this));
    }
  },

  handleMouseDown(event) {
    // Only start drag on header
    if (event.target.closest('.component-header')) {
      this.isDragging = true;
      this.dragOffset = {
        x: event.clientX - this.componentPosition.x,
        y: event.clientY - this.componentPosition.y
      };
      this.el.classList.add('dragging');
      event.preventDefault();
    }
  },

  handleMouseMove(event) {
    if (this.isDragging) {
      const newX = event.clientX - this.dragOffset.x;
      const newY = event.clientY - this.dragOffset.y;
      
      // Constrain to surface bounds
      const surface = document.getElementById('mud-surface');
      const surfaceRect = surface.getBoundingClientRect();
      const componentRect = this.el.getBoundingClientRect();
      
      const maxX = surfaceRect.width - componentRect.width;
      const maxY = surfaceRect.height - componentRect.height;
      
      this.componentPosition.x = Math.max(0, Math.min(newX, maxX));
      this.componentPosition.y = Math.max(0, Math.min(newY, maxY));
      
      this.el.style.left = `${this.componentPosition.x}px`;
      this.el.style.top = `${this.componentPosition.y}px`;
    }
  },

  handleMouseUp() {
    if (this.isDragging) {
      this.isDragging = false;
      this.el.classList.remove('dragging');
      
      // Update component position in LiveView
      this.pushEvent('update_component_position', {
        id: this.componentId,
        position: this.componentPosition
      });
    }
  },

  handleResizeStart(event) {
    this.isResizing = true;
    this.resizeStart = {
      x: event.clientX,
      y: event.clientY,
      width: this.componentSize.width,
      height: this.componentSize.height
    };
    
    document.addEventListener('mousemove', this.handleResizeMove.bind(this));
    document.addEventListener('mouseup', this.handleResizeEnd.bind(this));
    event.preventDefault();
  },

  handleResizeMove(event) {
    if (this.isResizing) {
      const deltaX = event.clientX - this.resizeStart.x;
      const deltaY = event.clientY - this.resizeStart.y;
      
      const newWidth = Math.max(200, this.resizeStart.width + deltaX);
      const newHeight = Math.max(150, this.resizeStart.height + deltaY);
      
      this.componentSize.width = newWidth;
      this.componentSize.height = newHeight;
      
      this.el.style.width = `${newWidth}px`;
      this.el.style.height = `${newHeight}px`;
    }
  },

  handleResizeEnd() {
    if (this.isResizing) {
      this.isResizing = false;
      
      // Update component size in LiveView
      this.pushEvent('update_component_size', {
        id: this.componentId,
        size: this.componentSize
      });
      
      document.removeEventListener('mousemove', this.handleResizeMove.bind(this));
      document.removeEventListener('mouseup', this.handleResizeEnd.bind(this));
    }
  },

  // Component control methods
  toggleMinimize() {
    const content = this.el.querySelector('.component-content');
    const resizeHandle = this.el.querySelector('.resize-handle');
    
    if (content.style.display === 'none') {
      content.style.display = 'block';
      if (resizeHandle) resizeHandle.style.display = 'block';
      this.el.style.height = `${this.componentSize.height}px`;
    } else {
      content.style.display = 'none';
      if (resizeHandle) resizeHandle.style.display = 'none';
      this.el.style.height = 'auto';
    }
  },

  toggleMaximize() {
    const surface = document.getElementById('mud-surface');
    const surfaceRect = surface.getBoundingClientRect();
    
    if (this.el.style.width === '100%') {
      // Restore original size
      this.el.style.width = `${this.componentSize.width}px`;
      this.el.style.height = `${this.componentSize.height}px`;
      this.el.style.left = `${this.componentPosition.x}px`;
      this.el.style.top = `${this.componentPosition.y}px`;
    } else {
      // Maximize
      this.el.style.width = '100%';
      this.el.style.height = '100%';
      this.el.style.left = '0px';
      this.el.style.top = '0px';
    }
  },

  closeComponent() {
    this.pushEvent('remove_component', { id: this.componentId });
  },

  updateComponentDisplay() {
    if (this.svelteApp && this.svelteApp.element) {
      // Re-render the component with current data
      const template = this.svelteApp.element.innerHTML;
      let rendered = template;
      
      Object.keys(this.svelteApp.data).forEach(key => {
        const regex = new RegExp(`{{${key}}}`, 'g');
        rendered = rendered.replace(regex, this.svelteApp.data[key]);
      });
      
      this.svelteApp.element.innerHTML = rendered;
    }
  }
};

// Export for use in app.js
window.MudSurfaceComponent = MudSurfaceComponent;
