# Quarterly Goal Plan

A personal web app for planning a quarter around your long-term goals and scoring
yourself week by week. Built with plain HTML, CSS, and JavaScript — no build step,
no dependencies, no backend.

## How the plan is structured

- **Long-term vision** — the north-star statement everything else serves.
- **Goal areas** — e.g. Healthy Lifestyle, Strong Relationships, Mental Toolkit,
  Multiple Assets, Retire at 45, Multiple Languages. Each goal records *why it
  matters* (your emotional connection to it).
- **Weekly habits** — each goal has measurable habits with a weekly target
  (e.g. Workout 7 days, Phone calls 2, Creative work 2 hours, Reading 30 minutes).
- **Weekly scores** — each week you log what you actually did. A habit scores
  `logged / target` (capped at 100%), a goal scores the average of its habits,
  and the week scores the average of all goals.

## Features

- **Dashboard** — quarter score, latest/best week, and per-goal averages at a glance.
- **My Plan** — edit your vision, goal areas, whys, habits, and weekly targets.
  Plan settings let you rename the quarter and change the number of weeks (default 13).
- **Weekly Tracker** — pick a week, type in your numbers, and watch the goal and
  week percentages update live. Scores save automatically as you type.
- **Progress** — a bar chart of weekly scores across the quarter plus a full
  color-coded score sheet (habits × weeks), with a Print / PDF button.

## Data

Everything is stored in your browser's `localStorage` — nothing leaves your machine.

- **Export JSON** downloads a backup of the whole plan.
- **Import JSON** restores a backup (or moves your plan to another browser/device).
- **Reset to starter plan** restores the seeded plan and Week 1 scores.

## Running it

Open `index.html` directly in a browser, or serve the folder:

```sh
python3 -m http.server 8000
# then visit http://localhost:8000
```

It also works as-is on any static host (GitHub Pages, Netlify, etc.).
