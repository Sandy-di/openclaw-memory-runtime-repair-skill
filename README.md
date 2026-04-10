# OpenClaw Memory Runtime Repair

[中文说明](./README.zh-CN.md)

Codex skill for diagnosing, repairing, and validating OpenClaw memory plugin failures, with a focus on `memory-lancedb-pro` regressions in `~/.openclaw`.

## What This Skill Covers

This skill packages a real repair workflow that was used to fix a broken OpenClaw memory setup. It is aimed at failures such as:

- `openclaw doctor` reporting `No active memory plugin is registered`
- `openclaw memory-pro` printing `invalid config: embedding...`
- stale `memory-lancedb` residue in `~/.openclaw/openclaw.json`
- `memory-core` public-surface access failures during doctor checks
- missing runtime registration in the LanceDB plugin source copies
- duplicate manifest/schema validation noise from the plugin manifests

The skill does not just describe the problem. It includes:

- a repair-oriented [SKILL.md](./SKILL.md)
- a symptom-to-fix playbook in [references/repair-playbook.md](./references/repair-playbook.md)
- a verifier script in [scripts/verify_openclaw_memory_fix.sh](./scripts/verify_openclaw_memory_fix.sh)

## Repository Layout

```text
openclaw-memory-runtime-repair/
├── README.md
├── README.zh-CN.md
├── SKILL.md
├── agents/openai.yaml
├── references/repair-playbook.md
└── scripts/verify_openclaw_memory_fix.sh
```

## Install

This repository is itself the skill folder. If you want Codex to auto-discover it, clone or copy it into your skills directory:

```bash
git clone https://github.com/Sandy-di/openclaw-memory-runtime-repair-skill.git \
  "${CODEX_HOME:-$HOME/.codex}/skills/openclaw-memory-runtime-repair"
```

If you already cloned it elsewhere, copy the folder into your skills directory:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R /path/to/openclaw-memory-runtime-repair \
  "${CODEX_HOME:-$HOME/.codex}/skills/openclaw-memory-runtime-repair"
```

## Use

Invoke it explicitly with:

```text
Use $openclaw-memory-runtime-repair to diagnose and fix OpenClaw memory plugin failures on this machine.
```

The skill is intended for local-machine debugging where OpenClaw state lives under `~/.openclaw`.

## Workflow Summary

The packaged repair order is:

1. Reproduce with `openclaw memory-pro stats`, `openclaw memory-pro --help`, `openclaw doctor --non-interactive`, and `openclaw plugins list --json`.
2. Normalize `~/.openclaw/openclaw.json` before touching plugin code.
3. Patch both plugin source copies:
   - `~/.openclaw/extensions/memory-lancedb-pro/index.ts`
   - `~/.openclaw/workspace/plugins/memory-lancedb-pro/index.ts`
4. Clean manifest-level validation noise in both `openclaw.plugin.json` copies if CLI metadata validation still fails.
5. Re-run acceptance checks and classify remaining output as fatal or advisory.

For the exact mapping from symptoms to fixes, read [references/repair-playbook.md](./references/repair-playbook.md).

## Verification Script

The repository includes a verifier:

```bash
./scripts/verify_openclaw_memory_fix.sh
```

It runs:

- `openclaw memory-pro stats`
- `openclaw memory-pro --help`
- `openclaw doctor --non-interactive`

and fails when it sees known regression patterns like:

- `Config validation failed`
- `No active memory plugin is registered`
- `Bundled plugin public surface access blocked`
- `invalid config: embedding`
- `unknown command 'memory-pro'`

## Important Caveat

Run the repair and verification against the real host state. Sandboxed runs can emit false `EPERM` errors for `~/.openclaw/memory/lancedb-pro` and make a healthy setup look broken.

Also note that OpenClaw CLI behavior can drift across versions and local states. This skill captures one successful repair path and a concrete acceptance strategy, but the verifier may still surface new failures if the machine's OpenClaw state later changes.

## Skill Metadata

The Codex-facing skill entrypoint is [SKILL.md](./SKILL.md). The UI metadata used by Codex is [agents/openai.yaml](./agents/openai.yaml).
