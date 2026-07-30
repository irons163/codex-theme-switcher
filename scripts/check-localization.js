"use strict";

const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const appSourceDirectory = path.join(
  root,
  "Sources",
  "CodexThemeSwitcher",
);
const supportedLanguages = [
  "en",
  "zh-Hant",
  "zh-Hans",
  "fr",
  "es",
  "ja",
  "ko",
];
const readmeByLanguage = {
  en: "README.md",
  "zh-Hant": "README.zh-Hant.md",
  "zh-Hans": "README.zh-Hans.md",
  fr: "README.fr.md",
  es: "README.es.md",
  ja: "README.ja.md",
  ko: "README.ko.md",
};

function markdownStructure(contents) {
  const headingLevels = contents
    .split("\n")
    .filter((line) => /^#{1,6}\s/.test(line))
    .map((line) => line.match(/^#+/)[0].length);
  const imageTargets = [
    ...contents.matchAll(/!\[[^\]]*\]\(([^)\s]+)[^)]*\)/g),
  ].map((match) => match[1]);
  const linkTargets = [
    ...contents.matchAll(/(?<!!)\[[^\]]+\]\(([^)\s]+)[^)]*\)/g),
  ]
    .map((match) => match[1])
    .filter((target) => !/^README(?:\.[^)]+)?\.md$/.test(target));
  const codeFenceLanguages = [
    ...contents.matchAll(/^```([^\s`]*)/gm),
  ].map((match) => match[1]);
  const bulletCount = contents
    .split("\n")
    .filter((line) => /^-\s/.test(line))
    .length;
  const orderedStepCount = contents
    .split("\n")
    .filter((line) => /^\d+\.\s/.test(line))
    .length;

  return {
    headingLevels,
    imageTargets,
    linkTargets,
    codeFenceLanguages,
    bulletCount,
    orderedStepCount,
  };
}

function sameSequence(left, right) {
  return left.length === right.length
    && left.every((value, index) => value === right[index]);
}

function fail(message) {
  console.error(`check-localization: ${message}`);
  process.exitCode = 1;
}

function sourceFiles(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const location = path.join(directory, entry.name);
    return entry.isDirectory() ? sourceFiles(location) : [location];
  });
}

function parseArguments(source, openingParenthesis) {
  const argumentsList = [];
  const delimiterStack = ["("];
  let argumentStart = openingParenthesis + 1;
  let inString = false;
  let inTripleString = false;
  let escaping = false;
  let inLineComment = false;
  let blockCommentDepth = 0;

  for (let index = argumentStart; index < source.length; index += 1) {
    const character = source[index];
    const next = source[index + 1];
    const nextNext = source[index + 2];

    if (inLineComment) {
      if (character === "\n") inLineComment = false;
      continue;
    }
    if (blockCommentDepth > 0) {
      if (character === "/" && next === "*") {
        blockCommentDepth += 1;
        index += 1;
      } else if (character === "*" && next === "/") {
        blockCommentDepth -= 1;
        index += 1;
      }
      continue;
    }
    if (inString) {
      if (inTripleString) {
        if (
          character === "\""
          && next === "\""
          && nextNext === "\""
        ) {
          inString = false;
          inTripleString = false;
          index += 2;
        }
      } else if (escaping) {
        escaping = false;
      } else if (character === "\\") {
        escaping = true;
      } else if (character === "\"") {
        inString = false;
      }
      continue;
    }

    if (character === "/" && next === "/") {
      inLineComment = true;
      index += 1;
      continue;
    }
    if (character === "/" && next === "*") {
      blockCommentDepth = 1;
      index += 1;
      continue;
    }
    if (character === "\"") {
      inString = true;
      inTripleString = next === "\"" && nextNext === "\"";
      if (inTripleString) index += 2;
      continue;
    }

    if (character === "(" || character === "[" || character === "{") {
      delimiterStack.push(character);
      continue;
    }
    if (character === ")" || character === "]" || character === "}") {
      delimiterStack.pop();
      if (delimiterStack.length === 0) {
        argumentsList.push(
          source.slice(argumentStart, index).trim(),
        );
        return argumentsList;
      }
      continue;
    }
    if (character === "," && delimiterStack.length === 1) {
      argumentsList.push(
        source.slice(argumentStart, index).trim(),
      );
      argumentStart = index + 1;
    }
  }
  return null;
}

