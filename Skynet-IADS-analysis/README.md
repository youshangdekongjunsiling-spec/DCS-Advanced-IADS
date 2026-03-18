# Skynet-IADS 拆解报告

这份报告面向“准备重做防空系统，并以 `Skynet-IADS` 为基础继续开发”的场景。目标不是重复 README 用法，而是回答三件事：

1. 这套系统真正的入口在哪。
2. 哪些文件是核心行为，哪些只是数据或适配层。
3. 如果你要改网络逻辑、SAM 激活逻辑、HARM、防护、Jammer，应该从哪里下手。

配套文件：

- `module-map.md`：按模块分层的详细拆解
- `dependency-graph.md`：文件依赖与继承关系可视化
- `runtime-flow.md`：启动与主循环的运行流程图

## 一句话结论

`Skynet-IADS` 是一套“总控调度器 + 雷达/SAM 抽象基类 + 支持类型数据库 + 辅助子系统”的 Lua 面向对象脚本框架。

真正的行为核心不是 `skynet-iads-sam-site.lua`，而是：

- `skynet-iads.lua`
- `skynet-iads-abstract-radar-element.lua`

前者负责“系统级调度”，后者负责“单个雷达/站点的行为”。

## 架构总览

可以把源码分成 6 层：

1. `数据层`
   - `skynet-iads-supported-types.lua`
   - 定义支持哪些 SAM/EWR、各自需要哪些子单元、NATO 名称、HARM 能力等

2. `总控层`
   - `skynet-iads.lua`
   - 创建 IADS、收集单位、构建覆盖图、周期性评估目标、分发给 SAM、调用 HARM/Logger

3. `抽象行为层`
   - `skynet-iads-abstract-dcs-object-wrapper.lua`
   - `skynet-iads-abstract-element.lua`
   - `skynet-iads-abstract-radar-element.lua`
   - 提供继承、DCS 封装、供电/节点/自治/开关机/目标检测/HARM/Jam 等通用行为

4. `实体层`
   - `skynet-iads-early-warning-radar.lua`
   - `skynet-iads-awacs-radar.lua`
   - `skynet-iads-sam-site.lua`
   - `skynet-iads-command-center.lua`
   - `skynet-iads-sam-search-radar.lua`
   - `skynet-iads-sam-tracking-radar.lua`
   - `syknet-iads-sam-launcher.lua`
   - `skynet-iads-contact.lua`

5. `辅助子系统`
   - `skynet-iads-harm-detection.lua`
   - `skynet-iads-jammer.lua`
   - `skynet-iads-logger.lua`
   - `skynet-mooose-a2a-dispatcher-connector.lua`
   - `skynet-iads-table-delegator.lua`

6. `构建层`
   - `build-tools/build-compiled-script.ps1`
   - 把所有源码按固定顺序拼成一个 `compiled.lua`

## 你应该先读什么

推荐阅读顺序：

1. `Skynet-IADS/skynet-iads-source/skynet-iads.lua`
2. `Skynet-IADS/skynet-iads-source/skynet-iads-abstract-radar-element.lua`
3. `Skynet-IADS/skynet-iads-source/skynet-iads-sam-site.lua`
4. `Skynet-IADS/skynet-iads-source/skynet-iads-contact.lua`
5. `Skynet-IADS/skynet-iads-source/skynet-iads-harm-detection.lua`
6. `Skynet-IADS/skynet-iads-source/skynet-iads-supported-types.lua`
7. 再看 `EWR/AWACS/SearchRadar/Launcher/Logger/Jammer/MOOSE`

原因：

- `skynet-iads.lua` 决定系统怎么跑。
- `abstract-radar-element` 决定“站点是什么样的行为体”。
- `sam-site.lua` 只是把“站点何时上线”的决策接到抽象层。
- `supported-types.lua` 决定这套系统支持哪些单位，属于扩展点，不是主逻辑入口。

## 关键入口

### 1. IADS 创建与注册

主要入口都在 `skynet-iads.lua`：

- `SkynetIADS:create(name)`，`skynet-iads.lua:19`
- `SkynetIADS:addEarlyWarningRadar(...)`，`skynet-iads.lua:186`
- `SkynetIADS:addSAMSite(...)`，`skynet-iads.lua:268`
- `SkynetIADS:addCommandCenter(...)`，`skynet-iads.lua:347`
- `SkynetIADS.activate(self)`，`skynet-iads.lua:701`

这几处定义了“系统实例如何建立、单位如何进入系统、系统何时开始工作”。

### 2. 主循环

真正的心脏是：

- `SkynetIADS.evaluateContacts(self)`，`skynet-iads.lua:381`

它做的事情是：

