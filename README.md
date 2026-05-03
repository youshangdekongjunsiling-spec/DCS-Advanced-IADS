# DCS Advanced IADS

面向 DCS World 任务制作者的高级防空与电子战脚本项目。  
本仓库基于定制版 Skynet-IADS，加入机动防空、兄弟组交接、轮换部署、伴随防空、GPS 欺骗、EWR 情报播报、任务级总开关和电子战模拟工具，用于构建更有对抗性的现代空地战场。

> English short description: a mission-scripting package for DCS World that extends Skynet-IADS with mobile SAM patrols, sibling SAM coordination, rotating deployment, accompanying air defence, GPS spoofing, EWR reporting, and EW simulation tools.

## 目录

- [项目内容](#项目内容)
- [快速开始](#快速开始)
- [DCS Mission Editor 加载顺序](#dcs-mission-editor-加载顺序)
- [群组命名规则](#群组命名规则)
- [核心功能](#核心功能)
- [配置入口](#配置入口)
- [日志与排障](#日志与排障)
- [重新编译 Skynet 运行时](#重新编译-skynet-运行时)
- [高级电子战模拟器](#高级电子战模拟器)
- [Git 克隆和子仓库](#git-克隆和子仓库)
- [常见问题](#常见问题)

## 项目内容

| 路径 | 作用 |
| --- | --- |
| `skynet-iads-compiled-ea18g.lua` | DCS 任务中直接导入的完整 Skynet 运行时。一般玩家和任务作者优先使用它。 |
| `my-iads-setup.lua` | 任务侧 IADS 配置入口，负责注册群组、开关功能、配置 family、GPS 欺骗和调试输出。 |
| `mist_4_5_126.lua` | MIST 依赖库，必须在 Skynet 之前加载。 |
| `advanced_jammer_simulation.lua` | DCS 内的 EA-18G / 电子战模拟脚本。 |
| `Skynet-IADS/` | 定制版 Skynet-IADS 源码子仓库。用于开发和重新编译，不是普通任务导入入口。 |
| `Skynet-IADS-analysis/` | 模块地图、运行流程、主控文档和开发治理说明。 |
| `advanced_ew_simulator/` | 外部高级电子战模拟器，包含 Python 源码和可运行 exe。 |
| `campaign/black_valley/` | 黑谷行动战役文档和剧情控制脚本。 |
| `*.miz` | 示例或测试任务文件。默认维护流程不会自动嵌入脚本到 miz。 |

## 快速开始

1. 克隆仓库。

   ```powershell
   git clone --recurse-submodules git@github.com:youshangdekongjunsiling-spec/DCS-Advanced-IADS.git
   cd DCS-Advanced-IADS
   ```

2. 在 DCS Mission Editor 中打开你的任务。

3. 按下方加载顺序添加 `DO SCRIPT FILE` 触发器。

4. 按命名规则放置或重命名防空、预警、GPS 欺骗和伴随防空群组。

5. 运行任务，查看屏幕提示和日志确认注册成功。

## DCS Mission Editor 加载顺序

在任务开始时按顺序加载：

```text
1. mist_4_5_126.lua
2. skynet-iads-compiled-ea18g.lua
3. advanced_jammer_simulation.lua
4. EA18G_EW_Script_improved_by_flyingsampig.lua    如果你的任务使用该脚本
5. my-iads-setup.lua
```

最小 IADS 测试只需要：

```text
1. mist_4_5_126.lua
2. skynet-iads-compiled-ea18g.lua
3. my-iads-setup.lua
```

注意：

- `my-iads-setup.lua` 必须最后加载，因为它依赖前面已经定义好的 Skynet 类和扩展模块。
- 如果你修改了 `Skynet-IADS/skynet-iads-source/` 源码，必须重新编译并同步 `skynet-iads-compiled-ea18g.lua`。
- 默认交付方式是提供完整可导入 Lua，不主动修改或嵌入 `.miz`。

## 群组命名规则

`my-iads-setup.lua` 通过群组名前缀识别不同单位类型。

| 前缀 | 类型 | 脚本行为 |
| --- | --- | --- |
| `EW` | 固定早警雷达 | 作为 IADS 情报源，提供态势感知。 |
| `MEW` | 机动早警雷达 | 预留/扩展为机动巡逻、开关机和 HARM 响应的早警雷达。 |
| `SAM` | 常规防空阵地 | 由 Skynet 管理开关机、HARM 反应和接敌逻辑。 |
| `MSAM` | 机动防空阵地 | 支持巡逻、部署、兄弟组交接、轮换机动和 HARM 规避。 |
| 其他名称 | ASAM 候选伴随防空 | 如果群组内含有效防空单位，可注册为伴随防空；脚本不接管路线和进攻任务。 |

建议命名示例：

```text
EW-1-Main-Valley-Radar
MEW-1-Mobile-EWR
SAM-1-SA15-Point-Defence
MSAM-1-SA11-Ambush-North
MSAM-2-SA11-Ambush-North
```

## 核心功能

### 1. 定制 Skynet-IADS

本项目不是原版 Skynet-IADS 的简单复制，而是在源码层加入了多个任务向扩展：

- 武器雷达总开关。
- GPS 欺骗模块。
- 伴随防空 ASAM 注册与配置。
- MSAM 机动巡逻和部署。
- 兄弟组主战仲裁、压制交接和轮换机动。
- EWR 情报播报。
- 更细的 Skynet 专属日志。
- HARM 判定角度和规避策略调整。
- 部分 DCS 原生行为限制的规避和记录。

### 2. MSAM 机动防空

`MSAM` 群组用于可移动中近程防空阵地，例如 SA-11 机动防空组。

典型行为：

- 常态沿 Mission Editor 航路点巡逻。
- 敌机进入警戒圈后进入部署态。
- 根据射程、射高和 family 仲裁决定是否开雷达。
- 被 HARM 压制时关机/机动/交接。
- 长时间部署后执行轮换机动，移动足够距离后重新部署。

### 3. Sibling Family 兄弟组交接

多个 `MSAM` 可以组成一个 family。family 用于解决“谁开机、谁备用、谁接防”的问题。

当前策略重点：

- 按距离和可用性选择主战组。
- 主战组被 HARM 压制后，最近可用成员接管。
- 轮换时只允许一个成员撤出，避免防区真空。
- 正在轮换的成员不会被普通仲裁立刻拉回，除非 cover 失效。
- 默认轮换间隔和最小移动距离由 `my-iads-setup.lua` 和 sibling 模块配置。

### 4. ASAM 伴随防空

ASAM 是“Accompanying SAM”的任务内扩展类型。

适用对象：

- 不属于 `EW`、`MEW`、`SAM`、`MSAM` 前缀。
- 群组内含有 Skynet 数据库支持的有效防空单位。
- 需要保留 Mission Editor 原生路线、进攻、防御任务。

脚本会：

- 管理其防空雷达开关和接敌逻辑。
- 支持 HARM 相关配置。
- 不覆盖其移动路线。
- 不把它变成 MSAM 巡逻/部署系统的一部分。

### 5. GPS 欺骗

GPS spoofing 模块会注册指定类型名的 GPS 欺骗器单位。

当前配置入口：

```lua
local ENABLE_GPS_SPOOFING = true
local GPS_SPOOFER_TYPE_NAMES = { "GPS_Spoofer_Red", "GPS_Spoofer_Blue" }
```

默认行为：

- 注册任务中匹配 type name 的 GPS 欺骗器。
- 对进入干扰半径内的 GPS 制导类武器进行脚本化偏移/欺骗模拟。
- 屏幕提示会显示注册数量和干扰半径。

注意：DCS 没有公开的原生 GPS 干扰接口，本项目使用 Lua 事件和武器效果模拟来实现“GPS 变得不可靠”的游戏效果。

### 6. Skynet 武器雷达总开关

配置项：

```lua
local ENABLE_SKYNET_MASTER_SWITCH = true
```

作用：

- 开启时，Skynet 正常管理 SAM/MSAM/ASAM。
- 关闭时，受 Skynet 管理的武器类雷达不会开机或开火。
- EW/MEW 情报雷达不被该开关压制，仍可提供情报。

用途：

- 剧情控制。
- 任务阶段锁定。
- 测试 IADS 行为。
- 给玩家提供“防空网激活/解除”的明确反馈。

### 7. EWR 情报播报

EWR reporter 会定时向玩家播报早警雷达发现的目标信息。

主要配置：

```lua
local ENABLE_EWR_REPORTER = true
local EWR_REPORT_INTERVAL_SECONDS = 15
local EWR_REPORT_DURATION_SECONDS = 8
local EWR_REPORT_MAX_CONTACTS = 3
```

适合用于：

- 单人任务中的态势提示。
- 调试早警雷达是否正常发现目标。
- 剧情任务中的地面指挥引导。

## 配置入口

大多数任务级配置都集中在 `my-iads-setup.lua` 顶部。

常用开关：

```lua
local ENABLE_RADIO_MENU = true
local ENABLE_MOBILE_PATROL = true
local ENABLE_EWR_REPORTER = true
local ENABLE_SIBLING_COORDINATION = true
local ENABLE_TACTICAL_RUNTIME_DEBUG = false
local ENABLE_GPS_SPOOFING = true
local ENABLE_SKYNET_MASTER_SWITCH = true
```

Sibling family 示例：

```lua
local SIBLING_FAMILIES = {
    {
        name = "MSAM ambush pair 1",
        members = { "MSAM-1-...", "MSAM-2-..." },
        mode = "ambush",
        primary = "MSAM-1-...",
        denialAlertDistanceNm = 25,
        passiveAction = "relocate",
        rotationIntervalSeconds = 120,
    },
}
```

建议：

- 先复制一份 `my-iads-setup.lua` 作为你的任务专用配置。
- 保留前缀识别和加载顺序。
- 根据你的 Mission Editor 群组名修改 `SIBLING_FAMILIES`。
- 先开少量 debug 验证，再关闭高频日志。

## 日志与排障

常用日志路径：

```text
C:\Users\<你的用户名>\Saved Games\DCS\Logs\dcs.log
C:\Users\<你的用户名>\Saved Games\DCS\Logs\Skynet\skynet-order-trace-RED.log
```

判断加载是否成功：

- 屏幕出现 `my-iads-setup: ... active` 之类提示。
- `dcs.log` 没有 Lua 报错。
- Skynet 专属日志中能看到 SAM/EW/MSAM 注册、目标扫描、go-live 决策和 HARM 处理记录。

常见排障方向：

| 现象 | 检查项 |
| --- | --- |
| 没有任何防空响应 | 检查 MIST、compiled Skynet、setup 加载顺序。 |
| `module missing` 提示 | 重新选择最新 `skynet-iads-compiled-ea18g.lua`，可能导入了旧编译版。 |
| MSAM 不巡逻 | 检查群组是否有有效航路点，是否以 `MSAM` 开头。 |
| MSAM 不加入 family | 检查 `SIBLING_FAMILIES.members` 是否和 Mission Editor 群组名完全一致。 |
| ASAM 没注册 | 检查群组是否含 Skynet 数据库支持的防空单位。 |
| GPS 欺骗器未注册 | 检查 DCS 单位 type name 是否匹配 `GPS_SPOOFER_TYPE_NAMES`。 |
| SA-15 被 HARM 打死但不移动 | 这可能是 DCS 原生 AI 限制，尤其是 SA-15 开火后停车。脚本可以关机，但未必能强制其立即机动。 |

## 重新编译 Skynet 运行时

普通任务制作者不需要重新编译。只有修改 `Skynet-IADS/skynet-iads-source/` 后才需要。

步骤：

```powershell
cd Skynet-IADS\build-tools
.\build-compiled-script.ps1 ea18g-your-build-name
```

该脚本会生成：

```text
Skynet-IADS\demo-missions\skynet-iads-compiled.lua
```

然后将生成内容同步为根目录运行时：

```powershell
Copy-Item ..\demo-missions\skynet-iads-compiled.lua ..\..\skynet-iads-compiled-ea18g.lua -Force
```

开发约束：

- 修改源码后必须重新编译。
- 根目录 `skynet-iads-compiled-ea18g.lua` 必须与源码变更同步。
- 每个可测试功能建议独立提交，便于回退。
- 不要只改源码不更新编译产物。

## 高级电子战模拟器

外部工具位于：

```text
advanced_ew_simulator/
```

直接运行 exe：

```text
advanced_ew_simulator/dist/AdvancedEWSimulator/AdvancedEWSimulator.exe
```

源码入口：

```text
advanced_ew_simulator/jammer_research_ui.py
advanced_ew_simulator/jammer_research_main.py
advanced_ew_simulator/build_exe.py
```

用途：

- 研究雷达、干扰机和干扰参数。
- 生成概率报告、图表和模板映射建议。
- 给任务设计提供电子战平衡参考。

## Git 克隆和子仓库

本仓库把 `Skynet-IADS` 作为 git submodule/gitlink 管理。

推荐克隆方式：

```powershell
git clone --recurse-submodules git@github.com:youshangdekongjunsiling-spec/DCS-Advanced-IADS.git
```

如果已经普通克隆：

```powershell
git submodule update --init --recursive
```

远端分支说明：

```text
main                 项目主分支
master               项目主分支镜像
skynet-iads-master   定制版 Skynet-IADS 源码历史
```

## 常见问题

### 我只想在任务里用，应该导入哪些文件？

最少导入：

```text
mist_4_5_126.lua
skynet-iads-compiled-ea18g.lua
my-iads-setup.lua
```

需要 EA-18G 电子战时，再加入：

```text
advanced_jammer_simulation.lua
EA18G_EW_Script_improved_by_flyingsampig.lua
```

### 我需要改 `.miz` 吗？

不需要。项目默认不直接修改 `.miz`。你在 Mission Editor 中用 `DO SCRIPT FILE` 选择脚本即可。

### 为什么 GitHub 上还有 `Skynet-IADS` 子模块？

因为 Skynet 定制源码很大，且有独立历史。根仓库记录当前使用的 Skynet 提交，`skynet-iads-master` 分支保存这部分源码历史。

### 为什么不把所有内容打成一个 Lua？

对任务导入来说已经有完整单文件：`skynet-iads-compiled-ea18g.lua`。  
源码拆分是为了开发、排障和回退。

### 可以用于任何阵营吗？

可以改，但当前 `my-iads-setup.lua` 默认创建的是：

```lua
local IADS_NAME = "RED"
```

你可以按任务需要复制并修改阵营、群组名前缀和 family 配置。

### 是否完全模拟真实电子战？

不是。DCS 脚本接口有边界。本项目优先追求“可玩、可测试、可调参”的任务效果，并在日志中尽量暴露决策原因。

## 许可证

本仓库包含原 Skynet-IADS 派生内容、任务脚本和自定义工具。使用前请同时查看：

- `LICENSE`
- `Skynet-IADS/LICENSE.md`

## 鸣谢

- Skynet-IADS 原项目和社区文档。
- DCS Mission Scripting 社区。
- 多轮实测中暴露问题并推动修正的任务测试流程。