function stringLiterals(expression) {
  const values = [];
  for (let index = 0; index < expression.length; index += 1) {
    if (expression[index] !== "\"") continue;

    if (expression.slice(index, index + 3) === "\"\"\"") {
      const end = expression.indexOf("\"\"\"", index + 3);
      if (end === -1) break;
      values.push(expression.slice(index + 3, end));
      index = end + 2;
      continue;
    }

    let end = index + 1;
    let escaping = false;
    for (; end < expression.length; end += 1) {
      const character = expression[end];
      if (escaping) {
        escaping = false;
      } else if (character === "\\") {
        escaping = true;
      } else if (character === "\"") {
        break;
      }
    }
    if (end >= expression.length) break;

    const rawLiteral = expression.slice(index, end + 1);
    try {
      values.push(JSON.parse(rawLiteral));
    } catch {
      fail(`unsupported Swift string literal: ${rawLiteral}`);
    }
    index = end;
  }
  return values;
}

function directString(argument) {
  const withoutLabel = argument.replace(
    /^[A-Za-z][A-Za-z0-9_]*\s*:\s*/,
    "",
  );
  const values = stringLiterals(withoutLabel);
  return values.length === 1 ? values[0] : null;
}

function catalogEntries(file, callPattern, translationCount) {
  const source = fs.readFileSync(file, "utf8");
  const entries = new Map();
  let match;
  while ((match = callPattern.exec(source)) !== null) {
    const openingParenthesis = source.indexOf("(", match.index);
    const argumentsList = parseArguments(source, openingParenthesis);
    if (!argumentsList || argumentsList.length < translationCount + 1) {
      continue;
    }
    const values = argumentsList
      .slice(0, translationCount + 1)
      .map(directString);
    if (values.some((value) => value === null)) continue;
    const [key, ...translations] = values;
    if (entries.has(key)) {
      fail(`${path.basename(file)} contains duplicate key: ${key}`);
      continue;
    }
    entries.set(key, translations);
  }
  return entries;
}

function placeholders(value) {
  return new Set(value.match(/\{\d+\}/g) ?? []);
}

function equalSets(left, right) {
  return left.size === right.size
    && [...left].every((value) => right.has(value));
}

