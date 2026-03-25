# Mobile Patrol Known Issues

## 2026-03-25

- `SA-11` can now register successfully as `MSAM`.
- Mission Editor route points are visible on the map and can be read by the patrol module.
- Current blocking issue:
  - Immediately after mission start, the `MSAM` group switches to `deployed`.
  - It does not return to `patrolling`, even when all aircraft are well outside the expected threat range.
- Expected behavior:
  - `MSAM` should remain in `patrolling` state until an aircraft enters the configured threat threshold.
  - Current configured patrol resume threshold for `MSAM` is `1.2x` engagement range.
- Most likely investigation areas:
  - false-positive threat detection in `findSAMThreatContact(entry)`
  - stale or over-broad contact data from Skynet at mission start
  - deployment state transition being triggered by early `informOfContact()` / `targetsInRange` changes
