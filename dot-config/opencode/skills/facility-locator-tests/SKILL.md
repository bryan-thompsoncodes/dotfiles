---
name: facility-locator-tests
description: Run all Cypress E2E and unit tests for facility-locator app - verified commands with proper entry name
---

# Facility Locator Test Suite

Run all tests for the facility-locator application in vets-website.

## Critical Configuration

```
APP_FOLDER="facility-locator"
ENTRY_NAME="facilities"  # NOT "facility-locator"!
TEST_FILES_E2E=20
TEST_FILES_UNIT=53
UNIT_TEST_COUNT=420
```

**⚠️ CRITICAL:** The webpack entry name is `facilities`, NOT `facility-locator`. This is defined in `manifest.json` and cannot be changed easily (hardcoded in content-build repo).

---

## Quick Commands

**Run all tests (full suite):**

```bash
# Terminal 1: Start dev server for E2E tests
yarn watch --env entry=facilities

# Terminal 2: Run E2E tests (20 files)
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/**/*.cypress.spec.js"

# Terminal 3 (or after E2E): Run unit tests (53 files, 420 tests)
yarn test:unit --app-folder facility-locator
```

**Run unit tests only (no dev server needed):**

```bash
yarn test:unit --app-folder facility-locator
# Result: 420 passing tests in ~15s
```

**Run E2E tests only (requires dev server):**

```bash
# Terminal 1
yarn watch --env entry=facilities

# Terminal 2
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/**/*.cypress.spec.js"
```

---

## Execution Workflow

### Phase 1: Verify Prerequisites

```bash
# Check if dev server is running (for E2E tests)
lsof -i :3001 | grep LISTEN || echo "Port 3001 available"

# Check vets-api is NOT running (APIs should be mocked)
lsof -i :3000 | grep LISTEN && echo "⚠️ Stop vets-api - tests mock APIs" || echo "✅ vets-api not running"
```

### Phase 2: Run Unit Tests First

Unit tests don't require dev server and run quickly:

```bash
yarn test:unit --app-folder facility-locator
```

**Expected output:**

- 420 passing tests
- ~15 seconds runtime
- No errors

**Verification:**

```bash
# Check exit code
echo $?  # Should be 0
```

### Phase 3: Start Dev Server for E2E

```bash
# Start in background or separate terminal
nohup yarn watch --env entry=facilities > /dev/null 2>&1 &

# Or in separate terminal (recommended for visibility)
yarn watch --env entry=facilities

# Wait for "Compiled successfully" message
```

**Verification:**

```bash
# Check port 3001 is listening
lsof -i :3001 | grep LISTEN

# Test endpoint is responsive
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/find-locations
# Should return 200
```

### Phase 4: Run E2E Tests

```bash
# All E2E tests
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/**/*.cypress.spec.js"

# Or specific test categories (see below)
```

**Expected behavior:**

- Cypress launches Chrome
- Tests run headlessly
- All 20 spec files execute
- Mapbox API calls are automatically mocked

---

## Test Categories

### Unit Test Categories

```bash
# Components (38 files)
yarn test:unit src/applications/facility-locator/tests/components/**/*.unit.spec.jsx

# Utils (6 files)
yarn test:unit src/applications/facility-locator/tests/utils/**/*.unit.spec.jsx

# Reducers (2 files)
yarn test:unit src/applications/facility-locator/tests/reducers/**/*.unit.spec.jsx

# Actions (3 files)
yarn test:unit src/applications/facility-locator/tests/actions/**/*.unit.spec.jsx

# Hooks (1 file)
yarn test:unit src/applications/facility-locator/tests/hooks/**/*.unit.spec.jsx
```

### E2E Test Categories

```bash
# Search functionality
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/*Search*.cypress.spec.js"

# Mobile tests
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/mobile*.cypress.spec.js"

# Detail page service messages (4 files)
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/details-page/**/*.cypress.spec.js"

# Error handling
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/errorMessages.cypress.spec.js"

# Geolocation
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/geolocation.cypress.spec.js"

# Analytics
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/gaEvents.cypress.spec.js"
```

