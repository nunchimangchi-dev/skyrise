const STATUS_LABEL = {
  done: "Done",
  "in-progress": "In progress",
  todo: "To do",
  blocked: "Blocked",
};

function badge(status) {
  const label = STATUS_LABEL[status] || status;
  return `<span class="badge ${status}"><span class="dot"></span>${label}</span>`;
}

function fmtDate(iso) {
  const d = new Date(iso);
  return d.toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

function countSteps(phases) {
  let done = 0, total = 0;
  for (const p of phases) {
    for (const s of p.steps) {
      total++;
      if (s.status === "done") done++;
    }
  }
  return { done, total };
}

function render(data) {
  const { meta, hosts, phases, decisions, updated } = data;
  const { done, total } = countSteps(phases);
  const pct = total ? Math.round((done / total) * 100) : 0;
  const phasesDone = phases.filter((p) => p.status === "done").length;

  document.querySelector(".meta-line").innerHTML =
    `${meta.host} · ${meta.host_ip} · tailnet ${meta.tailscale_ip}<br>` +
    `Last updated ${fmtDate(updated)}`;

  document.querySelector(".stat-row").innerHTML = `
    <div class="stat-tile">
      <div class="value">${pct}%</div>
      <div class="label">Overall progress</div>
      <div class="progress-track"><div class="progress-fill" style="width:${pct}%"></div></div>
    </div>
    <div class="stat-tile">
      <div class="value">${phasesDone} / ${phases.length}</div>
      <div class="label">Phases complete</div>
    </div>
    <div class="stat-tile">
      <div class="value">${done} / ${total}</div>
      <div class="label">Steps complete</div>
    </div>
    <div class="stat-tile">
      <div class="value">${hosts.filter((h) => h.status === "done").length} / ${hosts.length}</div>
      <div class="label">Hosts configured</div>
    </div>
  `;

  document.querySelector(".hosts").innerHTML = hosts
    .map(
      (h) =>
        `<div class="host-chip">${badge(h.status)}<span>${h.name} — ${h.role}</span></div>`
    )
    .join("");

  document.querySelector(".phase-list").innerHTML = phases
    .map((p, i) => {
      const stepsDone = p.steps.filter((s) => s.status === "done").length;
      return `
      <div class="phase-card" data-idx="${i}">
        <div class="phase-head">
          <div class="phase-head-left">
            <span class="chevron">&#9656;</span>
            <div>
              <div class="phase-title">${p.title}</div>
              <p class="phase-summary">${p.summary}</p>
            </div>
          </div>
          <div style="display:flex;align-items:center;gap:10px;">
            <span style="font-size:0.78rem;color:var(--text-muted);">${stepsDone}/${p.steps.length}</span>
            ${badge(p.status)}
          </div>
        </div>
        <ul class="step-list">
          ${p.steps
            .map(
              (s) =>
                `<li class="${s.status === "done" ? "done" : ""}">${
                  s.status === "done" ? "&#10003;" : "&#9675;"
                } ${s.label}</li>`
            )
            .join("")}
        </ul>
      </div>`;
    })
    .join("");

  document.querySelectorAll(".phase-card").forEach((card) => {
    card.querySelector(".phase-head").addEventListener("click", () => {
      card.classList.toggle("open");
    });
  });
  // open the first non-done phase by default
  const firstOpen = document.querySelector(
    ".phase-card:not(:has(.badge.done))"
  );
  (firstOpen || document.querySelector(".phase-card"))?.classList.add("open");

  document.querySelector(".learn-list").innerHTML = phases
    .filter((p) => p.learn)
    .map(
      (p) => `
      <a class="learn-card" href="${p.learn}">
        <div class="learn-title">${p.title}</div>
        <p class="learn-summary">${p.summary}</p>
        <span class="learn-link">What is this, and why? &rarr;</span>
      </a>`
    )
    .join("");

  document.querySelector(".decisions").innerHTML = decisions
    .map(
      (d) => `
      <div class="decision">
        <div class="d-title">${d.title}</div>
        <div class="d-why"><b>Why —</b> ${d.why}</div>
      </div>`
    )
    .join("");

  document.querySelector(".repo-link").href = meta.repo;
  document.querySelector(".repo-link").textContent = meta.repo.replace(
    "https://",
    ""
  );
}

fetch("data/progress.json")
  .then((r) => r.json())
  .then(render)
  .catch((err) => {
    document.querySelector(".wrap").innerHTML =
      `<p style="color:#d03b3b">Failed to load progress.json: ${err}</p>`;
  });
