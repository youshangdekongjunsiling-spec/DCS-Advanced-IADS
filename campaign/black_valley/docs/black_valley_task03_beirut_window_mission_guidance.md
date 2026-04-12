# 任务03《贝鲁特：孤城营救 / Beirut Extraction》任务落地指导

用途：
- 这是一份给任务开发阶段使用的详细落地指导文件
- 目标是把现有的玩家简报、内部设计和对白草案，收束成一份可直接照着做的实施清单
- 这份文件不负责新增剧情，不负责改对白，只负责把现有方案落地化

约束：
- 严格遵照当前对白草案
- 不允许在实现阶段临场改词、加词、换词
- 若实现上需要改对白，必须先回到对白草案文件审批

对应文档：
- [玩家简报](c:/Users/yuanh/Desktop/DCS现代化空地对抗/campaign/black_valley/docs/black_valley_task03_beirut_window_player_brief.md)
- [内部脚本设计](c:/Users/yuanh/Desktop/DCS现代化空地对抗/campaign/black_valley/docs/black_valley_task03_beirut_window_internal_design.md)
- [对白草案](c:/Users/yuanh/Desktop/DCS现代化空地对抗/campaign/black_valley/docs/black_valley_task03_beirut_window_dialogue_draft.md)
- [对白风格总结](c:/Users/yuanh/Desktop/DCS现代化空地对抗/campaign/black_valley/docs/black_valley_dialogue_style_guide.md)

---

## 1. 核心结论

任务03不是线性清关任务。

玩家从任务开始就同时面对三条压力线：
- 机场 `rush`
- 里亚格方向装甲推进
- `SA-15` 持续存在的进近风险

脚本需要做的不是“按顺序放怪”，而是：
- 用状态机控制玩家知道什么
- 用事件门控制谁在什么时候说话
- 用少量硬门控决定 `Atlas / Raven` 什么时候能进流程

---

## 2. 任务内对象和命名

### 2.1 蓝方 / 友军
- `Raven`
  - 地面残余力量频道
  - 同时也是车队群组名
- `Atlas`
  - `C-17` 群组名 / 呼号
- `QUEEN`
  - 二号人物代号
- `ORACLE`
  - 绝密设备代号

### 2.2 红方主要群组
- `AIRPORT_RUSH_1`
- `AIRPORT_RUSH_2`
- `第七装甲师-第一装甲旅-机械化营-A连`
- `第七装甲师-第一装甲旅-第一营-A连`
- `第七装甲师-第一装甲旅-第一营-B连`
- `第七装甲师-第一装甲旅-第一营-C连`
- `第七装甲防空团-第一近程防空营-2`

### 2.3 已移出任务03的群组
- `第七装甲师-第一装甲旅-机械化营-B连`
- `第七装甲师-第一装甲旅-机械化营-C连`

---

## 3. 关键区域

### 必需
- `Z_RUNWAY`
- `Z_AIRPORT_RING`
- `Z_INNER_RING`
- `Z_RUNWAY_FIRE_LOCK`
- `Z_RAVEN_GATE`
- `Z_RAVEN_LOAD`
- `Z_SAFE_SEA`
- `Z_RUNWAY_FIRE_LOCK`

### 建议额外准备
- 跑道封锁判定区
- `机械化营-A连` 机场突入终点区
- `Atlas` 地面卡死判定区

---

## 4. 玩家人数适配

### 规则
- `1` 名有效玩家：
  - `机械化营-A连`
  - 第一营三连中随机 `1` 连
- `2` 名有效玩家：
  - `机械化营-A连`
  - 第一营三连中随机 `2` 连
- `3` 名及以上有效玩家：
  - `机械化营-A连`
  - 第一营 `A/B/C` 全部参与

### 说明
- 未参与本轮任务的装甲连直接锁在原地
- `SA-15` 始终参与
- 机场 `rush` 波始终存在，但规模可随玩家人数微调

---

## 5. 主状态机

状态枚举：
- `intro`
- `startup`
- `takeoff`
- `airport_contact`
- `airport_rush`
- `runway_recovered`
- `armor_pressure`
- `atlas_call_window`
- `atlas_inbound`
- `atlas_land`
- `hot_load`
- `atlas_depart`
- `atlas_crash_denial`
- `success`
- `fail`

实现要求：
- 状态切换必须只由脚本统一维护
- 对白触发不能直接靠时间硬播，必须挂在状态变化或事件门上

---

## 6. 菜单设计

F10 菜单至少包含：
- `Atlas，机场安全，立即近进！`
- `无法清空机场，营救已经不可能，放弃任务。`

### 菜单可用时机
- `放弃任务`
  - 从 `takeoff` 起常驻
- `呼叫 Atlas`
  - 在 `runway_recovered` 第一次成立后解锁
  - 一直保留到：
    - `Atlas` 已进入进近流程
    - 或任务进入失败 / 拒止分支

---

## 7. 详细事件门

