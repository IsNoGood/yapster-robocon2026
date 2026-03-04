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
  margin-top: 0.2em;
  margin-bottom: 0.2em;
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
</style>

<!-- _class: lead -->

## Two-Hour Tutorial

<span class="title-with-cursor">AI Agentic Coding + Robot Framework<span class="title-cursor" aria-hidden="true"></span></span>

---

## Tutorial Goal

By the end of this session participants can:

- Explain what AI agentic coding means in software delivery
- Use Robot Framework as the quality guard rail for AI-generated code
- Clone and run a fullstack repository locally
- Collaborate with an AI coding agent to implement a feature
- Ship a working Like button verified by Robot tests

---

## Agenda (120 Minutes)

1. 0:00-0:20 Intro: What agentic coding is
2. 0:20-0:35 Clone and local setup
3. 0:35-0:50 Baseline walkthrough (app, tests, architecture)
4. 0:50-1:10 Robot test-first design for Like button
5. 1:10-1:40 Build Like button with AI agent (guided)
6. 1:40-1:55 Verify, demo, and discuss test quality
7. 1:55-2:00 Wrap-up and next steps

---

## What Is Agentic Coding?

Agentic coding means using an AI assistant as an active collaborator that can:

- Explore and understand a codebase
- Propose and make changes across files
- Run tests and validate behavior
- Iterate based on feedback and constraints

Human role remains critical:

- Set intent and boundaries
- Review decisions and tradeoffs
- Approve quality and correctness

---

## Agentic Workflow

1. Define goal and acceptance criteria
2. Ask agent to investigate current state
3. Implement in small validated increments
4. Run tests after every meaningful change
5. Refine prompt and code until done

Rule for this tutorial: no blind copy-paste, always verify.

---

## Strengths and Risks

**Strengths**
- Faster implementation
- Better scaffolding and refactoring speed
- Helps maintain momentum

**Risks**
- Wrong assumptions if prompts are vague
- Confident but incorrect solutions
- Missing edge cases unless tests are explicit

Mitigation: clear prompts + tests + review.

---

## Why Robot Framework Here

This session is test-first by design:

- Robot tests define expected behavior before implementation
- AI can generate code quickly, tests keep it honest
- Given/When/Then keeps technical and business language aligned
- UI + API coverage gives confidence across the full stack

Core message: Robot is the contract, AI is the accelerator.

---

## Prompting Pattern We Use Today

Use this sequence:

1. State the functionality we want
2. Ask AI to create Robot tests first (acceptance criteria)
3. Developer validates the tests and scenarios
4. Ask AI to implement code to satisfy the approved tests
5. Re-run tests and review output

Example:

```text
Implement like functionality for messages.
First create Robot Framework tests only.
These tests define acceptance criteria.
Do not implement code yet.
After I validate the tests, implement backend and frontend to pass them.
```

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

Quick API check with `curl` before UI work.

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

## Robot-First Loop (Live)

For each step in coding:

1. Write or adjust Robot test
2. Run tests and confirm failure
3. Implement smallest code change
4. Re-run tests and confirm pass
5. Refactor only with tests green

This is the discipline that makes agentic coding reliable.

---

## Discussion: What the Agent Did Well

- Fast cross-file implementation
- Consistent coding patterns
- Rapid iteration from feedback

## Discussion: What We Still Reviewed

- Correctness of endpoint contracts
- Test coverage quality and test readability
- Edge cases and UX details

---

## Common Failure Modes

- Prompt too broad, scope drifts
- Tests pass but behavior is wrong
- UI works locally but API contract is inconsistent

Recovery pattern:

1. Narrow prompt
2. Ask for small patch
3. Re-run tests
4. Repeat

---

## Stretch Goals (If Ahead of Time)

- Unlike toggle
- Prevent duplicate likes per user/session
- Add optimistic UI with rollback on error
- Add sorting by likes

---

## Wrap-Up

Key takeaway:

Agentic coding is not replacing engineering discipline.
It amplifies disciplined teams that define requirements, validate output, and iterate quickly.

---

<!-- _class: closing -->

# <span class="title-with-cursor">Thank you!<span class="title-cursor" aria-hidden="true"></span></span>
