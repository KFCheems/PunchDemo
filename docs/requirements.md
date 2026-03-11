请帮我在 Godot 4 里设计一个 2D 格斗/清版动作角色的逐帧战斗系统。

我的角色动作是用 Aseprite 画的，但我决定采用 静态帧 PNG / spritesheet 导入，不使用 Aseprite 插件来做状态机。

我要的是 Godot 内部自己控制的帧数据系统，而不是普通动画播放。

核心需求
每个动作由多个 FrameData 组成
每一帧都能单独设置：
显示哪张图
持续多少逻辑帧
是否可被打断
是否可取消
是否开启 hitbox / hurtbox
支持某一帧停留几秒
停留期间 hitbox 持续有效
命中敌人后可触发 hurt / hitstun / 击退 / 动画变化
支持：
单次命中
持续多段命中
当前动作结束后能回到 idle
请优先给我
推荐的整体架构
推荐的节点结构
MoveData / FrameData 的 GDScript 示例
一个最小可运行 Demo：
idle
attack
hurt
一个攻击动作示例：
其中某一帧停留 3 秒，并且停留期间持续有攻击判定
额外要求
请尽量用 Godot 4 + GDScript
不要把逻辑主要放在 AnimationPlayer 时间轴里
重点是“逐帧战斗逻辑控制”，不是普通播动画