## Gate A：黑场开场文字播报
触发：
- `MISSION START`

动作：
- 以文字播报方式顺序播放 Phase `-2` 全部必播内容
- 状态切到 `startup`

备注：
- 不使用音频资源
- 不要在黑场后立即播第二段
- 给 `1-2s` 静默缓冲

## Gate B：所有有效玩家离地
触发：
- 当前所有有效玩家都已离地

动作：
- 状态切到 `takeoff`
- 开启主任务频道
- 播放 `Phase 0` 必播对白

## Gate C：首次进入贝鲁特机场外圈
触发：
- 任意有效玩家进入 `Z_AIRPORT_RING`

动作：
- 状态切到 `airport_contact`
- `Raven` 入频
- 播放 `Phase 1` 必播对白
- 立即启动机场 `rush` 波
- 状态切到 `airport_rush`

## Gate D：机场 rush 被压到可控
触发：
- `AIRPORT_RUSH_1` 被压到阈值以下
- 若已激活 `AIRPORT_RUSH_2`，其也被压到阈值以下
- `Z_RUNWAY` 内持续无敌军若干秒

动作：
- 状态切到 `runway_recovered`
- 播放 `Phase 3` 必播对白
- 解锁 `Atlas` 呼叫菜单
- 状态切到 `atlas_call_window`

## Gate E：首次有效打击装甲推进
触发：
- 玩家首次对任一活跃装甲推进连造成有效打击

动作：
- 若尚未进入 `armor_pressure`，状态切到 `armor_pressure`
- 播放 `Phase 4` 首次命中对白
- 后续每次有效打击，从短句池中选一句 AWACS 压力句

## Gate F：SA-15 新开机周期
触发：
- `第七装甲防空团-第一近程防空营-2` 每次新的开机周期

动作：
- 播放一次 `Phase 5` 对应 AWACS 告警
- 刷新 F10 大致位置标记
- 不改状态

限制：
- 同一开机周期只播一次
- 不能因为同一周期里反复亮灭而刷屏

## Gate G：玩家呼叫 Atlas
触发：
- 玩家点击 `Atlas，机场安全，立即近进！`

动作顺序：
1. 先播玩家原句
2. 再做安全校验

校验失败条件：
- 机场 `rush` 波未清
- 跑道当前仍被装甲营压制

失败结果：
- 播放 `Raven` 拒绝降落对白
- `Atlas` 不放行
- `Raven` 不出发
- 状态不变

成功结果：
- 状态切到 `atlas_inbound`
- `Atlas` 开始沿既定航路进近
- `Raven` 放行
- 播放 `Phase 6B` 对白

### 重要说明
- `SA-15` 不参与这一步的放行判定
- 玩家可以误判并放行
- 后果由后面的风险链承担

## Gate H：Raven 接近南门
触发：
- `Raven` 进入 `Z_RAVEN_GATE`

动作：
- 播放 `Phase 9` 南门火力对白
- 强化机场外沿压力

## Gate I：Atlas 落地
触发：
- `Atlas` 成功落地并停稳

动作：
- 状态切到 `atlas_land`
- 播放 `Phase 10` 落地对白

## Gate J：Raven 进入装载区
触发：
- `Raven` 进入 `Z_RAVEN_LOAD`
- 且 `Atlas` 已落地

动作：
- 状态切到 `hot_load`
- 开始显性 `120s` 热装载倒计时
- 播放 `Raven` 入场相关对白

## Gate K：热装载完成
触发：
- `120s` 热装载倒计时归零

动作：
- `Atlas` 自动进入滑行 / 起飞流程
- 状态切到 `atlas_depart`
- 播放 `Phase 11` 对白

## Gate L：Atlas 卡地
触发：
- `Atlas` 在地面停滞超过 `130s`

动作：
- 保持任务主状态不立即失败
- 持续触发 AWACS 高压询问句池
- 玩家仍可通过 `放弃任务` 菜单终止任务并进入拒止分支

## Gate M：Atlas 成功脱海
触发：
- `Atlas` 进入 `Z_SAFE_SEA`

动作：
- 状态切到 `success`
- 播放 `Phase 12` 成功收束对白

---

## 7A. Debug 模式

### 目标
- 用于任务开发、自测、联调
- 不影响正式版本默认玩法

### 基本规则
- 脚本提供独立 `debugMode` 开关
- `debugMode == true` 时，F10 根菜单下增加 `Debug` 子菜单
- `debugMode == false` 时，`Debug` 子菜单完全不出现

### Debug 菜单能力
- `强制 Gate A`
- `强制 Gate B`
- `强制 Gate C`
- `强制 Gate D`
- `强制 Gate E`
- `强制 Gate F`
- `强制 Atlas 可呼叫`
- `强制 Atlas 进近`
- `强制 Atlas 落地`
- `强制进入热装载`
- `强制 Atlas 脱海成功`
- `强制进入拒止分支`

