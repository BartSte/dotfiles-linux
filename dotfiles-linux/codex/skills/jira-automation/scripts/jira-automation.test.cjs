const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  prepareBodyUpdate,
  readBodyManifest,
  sha256,
  writablePayload,
} = require("./jira-automation.cjs");

const ruleUuid = "019fa975-8f0d-78c2-94e5-f89ab1c80dcd";
const componentId = "2e6a3938-58cf-45d5-a32e-cbc7470f1b0f";

function response(body) {
  return {
    rule: {
      uuid: ruleUuid,
      name: "fr-developer-agent: request plan",
      state: "ENABLED",
      components: [
        { id: componentId, type: "jira.issue.outgoing.webhook", value: { customBody: body, url: "https://example.com" } },
        { id: "another", type: "jira.create.variable", value: { query: { value: body } } },
      ],
    },
    connections: [],
  };
}

function manifest(oldBody, newBody) {
  return {
    rule_uuid: ruleUuid,
    expected_name: "fr-developer-agent: request plan",
    expected_state: "ENABLED",
    component_id: componentId,
    old_sha256: sha256(oldBody),
    new_sha256: sha256(newBody),
  };
}

test("body update changes only the selected webhook body", () => {
  const current = response("old body");
  const update = prepareBodyUpdate(current, manifest("old body", "new body"), "new body");
  const expected = writablePayload(current);
  expected.rule.components[0].value.customBody = "new body";
  assert.deepEqual(update, expected);
  assert.equal(current.rule.components[0].value.customBody, "old body");
});

test("body update stops when the live body or rule state changes", () => {
  const current = response("different body");
  assert.throws(() => prepareBodyUpdate(current, manifest("old body", "new body"), "new body"), /current request body/);
  current.rule.state = "DISABLED";
  assert.throws(() => prepareBodyUpdate(current, manifest("different body", "new body"), "new body"), /rule state changed/);
});

test("body manifest checks the new file hash", (context) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "jira-automation-test-"));
  context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const bodyPath = path.join(directory, "body.txt");
  const manifestPath = path.join(directory, "manifest.json");
  fs.writeFileSync(bodyPath, "new body");
  fs.writeFileSync(manifestPath, JSON.stringify({
    ...manifest("old body", "new body"),
    new_body_file: bodyPath,
  }));
  assert.equal(readBodyManifest(manifestPath).body, "new body");
  fs.writeFileSync(bodyPath, "changed body");
  assert.throws(() => readBodyManifest(manifestPath), /does not match/);
});
