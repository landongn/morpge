<script>
  export let message = "Hello from Svelte Island!";
  export let color = "blue";

  let count = 0;

  function updateMessage() {
    count++;
    message = `Updated ${count} times at ${new Date().toLocaleTimeString()}`;
  }
</script>

<div class="p-4 bg-blue-100 rounded-lg border border-blue-300">
  <h3 class="text-lg font-semibold text-blue-800 mb-2">Hello World Component</h3>
  <p class="text-blue-700">{message}</p>
  <div class="mt-3">
    <button class="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600" on:click={updateMessage}>
      Update Message
    </button>
  </div>
</div>

<style>
  button {
    transition: background-color 0.2s;
  }

  button:hover {
    transform: translateY(-1px);
  }
</style>
