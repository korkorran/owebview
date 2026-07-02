// Count the seconds elapsed since the page (window) was launched. Everything
// happens in the browser — no OCaml binding is involved.

const start = Date.now();
const elapsed = document.getElementById("elapsed");

function tick() {
  const seconds = Math.floor((Date.now() - start) / 1000);
  elapsed.textContent = seconds;
}

tick();
// Update a few times per second so the display flips promptly on each new
// second, while the value itself is always derived from the start time.
setInterval(tick, 200);
