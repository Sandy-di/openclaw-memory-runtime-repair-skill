# OpenClaw Memory Runtime Repair

[English README](./README.md)

这是一个 Codex skill，用来诊断、修复并验证 OpenClaw 的 memory 插件故障，重点覆盖 `~/.openclaw` 下与 `memory-lancedb-pro` 相关的回归问题。

## 这个 Skill 解决什么

这个 skill 打包了一条已经在真实机器上验证过的修复链路，主要面向以下问题：

- `openclaw doctor` 报 `No active memory plugin is registered`
- `openclaw memory-pro` 报 `invalid config: embedding...`
- `~/.openclaw/openclaw.json` 里残留旧的 `memory-lancedb` 配置
- `doctor` 检查时出现 `memory-core` 公共 runtime 访问失败
- LanceDB 插件源码没有注册 memory runtime
- 插件 manifest 的重复 schema 校验噪音

这个仓库不是单纯的问题说明，而是一个可以直接复用的 skill，包含：

- 面向 Codex 的主入口 [SKILL.md](./SKILL.md)
- 症状到修复动作的映射文档 [references/repair-playbook.md](./references/repair-playbook.md)
- 一个用于复跑验收的脚本 [scripts/verify_openclaw_memory_fix.sh](./scripts/verify_openclaw_memory_fix.sh)

## 仓库结构

```text
openclaw-memory-runtime-repair/
├── README.md
├── README.zh-CN.md
├── SKILL.md
├── agents/openai.yaml
├── references/repair-playbook.md
└── scripts/verify_openclaw_memory_fix.sh
```

## 安装

这个仓库本身就是 skill 目录。如果你想让 Codex 自动发现它，可以直接 clone 到技能目录：

```bash
git clone https://github.com/Sandy-di/openclaw-memory-runtime-repair-skill.git \
  "${CODEX_HOME:-$HOME/.codex}/skills/openclaw-memory-runtime-repair"
```

如果你已经把仓库 clone 到别处，也可以直接复制进去：

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R /path/to/openclaw-memory-runtime-repair \
  "${CODEX_HOME:-$HOME/.codex}/skills/openclaw-memory-runtime-repair"
```

## 使用方式

你可以这样显式调用它：

```text
Use $openclaw-memory-runtime-repair to diagnose and fix OpenClaw memory plugin failures on this machine.
```

这个 skill 适合用于本机排障，尤其是 OpenClaw 状态保存在 `~/.openclaw` 时。

## 修复流程概览

这个 skill 采用的修复顺序是：

1. 先用 `openclaw memory-pro stats`、`openclaw memory-pro --help`、`openclaw doctor --non-interactive`、`openclaw plugins list --json` 复现问题。
2. 先清理 `~/.openclaw/openclaw.json`，再改插件代码。
3. 同步修补两份插件源码：
   - `~/.openclaw/extensions/memory-lancedb-pro/index.ts`
   - `~/.openclaw/workspace/plugins/memory-lancedb-pro/index.ts`
4. 如果 CLI 元数据校验还在报错，再处理两份 `openclaw.plugin.json` 里的 manifest 噪音。
5. 重新跑验收，并把剩余输出区分成致命错误还是提示信息。

更细的症状到修复映射，见 [references/repair-playbook.md](./references/repair-playbook.md)。

## 验收脚本

仓库里自带一个验收脚本：

```bash
./scripts/verify_openclaw_memory_fix.sh
```

它会执行：

- `openclaw memory-pro stats`
- `openclaw memory-pro --help`
- `openclaw doctor --non-interactive`

并在遇到以下回归信号时失败：

- `Config validation failed`
- `No active memory plugin is registered`
- `Bundled plugin public surface access blocked`
- `invalid config: embedding`
- `unknown command 'memory-pro'`

## 重要说明

请尽量在真实宿主机状态上运行修复和验收。沙箱环境有时会对 `~/.openclaw/memory/lancedb-pro` 产生假的 `EPERM` 报错，把本来正常的状态误判成坏掉。

另外，OpenClaw 的 CLI 行为会随着版本和本地状态变化而漂移。这个 skill 固化的是一条成功修复过的路径和一套可复跑的验收方法，但如果机器后续状态再次变化，验收脚本仍然可能报出新的失败点。

## Skill 元数据

Codex 实际读取的 skill 入口是 [SKILL.md](./SKILL.md)，UI 元数据在 [agents/openai.yaml](./agents/openai.yaml)。
