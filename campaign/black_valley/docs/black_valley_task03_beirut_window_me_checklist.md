# 任务03《贝鲁特：孤城营救 / Beirut Extraction》ME 接入清单

## 1. 脚本加载顺序

按这个顺序加载：

1. `campaign/black_valley/scripts/task03_beirut_extraction_dialogue.lua`
2. 可选配置脚本：
   - `_G.Task03BeirutExtractionConfig = { debugMode = true }`
3. `campaign/black_valley/scripts/task03_beirut_extraction_controller.lua`

说明：
- `debugMode` 默认关闭
- 若要启用 Debug 菜单和自动对象检查，必须在控制器加载前先写配置

---

## 2. 必需群组名

### 蓝方 / 友军
- `Raven`
- `Atlas`

### 红方
- `AIRPORT_RUSH_1`
- `AIRPORT_RUSH_2`
- `第七装甲师-第一装甲旅-机械化营-A连`
- `第七装甲师-第一装甲旅-第一营-A连`
- `第七装甲师-第一装甲旅-第一营-B连`
- `第七装甲师-第一装甲旅-第一营-C连`
- `第七装甲防空团-第一近程防空营-2`

说明：
- `机械化营-B连`
- `机械化营-C连`

这两支不在任务03里，不需要放。

---

## 3. 必需触发区

- `Z_RUNWAY`
- `Z_AIRPORT_RING`
- `Z_INNER_RING`
- `Z_MECH_A_AXIS`
- `Z_ARM2_A_AXIS`
- `Z_ARM2_B_AXIS`
- `Z_ARM2_C_AXIS`
- `Z_RUNWAY_FIRE_LOCK`
- `Z_ATLAS_HOLD`
- `Z_RAVEN_GATE`
- `Z_RAVEN_LOAD`
- `Z_SAFE_SEA`

---

## 4. 推荐额外触发区

当前控制器默认把下面一种判定复用到了现有区：
- 机械化营突入判定：复用 `Z_INNER_RING`

其中跑道封锁判定现在必须使用独立区：
- `Z_RUNWAY_FIRE_LOCK`
  - 画在坦克/装甲车进入后可以直接封锁跑道或进近线的位置
  - 不要再复用 `Z_RUNWAY`

---

## 5. 旗标用途

控制器会写这些用户旗标：

- `9500` 当前阶段
- `9501` 全部有效玩家离地
- `9502` 首次接通 `Raven`
- `9503` 跑道恢复 / `Atlas` 呼叫窗口已解锁
- `9504` 首次有效打击装甲推进线
- `9505` `Atlas` 已放行 / 进入进近流程
- `9506` `Atlas` 已落地
- `9507` 热装载开始
- `9508` `Atlas` 起飞流程开始
- `9509` 进入拒止分支
- `9510` 任务成功
- `9511` 任务失败
- `9512` `Raven` 已放行
- `9513` `Atlas` 呼叫菜单窗口已开启

---

## 6. 推荐的 ME 绑定方式

### Atlas
如果你要用 ME 的 `Triggered Actions / Push AI Task` 控制 `Atlas`：

- `9505 == 1`
  - 放行 `Atlas` 离开 `Z_ATLAS_HOLD`
  - 转入进近航线

- `9508 == 1`
  - 推送 `Atlas` 滑行 / 起飞动作
  - 或切换到离场航线

### Raven
如果你要用 ME 推 `Raven`：

- `9512 == 1`
  - 放行 `Raven` 从隐蔽区出发
  - 进入南门路线

说明：
- 控制器负责判定“什么时候该放”
- ME 负责把实际 AI 路线推起来

---

## 7. Debug 模式

启用方式：

在加载控制器之前先执行：

```lua
_G.Task03BeirutExtractionConfig = {
    debugMode = true
}
```

开启后会得到：

- F10 `Debug` 子菜单
- 脚本载入后自动检查群组和触发区命名
- 若有未命中，会立即在游戏内播报

---

## 8. 任务内特殊说明

- 开局录音没有音频资源，当前是文字播报
- `Gate B` 不是单机离地，而是**所有有效玩家离地**
- `SA-15` 不阻止 `Atlas` 放行
- 玩家可以误判放行，后果由战场承担
- `Atlas` 落地前被击落：转入摧毁 `Raven`
- `Atlas` 起飞后被击落：直接失败，不再转 `Raven`
- 玩家若在 `Atlas` 已落地后放弃任务：转入摧毁地面上的 `Atlas`
