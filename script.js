'use strict';

/* ---------------------------------------------------------------------------
 * Quarterly Goal Plan
 * Local-first: the whole plan lives in localStorage. Export/Import JSON to
 * back it up or move it between browsers.
 * ------------------------------------------------------------------------- */

const STORAGE_KEY = 'quarterlyGoalPlan.v1';

function defaultPlan() {
    return {
        owner: 'Jules',
        quarter: 'Q3 2026',
        weeksInQuarter: 13,
        vision:
            'I want to be living a healthy lifestyle that allows me to be fully present ' +
            'in my goal of having a strong relationship with my family, friends, and God; ' +
            'in my goal of having a toolkit of techniques at my disposal to deal with my emotions; ' +
            'in my goal of having multiple assets that allow me to exercise my creativity and ' +
            'drive enough income for me to have the option to retire at 45 years old; ' +
            'and to speak multiple languages.',
        goals: [
            {
                id: 'healthy',
                emoji: '💪',
                name: 'Healthy Lifestyle',
                why: "That's the base of everything. In whatever I try to do, I need to make sure " +
                    "I'm healthy — physically, mentally, and spiritually.",
                habits: [
                    { id: 'workout', name: 'Workout', unit: 'days', target: 7 },
                    { id: 'vitamins', name: 'Take vitamins', unit: 'days', target: 7 },
                    { id: 'cleanEating', name: 'Clean eating', unit: 'days', target: 7 },
                ],
            },
            {
                id: 'relationships',
                emoji: '❤️',
                name: 'Strong Relationships',
                why: "You only get one family in this life, and I want to help take care of them the " +
                    'same way they’ve taken care of me. Beyond family, having someone choose to spend ' +
                    'time with you is something special — I want to do my part to be a good friend. ' +
                    'And I want a strong relationship with God because my faith is my foundation.',
                habits: [
                    { id: 'calls', name: 'Phone calls', unit: 'calls', target: 2 },
                    { id: 'fellowship', name: 'Days with fellowship', unit: 'days', target: 1 },
                ],
            },
            {
                id: 'toolkit',
                emoji: '🧘',
                name: 'Mental Toolkit',
                why: 'Relying on a substance builds addiction, and I don’t want to be addicted to ' +
                    'anything that can be replaced with something I can do on my own to feel the same way. ' +
                    'I want a proper routine to deal with my issues.',
                habits: [
                    { id: 'breathing', name: '5-min breathing', unit: 'days', target: 7 },
                ],
            },
            {
                id: 'assets',
                emoji: '🎨',
                name: 'Multiple Assets',
                why: 'It’s a very special thing to create something in this world that you can share ' +
                    'with others — something you truly dove deep into your creativity bag to make. ' +
                    'Money-maker or just for fun, I want to create and acquire assets.',
                habits: [
                    { id: 'creative', name: 'Creative work', unit: 'hours', target: 2 },
                ],
            },
            {
                id: 'retire45',
                emoji: '🏖️',
                name: 'Retire at 45',
                why: 'There’s a lot I want to do in life that requires time, and the biggest time ' +
                    'consumer is my job. Waking up every day with the energy to decide what I want to do ' +
                    'in pursuit of my goals sounds way too exciting. In my 40s I’ll still have the ' +
                    'energy to chase my dreams — with twice the time.',
                habits: [
                    { id: 'reading', name: 'Reading', unit: 'minutes', target: 30 },
                ],
            },
            {
                id: 'languages',
                emoji: '🗣️',
                name: 'Multiple Languages',
                why: 'I want to speak Haitian Creole and French to deeply connect with my culture and ' +
                    'family, and pass the language on to my kids. I want to travel back to Haiti with my ' +
                    'family and connect with the people there on a deep level. French opens up even more ' +
                    'family connections and the chance to live freely where English isn’t the main language.',
                habits: [
                    { id: 'classes', name: 'Language classes', unit: 'classes', target: 2 },
                ],
            },
        ],
        scores: {
            '1': {
                workout: 3,
                vitamins: 6,
                cleanEating: 6,
                calls: 2,
                fellowship: 0.5,
                breathing: 6,
                creative: 2,
                reading: 30,
                classes: 2,
            },
        },
    };
}

