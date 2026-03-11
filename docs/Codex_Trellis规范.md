# Codex Trellis 执行规范（当前目录就绪版）

本目录已经调整为 Codex 可直接使用的版本。

## 已就绪内容

1. Codex 技能目录：`.agents/skills/start/SKILL.md`、`.agents/skills/finish-work/SKILL.md`
2. Trellis 共享约束：`.trellis/spec/shared/`
3. 当前任务：`.trellis/tasks/03-09-core-combat-p0/`
4. Codex 开发者身份：`.trellis/.developer` 已设为 `codex-agent`

## 建议启动顺序

```powershell
py ./.trellis/scripts/get_context.py
py ./.trellis/scripts/task.py start .trellis/tasks/03-09-core-combat-p0
```

如果 Trellis 仍误判到 `.claude`，先执行：

```powershell
$env:TRELLIS_PLATFORM = 'codex'
```

## Codex 会话入口

优先阅读：

1. `.agents/skills/start/SKILL.md`
2. `.trellis/tasks/03-09-core-combat-p0/prd.md`
3. `.trellis/spec/shared/fighting-core-constraints.md`
4. `.trellis/tasks/03-09-core-combat-p0/implement.jsonl`

## 当前任务的收尾检查

收尾时阅读：

1. `.agents/skills/finish-work/SKILL.md`
2. `.trellis/tasks/03-09-core-combat-p0/check.jsonl`

## 说明

- 任务上下文已改成 Codex 可识别路径，不再依赖 `.claude/commands/...`。
- 保留 `.claude` 和 `.cursor` 不影响使用，但 Trellis 平台应优先按 Codex 处理。
- 若后续给 Codex 补 PNG 和 JSON，只让它做素材映射层，不改战斗内核约束。
- `live input replay` 属于 battle test harness / validation layer，不是重做 input system 的入口。
- 当前 `live input replay` 默认只保留最近一段内存快照；不要在 P0 擅自扩展成录制文件系统。
- 若继续增强 replay，优先补结果签名对比与 deterministic verdict，而不是先做持久化录制。
