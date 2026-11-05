# CLAUDE.md

Guidelines for working in this repository.

## Project Docs

- `docs/IMPLEMENTATION_PLAN.md` — user stories, phases, tech stack, open decisions.
- `docs/PROGRESS.md` — what's implemented so far. **Read it before starting work, and update it when a story's status changes or a decision is made.**
- `docs/frontend-designer/` — UI/UX and frontend-craft skill library (visual design, avoiding the generic "AI-generated" look, Flutter/Material 3 implementation, motion, BrandNest's own e-commerce UX patterns, accessibility/responsive, and a pre-ship checklist). **Read the relevant files before any UI design or frontend/Flutter work.**

## 1. Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

Touch only what you must. Clean up only your own mess.

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

Define success criteria. Loop until verified.

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]

## 5. Clean Code

Follow clean code methodologies:

- **Meaningful names**: Variables, functions, and classes should reveal intent. No abbreviations or single letters (except loop indices).
- **Small functions**: Each function does one thing, at one level of abstraction. Extract when a function grows beyond ~20 lines or mixes concerns.
- **Self-documenting code**: Prefer clear code over comments. Comment only the "why" (constraints, non-obvious decisions), never the "what".
- **No duplication (DRY)**: Extract repeated logic — but only when it appears, not speculatively (see Simplicity First).
- **Single Responsibility**: Each module/class has one reason to change.
- **Fail fast**: Validate inputs early, return early, avoid deep nesting.
- **Consistent formatting**: Follow the project's existing conventions and linter rules.
- **Leave it clean**: Code you write should need no explanation to the next reader.
