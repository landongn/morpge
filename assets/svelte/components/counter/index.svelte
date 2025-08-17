<script>
  export let initial_value = 0;
  export let step = 1;

  let count = initial_value;

  function increment() {
    count += step;
  }

  function decrement() {
    count -= step;
  }

  function reset() {
    count = initial_value;
  }
</script>

<div class="p-4 bg-green-100 rounded-lg border border-green-300">
  <h3 class="text-lg font-semibold text-green-800 mb-2">Counter Component</h3>
  <div class="flex items-center space-x-4 mb-3">
    <button class="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600" on:click={decrement}> - </button>
    <span class="text-2xl font-bold text-green-700">{count}</span>
    <button class="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600" on:click={increment}> + </button>
  </div>
  <div class="flex space-x-2">
    <button class="px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700 text-sm" on:click={reset}>
      Reset
    </button>
  </div>
  <p class="text-sm text-green-600 mt-2">Step: {step}</p>
</div>

<style>
  button {
    transition: all 0.2s;
  }

  button:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }
</style>
