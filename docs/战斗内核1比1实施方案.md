# 《热血格斗传说》Godot 复刻：战斗内核 1:1 实施方案

## 1. 目标与边界
### 1.1 目标（P0）
在 Godot 4 中复刻原作战斗“手感内核”，优先保证：
1. 固定逻辑帧驱动（逐帧可控），不依赖 AnimationPlayer 时间轴作为主逻辑。
2. 攻击判定、受击判定、硬直、击退、倒地起身、可打断/可取消窗口一致。
3. 命令输入（前前、跳跃派生等）与动作触发一致。
4. 支持单次命中与多段命中。

### 1.2 非目标（后补）
1. 故事模式、菜单、秘籍入口、完整 UI。
2. 全角色全招式一次性完成。
3. 网络同步。

## 2. 第一性原理拆解
战斗系统最小原子只有 6 个：
1. 输入：在固定窗口内识别命令。
2. 状态：角色当前可做什么（idle/attack/hurt/knockdown...）。
3. 帧数据：每一逻辑帧显示和判定配置。
4. 碰撞盒：hitbox/hurtbox 的时序与形状。
5. 命中结算：伤害、硬直、击退、命中停顿。
6. 状态迁移：动作结束、被打断、取消连段。

只要这 6 点可控且可验证，原作手感就可逐步逼近。

## 3. 最短路径（实现顺序）
1. 固定 tick 战斗循环（60 Hz）。
2. MoveData/FrameData 数据结构。
3. idle/attack/hurt 三态跑通。
4. hit/hurt 结算跑通（单次 -> 多段）。
5. 命令输入解析（前前、方向+攻击）。
6. 倒地/起身与移动状态。
7. 将《游戏描述.md》中的招式与变体映射为数据。

## 4. Godot 工程结构建议

```text
res://
  scenes/
    battle/
      battle_test.tscn
    fighter/
      fighter.tscn
  scripts/
    core/
      battle_clock.gd
      input_buffer.gd
      command_parser.gd
      fighter_state_machine.gd
      move_runner.gd
      hit_resolver.gd
    data/
      move_data.gd
      frame_data.gd
      hitbox_data.gd
      hurtbox_data.gd
      hit_effect_data.gd
    fighter/
      fighter_controller.gd
  data/
    moves/
      player_idle.tres
      player_attack_light.tres
      player_hurt.tres
```

## 5. 节点结构建议

```text
FighterRoot (CharacterBody2D)
  Visual (Sprite2D)
  BoxesRoot (Node2D)
    HitboxArea (Area2D)
      HitboxShape (CollisionShape2D)
    HurtboxArea (Area2D)
      HurtboxShape (CollisionShape2D)
  FacingAnchor (Marker2D)
```

## 6. 数据模型（核心字段）
### 6.1 MoveData
1. move_id
2. frames: Array[FrameData]
3. on_finish_state（默认 idle）
4. priority（抢招/覆盖判定）
5. tags（ground/air/dash/special）

### 6.2 FrameData
1. sprite_id（当前显示帧）
2. duration_ticks（逻辑帧时长）
3. can_interrupt
4. can_cancel
5. hitboxes
6. hurtboxes
7. velocity_override（可选）
8. events（音效、命中停顿等）

### 6.3 HitEffectData
1. damage
2. hitstun_ticks
3. blockstun_ticks（后续）
4. pushback: Vector2
5. knockdown: bool
6. hitstop_attacker_ticks
7. hitstop_victim_ticks

## 7. 关键机制设计
### 7.1 固定帧循环
1. `_physics_process` 中累积并按固定 step 执行战斗 tick。
2. 所有持续时间统一用 ticks，不用秒。
3. 3 秒停留帧 = 180 ticks（60Hz）。

### 7.2 命中去重与多段
1. `single`：一个动作实例中，同目标只记一次命中。
2. `multi`：每个目标记录下次可命中 tick，达到间隔后可再次命中。

### 7.3 动作取消与打断
1. `can_interrupt`: 允许高优先级状态覆盖（例如受击）。
2. `can_cancel`: 允许从当前 move 切入指定后续 move。
3. 取消规则写入 move 配置，不写死在代码里。

### 7.4 输入缓冲
1. 保存最近 N ticks 的方向与按键边沿。
2. 命令按优先级匹配（必杀 > 普攻）。
3. 匹配成功后消费对应输入片段，避免重复触发。

## 8. P0 验收标准（必须全部通过）
1. idle 可稳定循环。
2. attack 可进入、播放、结束回 idle。
3. attack 某帧停留 180 ticks，停留期间 hitbox 持续有效。
4. 命中后对方进入 hurt/hitstun，并产生击退。
5. 支持 single 与 multi 两种命中模式切换。
6. 受击可打断当前非霸体动作。
7. 相同输入序列在重复测试中结果一致。

## 9. 版本计划
### 9.1 Week 1（内核跑通）
1. 建工程、搭骨架、实现 tick + 三态。
2. 完成最小 hit/hurt 结算。
3. 完成 1 个带 3 秒停留帧的攻击动作。

### 9.2 Week 2（手感逼近）
1. 命令输入与取消窗口。
2. 击退、倒地、起身。
3. 基础 AI 靶子与回归测试场景。

### 9.3 Week 3（内容映射）
1. 从《游戏描述.md》抽取招式触发与参数。
2. 增加快拳快腿等角色差异配置。
3. 平衡与微调（帧数、位移、硬直）。

## 10. 风险与对策
1. 风险：直接用 AnimationPlayer 会导致逻辑不可控。
   对策：动画只负责表现，逻辑以 FrameData 为唯一真源。
2. 风险：输入解析与状态机耦合过深，后续难扩展。
   对策：输入、状态、命中三模块分离。
3. 风险：先做全招式导致工期爆炸。
   对策：先做 2 角色 x 6 招的代表集，验证后批量导入。

## 11. 下一步（立即执行）
1. 初始化 Godot 4 项目结构。
2. 落地 `MoveData/FrameData` 资源脚本。
3. 完成最小 demo：idle / attack(含 3 秒停留) / hurt。
