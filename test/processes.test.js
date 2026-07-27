"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  codexMainProcessIds,
  isCodexMainProcessCommand,
} = require("../Sources/CodexThemeRuntime/Resources/runtime/lib/processes");

test("isCodexMainProcessCommand recognizes Codex and renamed ChatGPT mains", () => {
  const commands = [
    "/Applications/Codex.app/Contents/MacOS/Codex",
    "/Applications/Codex.app/Contents/MacOS/Codex --flag value",
    "/Applications/ChatGPT.app/Contents/MacOS/ChatGPT",
    "/Users/me/Applications/ChatGPT.app/Contents/MacOS/ChatGPT --flag",
  ];
  for (const command of commands) {
    assert.equal(isCodexMainProcessCommand(command), true, command);
  }
});

test("isCodexMainProcessCommand rejects helpers and lookalike paths", () => {
  const commands = [
    "",
    "/Applications/ChatGPT.app/Contents/Frameworks/ChatGPT Helper.app/Contents/MacOS/ChatGPT Helper (Renderer)",
    "/Applications/NotChatGPT.app/Contents/MacOS/ChatGPT",
    "/Applications/ChatGPT.app/Contents/MacOS/ChatGPTBeta",
    "/tmp/Codex.app/Contents/MacOS/Codex-copy",
  ];
  for (const command of commands) {
    assert.equal(isCodexMainProcessCommand(command), false, command);
  }
});

test("isCodexMainProcessCommand does not match a path appearing in arguments", () => {
  const commands = [
    "/bin/sh -c 'echo /Applications/Codex.app/Contents/MacOS/Codex'",
    "/bin/sh -c /Applications/Codex.app/Contents/MacOS/Codex --version",
  ];
  for (const command of commands) {
    assert.equal(isCodexMainProcessCommand(command), false, command);
  }
});

test("codexMainProcessIds parses ps output and drops malformed lines", () => {
  const output = [
    "  101 /Applications/Codex.app/Contents/MacOS/Codex",
    "202 /Applications/ChatGPT.app/Contents/MacOS/ChatGPT --flag",
    "  303 /Applications/ChatGPT.app/Contents/Frameworks/ChatGPT Helper.app/Contents/MacOS/ChatGPT Helper",
    "not-a-pid /Applications/Codex.app/Contents/MacOS/Codex",
    "-1 /Applications/Codex.app/Contents/MacOS/Codex",
    "404",
    "",
  ].join("\n");

  assert.deepEqual(codexMainProcessIds(output), [101, 202]);
  assert.deepEqual(codexMainProcessIds(null), []);
});
