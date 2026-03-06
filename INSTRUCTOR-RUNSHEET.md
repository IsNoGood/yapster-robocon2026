---
marp: true
theme: robocon
paginate: true
html: true
footer: 'RoboCon 2026 | Agentic Coding with Robot Framework'
---

<style>
section {
  font-size: 1.25em;
  line-height: 1.3;
  padding-top: 70px;
}
section h1 {
  font-size: 2.5em;
  margin-bottom: 0.5em;
  margin-top: 0;
}
section h2 {
  font-size: 2em;
  margin-bottom: 0.35em;
  margin-top: 0;
}
section h3 {
  font-size: 1.45em;
  margin-bottom: 0.2em;
  margin-top: 0.3em;
}
section ul {
  margin-top: 0;
  margin-bottom: 0.55em;
}
section p {
  margin-top: 0;
  margin-bottom: 0;
}
section li {
  margin-bottom: 0.12em;
}
section .title-with-cursor {
  display: inline-flex;
  align-items: baseline;
  gap: 0.16em;
}
section .title-cursor {
  width: 0.4em;
  height: 0.95em;
  background: #000;
  display: inline-block;
  vertical-align: text-bottom;
  animation: cursor-blink 1s steps(1, end) infinite;
}
@keyframes cursor-blink {
  0%, 45% { opacity: 1; }
  46%, 100% { opacity: 0; }
}

section.speaker-cover {
  justify-content: center;
}
section.speaker-cover h2 {
  font-size: 2.6em;
  margin-bottom: 0.35em;
}
section.speaker-cover h3 {
  font-size: 1.5em;
  max-width: 40%;
  line-height: 1.2;
  color: #dbe8f2;
}

</style>

<!-- _class: speaker-cover -->
![bg right:52% contain](./visual_assets/robocon/speaker.jpg)

## Ismo Aro


---

<!-- _class: lead -->

## Two-Hour Tutorial

<span class="title-with-cursor">AI Agentic Coding + Robot Framework<span class="title-cursor" aria-hidden="true"></span></span>

---

## Tutorial Goal

Master how to work effectively with coding agents by:

1. **Direct development with acceptance tests**
   - Write Robot Framework tests that define behavior *before* implementation
   - Use tests as the primary communication channel
   - Agent validates solutions against explicit requirements

2. **Create agent skill instructions**
   - Define best practices in your repository so agent learns them once
   - Example: Robot Framework should use self-documenting keyword names, no docstrings
   - Agent loads instructions automatically and follows them throughout the project

---

## What Is Agentic Coding?

Agentic coding is simple: **human prompts, agent does.**

**Your job:**
- Set clear goals and constraints
- Write acceptance tests that define requirements
- Ask agent to explore and implement
- Validate and iterate based on results

**The relationship:**
Better your prompts, tests, guard rails, and documentation → better the result.
Success depends on how well you set up the context and constraints.

**Key principle:** You set the bar; agent tries to reach it.

---

## Why Agentic Coding Is Hard

Agents work differently than humans.

**Key differences:**
- Agents need explicit info; humans understand implicitly
- Agents confuse easily; they don't signal confusion
- Agents repeat mistakes; context shifts cause regressions
- Training data is old; agents hallucinate confidently

---

## Challenge 1: Context and Confusion

**The Problem:**
- Humans infer context from experience
- Agents need everything explicit; vague prompts cause wrong results
- Context window limits (tokens) mean you can't paste everything
- **Agents are confident even when confused**

**This is why we need Part 1:**
Tests make requirements unambiguous. Agent can't be confused about pass/fail.

---

## Challenge 2: Knowledge and Hallucination

**The Problem:**
- Training data is old; new framework versions aren't known
- Agents invent APIs, functions, and libraries that don't exist
- They don't know your project's conventions

**This is why we need Part 2:**
Skills embed your patterns so agent follows them consistently.

---

## Challenge 3: Consistency and Drift

**The Problem:**
- Agents repeat mistakes even after being corrected
- Context shifts cause regressions (correct work gets undone)
- Pattern drift: ask for 3 things, agent adds a 4th

**This is why we validate after every change:**
Tests catch regressions immediately.

---

## Foundation: Strict Engineering Practices

Agentic coding works best with disciplined teams that follow engineering fundamentals.

Think **Extreme Programming (XP):**
- Test-first development
- Simple design
- Continuous integration
- Pair programming mindset (you + agent)