### 限制
- 每个强制触发都必须走统一的状态切换和对白绑定函数
- 不能为了 debug 直接跳过内部状态写入
- debug 动作需要写日志，便于复盘测试路径

---

## 8. 时间控制器设计

这关不采用“严格按秒数推进全部剧情”的方式。
推荐结构：

### 前半段
- 用事件门推进
- 不强行限时

### 中盘
- 事件门 + 持续压力
- 让玩家自己决定什么时候继续压机场、什么时候去打装甲、什么时候赌 `Atlas`

### 末段
- 进入 `hot_load` 后启用真正硬时限

## 推荐总时长
- 单人：`40 - 55` 分钟
- 多人：`35 - 50` 分钟

## 时间窗建议
- `00:00 - 05:00`
  - 黑场、启动、起飞
- `05:00 - 15:00`
  - 贝鲁特接敌、机场 `rush`、跑道第一次恢复
- `08:00` 起
  - 装甲推进线已持续存在，玩家可以提前介入
- `15:00` 起
  - `Atlas` 呼叫项可被尝试使用
- `15:00 - 35:00`
  - 中盘博弈：机场、装甲、`SA-15` 风险三线拉扯
- `Atlas` 落地后
  - `120s` 热装载
- 热装后
  - `130s` 卡地高压阈值

---

## 9. 对白绑定规则

### 9.1 原则
- 严格使用当前对白草案
- 不得在脚本里临时改词
- 不得把对白压缩成“差不多意思”

### 9.2 绑定方式
- 每个 Phase 以“必播 / 可选 / 条件式 / 句池”形式绑定
- 必播句必须按顺序播
- 可选句按玩家人数和当前态势决定
- 句池只用于重复性压力播报

### 9.3 共享频道
- `中队长`、`AWACS / 灯塔`、`Raven`、`Atlas` 为固定频道
- `玩家` 台词按触发者优先，再做多人轮换

---

## 10. 失败分支

## Fail A：机械化营-A连冲进机场
条件：
- `机械化营-A连` 到达机场突入终点

结果：
- `Raven` 被俘
- `ORACLE` 被缴获
- 灾难性失败

## Fail B：Raven 被毁
条件：
- `Raven` 在完成交接前被摧毁

结果：
- 主任务失败

## Fail C：Atlas 落地前被击落
条件：
- `Atlas` 在落地前被击落

结果：
- 进入 `atlas_crash_denial`
- 新目标：摧毁 `Raven`
- 严格使用对白稿 `5A`

## Fail D：Atlas 起飞后被击落
条件：
- `Atlas` 已离地后被击落

结果：
- 直接进入失败收束
- 不再进入 `Raven` 拒止阶段

## Fail E：玩家主动放弃任务
条件：
- 玩家点击放弃菜单
- 单人：一次生效
- 多人：所有有效玩家全部同意才生效

结果分两种：

### Atlas 尚未落地
- 进入 `atlas_crash_denial`
- 目标改为摧毁 `Raven`

### Atlas 已落地但未成功起飞
- 进入 `atlas_crash_denial`
- 目标改为摧毁地面上的 `Atlas`

---

## 11. Mission Editor 与脚本分工

### 适合放在 ME 里
- 所有地面群组和基础路线
- `Atlas` 待机、进近、撤离航线
- 所有触发区
- 机场守军与氛围对象

### 适合放在任务控制脚本里
- 玩家检测
- 状态机
- 菜单
- 事件门
- 对白分配
- 倒计时
- `Atlas / Raven` 放行逻辑
- 多人投票放弃逻辑
- 失败与拒止分支

---

## 12. 实施顺序建议

建议开发顺序：

1. 先完成 ME 摆放
2. 再接状态机骨架
3. 再接机场线
4. 再接装甲推进线
5. 再接 `SA-15` 风险播报
6. 再接 `Atlas / Raven` 放行与热装载
7. 最后接失败分支和拒止分支

理由：
- 这样最容易逐段测试
- 每段都能单独验证，不会一上来就让整关一起炸

---

## 13. 当前已确认项

1. `Raven` 群组名已确定
2. `Atlas` 群组名已确定
3. `QUEEN / ORACLE` 代号已确定
4. 只有 `机械化营-A连` 参与机场突入
5. `机械化营-B连 / C连` 已从任务03移除
6. `第七装甲防空团-第一近程防空营-2` 单独编组
7. `Atlas` 路线已预先设置好，只需脚本控制待机与放行
8. 热装载显性倒计时固定为 `120s`
9. 不引入贝卡谷地边缘节点远程支援风险
## 接入更新

- `Z_MECH_A_AXIS` 已移除，不再需要建立
- `Raven / AIRPORT_RUSH_1 / AIRPORT_RUSH_2` 现在推荐改成 `Late Activation + GROUP ACTIVATE`
- 新增激活旗标：
  - `9514` -> `AIRPORT_RUSH_1`
  - `9515` -> `AIRPORT_RUSH_2`
- `Raven` 继续复用：
  - `9512` -> `Raven`
