# Skynet-IADS 模块地图

## 1. 构建与装配层

### `Skynet-IADS/build-tools/build-compiled-script.ps1`

作用：

- 按固定顺序拼接源码
- 产出 `demo-missions/skynet-iads-compiled.lua`
- 生成 README

重要性：

- 很高
- 这套项目没有 `require` 依赖树，构建顺序就是“真实链接顺序”

当前拼接顺序：

1. `skynet-iads-supported-types.lua`
2. `highdigitsams/skynet-iads-high-digit-sams-suported-types.lua`
3. `skynet-iads-logger.lua`
4. `skynet-iads.lua`
5. `skynet-mooose-a2a-dispatcher-connector.lua`
6. `skynet-iads-table-delegator.lua`
7. `skynet-iads-abstract-dcs-object-wrapper.lua`
8. `skynet-iads-abstract-element.lua`
9. `skynet-iads-abstract-radar-element.lua`
10. `skynet-iads-awacs-radar.lua`
11. `skynet-iads-command-center.lua`
12. `skynet-iads-contact.lua`
13. `skynet-iads-early-warning-radar.lua`
14. `skynet-iads-jammer.lua`
15. `skynet-iads-sam-search-radar.lua`
16. `skynet-iads-sam-site.lua`
17. `skynet-iads-sam-tracking-radar.lua`
18. `syknet-iads-sam-launcher.lua`
19. `skynet-iads-harm-detection.lua`

结论：

- 理解源码时，不能只看“谁调用谁”，还要看“谁必须先定义”

## 2. 数据层

### `Skynet-IADS/skynet-iads-source/skynet-iads-supported-types.lua`

作用：

- 定义 Skynet 支持的防空系统数据库
- 每个系统包含：
  - `searchRadar`
  - `trackingRadar`
  - `launchers`
  - `misc`
  - `name.NATO`
  - `harm_detection_chance`
  - `can_engage_harm`

你什么时候改它：

- 新增一种 DCS 防空系统支持
- 修正某个系统的组成单元
- 修改 NATO 名称
- 调整 HARM 能力元数据

不适合在这里做的事：

- 修改 SAM 激活逻辑
- 修改 HARM 轨迹判定
- 修改网络覆盖逻辑

## 3. 基础封装层

### `skynet-iads-abstract-dcs-object-wrapper.lua`

作用：

- 提供 DCS 对象包装
- 提供基础属性：
  - `dcsRepresentation`
  - `dcsName`
  - `typeName`
- 提供 `inheritsFrom`

这是整个项目的 OO 根。

### `skynet-iads-abstract-element.lua`

作用：

- 在 DCS 包装之上，增加 IADS 元素通用能力：
  - 电源
  - 连接节点
  - DCS 事件处理
  - 摧毁状态传播

这是“任何 IADS 元素”的基类。

### `skynet-iads-abstract-radar-element.lua`

作用：

- 真正的行为中枢
- 在抽象元素基础上加入：
  - launchers / radars 组合
  - EW 父子关系
  - 自治状态
  - 开机 / 关机
  - 目标缓存
  - 导弹在途
  - HARM 防御
  - Point defence
  - Jammer 响应

这是最重要的“必读文件”。

## 4. 核心总控层

### `skynet-iads.lua`

作用：

- IADS 实例创建
- 加入 EW / SAM / Command Center
- 启动主循环
- 合并 contact track file
- 构建 EW 覆盖图
- 分发目标给 SAM
- 调用 HARM 与 Logger

关键方法：

- `create`
- `addEarlyWarningRadar`
- `addSAMSite`
- `addCommandCenter`
- `evaluateContacts`
- `buildRadarCoverage`
- `activate`
- `deactivate`

你要改“系统层规则”时，通常先看这里。

## 5. 实体层

### `skynet-iads-early-warning-radar.lua`

作用：

- 把单个地面 EW 单位包装成 EWR
- 从数据库里校验是否支持
- 建立搜索雷达包装器
- 采用更简单的自治判据

入口：

- `setupElements`
- `setToCorrectAutonomousState`

### `skynet-iads-awacs-radar.lua`

作用：

- 把 AWACS / 舰船视为机动 EW 雷达
- 不参与 HARM 扫描
- 因为它会移动，所以附带“覆盖图需要重建”的判据

入口：

- `setupElements`
- `isUpdateOfAutonomousStateOfSAMSitesRequired`

### `skynet-iads-sam-site.lua`

