// A simple D3.js bar chart, rendered entirely in the page — no OCaml binding.
// Single series, so the title names it and no legend is needed.

const data = [
  { label: "Jan", value: 42 },
  { label: "Feb", value: 55 },
  { label: "Mar", value: 39 },
  { label: "Apr", value: 71 },
  { label: "May", value: 63 },
  { label: "Jun", value: 88 },
  { label: "Jul", value: 74 },
];

const tooltip = document.getElementById("tooltip");

// Bar with a square base and a 4px rounded top (the data end sits on the
// baseline; only the value end is rounded).
function topRoundedBar(x, y, w, h, r) {
  const rr = Math.max(0, Math.min(r, w / 2, h));
  return (
    `M${x},${y + h}` +
    `L${x},${y + rr}` +
    `Q${x},${y} ${x + rr},${y}` +
    `L${x + w - rr},${y}` +
    `Q${x + w},${y} ${x + w},${y + rr}` +
    `L${x + w},${y + h}Z`
  );
}

function draw() {
  const container = document.getElementById("chart");
  container.innerHTML = ""; // clear on (re)draw

  const margin = { top: 12, right: 14, bottom: 30, left: 42 };
  const width = Math.max(320, container.clientWidth);
  const height = 360;
  const innerW = width - margin.left - margin.right;
  const innerH = height - margin.top - margin.bottom;

  const x = d3
    .scaleBand()
    .domain(data.map((d) => d.label))
    .range([0, innerW])
    .padding(0.22);

  const y = d3
    .scaleLinear()
    .domain([0, d3.max(data, (d) => d.value)])
    .nice()
    .range([innerH, 0]);

  const svg = d3
    .select(container)
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", `0 0 ${width} ${height}`);

  const g = svg
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  // Recessive horizontal gridlines.
  g.append("g")
    .attr("class", "grid")
    .call(d3.axisLeft(y).ticks(5).tickSize(-innerW).tickFormat(""));

  // Axes.
  g.append("g")
    .attr("class", "axis axis-y")
    .call(d3.axisLeft(y).ticks(5).tickSize(0).tickPadding(8));

  g.append("g")
    .attr("class", "axis axis-x")
    .attr("transform", `translate(0,${innerH})`)
    .call(d3.axisBottom(x).tickSize(0).tickPadding(8));

  // Bars.
  g.selectAll(".bar")
    .data(data)
    .join("path")
    .attr("class", "bar")
    .attr("d", (d) =>
      topRoundedBar(x(d.label), y(d.value), x.bandwidth(), innerH - y(d.value), 4)
    )
    .on("pointerenter pointermove", (event, d) => {
      tooltip.innerHTML = `${d.label} &middot; <b>${d.value}</b>`;
      tooltip.style.left = event.clientX + "px";
      tooltip.style.top = event.clientY + "px";
      tooltip.hidden = false;
    })
    .on("pointerleave", () => {
      tooltip.hidden = true;
    });
}

draw();
window.addEventListener("resize", draw);
