# Yapster: Robot Framework Agentic Coding Workshop

This repository is used for a **2-hour hands-on tutorial** on AI agentic coding with a strong **Robot Framework test-first** workflow.

## Purpose

Participants learn how to:

- understand a real fullstack codebase with an AI agent
- define acceptance criteria before implementation
- use Robot Framework tests as quality guard rails
- implement a feature end-to-end with AI guidance

Current workshop feature exercise: **add a Like button** to existing yaps.

## Current Application State

Yapster is a small social app with:

- backend health endpoint: `/health`
- message APIs: `GET /api/messages`, `POST /api/messages`
- frontend UI for posting and listing yaps
- in-memory storage (no database)

The Like button is intentionally left as a workshop implementation exercise.

## Workshop Flow (2 Hours)

1. Intro to agentic coding concepts
2. Clone and local setup
3. Baseline walkthrough (frontend, backend, Robot tests)
4. Test-first design for Like button
5. Guided implementation with AI agent
6. Validation and retrospective

Instructor slides are in [INSTRUCTOR-RUNSHEET.md](./INSTRUCTOR-RUNSHEET.md).

## Quickstart

### 1) Setup

```bash
./setup-linux.sh
# or
./setup-macos.sh
# or
./install-windows-nonadmin.ps1
```

### 2) Verify environment

```bash
./check-environment.sh
```

### 3) Run tests

```bash
./run-tests.sh
```

### 4) Start services (separate terminals)

```bash
cd backend && npm run dev
```

```bash
cd frontend && npm run dev
```

### 5) Health checks

```bash
curl http://localhost:3000/health
curl http://localhost:5173/health
```

## Testing First (Robot Framework)

Robot Framework is the primary quality gate in this repository.

- UI tests: `atests/ui/*.robot`
- API tests: `atests/api/*.robot`
- shared run command: `./run-tests.sh`

Recommended implementation loop:

1. Add/adjust Robot tests for expected behavior
2. Run tests and observe failure
3. Implement minimal code changes
4. Re-run tests until green

## Repository Structure

```text
yapster-rf/
├── frontend/                  # React + TypeScript (Vite)
├── backend/                   # Express + TypeScript
├── atests/                    # Robot Framework tests
├── INSTRUCTOR-RUNSHEET.md     # Marp slides for workshop
├── DEMO-GUIDE.md              # Facilitator guide (2-hour tutorial)
└── README.md
```


## Additional Docs

- `INSTRUCTOR-RUNSHEET.md`: presentation deck
- `DEMO-GUIDE.md`: facilitator checklist and timing
