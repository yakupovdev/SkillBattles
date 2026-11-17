# Local Storage — Preferences and Secure Storage

> Part of the mandatory architecture rules: split out of `.claude/rules/architecture.md` (key-value storage; the drift response cache is in `.claude/rules/local_database.md`). Same scope and source-fidelity notes as there: "Existing project conventions" are the original rules, "Added safeguards" apply where compatible with the repository.

## Existing project conventions

### Local storage

- Use a storage interface and an implementation with the `Impl` suffix.
- Obtain the storage library through a constructor or an asynchronous creation factory.
- Declare keys centrally in `StorageKeys`.
- Do not hide asynchronous writes behind `void`. Return a Future and await completion when the write affects subsequent actions.
- If the library returns a boolean indicating write success, preserve and handle that result.
- Define missing-key behavior explicitly. Use a nullable result when absence must be distinguished from false, zero, or an empty string.
- Serialize feature models in the feature's local source, not in the shared preferences wrapper.
- Do not access the storage library directly from UI or use cases.
- Server answers are cached in the drift database through `ResponseCache` and the features' `<Feature>Local` sources: network first, cache fallback. Everything about it (policy, scopes, cached models, schema, tests) is in `local_database.md`.

## Added safeguards

### Local storage and caching

- Declare keys in `StorageKeys` and preserve existing keys; key renames require a migration or intentional data-loss decision.
- Define missing-key semantics, default values, expiry/freshness, and failure propagation for each stored value where relevant.
- Keep sensitive credentials in the storage mechanism already approved for sensitive data, not automatically in ordinary shared preferences. Do not change storage products without a specific requirement.
- On async writes, await completion when following actions assume persisted data. Preserve `bool` write status if exposed by the underlying API.
- Feature serialization lives in its `data/sources/local` implementation or associated parser/model—not in generic storage wrappers.
