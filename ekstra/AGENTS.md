# AGENTS

## Scope
- EKSTRA is a local-first Flutter MVP for tracking overtime hours and estimated extra earnings.
- Auth is optional: local-first usage must always work without login.
- Do not add payment, notifications, social features, real Supabase calls, or AI features in the MVP.
- Keep the app fast: adding daily overtime must stay a 2-3 tap workflow.

## Coding Rules
- UI must not contain business calculations.
- Overtime earnings are calculated in domain/services.
- Persistence goes through repository interfaces.
- Account/session state must go through the auth feature; do not branch on auth directly in UI business rules.
- Prefer feature-based folders under `lib/features`.
- Keep abstractions practical; avoid framework-heavy overengineering.

## Tests
- Add focused tests for calculations and repository-sensitive behavior.
- Widget tests should cover major screen bootability and critical flows when changed.
- Run `flutter analyze` before handoff.

## UX Rules
- Default to a premium dark finance-app feel.
- Dashboard must answer: "Bu ay ne kadar ekstra kazandım?"
- Do not add complex onboarding.
