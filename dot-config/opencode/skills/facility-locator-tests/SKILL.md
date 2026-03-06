---
name: facility-locator-tests
description: Run all Cypress E2E and unit tests for facility-locator app - verified commands with proper entry name
---

# Facility Locator Test Suite

Run all tests for the facility-locator application in vets-website.

## Default Behavior

**When this skill is loaded with no specific prompt or an empty request, the default action is to run the full test suite (unit + E2E).** Follow the execution workflow below — check prerequisites, run unit tests, then run E2E tests, and report results.

## Critical Configuration

```
APP_FOLDER="facility-locator"
ENTRY_NAME="facilities"  # NOT "facility-locator"!
TEST_FILES_E2E=20
TEST_FILES_UNIT=53
UNIT_TEST_COUNT=442
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
```

**Note:** vets-api can be running during E2E tests. Some vets-website functionality relies on the API, and Cypress `cy.intercept` calls take precedence over real network requests, so mocked endpoints are unaffected.

### Phase 2: Run Unit Tests First

Unit tests don't require dev server and run quickly:

```bash
yarn test:unit --app-folder facility-locator
```

**Expected output:**

- 442 passing tests
- ~8 seconds runtime
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

**Cause:** Dev server not running on port 3001, OR test-server bound to IPv6 only  
**Solution:** Start dev server first. If using test-server, add `--host=0.0.0.0` (macOS binds IPv6 by default, Cypress checks IPv4 `127.0.0.1`).

```bash
# Check if running
lsof -i :3001 | grep LISTEN

# Option A: Dev server (has webpack overlay issues, see below)
yarn watch --env entry=facilities

# Option B: Production build (recommended for reliable E2E)
yarn build --buildtype=localhost --entry=facilities
node src/platform/testing/e2e/test-server.js --buildtype=localhost --port=3001 --host=0.0.0.0
```

---

### Issue: Webpack dev server overlay blocks Cypress

**Cause:** The overlay (`#webpack-dev-server-client-overlay`) activates on ANY uncaught JS error in dev mode. Empty-body tile mocks trigger Mapbox GL parse errors.  
**Solution:** Use production builds for E2E instead of `yarn watch`:

```bash
yarn build --buildtype=localhost --entry=facilities
node src/platform/testing/e2e/test-server.js --buildtype=localhost --port=3001 --host=0.0.0.0
yarn cy:run --spec "src/applications/facility-locator/tests/e2e/**/*.cypress.spec.js"
```

---

### Issue: `cy.intercept` image mock returns broken image (naturalWidth === 0)

**Cause:** `cy.intercept` body accepts `string | object | ArrayBuffer`. `Uint8Array` is NOT `ArrayBuffer`.  
**Solution:** Use `.buffer` to unwrap, and verify base64 PNG has complete IEND chunk:

```js
// Wrong
body: Uint8Array.from(atob(base64), c => c.charCodeAt(0));

// Correct
body: Uint8Array.from(atob(base64), c => c.charCodeAt(0)).buffer;
```

---

### Issue: Mapbox API errors in Cypress tests

**Cause:** Non-data Mapbox endpoints (tiles, fonts, sprites, static images, telemetry) are globally mocked in `src/platform/testing/e2e/cypress/support/index.js`.  
**Important:** Geocoding is **NOT** globally mocked. Each test that needs geocoding must provide its own `cy.intercept('GET', '/geocoding/**/*', mockData)` with city-specific data. A global geocoding mock returning a hardcoded city will break any test searching for a different city.

---

## Output Expectations

### Unit Tests Success

```
442 passing (2s)
Done in 7.58s.
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

**Unit Tests:** 53 files, 442 tests

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

✅ **Last verified:** 2026-03-03

**Unit tests:**

- Command: `yarn test:unit --app-folder facility-locator`
- Result: 442 passing (2s)
- Exit code: 0

**E2E tests:**

- Command: `yarn cy:run --spec "src/applications/facility-locator/tests/e2e/**/*.cypress.spec.js"`
- Result: 19/20 specs passed, 117/118 tests passing
- 1 known flaky: `addressAutosuggest.cypress.spec.js` — "Search results in 5 results" (assertion timeout on `usa-input-error` class)
- Duration: ~4 minutes
- Requires localhost:3001

---

## Agent Usage Pattern

**When loaded with no prompt or empty request → run full test suite automatically.**

When this skill is loaded, agents should:

1. **If no specific prompt is given**: Run all tests (unit + E2E) as the default action
2. **Check prerequisites** before running tests
3. **Run unit tests first** (fast, no server needed)
4. **Start dev server** if running E2E tests (check port 3001 first — may already be running)
5. **Verify server is ready** before launching Cypress
6. **Report test results** with pass/fail counts
7. **Provide actionable feedback** if tests fail

**Example delegation:**

```
task(
  category="quick",
  load_skills=["facility-locator-tests"],
  prompt="Run all facility-locator tests and report results"
)
```
