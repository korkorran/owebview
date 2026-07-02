// The bindings exposed from OCaml (see hello.ml) are available as
// window.add(...) and window.os_type(), each returning a Promise.

const out = document.querySelector("#out");

const show = (value) => {
  out.textContent = value;
};

document
  .querySelector("#btn-add")
  .addEventListener("click", () => add(20, 22).then(show));

document
  .querySelector("#btn-os")
  .addEventListener("click", () => os_type().then(show));
