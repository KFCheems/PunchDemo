# PunchDemo

Godot 4.x 2D 格斗/清版动作项目，当前目标是先做出**可验证、可扩展的《热血格斗传说》风格战斗内核**，再逐步完善正式游戏流、角色资源化、地图与毕设内容。

---

## 1. 当前项目定位

这个仓库现在不是“纯 demo”，也不是“完整成品”，而是：

- 已有稳定的 **fixed-tick combat core**
- 已有 **debug sandbox / replay validation**
- 已有最小 **formal battle flow**
- 正在向 **毕业设计级 Godot 工程** 演进

核心设计原则：

- 战斗规则在代码里
- 动作内容在资源里
- 表现映射独立于战斗逻辑

---

## 2. 当前主要目录

```text
assets/
  audio/
  sprites/
resources/
  fighters/
  moves/
scenes/
  boot/
  ui/
  battle/
  fighters/
  debug/
scripts/
  autoload/
  battle/
    core/
    runtime/
    debug/
  fighter/
    base/
    presentation/
  data/
    schema/
.trellis/
  spec/
  tasks/
  task-templates/
```

更完整的目录规则见：

- [.trellis/spec/shared/godot-directory-structure.md](./.trellis/spec/shared/godot-directory-structure.md)

---

## 3. 运行流与调试流

### Formal flow

主入口：

- `res://scenes/boot/boot.tscn`

正式流程：

- Boot
- Main Menu
- Battle Scene
- Result Screen

### Debug flow

调试战斗场景：

- `res://scenes/debug/battle_sandbox.tscn`

这里保留：

- deterministic replay
- live input replay
- 调试文本面板
- 命中框/受击框可视化

**规则**：  
正式 flow 和 debug flow 都必须共用同一套 combat core，不允许各写一套。

详见：

- [.trellis/spec/shared/battle-runtime-boundaries.md](./.trellis/spec/shared/battle-runtime-boundaries.md)

---

## 4. 战斗架构概览

### Combat core

位于：

- `scripts/battle/core/`

核心模块：

- `input_buffer.gd`
- `fighter_state_machine.gd`
- `move_runner.gd`
- `hit_resolver.gd`

这些模块负责：

- fixed tick 行为
- frame 推进
- 命中判定
- 状态切换
- deterministic behavior

### Fighter layer

位于：

- `scripts/fighter/base/`

当前共享 fighter 模块：

- `fighter_controller.gd`
- `fighter_runtime_state.gd`
- `fighter_input.gd`
- `fighter_motor.gd`
- `fighter_combat.gd`
- `fighter_grab.gd`
- `fighter_stats.gd`

### Data layer

Schema：

- `scripts/data/schema/`

内容资源：

- `resources/moves/`
- `resources/fighters/`

说明见：

- [.trellis/spec/shared/data-driven-combat.md](./.trellis/spec/shared/data-driven-combat.md)

---

## 5. 必读 Trellis 规范

开始任何中大型改动前，至少阅读：

### Shared specs

- [.trellis/spec/shared/index.md](./.trellis/spec/shared/index.md)
- [.trellis/spec/shared/fighting-core-constraints.md](./.trellis/spec/shared/fighting-core-constraints.md)
- [.trellis/spec/shared/godot-directory-structure.md](./.trellis/spec/shared/godot-directory-structure.md)
- [.trellis/spec/shared/data-driven-combat.md](./.trellis/spec/shared/data-driven-combat.md)
- [.trellis/spec/shared/resource-naming.md](./.trellis/spec/shared/resource-naming.md)
- [.trellis/spec/shared/battle-runtime-boundaries.md](./.trellis/spec/shared/battle-runtime-boundaries.md)

### Guides

- [.trellis/spec/guides/index.md](./.trellis/spec/guides/index.md)
- [.trellis/spec/guides/how-to-add-a-new-fighter.md](./.trellis/spec/guides/how-to-add-a-new-fighter.md)
- [.trellis/spec/guides/how-to-add-a-new-move.md](./.trellis/spec/guides/how-to-add-a-new-move.md)
- [.trellis/spec/guides/how-to-add-a-new-stage.md](./.trellis/spec/guides/how-to-add-a-new-stage.md)

---

## 6. Trellis 日常工作流

### 6.1 创建任务

```powershell
python3 ./.trellis/scripts/task.py create "Migrate run punch to resource" --slug migrate-run-punch
```

### 6.2 初始化上下文

```powershell
python3 ./.trellis/scripts/task.py init-context .trellis/tasks/03-13-migrate-run-punch fullstack
```

### 6.3 设置当前任务

```powershell
python3 ./.trellis/scripts/task.py start .trellis/tasks/03-13-migrate-run-punch
```

### 6.4 查看任务

```powershell
python3 ./.trellis/scripts/task.py list
python3 ./.trellis/scripts/task.py list --mine
```

---

## 7. 任务模板怎么用

任务模板位于：

- [`.trellis/task-templates/`](./.trellis/task-templates/)

可用模板：

- `system-refactor/`
- `move-resource-migration/`
- `fighter-addition/`
- `stage-addition/`

模板不会放进 `.trellis/tasks/`，因为 `task.py list` 会把 `.trellis/tasks/` 下的目录当真实任务。

### 推荐用法

1. 先创建真实任务目录
2. 再从模板复制内容
3. 替换占位符
4. 根据实际任务裁剪

示例：

```powershell
python3 ./.trellis/scripts/task.py create "Add fighter riki" --slug add-fighter-riki
```

然后参考：

- `.trellis/task-templates/fighter-addition/`

模板说明见：

- [.trellis/task-templates/README.md](./.trellis/task-templates/README.md)

---

## 8. 这个项目里常见的任务类型

### A. 系统重构

适用：

- controller 瘦身
- runtime/core/debug 边界整理
- DataManager 拆分
- 目录迁移

模板：

- `system-refactor`

### B. 动作资源化

适用：

- 把 move 从 `demo_move_library.gd` 迁移到 `.tres`
- 补 display id
- 更新 fighter definition 的 move map

模板：

- `move-resource-migration`

### C. 新增角色

适用：

- 新角色素材接入
- 新 fighter definition
- visual profile
- move map 配置

模板：

- `fighter-addition`

### D. 新增地图

适用：

- stage 背景与 BGM
- stage data
- formal runtime stage integration

模板：

- `stage-addition`

---

## 9. 当前最重要的工程约束

### 必须坚持

- Combat core 必须 deterministic
- `MoveData / FrameData` 是战斗内容真源
- 正式战斗和 sandbox 必须共用 core
- 新内容优先放到资源层，而不是继续塞进 controller

### 不要做

- 不要把 combat 逻辑放回 AnimationPlayer 时间轴
- 不要让 UI 直接改 combat core
- 不要在 debug harness 中偷偷实现 formal runtime 没有的行为
- 不要把新资源继续塞进旧目录如 `assets/BGM/`、`assets/backgrounds/`、`assets/Sprite/`

---

## 10. 当前建议开发顺序

如果继续推进毕业设计版本，推荐优先级：

1. 继续 move 资源化
2. 继续清理 legacy 路径
3. 新增 fighter / stage
4. 补完整 UI/设置/角色选择
5. 做 AI 和答辩材料

---

## 11. 仓库内附带插件

仓库中还包含 Godot 编辑器插件：

- `addons/copy_all_errors/`

它是一个辅助调试插件，不是本项目战斗架构的核心组成部分。  
如果需要单独发布插件，请将插件说明拆到独立文档或插件仓库 README。

---

## 12. License

[MIT](./LICENSE)
