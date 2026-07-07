// Seconds counter with pause/resume. start() and stop() are exposed on window
// so the OCaml side can call them via Webview.eval (see timer.ml) — no binding
// is involved. Elapsed time is always derived from the accumulated run time,
// so it never drifts and it resumes where it was paused.

const elapsedEl = document.getElementById("elapsed");

let running = true;
let segmentStart = Date.now(); // when the current running segment began
let accumulatedMs = 0; // time already counted during previous segments

function currentMs() {
  return accumulatedMs + (running ? Date.now() - segmentStart : 0);
}

function render() {
  elapsedEl.textContent = Math.floor(currentMs() / 1000);
  document.body.classList.toggle("paused", !running);
}

function stop() {
  if (!running) return;
  accumulatedMs += Date.now() - segmentStart;
  running = false;
  render();
}

function start() {
  if (running) return;
  segmentStart = Date.now();
  running = true;
  render();
}

// Expose to the OCaml side (called through Webview.eval).
window.start = start;
window.stop = stop;

// "print time in console" button: call the OCaml binding print_time(seconds),
// which writes the elapsed time to the main process's console.
document.getElementById("print").addEventListener("click", () => {
  print_time(Math.floor(currentMs() / 1000));
});

render();
setInterval(render, 200);
