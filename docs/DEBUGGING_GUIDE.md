# Debugging Guide for Svelte Build Pipeline

## Quick Debugging Checklist

### 1. Asset Pipeline Issues

**Problem**: `app.js` not found or hooks not loading
**Quick Fix**:
```bash
# Clean and rebuild assets
mix clean
mix assets.deploy

# Check if hooks are in bundled app.js
grep -i "mudsurfacecomponent\|svelteisland" priv/static/assets/js/app.js
```

**Verify**: `priv/static/assets/js/app.js` should be ~150kb and contain both hooks

### 2. Hook Registration Issues

**Problem**: "Hook not found" errors in browser console
**Quick Fix**:
```bash
# Check hook files exist
ls -la assets/js/*hook.js

# Verify imports in app.js
cat assets/js/app.js | grep -A 5 -B 5 "import.*hook"
```

**Verify**: Both `svelte_island_hook.js` and `mud_surface_hook.js` should be imported

### 3. Component Loading Issues

**Problem**: Components not appearing or not interactive
**Quick Fix**:
```bash
# Check component registry
iex -S mix
iex> MoreWeb.SvelteComponentRegistry.list_components()

# Check LiveView assigns
# Look at browser network tab for errors
```

**Verify**: Components should be listed as "Available" in registry

### 4. Build System Issues

**Problem**: Svelte components not building
**Quick Fix**:
```bash
cd assets/svelte
npm run build:world-scene
npm run build:world-chat
# etc.
```

**Verify**: Components should build without errors

## Common Error Messages & Solutions

### "app.js not found"
- **Cause**: Asset pipeline not building
- **Solution**: `mix assets.deploy`

### "Hook not found for [HookName]"
- **Cause**: Hook not properly imported or registered
- **Solution**: Check import statements and rebuild assets

### "Component not loading"
- **Cause**: Component not built or registry issue
- **Solution**: Build component and check registry

### "TypeScript compilation failed"
- **Cause**: Svelte 5 compatibility or type issues
- **Solution**: Check Svelte version and TypeScript config

## Browser Console Debugging

### Check Hook Registration
```javascript
// In browser console
console.log('Hooks:', window.LiveSocket.hooks);
console.log('Available hooks:', {
  SvelteIsland: window.SvelteIsland,
  MudSurfaceComponent: window.MudSurfaceComponent
});
```

### Check Component State
```javascript
// Check if components are mounted
document.querySelectorAll('[data-component-type]').forEach(el => {
  console.log('Component:', el.dataset.componentType, el);
});

// Check if hooks are attached
document.querySelectorAll('.mud-component').forEach(el => {
  console.log('Hook:', el.__mudHook);
});
```

### Test Hook Methods
```javascript
// Test drag and drop
const component = document.querySelector('.mud-component');
if (component && component.__mudHook) {
  console.log('Component position:', component.__mudHook.componentPosition);
  console.log('Component size:', component.__mudHook.componentSize);
}
```

## Network Tab Debugging

1. **Open Developer Tools** → Network tab
2. **Refresh page** and look for:
   - `app.js` loading successfully (200 status)
   - Any 404 errors for missing assets
   - WebSocket connections for LiveView

## LiveView Debugging

### Check LiveView State
```elixir
# In IEx
iex> MoreWeb.SvelteComponentRegistry.list_components()
iex> MoreWeb.SvelteComponentRegistry.get_build_status()
```

### Check LiveView Events
```elixir
# In browser console, look for LiveView events
# Add component, check network tab for LiveView requests
```

## File Structure Verification

```bash
# Check all required files exist
ls -la assets/js/
ls -la assets/svelte/components/
ls -la priv/static/assets/js/

# Verify file contents
head -20 assets/js/app.js
head -20 assets/js/svelte_island_hook.js
head -20 assets/js/mud_surface_hook.js
```

## Quick Recovery Steps

### 1. Full Reset
```bash
# Stop server, clean everything, restart
mix phx.server stop
mix clean
mix deps.get
mix assets.deploy
mix phx.server
```

### 2. Asset Rebuild
```bash
# Just rebuild assets
mix assets.deploy
```

### 3. Component Rebuild
```bash
# Rebuild Svelte components
cd assets/svelte
npm run build:all
```

## Performance Monitoring

### Check Asset Sizes
```bash
# Monitor asset sizes
ls -lh priv/static/assets/js/
ls -lh priv/static/assets/css/
```

### Check Build Times
```bash
# Monitor build performance
time mix assets.deploy
time npm run build:all
```

## Development vs Production

### Development Mode
- Assets rebuild automatically
- Hooks load from source files
- Hot reload enabled

### Production Mode
- Assets must be pre-built
- Hooks bundled in app.js
- No hot reload

## When to Seek Help

**Seek help if**:
- Assets won't build after multiple attempts
- Hooks consistently fail to load
- Components won't render despite correct setup
- Performance issues persist after optimization

**Provide when seeking help**:
- Error messages from console
- Asset pipeline output
- Component registry status
- Browser console logs
- File structure listing