/* ----------------------------- State ------------------------------------ */

function newId(prefix) {
    return prefix + '-' + Math.random().toString(36).slice(2, 8) + Date.now().toString(36);
}

function normalizePlan(p) {
    const d = defaultPlan();
    const weeks = Math.round(Number(p.weeksInQuarter));
    return {
        owner: typeof p.owner === 'string' && p.owner.trim() ? p.owner : d.owner,
        quarter: typeof p.quarter === 'string' && p.quarter.trim() ? p.quarter : d.quarter,
        weeksInQuarter: weeks >= 1 ? Math.min(weeks, 27) : d.weeksInQuarter,
        vision: typeof p.vision === 'string' ? p.vision : '',
        goals: p.goals.map((g) => ({
            id: String(g.id || newId('g')),
            emoji: typeof g.emoji === 'string' ? g.emoji : '🎯',
            name: String(g.name || 'Untitled goal'),
            why: typeof g.why === 'string' ? g.why : '',
            habits: Array.isArray(g.habits)
                ? g.habits.map((h) => ({
                    id: String(h.id || newId('h')),
                    name: String(h.name || 'Habit'),
                    unit: String(h.unit || 'times'),
                    target: Number(h.target) > 0 ? Number(h.target) : 1,
                }))
                : [],
        })),
        scores: p.scores && typeof p.scores === 'object' ? p.scores : {},
    };
}

function loadPlan() {
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (raw) {
            const p = JSON.parse(raw);
            if (p && Array.isArray(p.goals)) return normalizePlan(p);
        }
    } catch (err) {
        console.warn('Could not load saved plan, starting fresh.', err);
    }
    return defaultPlan();
}

function save() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(plan));
}

let plan = loadPlan();
const ui = {
    tab: 'dashboard',
    week: 1,
    editingVision: false,
    editingGoalId: null,
    draftGoal: null,
};

/* ----------------------------- Scoring ---------------------------------- */

function weekScores(week) {
    return plan.scores[String(week)] || {};
}

function habitPct(habit, value) {
    if (value === undefined || value === null || isNaN(value) || !habit.target) return null;
    return Math.min(value / habit.target, 1);
}

function avg(list) {
    return list.length ? list.reduce((a, b) => a + b, 0) / list.length : null;
}

function goalPct(goal, week) {
    const scores = weekScores(week);
    return avg(goal.habits.map((h) => habitPct(h, scores[h.id])).filter((p) => p != null));
}

function weekPct(week) {
    return avg(plan.goals.map((g) => goalPct(g, week)).filter((p) => p != null));
}

function loggedWeeks() {
    const weeks = [];
    for (let w = 1; w <= plan.weeksInQuarter; w++) {
        if (weekPct(w) != null) weeks.push(w);
    }
    return weeks;
}

function quarterPct() {
    return avg(loggedWeeks().map((w) => weekPct(w)));
}

function goalQuarterPct(goal) {
    const pcts = [];
    for (let w = 1; w <= plan.weeksInQuarter; w++) {
        const p = goalPct(goal, w);
        if (p != null) pcts.push(p);
    }
    return avg(pcts);
}

function nextWeekToLog() {
    for (let w = 1; w <= plan.weeksInQuarter; w++) {
        if (weekPct(w) == null) return w;
    }
    return plan.weeksInQuarter;
}

/* ----------------------------- Formatting ------------------------------- */