作用：

- SAM 站点薄封装
- 增加 go-live constraint
- 提供目标周期开始/结束钩子
- `informOfContact` 决定是否上线

注意：

- 它很重要，但很薄
- 很多你以为属于它的逻辑，其实在 `abstract-radar-element`

### `skynet-iads-command-center.lua`

作用：

- 命令中心包装
- 在继承结构里属于 radar element
- 但行为极薄，主要作为联网/自治的可用性节点

### `skynet-iads-contact.lua`

作用：

- 目标轨迹文件对象
- 记录：
  - 被哪些雷达探测到
  - 最近看到时间
  - 刷新次数
  - 速度
  - 简化爬升/下降轨迹
  - HARM 状态

它是主循环、HARM、防御之间的数据桥。

### `skynet-iads-sam-search-radar.lua`

作用：

- 用 DCS `getSensors()` 提取雷达探测距离
- 判断目标是否在搜索距离内

### `skynet-iads-sam-tracking-radar.lua`

作用：

- 只是 `SAMSearchRadar` 的细分类型
- 目前很薄

### `syknet-iads-sam-launcher.lua`

作用：

- 用 DCS `getAmmo()` 提取导弹数量、射程、射高
- 负责“发射单元是否还能打”的判定

这部分决定 `isTargetInRange` 最终是否成立。

## 6. 辅助子系统

### `skynet-iads-harm-detection.lua`

作用：

- 从全局 contact file 中识别可能的 HARM
- 规则主要基于：
  - 速度阈值
  - 简化爬升/下降轨迹
  - 多雷达联合识别概率

然后调用各站点的 `informOfHARM`

如果你要重写反辐射导弹行为，这是主入口。

### `skynet-iads-jammer.lua`

作用：

- 周期性检查 jammer 与活动 SAM 的 LOS 和距离
- 按 `jammerTable` 的经验函数计算概率
- 调用 `samSite:jam(probability)`

它本质是玩法/经验模型，不是高保真电磁模型。

### `skynet-iads-logger.lua`

作用：

- 管理调试开关
- 输出 EW / SAM / Command Center / contacts 状态

如果你准备理解运行时状态变化，这个文件很有帮助。

### `skynet-iads-table-delegator.lua`

作用：

- 批量转发调用
- 支持类似：
  - `redIADS:getSAMSites():setActAsEW(true)`

它不复杂，但会影响你对 API 入口的理解。

### `skynet-mooose-a2a-dispatcher-connector.lua`

作用：

- 把 Skynet 当前可用的 EW / SAM group 名字同步给 MOOSE 的 `SET_GROUP`

这不是 IADS 核心，但如果你要做“防空 + 截击一体化”，这是现成接口。

## 7. 真正的改造入口

### 场景 A：我想支持更多 DCS 防空单位

先看：

- `skynet-iads-supported-types.lua`
- `skynet-iads-early-warning-radar.lua`
- `skynet-iads.lua:addSAMSite`

### 场景 B：我想改 SAM 何时开机

先看：

- `skynet-iads-sam-site.lua:informOfContact`
- `skynet-iads-abstract-radar-element.lua:isTargetInRange`
- `skynet-iads-abstract-radar-element.lua:goLive`
- `skynet-iads-abstract-radar-element.lua:goDark`

### 场景 C：我想改联网/自治

先看：

- `skynet-iads.lua:buildRadarCoverage`
- `skynet-iads.lua:buildRadarAssociation`
- `skynet-iads-abstract-radar-element.lua:setToCorrectAutonomousState`
- `skynet-iads-early-warning-radar.lua:setToCorrectAutonomousState`

### 场景 D：我想改 HARM 行为

先看：

- `skynet-iads-harm-detection.lua`
- `skynet-iads-contact.lua`
- `skynet-iads-abstract-radar-element.lua:informOfHARM`

### 场景 E：我想改干扰机/电子战

先看：

- `skynet-iads-jammer.lua`
- `skynet-iads-abstract-radar-element.lua:jam`

## 8. 读代码时的几个陷阱

1. `SAM 站点逻辑` 不只在 `sam-site.lua`
2. `命令中心` 继承自 radar element，但行为上更像网络节点
3. `AWACS` 被当成特殊 EW，而不是单独探测系统
4. 项目是“拼接式 OO Lua”，不是模块化 Lua
5. 运行时状态很多依赖 MIST 调度与 DCS 回调，静态阅读不够，必须顺着主循环看
