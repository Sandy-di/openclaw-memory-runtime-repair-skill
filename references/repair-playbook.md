# Repair Playbook

## Scope

Use this playbook for OpenClaw memory failures centered on `memory-lancedb-pro` in `~/.openclaw`.

## Files That Mattered in the Successful Repair

- `~/.openclaw/openclaw.json`
- `~/.openclaw/extensions/memory-lancedb-pro/index.ts`
- `~/.openclaw/workspace/plugins/memory-lancedb-pro/index.ts`
- `~/.openclaw/extensions/memory-lancedb-pro/openclaw.plugin.json`
- `~/.openclaw/workspace/plugins/memory-lancedb-pro/openclaw.plugin.json`

## Symptom to Fix Map

### `Config validation failed: plugins.entries.memory-lancedb.config.embedding...`

- Remove stale `plugins.entries.memory-lancedb` from `openclaw.json`.
- Remove disabled-plugin residue that still carries old config.
- Re-run `openclaw doctor`.

### `No active memory plugin is registered for the current config.`

- Patch both `memory-lancedb-pro/index.ts` copies.
- Register a minimal memory runtime with `api.registerMemoryCapability({ runtime: ... })`.
- Make the runtime return a search manager backed by the existing LanceDB store and retriever.

### `Bundled plugin public surface access blocked for "memory-core"...`

- Keep `memory-core` enabled in `openclaw.json` so doctor can reach its bundled public runtime surface.
- Do not move `plugins.slots.memory`; leave the memory slot on `memory-lancedb-pro`.

### `memory-lancedb-pro invalid config: embedding: must have required property 'embedding'`

- If runtime config is already valid and `memory-pro` still prints this at the end, inspect both `openclaw.plugin.json` files.
- Remove the top-level `"required": ["embedding"]` if runtime code already enforces `embedding`.
- Re-run `openclaw memory-pro stats` and `openclaw memory-pro --help`.

## Runtime Patch Characteristics

Keep the runtime patch narrow. The successful repair did not replace the storage or retrieval stack.

The registered runtime did four things:

- expose `getMemorySearchManager`
- expose `resolveMemoryBackendConfig`
- expose embedding/vector probes
- map memory rows to a stable virtual path so `readFile` can work

The search manager reused:

- `store`
- `retriever`
- `embedder`
- `scopeManager`

## Config End State

The successful end state kept these invariants:

- `plugins.slots.memory = "memory-lancedb-pro"`
- `plugins.entries.memory-lancedb-pro.enabled = true`
- `plugins.entries.memory-core.enabled = true`
- `plugins.entries.memory-lancedb` absent
- duplicated plugin source copies kept in sync
- duplicated manifest files kept in sync

## Acceptance Criteria

Treat the repair as complete when all of these are true:

- `openclaw memory-pro stats` exits `0`
- `openclaw memory-pro stats` prints real memory counts
- `openclaw memory-pro --help` exits `0`
- neither command prints `invalid config: embedding`
- `openclaw doctor --non-interactive` exits `0`
- `doctor` no longer reports `No active memory plugin is registered`
- `doctor` no longer fails on `memory-core/runtime-api.js`

## Known Non-Blocking Output

These messages may remain and are not proof of failure by themselves:

- `memory_recall queries the plugin store (LanceDB), not MEMORY.md`
- `Memory search provider is set to "auto" but the API key was not found in the CLI environment` when the gateway already reports embeddings ready

## Execution Note

When checking the real `~/.openclaw` tree, prefer host-level execution. Sandboxed runs can produce false `EPERM` results against the LanceDB path and make a healthy setup look broken.