1. 获取可用 EW 雷达和可用 SAM 站点
2. 让活动中的 SAM 直接贡献目标
3. 让 EW 雷达贡献目标，并决定哪些 SAM 应该被唤醒
4. 清理过期目标
5. 把目标分发给覆盖范围内的 SAM
6. 结束一次 SAM 目标周期
7. 执行 HARM 识别与反应
8. 输出日志

### 3. 覆盖图 / 网络图

网络关系构建入口：

- `SkynetIADS:buildRadarCoverage()`，`skynet-iads.lua:577`
- `SkynetIADS:buildRadarCoverageForAbstractRadarElement(...)`，`skynet-iads.lua:617`
- `SkynetIADS:buildRadarAssociation(...)`，`skynet-iads.lua:632`

这套逻辑负责把：

- EW / AWACS / actAsEW 的 SAM
- 与
- 被其探测范围覆盖的 SAM 站点

连接成父子关系图。

这里非常关键，因为 `SAM 是否联网、是否需要自治、谁给它提供外部态势` 都来自这张覆盖图。

### 4. 单站点行为核心

核心文件：

- `skynet-iads-abstract-radar-element.lua`

关键方法：

- `create(...)`，`:15`
- `setToCorrectAutonomousState()`，`:161`
- `goLive()`，`:539`
- `goDark()`，`:568`
- `isTargetInRange(target)`，`:611`
- `jam(successProbability)`，`:685`
- `getDetectedTargets()`，`:761`
- `informOfHARM(harmContact)`，`:830`

这说明所有“雷达站点真正做什么”的行为，几乎都集中在这里。

## 当前我对系统的判断

### 优点

- 分层是清楚的。
- 行为抽象相对统一，EW、AWACS、SAM 都复用了同一套核心行为。
- `Contact`、`HARM`、`Jammer` 都是独立子系统，可拆、可替换。
- `supported-types.lua` 把“支持哪些单位”与“行为逻辑”分开了，扩展性不错。

### 真实瓶颈

- 这不是基于 `require` 的模块系统，而是“全局表 + 编译拼接顺序”。
- 真正的文件依赖不完全靠 `import` 能看出来，必须结合构建顺序和全局类名理解。
- 行为大量下沉在 `abstract-radar-element.lua`，导致表面上看 `sam-site.lua` 很薄，容易误判入口。
- 很多系统状态依赖 DCS API 的返回值和 MIST 定时器，阅读时必须同时理解“静态结构”和“定时调用”。

## 如果你准备重做防空系统，最值得先理解的 5 个点

1. `evaluateContacts` 是如何把“侦察”和“开火”解耦的。
2. `buildRadarCoverage` 是如何建立 EW 到 SAM 的父子关系的。
3. `setToCorrectAutonomousState` 如何决定联网/自治。
4. `informOfContact` 与 `isTargetInRange` 如何触发 SAM 上线。
5. `informOfHARM` 和 `HARMDetection:evaluateContacts` 如何做反辐射导弹防御。

## 最重要的入口建议

如果你的目标是“基于 Skynet 重做一套自己的防空系统”，建议这样切：

### 先读懂，不急着改

- `skynet-iads.lua`
- `skynet-iads-abstract-radar-element.lua`
- `skynet-iads-sam-site.lua`

### 再决定你要改哪一类能力

- 加新单位支持：
  - `skynet-iads-supported-types.lua`

- 改覆盖/联网/自治：
  - `skynet-iads.lua`
  - `skynet-iads-abstract-radar-element.lua`

- 改 SAM 上线条件：
  - `skynet-iads-sam-site.lua`
  - `skynet-iads-abstract-radar-element.lua:isTargetInRange`

- 改 HARM 识别与防御：
  - `skynet-iads-harm-detection.lua`
  - `skynet-iads-abstract-radar-element.lua:informOfHARM`

- 改干扰：
  - `skynet-iads-jammer.lua`
  - `skynet-iads-abstract-radar-element.lua:jam`

## 这套代码最像什么

如果用一句工程语言概括：

它不是“雷达物理仿真器”，而是“基于 DCS 探测结果的 IADS 行为编排器”。

也就是说，它主要做的是：

- 态势关联
- 覆盖关系
- 联网/自治切换
- 发射站点开关机管理
- HARM 规避
- Jammer 交互

而不是：

- 高保真波束建模
- 细粒度雷达模式机理
- 真实数据链协议仿真

这点对你后续设计非常重要，因为如果你要在这个基础上继续开发，最容易成功的方向是：

- 保留它的“系统编排骨架”
- 再逐步替换局部判据和玩法逻辑

而不是直接把它当成完整雷达仿真底座。
