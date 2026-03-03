# Workshop Facilitator Guide

This guide supports a **2-hour tutorial** on AI agentic coding with **Robot Framework-first development**.

## Session Objective

Teach participants to implement a Like button using an AI coding agent while maintaining engineering quality through Robot tests.

## Audience Context

This version is tailored for a Robot Framework conference audience.

Primary message:

- AI increases implementation speed
- Robot tests preserve correctness and trust

## Time Plan (120 minutes)

1. 0:00-0:20 Agentic coding concepts
2. 0:20-0:35 Clone and setup
3. 0:35-0:50 Baseline architecture + existing tests
4. 0:50-1:10 Define Like behavior as tests
5. 1:10-1:40 Implement backend and frontend with AI
6. 1:40-1:55 Validate, debug, and review
7. 1:55-2:00 Wrap-up

## Pre-Session Checklist

### Environment

- setup scripts run successfully
- `./check-environment.sh` passes
- `./run-tests.sh` passes on baseline
- backend healthy at `http://localhost:3000/health`
- frontend healthy at `http://localhost:5173/health`

### Instructor Assets

- slides ready: `INSTRUCTOR-RUNSHEET.md`
- terminal windows prepared (backend/frontend/tests)
- example prompts ready for copy/paste

## Live Delivery Script

### Phase 1: Explain agentic coding

Focus points:

- the agent is a collaborator, not an authority
- prompts define constraints and quality expectations
- tests are the contract

### Phase 2: Baseline walkthrough

Show:

- current app behavior (post + list yaps)
- existing Robot tests in `atests/ui` and `atests/api`
- where the Like feature will be added

### Phase 3: Test-first Like definition

Ask AI to create failing Robot tests first:

- API test: liking a message increments likes
- UI test: clicking Like updates count

Run tests and show expected failure.

### Phase 4: Implement with AI

1. backend changes for likes field and like endpoint
2. frontend changes for like button and count display
3. minimal CSS adjustments if needed

Run tests after each step.

### Phase 5: Validate and reflect

- run full Robot suite
- do a quick manual browser check
- discuss what the agent did well and what humans still validated

## Suggested Prompt Sequence

1. Investigation prompt

```text
Analyze this repository and summarize architecture, current features, and Robot testing setup.
```

2. Test-first prompt

```text
Add failing Robot Framework tests for a Like button feature:
one API test and one UI test using Given/When/Then style.
Do not change app code yet.
```

3. Backend prompt

```text
Implement likes in backend/src/server.ts.
Add likes to message model and POST /api/messages/:id/like.
Keep existing behavior unchanged and update tests only if required.
```

4. Frontend prompt

```text
Implement Like button in frontend/src/App.tsx.
Display count and call POST /api/messages/:id/like on click.
Keep selectors stable for Robot tests.
```

## Quality Gates

At minimum, require:

- all Robot tests pass (`./run-tests.sh`)
- existing message posting behavior still works
- new Like behavior works in both API and UI tests

## Optional Extensions (if time allows)

- unlike/toggle support
- optimistic UI + rollback on failure
- sorting by likes
- additional negative API test cases

