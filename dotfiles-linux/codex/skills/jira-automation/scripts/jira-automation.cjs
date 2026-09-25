#!/usr/bin/env node

const assert = require("node:assert/strict");
const childProcess = require("node:child_process");
const crypto = require("node:crypto");
const fs = require("node:fs");

const cloudIdPattern = /^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$/i;
const uuidPattern = cloudIdPattern;
const sha256Pattern = /^[a-f0-9]{64}$/;

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function fail(message) {
  throw new Error(message);
}

function configuration(environment) {
  const email = String(environment.ATLASSIAN_EMAIL || "").trim();
  const cloudId = String(environment.ATLASSIAN_CLOUD_ID || "").trim();
  if (!email || !email.includes("@")) fail("ATLASSIAN_EMAIL is invalid.");
  if (!cloudIdPattern.test(cloudId)) fail("ATLASSIAN_CLOUD_ID is invalid.");
  return { email, cloudId };
}

function apiToken(environment) {
  const provided = String(environment.ATLASSIAN_API_TOKEN || "").trim();
  if (provided) return provided;

  const item = String(
    environment.ATLASSIAN_TOKEN_RBW_ITEM || "atlassian_token",
  ).trim();
  if (!item) fail("ATLASSIAN_TOKEN_RBW_ITEM is invalid.");
  try {
    const token = childProcess.execFileSync("rbw", ["get", item], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    }).trim();
    if (!token) fail("The Atlassian API token is empty.");
    return token;
  } catch (error) {
    fail(`Cannot read the Atlassian API token from rbw: ${error.message}`);
  }
}

function authorization(email, token) {
  return `Basic ${Buffer.from(`${email}:${token}`, "utf8").toString("base64")}`;
}

function safeApiError(status, text) {
  let message = "The response did not contain a safe error summary.";
  try {
    const parsed = JSON.parse(text);
    if (Array.isArray(parsed.errors)) {
      message = JSON.stringify(parsed.errors.map((error) => ({
        status: error.status,
        code: error.code,
        title: error.title,
        field: error.field,
      })));
    } else if (typeof parsed.message === "string") {
      message = parsed.message;
    }
  } catch {}
  return `Automation API returned HTTP ${status}: ${String(message).slice(0, 2000)}`;
}

async function request(url, { auth, method = "GET", body } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      Accept: "application/json",
      Authorization: auth,
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    redirect: "error",
    signal: AbortSignal.timeout(30000),
  });
  const text = await response.text();
  if (!response.ok) fail(safeApiError(response.status, text));
  try {
    return text ? JSON.parse(text) : null;
  } catch {
    fail("Automation API returned invalid JSON.");
  }
}

function apiContext(environment) {
  const { email, cloudId } = configuration(environment);
  const token = apiToken(environment);
  return {
    auth: authorization(email, token),
    baseUrl:
      `https://api.atlassian.com/automation/public/jira/${cloudId}/rest/v1`,
  };
}

async function listRules(context, exactName) {
  let url = `${context.baseUrl}/rule/summary?limit=100`;
  const rules = [];
  let page = 0;
  while (url) {
    if (page >= 20) fail("Rule discovery exceeded the 20-page safety limit.");
    const response = await request(url, { auth: context.auth });
    if (!Array.isArray(response?.data)) fail("The rule summary response is invalid.");
    rules.push(...response.data);
    const next = response.links?.next;
    url = next ? new URL(next, url).toString() : null;
    page += 1;
  }
  const selected = exactName
    ? rules.filter((rule) => rule.name === exactName)
    : rules;
  if (exactName && selected.length !== 1) {
    fail(`Expected one rule named ${exactName}, found ${selected.length}.`);
  }
  return selected.map((rule) => ({
    uuid: rule.uuid,
    name: rule.name,
    state: rule.state,
    updated: rule.updated,
  }));
}

async function getRule(context, uuid) {
  if (!uuidPattern.test(uuid)) fail("The rule UUID is invalid.");
  const response = await request(`${context.baseUrl}/rule/${uuid}`, {
    auth: context.auth,
  });
  if (!response?.rule || !Array.isArray(response.connections)) {
    fail("The rule response is invalid.");
  }
  return response;
}

function readManifest(filePath) {
  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    fail(`Cannot read the update manifest: ${error.message}`);
  }
  if (!uuidPattern.test(manifest?.rule_uuid || "")) {
    fail("The manifest rule_uuid is invalid.");
  }
  for (const field of ["expected_name", "expected_state"]) {
    if (typeof manifest[field] !== "string" || !manifest[field]) {
      fail(`The manifest ${field} is invalid.`);
    }
  }
  if (!Array.isArray(manifest.replacements) || manifest.replacements.length === 0) {
    fail("The manifest needs at least one replacement.");
  }
  const unique = new Set();
  for (const replacement of manifest.replacements) {
    for (const field of ["first", "operator", "old_second", "new_second"]) {
      if (typeof replacement?.[field] !== "string" || !replacement[field]) {
        fail(`A replacement ${field} is invalid.`);
      }
    }
    if (replacement.old_second === replacement.new_second) {
      fail("A replacement old_second and new_second are equal.");
    }
    const key = [
      replacement.first,
      replacement.operator,
      replacement.old_second,
    ].join("\u0000");
    if (unique.has(key)) fail("The manifest contains a duplicate replacement.");
    unique.add(key);
  }
  return manifest;
}

