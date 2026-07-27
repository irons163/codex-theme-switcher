"use strict";

const fs = require("node:fs");

async function fetchJSON(url, options = {}, timeoutMs = 1500) {
  const response = await fetch(url, {
    ...options,
    signal: AbortSignal.timeout(timeoutMs),
  });
  const text = await response.text();
  let payload = null;
  try {
    payload = text ? JSON.parse(text) : null;
  } catch {}
  if (!response.ok) {
    const error = new Error(
      payload?.error?.message || `HTTP request failed: ${response.status}`,
    );
    error.code = payload?.error?.code || "http-error";
    error.payload = payload;
    throw error;
  }
  return payload || {};
}

function readToken(tokenFile) {
  return fs.readFileSync(tokenFile, "utf8").trim();
}

async function queryBridge(
  options,
  pathname = "/status",
  method = "GET",
  body = null,
) {
  const headers = {
    Authorization: `Bearer ${readToken(options.tokenFile)}`,
  };
  const request = { method, headers };
  if (body !== null) {
    headers["Content-Type"] = "application/json";
    request.body = JSON.stringify(body);
  }
  return fetchJSON(
    `http://127.0.0.1:${options.bridgePort}${pathname}`,
    request,
    7000,
  );
}

function writeJSON(response, statusCode, payload) {
  const body = `${JSON.stringify(payload, null, 2)}\n`;
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
    "Cache-Control": "no-store",
  });
  response.end(body);
}

async function readJSONBody(request, maxBytes = 72 * 1024 * 1024) {
  const chunks = [];
  let total = 0;
  for await (const chunk of request) {
    total += chunk.length;
    if (total > maxBytes) {
      const error = new Error("Request body is too large.");
      error.code = "payload-too-large";
      throw error;
    }
    chunks.push(chunk);
  }
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    const error = new Error("Request body is not valid JSON.");
    error.code = "invalid-json";
    throw error;
  }
}

module.exports = {
  fetchJSON,
  queryBridge,
  readJSONBody,
  readToken,
  writeJSON,
};
