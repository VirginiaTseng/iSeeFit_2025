<script>
    let count = 0;
    function increment() {
        count += 1;
    }
</script>

<main>
    <h1>Hello, Svelte!</h1>
    <p>Count: {count}</p>
    <button on:click={increment}>Click me</button>
</main>

<style>
    main {
        text-align: center;
        font-family: Arial, sans-serif;
    }
    button {
        padding: 8px 16px;
        margin-top: 10px;
        cursor: pointer;
    }
</style>
