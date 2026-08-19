# Quit History Implementation Notes

## Scope

Implement the quit history from the 2026-08-19 brief.

## Architecture

The repository uses a small layered service graph. `AppDelegate` builds the core services.
`WindowEventHandler` owns the quit decision. `QuitHistoryStore` owns history persistence.
SwiftUI views observe the preference and history singletons.

## Deviations

- `record` returns `UUID?`. The brief also requires a nil-equivalent result when
  recording is off. A non-optional `UUID` cannot represent that result.
