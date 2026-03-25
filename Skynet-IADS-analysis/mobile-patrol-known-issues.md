# Mobile Patrol Known Issues

## 2026-03-25

- Current stable state:
  - `SA-11` can now register successfully as `MSAM`.
  - `SA-11` can now patrol correctly and, once patrol is established, can switch to `combat` and engage even without an internal `SR` radar.
  - External `EW` cueing for no-`SR` `SA-11` is working in the validated scenario.
- Remaining known edge case:
  - If an enemy aircraft is already inside the engagement area at mission startup, `SA-11/MSAM` may visually remain deployed in place while the reported state is still `patrolling`.
  - Once the group has transitioned into normal patrol behavior, subsequent `patrol <-> combat` switching behaves correctly.
- Current configured thresholds:
  - `MSAM` patrol resume threshold: `1.2x` engagement range.
  - `MSAM` patrol resume delay: `30s`.
