"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { test } = require("node:test");

const workflow = fs.readFileSync(path.join(__dirname, "../.github/workflows/release.yml"), "utf8");
const retry = workflow.match(/# BEGIN APPLE_TICKET_RETRY\n([\s\S]*?)\s*# END APPLE_TICKET_RETRY/)[1]
  .split("\n").map(line => line.replace(/^ {10}/, "")).join("\n");

function invoke(args, failures, status) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "codex-apple-ticket-test-"));
  try {
    const counter = path.join(dir, "count");
    fs.writeFileSync(path.join(dir, "xcrun"), `#!/bin/bash
n=0
if [[ -f "$TICKET_TEST_COUNT" ]]; then read -r n < "$TICKET_TEST_COUNT"; fi
n=$((n + 1))
printf '%s\\n' "$n" > "$TICKET_TEST_COUNT"
if [[ "$n" -le "$TICKET_TEST_FAILURES" ]]; then exit "$TICKET_TEST_STATUS"; fi
exit 0
`, { mode: 0o755 });
    const result = spawnSync("/bin/bash", ["-c", [
      "set -euo pipefail", retry,
      "sleep() { :; }; export -f sleep",
      // The release script is another Bash process: exported functions must
      // keep the operation-specific retry policy in that child as well.
      '/bin/bash -c \'set -euo pipefail; xcrun "$@"; printf passed\' _ "$@"',
    ].join("\n"), "_", ...args], {
      encoding: "utf8",
      env: { ...process.env, PATH: `${dir}:${process.env.PATH}`,
        TICKET_TEST_COUNT: counter, TICKET_TEST_FAILURES: String(failures), TICKET_TEST_STATUS: String(status) },
    });
    return { status: result.status, output: result.stdout,
      count: Number(fs.readFileSync(counter, "utf8")) };
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

test("Apple ticket delivery retries error 68 in place for staple and validate", () => {
  for (const operation of ["staple", "validate"]) {
    assert.deepEqual(invoke(["stapler", operation, "release.dmg"], 2, 68),
      { status: 0, output: "passed", count: 3 });
  }
});

test("Apple ticket delivery retains mandatory checks and bounded attempts", () => {
  assert.deepEqual(invoke(["stapler", "validate", "release.dmg"], 10, 68),
    { status: 68, output: "", count: 5 });
  assert.deepEqual(invoke(["stapler", "validate", "release.dmg"], 10, 65),
    { status: 65, output: "", count: 1 });
  assert.deepEqual(invoke(["notarytool", "submit", "release.dmg"], 10, 68),
    { status: 68, output: "", count: 1 });
  assert.deepEqual(invoke(["stapler", "staple", "release.dmg"], 0, 68),
    { status: 0, output: "passed", count: 1 });
});