**Essential: Fast feedback loops**
- Run tests after every meaningful change
- Catch agent drift immediately
- Iterate quickly based on results

The stricter your practices and the faster your feedback, the more successful agentic coding becomes.
Agents amplify good discipline; they expose sloppy practices.

---

## Clone the Repository

```bash
git clone https://github.com/IsNoGood/yapster-robocon2026.git
cd yapster-robocon2026
```

---

## Local Setup

Run one setup script based on OS:

```bash
./setup-linux.sh
./setup-macos.sh
./install-windows-nonadmin.ps1
```

Verify setup by running tests:

```bash
# macOS / Linux
./run-tests.sh

# Windows (PowerShell)
.\run-tests.ps1
```

---

## Start the Baseline App

Start and verify services:

```bash
# macOS / Linux
./manage-services.sh start
./manage-services.sh status

# Windows (PowerShell)
.\manage-services.ps1 start
.\manage-services.ps1 status

# Health checks
curl http://localhost:3000/health
curl http://localhost:5173/health
```

Stop when done: `./manage-services.sh stop` or `.\manage-services.ps1 stop`

---

## Baseline Repository Map

- `frontend/`: React + TypeScript UI
- `backend/`: Express + TypeScript API
- `atests/`: Robot Framework UI/API tests

Current core feature: create and list yaps.

---

## Pick Your Agentic Tool

Choose your preferred tool:

- GitHub Copilot
- Codex
- Cursor
- Claude Code

Then ask it to investigate this repository and explain what it is about.

Suggested prompt:

```text
Investigate this repository and explain what it is about.
Summarize architecture, current features, and test strategy.
```

---

## Part 1: Implement Like Button with Acceptance Tests

We use Robot tests to direct development from start to finish.

---

## Exercise Goal: Add Like Button

User story:

- As a Yapster user, I want to like a yap so I can react to content.

Minimum acceptance criteria:

- Each yap shows a Like button and current like count
- Clicking Like increments count immediately in UI
- Like count persists through backend API responses
- Existing posting behavior remains working
- Robot API and UI tests pass for the new behavior

---

## Technical Scope (Today)

Implement across three layers:

1. Backend model and endpoint
2. Frontend rendering and interaction
3. Test suite updates (API + UI)

---

## Robot Test Strategy

Test layers we add first:

1. API test: liking a message increments count from 0 to 1
2. UI test: user clicks Like and sees counter update

Tags to use:

- `business-value` for behavior
- `api` and `ui` for layer-specific checks
- `smoke` for critical happy path

---

## Phase 1: Test-First Prompt

Instructor prompt to AI:

```text
Implement like functionality.
Messages can be liked.
First create Robot Framework tests before implementation, so we can validate the right approach.
Create only tests, no implementation.
```

Run tests:

```bash
./run-tests.sh
```

Expected: new tests fail.

---

## Phase 2: Backend Prompt

Instructor prompt to AI:

```text
Implement only backend support and let's validate with tests that it works.
```

Run tests and confirm progress:

```bash
./run-tests.sh
```

---

## Phase 3: Frontend Prompt

Instructor prompt to AI:

```text
Implement only frontend support and let's validate with tests that it works.
Update CSS to match the existing style.
```

---

## Phase 4: Validate End-to-End

Run full suite:

```bash
./run-tests.sh
```

Manual checks in browser:

1. Post two yaps
2. Like first yap multiple times
3. Refresh page and confirm counts remain

---

## Part 2: Create Agent Skill (No Extra Docs)

**Goal:** teach the agent once so it stops adding extra documentation.

**Prompt to the agent:**

```text
Create a project skill/instructions file.
Rule: Robot Framework keywords must be self-documenting.
Do NOT add docstrings or comments to keywords.
Store it in the tool's skill location.
```

That's it. After this, the agent follows the rule automatically.

---

## Discussion: What Went Well and Where Was the Pain?

- What worked smoothly with the agent?
- Where did it struggle or drift?
- What surprised you (good or bad)?
- What would you change next time?

---

## Stretch Goals (If Ahead of Time)

- Unlike support
- Multiple users and per-user likes
- UI redesign (e.g., cassette-futuristic theme)
- Comment on messages

---

## Wrap-Up

Key takeaway:

Agentic coding is not replacing engineering discipline.
It amplifies disciplined teams that define requirements, validate output, and iterate quickly.

---

<!-- _class: closing -->

# <span class="title-with-cursor">Thank you!<span class="title-cursor" aria-hidden="true"></span></span>
