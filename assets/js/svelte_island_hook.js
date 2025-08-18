const SvelteIsland = {
  mounted() {
    this.componentType = this.el.dataset.componentType;
    this.componentProps = JSON.parse(this.el.dataset.componentProps || '{}');
    this.componentId = this.el.id;
    
    console.log(`SvelteIsland mounted: ${this.componentType}`, this.componentProps);
    
    // Initialize the component
    this.initializeComponent();
  },

  updated() {
    // Handle updates from LiveView
    const newProps = JSON.parse(this.el.dataset.componentProps || '{}');
    if (this.svelteApp && JSON.stringify(newProps) !== JSON.stringify(this.componentProps)) {
      this.componentProps = newProps;
      this.updateComponent();
    }
  },

  destroyed() {
    // Cleanup Svelte app or simulated component
    if (this.svelteApp) {
      if (typeof this.svelteApp.$destroy === 'function') {
        // Real Svelte app
        this.svelteApp.$destroy();
      } else if (this.svelteApp.element && this.svelteApp.element.remove) {
        // Simulated component - remove the DOM element
        this.svelteApp.element.remove();
      }
      this.svelteApp = null;
    }
  },

  async initializeComponent() {
    try {
      // Try to load the component from the registry
      const component = await this.loadComponent(this.componentType);
      
      if (component) {
        this.renderComponent(component);
      } else {
        // Component not found, show placeholder
        this.showPlaceholder();
      }
    } catch (error) {
      console.error(`Failed to initialize component ${this.componentType}:`, error);
      this.showError(error);
    }
  },

  async loadComponent(componentType) {
    // In a real implementation, this would load from the component registry
    // For now, we'll simulate component loading
    
    const componentMap = {
      'hello-world': {
        template: `
          <div class="p-4 bg-blue-100 rounded-lg border border-blue-300">
            <h3 class="text-lg font-semibold text-blue-800 mb-2">Hello World Component</h3>
            <p class="text-blue-700">{{message}}</p>
            <div class="mt-3">
              <button 
                class="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
                onclick={() => this.updateMessage()}>
                Update Message
              </button>
            </div>
          </div>
        `,
        data(props) {
          return {
            message: props.message || 'Hello from Svelte Island!'
          };
        },
        methods: {
          updateMessage() {
            this.message = `Updated at ${new Date().toLocaleTimeString()}`;
          }
        }
      },
      
      'counter': {
        template: `
          <div class="p-4 bg-green-100 rounded-lg border border-green-300">
            <h3 class="text-lg font-semibold text-green-800 mb-2">Counter Component</h3>
            <div class="flex items-center space-x-4">
              <button 
                class="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600"
                onclick={() => this.decrement()}>
                -
              </button>
              <span class="text-2xl font-bold text-green-700">{{count}}</span>
              <button 
                class="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600"
                onclick={() => this.increment()}>
                +
              </button>
            </div>
            <p class="text-sm text-green-600 mt-2">Step: {{step}}</p>
          </div>
        `,
        data(props) {
          return {
            count: props.initial_value || 0,
            step: props.step || 1
          };
        },
        methods: {
          increment() {
            this.count += this.step;
          },
          decrement() {
            this.count -= this.step;
          }
        }
      },
      
      '3d-cube': {
        template: `
          <div class="p-4 bg-purple-100 rounded-lg border border-purple-300">
            <h3 class="text-lg font-semibold text-purple-800 mb-2">3D Cube Component</h3>
            <div class="w-32 h-32 bg-gradient-to-br from-purple-400 to-purple-600 rounded-lg shadow-lg transform rotate-45 hover:scale-110 transition-transform duration-300">
              <div class="w-full h-full flex items-center justify-center text-white font-bold">
                3D
              </div>
            </div>
            <p class="text-sm text-purple-600 mt-2">Size: {{size}}, Color: {{color}}</p>
            <button 
              class="mt-2 px-3 py-1 bg-purple-500 text-white rounded hover:bg-purple-600"
              onclick={() => this.rotate()}>
              Rotate
            </button>
          </div>
        `,
        data(props) {
          return {
            size: props.size || 1.0,
            color: props.color || '#ff6b6b',
            rotation: 0
          };
        },
        methods: {
          rotate() {
            this.rotation += 45;
            this.$el.style.transform = `rotate(${this.rotation}deg)`;
          }
        }
      },
      
      'world-scene': {
        template: `
          <div class="p-4 bg-indigo-100 rounded-lg border border-indigo-300">
            <h3 class="text-lg font-semibold text-indigo-800 mb-2">World Scene Component</h3>
            <div class="w-full h-64 bg-gradient-to-br from-indigo-400 to-indigo-600 rounded-lg shadow-lg relative overflow-hidden">
              <div class="absolute inset-0 flex items-center justify-center text-white font-bold text-lg">
                3D World Scene
              </div>
              <div class="absolute bottom-2 left-2 text-xs text-white opacity-75">
                Camera: ({{cameraX}}, {{cameraY}}, {{cameraZ}})
              </div>
            </div>
            <div class="mt-3 space-y-2">
              <div class="flex items-center space-x-2">
                <input type="checkbox" id="showGrid" checked="{{showGrid}}" onchange={() => this.toggleGrid()}>
                <label for="showGrid" class="text-sm text-indigo-700">Show Grid</label>
              </div>
              <div class="flex items-center space-x-2">
                <input type="checkbox" id="showAxes" checked="{{showAxes}}" onchange={() => this.toggleAxes()}>
                <label for="showAxes" class="text-sm text-indigo-700">Show Axes</label>
              </div>
            </div>
            <p class="text-sm text-indigo-600 mt-2">A 3D world with terrain and player character</p>
          </div>
        `,
        data(props) {
          return {
            cameraX: props.cameraPosition?.x || 10,
            cameraY: props.cameraPosition?.y || 15,
            cameraZ: props.cameraPosition?.z || 10,
            showGrid: props.showGrid !== undefined ? props.showGrid : true,
            showAxes: props.showAxes !== undefined ? props.showAxes : true
          };
        },
        methods: {
          toggleGrid() {
            this.showGrid = !this.showGrid;
            console.log('Grid toggled:', this.showGrid);
          },
          toggleAxes() {
            this.showAxes = !this.showAxes;
            console.log('Axes toggled:', this.showAxes);
          }
        }
      }
    };

    const component = componentMap[componentType];
    
    if (component) {
      // Simulate async loading
      await new Promise(resolve => setTimeout(resolve, 500));
      return component;
    }
    
    return null;
  },

  renderComponent(component) {
    // In a real implementation, this would use Svelte to render the component
    // For now, we'll create a simple DOM-based component
    
    const container = this.el;
    container.innerHTML = '';
    
    // Create a simple component instance
    const componentInstance = this.createSimpleComponent(component);
    
    // Store reference for cleanup
    this.svelteApp = componentInstance;
    
    // Render the component
    container.appendChild(componentInstance.element);
  },

  createSimpleComponent(componentDef) {
    // Simple component implementation for demonstration
    const element = document.createElement('div');
    element.innerHTML = componentDef.template;
    
    // Simple template engine
    const template = element.innerHTML;
    // Pass the props to the data function
    const data = componentDef.data ? componentDef.data(this.componentProps) : {};
    const methods = componentDef.methods || {};
    
    // Replace template variables
    let rendered = template;
    Object.keys(data).forEach(key => {
      const regex = new RegExp(`{{${key}}}`, 'g');
      rendered = rendered.replace(regex, data[key]);
    });
    
    element.innerHTML = rendered;
    
    // Bind methods
    Object.keys(methods).forEach(methodName => {
      const method = methods[methodName];
      const buttons = element.querySelectorAll(`[onclick]`);
      
      buttons.forEach(button => {
        const clickHandler = button.getAttribute('onclick');
        if (clickHandler && clickHandler.includes(methodName)) {
          button.addEventListener('click', () => {
            const context = { ...data, $el: element };
            method.call(context);
            // Update the data in our component instance
            Object.assign(this.svelteApp.data, context);
            // Re-render with updated data
            this.updateComponentDisplay();
          });
        }
      });
    });
    
    return {
      element,
      data,
      methods,
      $el: element
    };
  },

  updateComponent() {
    if (this.svelteApp) {
      // Update component with new props
      Object.assign(this.svelteApp.data, this.componentProps);
      this.updateComponentDisplay();
    }
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
  },

  showPlaceholder() {
    this.el.innerHTML = `
      <div class="text-center text-gray-500 p-4">
        <p>Component "${this.componentType}" not found</p>
        <p class="text-sm">Check the component registry</p>
      </div>
    `;
  },

  showError(error) {
    this.el.innerHTML = `
      <div class="text-center text-red-500 p-4">
        <p>Error loading component "${this.componentType}"</p>
        <p class="text-sm">${error.message}</p>
      </div>
    `;
  }
};

// Make it available globally
window.SvelteIsland = SvelteIsland;

// Debug logging
console.log('SvelteIsland hook loaded:', window.SvelteIsland);
console.log('Hook keys:', Object.keys(window.SvelteIsland));
