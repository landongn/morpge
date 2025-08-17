# Svelte Components for More MUD

This directory contains Svelte components that can be dynamically loaded into Phoenix LiveView as "islands".

## Architecture

The Svelte islands approach allows us to:
- Develop 3D components independently using Svelte
- Hot-reload components during development
- Dynamically inject components into LiveView at runtime
- Maintain separation of concerns between UI logic and game state

## Components

### Available Components

1. **Hello World** (`hello-world/`)
   - Simple text component with update functionality
   - Demonstrates basic props and event handling

2. **Counter** (`counter/`)
   - Interactive counter with increment/decrement/reset
   - Shows how to manage component state

3. **3D Cube** (`3d-cube/`)
   - Three.js-powered 3D cube with rotation
   - Demonstrates 3D graphics integration

### Component Structure

Each component follows this structure:
```
component-name/
├── index.svelte          # Main component file
├── package.json          # Component-specific dependencies (optional)
└── README.md            # Component documentation (optional)
```

## Development

### Prerequisites

```bash
cd assets/svelte
npm install
```

### Building Components

Build a specific component:
```bash
npm run build:component hello-world
```

Build all components:
```bash
npm run build:all
```

### Development Mode

Start development server with hot reload:
```bash
npm run dev
```

## Integration with Phoenix

### LiveView Integration

Components are loaded via the `SvelteIsland` hook:

```heex
<div id="svelte-component-123" 
     phx-hook="SvelteIsland"
     data-component-type="hello-world"
     data-component-props={Jason.encode!(%{message: "Hello!"})}>
</div>
```

### Component Registry

The `MoreWeb.SvelteComponentRegistry` manages:
- Available components
- Build status
- Hot reloading
- Component metadata

### Dynamic Loading

Components can be added/removed at runtime:
- LiveView controls component lifecycle
- Svelte handles rendering and interactivity
- Props are passed from LiveView to Svelte

## Build Pipeline

### Individual Component Builds

Each component is built independently using Vite:
- ES module output
- Tree-shaking for optimal bundle size
- External Svelte dependency

### Hot Reloading

In development mode:
- File watchers monitor component changes
- Automatic rebuilds trigger LiveView updates
- Components reload without page refresh

## Future Enhancements

1. **Component Marketplace**: Registry of community components
2. **Dynamic Props**: LiveView-driven component configuration
3. **Performance Monitoring**: Bundle size and render time tracking
4. **TypeScript Support**: Full type safety for component props
5. **Testing Framework**: Component unit and integration tests

## Troubleshooting

### Common Issues

1. **Component not loading**: Check browser console for errors
2. **Build failures**: Ensure all dependencies are installed
3. **Hot reload not working**: Verify file watchers are active
4. **3D not rendering**: Check WebGL support and Three.js loading

### Debug Mode

Enable debug logging:
```javascript
// In browser console
window.liveSocket.enableDebug()
```

## Contributing

1. Create new component in `components/` directory
2. Follow existing component structure
3. Add build configuration to `build-component.js`
4. Test integration with LiveView
5. Update documentation