function readBodyManifest(filePath) {
  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    fail(`Cannot read the body manifest: ${error.message}`);
  }
  if (!uuidPattern.test(manifest?.rule_uuid || "")) {
    fail("The body manifest rule_uuid is invalid.");
  }
  if (!uuidPattern.test(manifest?.component_id || "")) {
    fail("The body manifest component_id is invalid.");
  }
  for (const field of ["expected_name", "expected_state"]) {
    if (typeof manifest[field] !== "string" || !manifest[field]) {
      fail(`The body manifest ${field} is invalid.`);
    }
  }
  for (const field of ["old_sha256", "new_sha256"]) {
    if (!sha256Pattern.test(manifest[field] || "")) {
      fail(`The body manifest ${field} is invalid.`);
    }
  }
  if (manifest.old_sha256 === manifest.new_sha256) {
    fail("The old and new request bodies are equal.");
  }
  if (
    typeof manifest.new_body_file !== "string" ||
    !require("node:path").isAbsolute(manifest.new_body_file)
  ) {
    fail("The body manifest new_body_file must be an absolute path.");
  }
  const body = fs.readFileSync(manifest.new_body_file, "utf8");
  if (!body || sha256(body) !== manifest.new_sha256) {
    fail("The new request body does not match the manifest hash.");
  }
  return { manifest, body };
}

function writablePayload(response) {
  const { created, updated, uuid, ...rule } = structuredClone(response.rule);
  const connections = response.connections.map(
    ({ createdAt, updatedAt, container, ...connection }) => connection,
  );
  return { rule, connections };
}

function matchingStrings(value, needle, path = []) {
  if (typeof value === "string") {
    return value.includes(needle)
      ? [{
        path,
        sha256: crypto.createHash("sha256").update(value).digest("hex"),
        length: value.length,
        trimmed_sha256: crypto.createHash("sha256").update(value.trim()).digest("hex"),
        trimmed_length: value.trim().length,
      }]
      : [];
  }
  if (!value || typeof value !== "object") return [];
  return Object.entries(value).flatMap(([key, child]) =>
    matchingStrings(child, needle, [...path, key]));
}

function valueAtPath(value, path) {
  return path.reduce((current, key) => current?.[key], value);
}

function prepareBodyUpdate(response, manifest, newBody) {
  if (response.rule.uuid !== manifest.rule_uuid) fail("The rule UUID changed.");
  if (response.rule.name !== manifest.expected_name) fail("The rule name changed.");
  if (response.rule.state !== manifest.expected_state) fail("The rule state changed.");
  const payload = writablePayload(response);
  const matches = payload.rule.components.filter((component) =>
    component.id === manifest.component_id &&
    component.type === "jira.issue.outgoing.webhook");
  if (matches.length !== 1) {
    fail(`Expected one outgoing webhook component, found ${matches.length}.`);
  }
  const currentBody = matches[0].value?.customBody;
  if (typeof currentBody !== "string" || sha256(currentBody) !== manifest.old_sha256) {
    fail("The current request body does not match the manifest hash.");
  }
  matches[0].value.customBody = newBody;
  return payload;
}

function applyReplacements(payload, replacements) {
  const counts = new Array(replacements.length).fill(0);
  function visit(item) {
    if (Array.isArray(item)) {
      item.forEach(visit);
      return;
    }
    if (!item || typeof item !== "object") return;
    for (const [index, replacement] of replacements.entries()) {
      if (
        item.value?.first === replacement.first &&
        item.value?.operator === replacement.operator &&
        item.value?.second === replacement.old_second
      ) {
        item.value.second = replacement.new_second;
        counts[index] += 1;
      }
    }
    Object.values(item).forEach(visit);
  }
  visit(payload.rule.components);
  counts.forEach((count, index) => {
    if (count !== 1) {
      fail(`Replacement ${index + 1} matched ${count} conditions instead of one.`);
    }
  });
  return payload;
}

function prepareUpdate(response, manifest) {
  if (response.rule.uuid !== manifest.rule_uuid) fail("The rule UUID changed.");
  if (response.rule.name !== manifest.expected_name) fail("The rule name changed.");
  if (response.rule.state !== manifest.expected_state) fail("The rule state changed.");
  return applyReplacements(writablePayload(response), manifest.replacements);
}