---

## Coverage Reports

```bash
# Unit test coverage with HTML report
yarn test:coverage-app facility-locator

# Coverage output location
open coverage/index.html
```

---

## Interactive Testing

```bash
# Open Cypress UI (with dev server running)
yarn cy:open

# Then select facility-locator tests from the UI
```

---

## Common Issues & Solutions

### Issue: "Entry 'facility-locator' not found"

**Cause:** Using wrong entry name  
**Solution:** Use `facilities` not `facility-locator`

```bash
# ❌ Wrong
yarn watch --env entry=facility-locator

# ✅ Correct
yarn watch --env entry=facilities
```

---

### Issue: "Cypress failed to verify that your server is running"

**Cause:** Dev server not running on port 3001  
**Solution:** Start dev server first

```bash
# Check if running
lsof -i :3001 | grep LISTEN

# If not, start it
yarn watch --env entry=facilities
```

---

### Issue: Mapbox API errors in Cypress tests

**Cause:** Should NOT happen - Mapbox is auto-mocked  
**Solution:** Check global mock in `src/platform/testing/e2e/cypress/support/index.js`

Mapbox API calls are automatically intercepted globally. Tests should never add their own Mapbox intercepts.

---

### Issue: vets-api running during E2E tests

**Cause:** Local API might interfere with mocked responses  
**Solution:** Stop vets-api before running E2E tests

```bash
# Check if running
lsof -i :3000 | grep LISTEN

# Stop if running (Ctrl+C in terminal or pkill)
```

---

## Output Expectations

### Unit Tests Success

```
420 passing (15.32s)
Done in 15.32s.
```

### E2E Tests Success

```
  (Run Finished)

       Spec                                              Tests  Passing  Failing  ...
  ┌────────────────────────────────────────────────────────────────────────────┐
  │ ✔  errorMessages.cypress.spec.js           XX:XX        N        N        0 │
  │ ✔  facilitySearch.cypress.spec.js          XX:XX        N        N        0 │
  │ ...                                                                         │
  └────────────────────────────────────────────────────────────────────────────┘
    ✔  All specs passed!                       XX:XX       NN       NN        0
```

---

## Test File Inventory

**Unit Tests:** 53 files, 420 tests

- Components: 38 files
- Utils: 6 files
- Reducers: 2 files
- Actions: 3 files
- Hooks: 1 file
- Helpers: 1 file
- Root: 2 files

**E2E Tests:** 20 files

- Root level: 15 files
- details-page/service-message/: 4 files
- limited-service-hours-display/: 1 file

---

## Full Documentation

For complete test documentation including verification timestamps and more examples, see:

```
/Users/bryan/code/department-of-veterans-affairs/vets-website/.notes/facility-locator-test-guide.md
```

Also documented in project AGENTS.md:

```
/Users/bryan/code/department-of-veterans-affairs/vets-website/AGENTS.md
```

---

## Verification Status

✅ **Last verified:** 2026-02-09

**Unit tests:**

- Command: `yarn test:unit --app-folder facility-locator`
- Result: 420 passing (15.32s)
- Exit code: 0

**E2E tests:**

- Command syntax verified via Cypress
- 20 test files confirmed in directory
- Requires localhost:3001 (verified by Cypress connection check)

---

## Agent Usage Pattern

When this skill is loaded, agents should:

1. **Check prerequisites** before running tests
2. **Run unit tests first** (fast, no server needed)
3. **Start dev server** if running E2E tests
4. **Verify server is ready** before launching Cypress
5. **Report test results** with pass/fail counts
6. **Provide actionable feedback** if tests fail

**Example delegation:**

```
task(
  category="quick",
  load_skills=["facility-locator-tests"],
  prompt="Run all facility-locator tests and report results"
)
```
