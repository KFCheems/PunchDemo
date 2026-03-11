# Claude Trellis 执行规范（当前目录就绪版）

本目录已经落好可直接复制到游戏根目录的 Trellis 任务文件。  
你不需要再手工创建骨架，只要复制后让 Claude 按任务执行即可。

## 已创建文件

1. `.trellis/spec/shared/index.md`
2. `.trellis/spec/shared/fighting-core-constraints.md`
3. `.trellis/tasks/03-09-core-combat-p0/task.json`
4. `.trellis/tasks/03-09-core-combat-p0/prd.md`
5. `.trellis/tasks/03-09-core-combat-p0/implement.jsonl`
6. `.trellis/tasks/03-09-core-combat-p0/check.jsonl`
7. `.trellis/tasks/03-09-core-combat-p0/debug.jsonl`

## 设计目标（与原方案一致）

- 只做《热血格斗传说》战斗内核 1:1 复刻（P0）。
- 外层系统（菜单、剧情、秘籍入口、完整 UI）后补。
- 固定 60Hz + MoveData/FrameData 数据驱动。
- 必须覆盖：idle / attack / hurt、single/multi hit、180 ticks 停留帧持续判定。

## 你对 Claude 的启动指令（直接复制）

```text
请严格按 Trellis 当前任务执行。
任务目录：.trellis/tasks/03-09-core-combat-p0

先读取：
1) prd.md
2) implement.jsonl 中列出的所有上下文文件
3) .trellis/spec/shared/fighting-core-constraints.md

执行要求：
1. 先做“需求完整性检查”；若有歧义先提问，不要直接编码。
2. 若目标清晰，按最短路径实现，不做超范围扩展。
3. 每完成一个验收项，给出复现步骤与结果。
4. 若你发现当前路径不是最短，必须给出更短替代方案并说明取舍。
5. 任何偏离 fighting-core-constraints.md 的行为都要先请求确认。
```

## 可选命令（在复制后的游戏根目录执行）

```bash
# 查看任务
py ./.trellis/scripts/task.py list

# 查看任务上下文
py ./.trellis/scripts/task.py list-context .trellis/tasks/03-09-core-combat-p0

# 将该任务设为当前任务（可选）
py ./.trellis/scripts/task.py start .trellis/tasks/03-09-core-combat-p0
```

## 审慎规则（建议你保留）

1. 有歧义先停下提问。
2. 先内核后外层，不要提前做 UI/模式。
3. 先验收后总结，避免“看起来完成”但不可复现。

## ASCII 上下文镜像（为避免中文路径编码问题）

1. `docs/combat-kernel-1to1-plan.md`（来自 `docs/战斗内核1比1实施方案.md`）
2. `docs/requirements.md`（来自 `需求.md`）
3. `docs/game-description.md`（来自 `游戏描述.md`）

`implement.jsonl` 和 `check.jsonl` 已改为引用以上 ASCII 路径。
