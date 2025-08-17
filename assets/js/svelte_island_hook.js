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
    // Cleanup Svelte app
    if (this.svelteApp) {
      this.svelteApp.$destroy();
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
                on:click={() => this.updateMessage()}>
                Update Message
              </button>
            </div>
          </div>
        `,
        data() {
          return {
            message: this.props.message || 'Hello from Svelte Island!'
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
                on:click={() => this.decrement()}>
                -
              </button>
              <span class="text-2xl font-bold text-green-700">{{count}}</span>
              <button 
                class="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600"
                on:click={() => this.increment()}>
                +
              </button>
            </div>
            <p class="text-sm text-green-600 mt-2">Step: {{step}}</p>
          </div>
        `,
        data() {
          return {
            count: this.props.initial_value || 0,
            step: this.props.step || 1
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
              on:click={() => this.rotate()}>
              Rotate
            </button>
          </div>
        `,
        data() {
          return {
            size: this.props.size || 1.0,
            color: this.props.color || '#ff6b6b',
            rotation: 0
          };
        },
        methods: {
          rotate() {
            this.rotation += 45;
            this.$el.style.transform = `rotate(${this.rotation}deg)`;
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
    const data = componentDef.data ? componentDef.data.call(this) : {};
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
      const buttons = element.querySelectorAll(`[on\\:click]`);
      
      buttons.forEach(button => {
        const clickHandler = button.getAttribute('on:click');
        if (clickHandler.includes(methodName)) {
          button.addEventListener('click', () => {
            method.call({ ...data, $el: element });
            // Re-render after method call
            this.updateComponent();
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
      this.renderComponent(this.loadComponent(this.componentType));
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