function esc(s) {
    return String(s ?? '').replace(/[&<>"']/g, (c) => (
        { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
    ));
}

function fmtPct(p) {
    return p == null ? '—' : Math.round(p * 100) + '%';
}

function pctWidth(p) {
    return p == null ? 0 : Math.round(p * 100);
}

function fmtNum(n) {
    return n == null || isNaN(n) ? '' : String(n);
}

function cellClass(p) {
    if (p == null) return '';
    if (p >= 1) return 'c-full';
    if (p >= 0.7) return 'c-good';
    if (p >= 0.4) return 'c-mid';
    return 'c-low';
}

/* ----------------------------- Rendering -------------------------------- */

function renderAll() {
    document.getElementById('quarterLabel').textContent = `${plan.owner} · ${plan.quarter}`;
    document.querySelectorAll('.tab').forEach((b) => {
        b.classList.toggle('active', b.dataset.tab === ui.tab);
    });
    ['dashboard', 'plan', 'tracker', 'progress'].forEach((name) => {
        document.getElementById(`view-${name}`).classList.toggle('hidden', name !== ui.tab);
    });
    renderDashboard();
    renderPlan();
    renderTracker();
    renderProgress();
}

function renderDashboard() {
    const el = document.getElementById('view-dashboard');
    const logged = loggedWeeks();
    const latest = logged.length ? logged[logged.length - 1] : null;
    let best = null;
    for (const w of logged) {
        const p = weekPct(w);
        if (!best || p > best.p) best = { w, p };
    }

    const goalCards = plan.goals.map((g) => {
        const quarterAvg = goalQuarterPct(g);
        const last = latest != null ? goalPct(g, latest) : null;
        return `
        <article class="card goal-stat">
            <div class="card-head">
                <h4><span class="goal-emoji">${esc(g.emoji)}</span> ${esc(g.name)}</h4>
                <span class="pct-badge">${fmtPct(quarterAvg)}</span>
            </div>
            <div class="meter slim"><div class="meter-fill" style="width:${pctWidth(quarterAvg)}%"></div></div>
            <p class="muted small">${latest != null ? `Week ${latest}: ${fmtPct(last)}` : 'No weeks logged yet'}</p>
        </article>`;
    }).join('');

    el.innerHTML = `
        <section class="card hero">
            <div class="hero-text">
                <h2>Hey ${esc(plan.owner)} 👋</h2>
                <p class="muted">${esc(plan.quarter)} — ${logged.length} of ${plan.weeksInQuarter} weeks logged</p>
            </div>
            <div class="big-stats">
                <div class="big-stat"><span class="big-num">${fmtPct(quarterPct())}</span><span class="big-label">Quarter score</span></div>
                <div class="big-stat"><span class="big-num">${latest != null ? fmtPct(weekPct(latest)) : '—'}</span><span class="big-label">${latest != null ? `Week ${latest}` : 'Latest week'}</span></div>
                <div class="big-stat"><span class="big-num">${best ? fmtPct(best.p) : '—'}</span><span class="big-label">${best ? `Best (W${best.w})` : 'Best week'}</span></div>
            </div>
            <button class="btn btn-primary" data-action="goto-tracker">Log week ${nextWeekToLog()}</button>
        </section>
        <h3 class="section-heading">Goal areas</h3>
        <div class="grid">${goalCards}</div>
        <section class="card vision-card">
            <h3>⭐ North star</h3>
            <p class="vision-text">${esc(plan.vision)}</p>
        </section>`;
}

function goalViewHtml(g) {
    const habits = g.habits.map((h) => `
        <li><span>${esc(h.name)}</span><span class="habit-target">${fmtNum(h.target)} ${esc(h.unit)} / week</span></li>
    `).join('');
    return `
    <article class="card goal-card">
        <header class="card-head">
            <h3><span class="goal-emoji">${esc(g.emoji)}</span> ${esc(g.name)}</h3>
            <button class="btn btn-ghost" data-action="edit-goal" data-goal="${esc(g.id)}">Edit</button>
        </header>
        ${g.why ? `<p class="why">${esc(g.why)}</p>` : ''}
        <h4 class="habit-heading">Weekly habits</h4>
        <ul class="habit-list">${habits || '<li class="muted">No habits yet — hit Edit to add some.</li>'}</ul>
    </article>`;
}

function goalEditHtml(d) {
    const habitRows = d.habits.map((h) => `
        <div class="habit-edit-row">
            <input type="text" data-draft-habit="${esc(h.id)}" data-field="name" value="${esc(h.name)}" placeholder="Habit (e.g. Workout)">
            <input type="number" data-draft-habit="${esc(h.id)}" data-field="target" value="${fmtNum(h.target)}" min="0.5" step="0.5" title="Weekly target">
            <input type="text" data-draft-habit="${esc(h.id)}" data-field="unit" value="${esc(h.unit)}" list="unitOptions" placeholder="unit">
            <button class="btn btn-ghost danger" data-action="draft-remove-habit" data-habit="${esc(h.id)}" title="Remove habit">✕</button>
        </div>
    `).join('');
    return `
    <article class="card goal-card editing">
        <div class="edit-name-row">
            <label class="emoji-field">Emoji
                <input type="text" data-draft-field="emoji" value="${esc(d.emoji)}" maxlength="4">
            </label>
            <label class="grow">Goal name
                <input type="text" data-draft-field="name" value="${esc(d.name)}" placeholder="e.g. Healthy Lifestyle">
            </label>
        </div>
        <label>Why it matters (your emotional connection)
            <textarea data-draft-field="why" rows="3" placeholder="Why does this goal matter to you?">${esc(d.why)}</textarea>
        </label>
        <h4 class="habit-heading">Weekly habits</h4>
        <div class="habit-edit-rows">${habitRows}</div>
        <button class="btn btn-ghost" data-action="draft-add-habit">+ Add habit</button>
        <div class="btn-row">
            <button class="btn btn-primary" data-action="save-goal">Save goal</button>
            <button class="btn btn-ghost" data-action="cancel-goal">Cancel</button>
            ${d.isNew ? '' : '<button class="btn btn-ghost danger" data-action="delete-goal">Delete goal</button>'}
        </div>
    </article>`;
}

function renderPlan() {
    const el = document.getElementById('view-plan');
    const goalsHtml = plan.goals.map((g) => (
        ui.editingGoalId === g.id && ui.draftGoal ? goalEditHtml(ui.draftGoal) : goalViewHtml(g)
    )).join('');
    const newGoalHtml = ui.draftGoal && ui.draftGoal.isNew ? goalEditHtml(ui.draftGoal) : '';

    el.innerHTML = `
        <section class="card settings-card">
            <h3>Plan settings</h3>
            <div class="settings-grid">
                <label>Name <input type="text" data-setting="owner" value="${esc(plan.owner)}"></label>
                <label>Quarter <input type="text" data-setting="quarter" value="${esc(plan.quarter)}"></label>
                <label>Weeks <input type="number" min="1" max="27" data-setting="weeksInQuarter" value="${plan.weeksInQuarter}"></label>
            </div>
        </section>
        <section class="card vision-card">
            <header class="card-head">
                <h3>⭐ Long-term vision</h3>
                ${ui.editingVision ? '' : '<button class="btn btn-ghost" data-action="edit-vision">Edit</button>'}
            </header>
            ${ui.editingVision
                ? `<textarea id="visionInput" rows="6">${esc(plan.vision)}</textarea>
                   <div class="btn-row">
                       <button class="btn btn-primary" data-action="save-vision">Save</button>
                       <button class="btn btn-ghost" data-action="cancel-vision">Cancel</button>
                   </div>`
                : `<p class="vision-text">${esc(plan.vision)}</p>`}
        </section>
        <header class="section-row">
            <h3 class="section-heading">Goal areas & weekly habits</h3>
            <button class="btn btn-primary" data-action="add-goal">+ Add goal</button>
        </header>
        <div class="goal-list">${goalsHtml}${newGoalHtml}</div>
        <datalist id="unitOptions">
            <option value="days"></option>
            <option value="hours"></option>
            <option value="minutes"></option>
            <option value="calls"></option>
            <option value="classes"></option>
            <option value="sessions"></option>
        </datalist>`;
}

function renderTracker() {
    const el = document.getElementById('view-tracker');
    const wk = ui.week;
    const scores = weekScores(wk);

    const chips = [];
    for (let w = 1; w <= plan.weeksInQuarter; w++) {
        const logged = weekPct(w) != null;
        chips.push(`<button class="chip${w === wk ? ' active' : ''}${logged ? ' logged' : ''}" data-action="select-week" data-week="${w}">W${w}</button>`);
    }

    const goalsHtml = plan.goals.map((g) => {
        const gp = goalPct(g, wk);
        const rows = g.habits.map((h) => {
            const v = scores[h.id];
            return `
            <div class="score-row">
                <label for="score-${esc(h.id)}">${esc(h.name)}</label>
                <div class="score-input">
                    <input id="score-${esc(h.id)}" type="number" inputmode="decimal" min="0" step="0.5"
                        ${h.unit === 'days' ? 'max="7"' : ''} data-score="${esc(h.id)}"
                        value="${v === undefined ? '' : fmtNum(v)}" placeholder="–">
                    <span class="score-target">/ ${fmtNum(h.target)} ${esc(h.unit)}</span>
                </div>
                <span class="pct-mini" id="habitpct-${esc(h.id)}">${fmtPct(habitPct(h, v))}</span>
            </div>`;
        }).join('');
        return `
        <article class="card tracker-goal">
            <header class="card-head">
                <h3><span class="goal-emoji">${esc(g.emoji)}</span> ${esc(g.name)}</h3>
                <span class="pct-badge" id="goalpct-${esc(g.id)}">${fmtPct(gp)}</span>
            </header>
            <div class="meter slim"><div class="meter-fill" id="goalbar-${esc(g.id)}" style="width:${pctWidth(gp)}%"></div></div>
            ${rows || '<p class="muted">No habits in this goal yet.</p>'}
        </article>`;
    }).join('');

    const wp = weekPct(wk);
    el.innerHTML = `
        <section class="card week-picker">
            <h3>Pick a week</h3>
            <div class="chip-row">${chips.join('')}</div>
        </section>
        <section class="card week-summary">
            <header class="card-head">
                <h3>Week ${wk} score</h3>
                <span class="pct-badge big" id="weekpct">${fmtPct(wp)}</span>
            </header>
            <div class="meter"><div class="meter-fill" id="weekbar" style="width:${pctWidth(wp)}%"></div></div>
            <p class="muted small">Scores save automatically. Leave a habit blank if you didn't track it.</p>
            <button class="btn btn-ghost danger" data-action="clear-week">Clear week ${wk}</button>
        </section>
        <div class="grid">${goalsHtml}</div>`;
}

function updateTrackerSummaries() {
    const wk = ui.week;
    const scores = weekScores(wk);
    for (const g of plan.goals) {
        const gp = goalPct(g, wk);
        const badge = document.getElementById(`goalpct-${g.id}`);
        const bar = document.getElementById(`goalbar-${g.id}`);
        if (badge) badge.textContent = fmtPct(gp);
        if (bar) bar.style.width = pctWidth(gp) + '%';
        for (const h of g.habits) {
            const mini = document.getElementById(`habitpct-${h.id}`);
            if (mini) mini.textContent = fmtPct(habitPct(h, scores[h.id]));
        }
    }
    const wp = weekPct(wk);
    const badge = document.getElementById('weekpct');
    const bar = document.getElementById('weekbar');
    if (badge) badge.textContent = fmtPct(wp);
    if (bar) bar.style.width = pctWidth(wp) + '%';
}

function renderProgress() {
    const el = document.getElementById('view-progress');

    const bars = [];
    for (let w = 1; w <= plan.weeksInQuarter; w++) {
        const p = weekPct(w);
        bars.push(`
        <div class="bar-col" title="Week ${w}${p != null ? ` — ${fmtPct(p)}` : ' — not logged'}">
            <div class="bar-track"><div class="bar${p == null ? ' empty' : ''}" style="height:${p != null ? Math.max(pctWidth(p), 4) : 4}%"></div></div>
            <span class="bar-label">${w}</span>
        </div>`);
    }

    const weekTh = [];
    for (let w = 1; w <= plan.weeksInQuarter; w++) weekTh.push(`<th>W${w}</th>`);

    const rows = plan.goals.map((g) => {
        const goalCells = [];
        for (let w = 1; w <= plan.weeksInQuarter; w++) {
            const p = goalPct(g, w);
            goalCells.push(`<td class="${cellClass(p)}">${p != null ? fmtPct(p) : ''}</td>`);
        }
        const habitRows = g.habits.map((h) => {
            const cells = [];
            const pcts = [];
            for (let w = 1; w <= plan.weeksInQuarter; w++) {
                const v = weekScores(w)[h.id];
                const p = habitPct(h, v);
                if (p != null) pcts.push(p);
                cells.push(`<td class="${cellClass(p)}">${v !== undefined ? fmtNum(v) : ''}</td>`);
            }
            return `<tr><th class="habit-name">${esc(h.name)}</th><td class="target-cell">${fmtNum(h.target)} ${esc(h.unit)}</td>${cells.join('')}<td class="avg-cell">${fmtPct(avg(pcts))}</td></tr>`;
        }).join('');
        return `<tr class="goal-row"><th colspan="2">${esc(g.emoji)} ${esc(g.name)}</th>${goalCells.join('')}<td class="avg-cell">${fmtPct(goalQuarterPct(g))}</td></tr>${habitRows}`;
    }).join('');

    el.innerHTML = `
        <section class="card">
            <header class="card-head">
                <h3>Weekly scores across the quarter</h3>
                <span class="pct-badge big">${fmtPct(quarterPct())} avg</span>
            </header>
            <div class="chart">${bars.join('')}</div>
        </section>
        <section class="card">
            <header class="card-head">
                <h3>Score sheet</h3>
                <button class="btn btn-ghost" data-action="print">Print / PDF</button>
            </header>
            <div class="table-wrap">
                <table class="score-table">
                    <thead><tr><th>Habit</th><th>Target</th>${weekTh.join('')}<th>Avg</th></tr></thead>
                    <tbody>${rows}</tbody>
                </table>
            </div>
        </section>`;
}

/* ----------------------------- Actions ---------------------------------- */

function saveDraftGoal() {
    const d = ui.draftGoal;
    if (!d) return;
    const name = d.name.trim();
    if (!name) {
        alert('Give this goal a name first.');
        return;
    }
    const habits = d.habits
        .map((h) => ({
            id: h.id,
            name: String(h.name || '').trim(),
            unit: String(h.unit || '').trim() || 'times',
            target: Math.max(Number(h.target) || 0, 0.5),
        }))
        .filter((h) => h.name);
    const clean = {
        id: d.id,
        emoji: String(d.emoji || '').trim() || '🎯',
        name,
        why: String(d.why || '').trim(),
        habits,
    };
    if (d.isNew) {
        plan.goals.push(clean);
    } else {
        const i = plan.goals.findIndex((g) => g.id === d.id);
        if (i >= 0) plan.goals[i] = clean;
    }
    ui.draftGoal = null;
    ui.editingGoalId = null;
    save();
    renderAll();
}

function exportPlan() {
    const blob = new Blob([JSON.stringify(plan, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `quarterly-goal-plan-${plan.quarter.replace(/\s+/g, '-').toLowerCase()}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
}

document.addEventListener('click', (e) => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const action = btn.dataset.action;

    if (action === 'tab') {
        ui.tab = btn.dataset.tab;
        renderAll();
    } else if (action === 'goto-tracker') {
        ui.tab = 'tracker';
        ui.week = nextWeekToLog();
        renderAll();
    } else if (action === 'select-week') {
        ui.week = Number(btn.dataset.week);
        renderTracker();
    } else if (action === 'clear-week') {
        if (confirm(`Clear all scores for week ${ui.week}?`)) {
            delete plan.scores[String(ui.week)];
            save();
            renderTracker();
        }
    } else if (action === 'edit-vision') {
        ui.editingVision = true;
        renderPlan();
    } else if (action === 'save-vision') {
        plan.vision = document.getElementById('visionInput').value.trim();
        ui.editingVision = false;
        save();
        renderAll();
    } else if (action === 'cancel-vision') {
        ui.editingVision = false;
        renderPlan();
    } else if (action === 'add-goal') {
        ui.draftGoal = {
            id: newId('g'),
            isNew: true,
            emoji: '🎯',
            name: '',
            why: '',
            habits: [{ id: newId('h'), name: '', unit: 'days', target: 7 }],
        };
        ui.editingGoalId = null;
        renderPlan();
    } else if (action === 'edit-goal') {
        const g = plan.goals.find((x) => x.id === btn.dataset.goal);
        if (g) {
            ui.draftGoal = JSON.parse(JSON.stringify(g));
            ui.editingGoalId = g.id;
            renderPlan();
        }
    } else if (action === 'save-goal') {
        saveDraftGoal();
    } else if (action === 'cancel-goal') {
        ui.draftGoal = null;
        ui.editingGoalId = null;
        renderPlan();
    } else if (action === 'delete-goal') {
        const g = plan.goals.find((x) => x.id === ui.editingGoalId);
        if (g && confirm(`Delete "${g.name}" and its logged scores?`)) {
            for (const wk of Object.keys(plan.scores)) {
                for (const h of g.habits) delete plan.scores[wk][h.id];
            }
            plan.goals = plan.goals.filter((x) => x.id !== g.id);
            ui.draftGoal = null;
            ui.editingGoalId = null;
            save();
            renderAll();
        }
    } else if (action === 'draft-add-habit') {
        if (!ui.draftGoal) return;
        ui.draftGoal.habits.push({ id: newId('h'), name: '', unit: 'days', target: 7 });
        renderPlan();
    } else if (action === 'draft-remove-habit') {
        if (!ui.draftGoal) return;
        ui.draftGoal.habits = ui.draftGoal.habits.filter((h) => h.id !== btn.dataset.habit);
        renderPlan();
    } else if (action === 'export') {
        exportPlan();
    } else if (action === 'import') {
        document.getElementById('importFile').click();
    } else if (action === 'reset') {
        if (confirm('Replace your current plan with the starter plan? This cannot be undone.')) {
            plan = defaultPlan();
            ui.week = nextWeekToLog();
            ui.editingGoalId = null;
            ui.draftGoal = null;
            ui.editingVision = false;
            save();
            renderAll();
        }
    } else if (action === 'print') {
        window.print();
    }
});

document.addEventListener('input', (e) => {
    const t = e.target;
    if (t.matches('[data-score]')) {
        const habitId = t.dataset.score;
        const wk = String(ui.week);
        const raw = t.value.trim();
        if (!plan.scores[wk]) plan.scores[wk] = {};
        if (raw === '') {
            delete plan.scores[wk][habitId];
        } else {
            const n = Number(raw);
            if (isFinite(n) && n >= 0) plan.scores[wk][habitId] = n;
        }
        if (!Object.keys(plan.scores[wk]).length) delete plan.scores[wk];
        save();
        updateTrackerSummaries();
    } else if (t.matches('[data-draft-field]') && ui.draftGoal) {
        ui.draftGoal[t.dataset.draftField] = t.value;
    } else if (t.matches('[data-draft-habit]') && ui.draftGoal) {
        const h = ui.draftGoal.habits.find((x) => x.id === t.dataset.draftHabit);
        if (h) h[t.dataset.field] = t.dataset.field === 'target' ? Number(t.value) : t.value;
    }
});

document.addEventListener('change', (e) => {
    const t = e.target;
    if (t.matches('[data-setting]')) {
        const key = t.dataset.setting;
        if (key === 'weeksInQuarter') {
            const n = Math.round(Number(t.value));
            plan.weeksInQuarter = isFinite(n) && n >= 1 ? Math.min(n, 27) : 13;
            if (ui.week > plan.weeksInQuarter) ui.week = plan.weeksInQuarter;
        } else if (t.value.trim()) {
            plan[key] = t.value.trim();
        }
        save();
        renderAll();
    } else if (t.id === 'importFile') {
        const file = t.files && t.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = () => {
            try {
                const p = JSON.parse(reader.result);
                if (!p || !Array.isArray(p.goals) || typeof p.scores !== 'object') {
                    throw new Error('unexpected shape');
                }
                plan = normalizePlan(p);
                ui.week = nextWeekToLog();
                ui.editingGoalId = null;
                ui.draftGoal = null;
                save();
                renderAll();
            } catch (err) {
                alert("That file doesn't look like an exported plan.");
            }
            t.value = '';
        };
        reader.readAsText(file);
    }
});

/* ----------------------------- Init ------------------------------------- */

ui.week = nextWeekToLog();
renderAll();
