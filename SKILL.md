---
name: openclaw-memory-runtime-repair
description: Diagnose, repair, and validate OpenClaw memory plugin failures on the local machine, especially `memory-lancedb-pro` regressions in `~/.openclaw` such as `openclaw doctor` reporting no active memory plugin, `openclaw memory-pro` printing invalid config errors, stale memory plugin entries in `openclaw.json`, disabled `memory-core` public-surface access, or missing runtime registration in the LanceDB plugin source copies.
---

# OpenClaw Memory Runtime Repair

Repair OpenClaw memory breakage in the order that proved successful on a live machine: clean config, patch both plugin source copies, remove duplicate manifest validation noise, then verify with `memory-pro` and `doctor`.

## Quick Start

- Reproduce with `openclaw memory-pro stats`, `openclaw memory-pro --help`, `openclaw doctor --non-interactive`, and `openclaw plugins list --json`.
- Prefer host-level execution when touching `~/.openclaw` or running `openclaw`; sandboxed runs can emit false `EPERM` on `~/.openclaw/memory/lancedb-pro`.
- Run [verify_openclaw_memory_fix.sh](./scripts/verify_openclaw_memory_fix.sh) after each meaningful change.

## Workflow

1. Inspect the active memory slot and plugin entries in `~/.openclaw/openclaw.json`.
2. Normalize config before touching plugin code.
3. Patch both LanceDB plugin source copies if the issue is code-related.
4. Clean manifest/schema noise if CLI validation still fails after runtime fixes.
5. Re-run verification and classify any remaining output as fatal or advisory.

## Normalize Config First

- Keep `plugins.slots.memory` pointed at `memory-lancedb-pro`.
- Remove stale config residue such as `plugins.entries.memory-lancedb`.
- Remove disabled-plugin config blocks that only create validation noise.
- Keep `memory-core` loadable when OpenClaw doctor needs its bundled public runtime surface, but do not move the memory slot away from `memory-lancedb-pro`.
- Migrate unrelated legacy config warnings if `doctor` keeps surfacing them and they obscure the memory failure.

## Patch Both Plugin Source Copies

- Treat these files as a mirrored pair and keep them in sync:
- `~/.openclaw/extensions/memory-lancedb-pro/index.ts`
- `~/.openclaw/workspace/plugins/memory-lancedb-pro/index.ts`
- If `doctor` says no active memory plugin is registered, add `api.registerMemoryCapability({ runtime: ... })`.
- Expose a minimal runtime that reuses the existing `store`, `retriever`, `embedder`, and `scopeManager`.
- Support four operations in that runtime:
- return a registered memory search manager
- resolve a backend config that OpenClaw health checks accept
- probe embeddings and vector availability
- read memory entries through a stable virtual-path format

## Clean Manifest Validation Noise

- Inspect both manifests if `openclaw memory-pro` works but still prints trailing `invalid config: embedding...`:
- `~/.openclaw/extensions/memory-lancedb-pro/openclaw.plugin.json`
- `~/.openclaw/workspace/plugins/memory-lancedb-pro/openclaw.plugin.json`
- A top-level `"required": ["embedding"]` can trigger a second CLI metadata validation path even when runtime config is already valid.
- If runtime code already validates `embedding` itself, drop the manifest-level top-level required list to silence duplicate CLI-only errors.

## Validate in This Order

1. `openclaw memory-pro stats`
2. `openclaw memory-pro --help`
3. `openclaw doctor --non-interactive`
4. `openclaw plugins list --json`

## Treat These as Fatal

- `Config validation failed`
- `No active memory plugin is registered`
- `Bundled plugin public surface access blocked`
- `invalid config: embedding`
- plugin summary errors for the active memory plugin

## Treat These as Advisory Unless They Block the Task

- `Memory search provider is set to "auto" but the API key was not found in the CLI environment` when the gateway already reports embeddings ready
- generic gateway timeout noise if the gateway is already running and the memory plugin checks passed
- explanatory `memory_recall queries the plugin store...` logging from the LanceDB plugin

## Bundled Resources

- Read [repair-playbook.md](./references/repair-playbook.md) for the exact symptom-to-fix mapping from the successful repair.
- Run [verify_openclaw_memory_fix.sh](./scripts/verify_openclaw_memory_fix.sh) to execute the acceptance checks and fail fast on the known regression strings.
