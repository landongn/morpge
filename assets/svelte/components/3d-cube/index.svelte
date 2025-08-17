<script>
  import { onDestroy, onMount } from "svelte";
  import * as THREE from "three";

  export let size = 1.0;
  export let color = "#ff6b6b";
  export let rotation_speed = 0.01;

  let container;
  let scene, camera, renderer, cube;
  let animationId;

  onMount(() => {
    initThreeJS();
    animate();
  });

  onDestroy(() => {
    if (animationId) {
      cancelAnimationFrame(animationId);
    }
    if (renderer) {
      renderer.dispose();
    }
  });

  function initThreeJS() {
    // Scene
    scene = new THREE.Scene();

    // Camera
    camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.z = 5;

    // Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setClearColor(0x000000, 0);
    container.appendChild(renderer.domElement);

    // Cube
    const geometry = new THREE.BoxGeometry(size, size, size);
    const material = new THREE.MeshBasicMaterial({ color: color, wireframe: false });
    cube = new THREE.Mesh(geometry, material);
    scene.add(cube);

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(10, 10, 5);
    scene.add(directionalLight);

    // Handle resize
    window.addEventListener("resize", onWindowResize);
  }

  function animate() {
    animationId = requestAnimationFrame(animate);

    if (cube) {
      cube.rotation.x += rotation_speed;
      cube.rotation.y += rotation_speed;
    }

    renderer.render(scene, camera);
  }

  function onWindowResize() {
    if (camera && renderer && container) {
      camera.aspect = container.clientWidth / container.clientHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(container.clientWidth, container.clientHeight);
    }
  }

  function rotate() {
    if (cube) {
      cube.rotation.x += Math.PI / 4;
      cube.rotation.y += Math.PI / 4;
    }
  }

  function toggleWireframe() {
    if (cube && cube.material) {
      cube.material.wireframe = !cube.material.wireframe;
    }
  }
</script>

<div class="p-4 bg-purple-100 rounded-lg border border-purple-300">
  <h3 class="text-lg font-semibold text-purple-800 mb-2">3D Cube Component</h3>

  <div class="mb-3">
    <div bind:this={container} class="w-64 h-64 bg-gray-900 rounded-lg overflow-hidden">
      <!-- Three.js will render here -->
    </div>
  </div>

  <div class="flex space-x-2 mb-3">
    <button class="px-3 py-1 bg-purple-500 text-white rounded hover:bg-purple-600" on:click={rotate}>
      Rotate 45°
    </button>
    <button class="px-3 py-1 bg-purple-600 text-white rounded hover:bg-purple-700" on:click={toggleWireframe}>
      Toggle Wireframe
    </button>
  </div>

  <div class="text-sm text-purple-600 space-y-1">
    <p>Size: {size}</p>
    <p>Color: {color}</p>
    <p>Rotation Speed: {rotation_speed}</p>
  </div>
</div>

<style>
  button {
    transition: all 0.2s;
  }

  button:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }

  canvas {
    display: block;
    width: 100% !important;
    height: 100% !important;
  }
</style>