function report(manifest, state, applied) {
  return {
    applied,
    rule_uuid: manifest.rule_uuid,
    name: manifest.expected_name,
    state,
    replacements: manifest.replacements.map((replacement) => ({
      first: replacement.first,
      operator: replacement.operator,
      old_second: replacement.old_second,
      new_second: replacement.new_second,
    })),
  };
}

function option(args, name) {
  const index = args.indexOf(name);
  if (index === -1) return null;
  if (!args[index + 1]) fail(`${name} needs a value.`);
  return args[index + 1];
}

function usage() {
  return [
    "Usage:",
    "  node scripts/jira-automation.cjs list [--name <exact-name>]",
    "  node scripts/jira-automation.cjs inspect <rule-uuid> --contains <text>",
    "  node scripts/jira-automation.cjs plan <manifest.json>",
    "  node scripts/jira-automation.cjs apply <manifest.json>",
    "  node scripts/jira-automation.cjs plan-body <manifest.json>",
    "  node scripts/jira-automation.cjs apply-body <manifest.json>",
  ].join("\n");
}

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  if (!command || !["list", "inspect", "plan", "apply", "plan-body", "apply-body"].includes(command)) {
    console.error(usage());
    process.exitCode = 2;
    return;
  }
  try {
    const context = apiContext(process.env);
    if (command === "list") {
      console.log(JSON.stringify(
        await listRules(context, option(args, "--name")),
        null,
        2,
      ));
      return;
    }

    if (command === "inspect") {
      const uuid = args[1];
      const needle = option(args, "--contains");
      if (!needle) fail("--contains needs non-empty text.");
      const current = await getRule(context, uuid);
      const matches = matchingStrings(current.rule.components, needle);
      const bodies = matches.map((match) => valueAtPath(current.rule.components, match.path));
      console.log(JSON.stringify({
        rule_uuid: current.rule.uuid,
        name: current.rule.name,
        state: current.rule.state,
        matches: matches.map((match) => {
          const component = current.rule.components[Number(match.path[0])];
          return {
            ...match,
            component_type: component?.type,
            component_id: component?.id,
            component_keys: Object.keys(component || {}),
            value_keys: Object.keys(component?.value || {}),
            variable_name: component?.type === "jira.create.variable"
              ? component.value?.name : undefined,
            query_type: component?.type === "jira.create.variable"
              ? component.value?.query?.type : undefined,
          };
        }),
        containment: bodies.length === 2 ? {
          first_contains_second_at: bodies[0].indexOf(bodies[1]),
          second_contains_first_at: bodies[1].indexOf(bodies[0]),
        } : undefined,
      }, null, 2));
      return;
    }

    const manifestPath = args[1];
    if (!manifestPath) fail("The manifest path is required.");
    if (command === "plan-body" || command === "apply-body") {
      const { manifest, body } = readBodyManifest(manifestPath);
      const current = await getRule(context, manifest.rule_uuid);
      const payload = prepareBodyUpdate(current, manifest, body);
      const result = {
        applied: command === "apply-body",
        rule_uuid: manifest.rule_uuid,
        name: manifest.expected_name,
        state: current.rule.state,
        component_id: manifest.component_id,
        old_sha256: manifest.old_sha256,
        new_sha256: manifest.new_sha256,
      };
      if (command === "plan-body") {
        console.log(JSON.stringify(result, null, 2));
        return;
      }
      const update = await request(
        `${context.baseUrl}/rule/${manifest.rule_uuid}`,
        { auth: context.auth, method: "PUT", body: payload },
      );
      if (update?.ruleUuid !== manifest.rule_uuid) {
        fail("The update response contains the wrong rule UUID.");
      }
      const saved = await getRule(context, manifest.rule_uuid);
      assert.deepStrictEqual(
        writablePayload(saved), payload,
        "The saved rule differs from the submitted rule.",
      );
      console.log(JSON.stringify(result, null, 2));
      return;
    }
    const manifest = readManifest(manifestPath);
    const current = await getRule(context, manifest.rule_uuid);
    const payload = prepareUpdate(current, manifest);
    if (command === "plan") {
      console.log(JSON.stringify(
        report(manifest, current.rule.state, false),
        null,
        2,
      ));
      return;
    }

    const response = await request(
      `${context.baseUrl}/rule/${manifest.rule_uuid}`,
      { auth: context.auth, method: "PUT", body: payload },
    );
    if (response?.ruleUuid !== manifest.rule_uuid) {
      fail("The update response contains the wrong rule UUID.");
    }
    const saved = await getRule(context, manifest.rule_uuid);
    assert.deepStrictEqual(
      writablePayload(saved),
      payload,
      "The saved rule differs from the submitted rule.",
    );
    console.log(JSON.stringify(
      report(manifest, saved.rule.state, true),
      null,
      2,
    ));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}

module.exports = {
  applyReplacements,
  matchingStrings,
  prepareBodyUpdate,
  readBodyManifest,
  sha256,
  valueAtPath,
  prepareUpdate,
  readManifest,
  writablePayload,
};

if (require.main === module) main();