const cjkCatalog = catalogEntries(
  path.join(appSourceDirectory, "L10nCatalogCJK.swift"),
  /\.init\s*\(/g,
  3,
);
const westernCatalog = catalogEntries(
  path.join(appSourceDirectory, "L10nCatalogWestern.swift"),
  /Entry\s*\(/g,
  2,
);
const cjkKeys = new Set(cjkCatalog.keys());
const westernKeys = new Set(westernCatalog.keys());

if (!equalSets(cjkKeys, westernKeys)) {
  for (const key of cjkKeys) {
    if (!westernKeys.has(key)) {
      fail(`French/Spanish catalog is missing: ${key}`);
    }
  }
  for (const key of westernKeys) {
    if (!cjkKeys.has(key)) {
      fail(`CJK catalog is missing: ${key}`);
    }
  }
}

for (const [key, translations] of [
  ...cjkCatalog,
  ...westernCatalog,
]) {
  for (const translation of translations) {
    if (translation.trim().length === 0) {
      fail(`empty translation for: ${key}`);
    }
    if (!equalSets(placeholders(key), placeholders(translation))) {
      fail(`placeholder mismatch for: ${key}`);
    }
  }
}

const localizationCalls = /\b(?:L10n\.)?(text|format)\s*\(/g;
const sourceKeys = new Map();
const unresolvedCalls = [];
for (const file of sourceFiles(appSourceDirectory)) {
  if (
    !file.endsWith(".swift")
    || file.includes("L10nCatalog")
  ) {
    continue;
  }
  const source = fs.readFileSync(file, "utf8");
  localizationCalls.lastIndex = 0;
  let match;
  while ((match = localizationCalls.exec(source)) !== null) {
    const prefix = source.slice(Math.max(0, match.index - 8), match.index);
    if (/\bfunc\s+$/.test(prefix)) continue;
    if (
      path.basename(file) !== "L10n.swift"
      && !match[0].startsWith("L10n.")
    ) {
      continue;
    }

    const openingParenthesis = source.indexOf("(", match.index);
    const argumentsList = parseArguments(source, openingParenthesis);
    if (!argumentsList || argumentsList.length < 2) continue;
    const keys = stringLiterals(argumentsList[1]);
    const line = source.slice(0, match.index).split("\n").length;
    const location = `${path.relative(root, file)}:${line}`;
    if (keys.length === 0) {
      if (path.basename(file) !== "L10n.swift") {
        unresolvedCalls.push(location);
      }
      continue;
    }
    for (const key of keys) {
      if (!sourceKeys.has(key)) sourceKeys.set(key, []);
      sourceKeys.get(key).push(location);
    }
  }
}

for (const location of unresolvedCalls) {
  fail(
    `${location} passes a nonliteral English localization key; `
    + "use literal branches so coverage can be checked",
  );
}
for (const [key, locations] of sourceKeys) {
  if (!cjkCatalog.has(key) || !westernCatalog.has(key)) {
    fail(
      `missing translation key ${JSON.stringify(key)} used at `
      + locations.join(", "),
    );
  }
}
for (const key of cjkCatalog.keys()) {
  if (!sourceKeys.has(key)) {
    fail(`unused translation key: ${key}`);
  }
}

const readmeStructures = new Map();
for (const language of supportedLanguages) {
  const readme = path.join(root, readmeByLanguage[language]);
  if (!fs.existsSync(readme) || fs.statSync(readme).size === 0) {
    fail(`missing or empty ${readmeByLanguage[language]}`);
    continue;
  }
  const contents = fs.readFileSync(readme, "utf8");
  readmeStructures.set(language, markdownStructure(contents));
  for (const otherLanguage of supportedLanguages) {
    if (otherLanguage === language) continue;
    const otherReadme = readmeByLanguage[otherLanguage];
    if (!contents.includes(otherReadme)) {
      fail(
        `${readmeByLanguage[language]} does not link to ${otherReadme}`,
      );
    }
  }
}

const englishReadmeStructure = readmeStructures.get("en");
for (const language of supportedLanguages.filter((value) => value !== "en")) {
  const structure = readmeStructures.get(language);
  for (const field of [
    "headingLevels",
    "imageTargets",
    "linkTargets",
    "codeFenceLanguages",
  ]) {
    if (!sameSequence(englishReadmeStructure[field], structure[field])) {
      fail(
        `${readmeByLanguage[language]} does not match README.md `
        + `${field}`,
      );
    }
  }
  for (const field of ["bulletCount", "orderedStepCount"]) {
    if (englishReadmeStructure[field] !== structure[field]) {
      fail(
        `${readmeByLanguage[language]} does not match README.md `
        + `${field}`,
      );
    }
  }
}

const releaseNotesRoot = path.join(root, "docs", "release-notes");
for (const entry of fs.readdirSync(releaseNotesRoot, {
  withFileTypes: true,
})) {
  if (!entry.isDirectory() || !entry.name.startsWith("v")) continue;
  const englishNotes = path.join(
    releaseNotesRoot,
    entry.name,
    "release-notes.en.md",
  );
  const englishContents = fs.readFileSync(englishNotes, "utf8").trim();
  for (const language of supportedLanguages) {
    const notes = path.join(
      releaseNotesRoot,
      entry.name,
      `release-notes.${language}.md`,
    );
    if (!fs.existsSync(notes) || fs.statSync(notes).size === 0) {
      fail(
        `missing or empty ${path.relative(root, notes)}`,
      );
      continue;
    }
    if (
      language !== "en"
      && fs.readFileSync(notes, "utf8").trim() === englishContents
    ) {
      fail(
        `${path.relative(root, notes)} is an untranslated copy of English`,
      );
    }
  }
}

if (!process.exitCode) {
  console.log(
    `Localization check passed: ${sourceKeys.size} source keys, `
    + `${cjkCatalog.size} catalog entries, `
    + `${supportedLanguages.length} languages.`,
  );
}
