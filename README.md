# DCS Advanced IADS

> Advanced mission scripting package for DCS World.  
> 中文说明在前，English version follows after the Chinese guide.

## 中文版

### 项目简介

DCS Advanced IADS 是一个面向 DCS World 任务制作者的高级防空与电子战脚本项目。它基于 Skynet-IADS 扩展，重点解决动态防空、机动防空阵地、兄弟组交接、轮换部署、伴随防空和任务剧情控制等问题。

### 设计理念：让 HARM 重新具有战术意义

传统 DCS 空地对抗里，反辐射作战经常落入两个极端。

第一种极端是地面雷达过于容易被摧毁。防空系统持续开机，玩家发射 HARM 后很容易直接摧毁核心雷达，整个防空网迅速崩溃。

第二种极端出现在加入 HARM 拦截系统的任务里。每一发反辐射导弹都可能被 SA-15、NASAMS 或其他点防御系统拦截，防空阵地可以长期保持全程开机，玩家发射 HARM 只是在消耗弹药，几乎得不到战术反馈。

本项目试图在这两者之间建立更接近现实的空地对抗逻辑：

- HARM 不再被设计为轻松秒杀整个防空网的按钮。
- 防空系统也不再能无代价全程开机并稳定拦截每一发 HARM。
- 每一发 HARM 都应该迫使被威胁的防空单位关机、机动、规避或转移。
- HARM 的核心价值是制造雷达沉默和阵地转移窗口，为后续突防、压制或打击创造机会。

因此，在这套 IADS 里，反辐射导弹即使没有直接摧毁目标，也应该让玩家切实感受到作用：目标关机了、阵地转移了、防区出现了短暂缺口。它不会像传统简单任务那样一发解决全部问题，也不会像全拦截任务那样变成毫无反馈的空耗弹药。

这套逻辑让空地对抗更有策略性：玩家需要规划 HARM 发射时机、压制窗口、后续突防路线和多轮打击节奏；防空方则通过关机、转移、兄弟组接替和轮换部署来维持体系生存。

本项目适合用于：

- 制作更有压迫感的现代 SEAD / DEAD 任务。
- 让 SA-11、SA-15 等防空单位具备更复杂的开关机、机动和交接行为。
- 在任务中组织固定预警雷达、机动防空、伴随防空和剧情控制。
- 为多人 PVP / PVE 任务提供更难被一次性摧毁的防空网络。
- 参考“黑谷行动”任务模板，体验一套多层次防御体系如何在实战任务中运作。

### 原始项目声明

本仓库基于并扩展了原版 Skynet-IADS。

原项目地址：

```text
https://github.com/walder/Skynet-IADS
```

本仓库中的 `Skynet-IADS/` 子仓库包含定制修改。请同时阅读：

- `LICENSE`
- `Skynet-IADS/LICENSE.md`

### 当前公开支持的功能

| 功能                   | 状态       | 说明                                   |
| -------------------- | -------- | ------------------------------------ |
| Skynet-IADS 基础防空网    | 支持       | 基于原 Skynet-IADS。                     |
| MSAM 机动防空            | 支持       | 机动巡逻、部署、撤收、重新部署。                     |
| Sibling family 兄弟组交接 | 支持       | 主战/备用/接防/轮换。                         |
| HARM 压制驱动规避          | 支持       | HARM 会迫使受威胁单位关机、规避、转移或交接。             |
| ASAM 伴随防空            | 支持       | 管理雷达和接敌，不接管原生路线。                     |
| EWR 情报播报             | 支持       | 定时向玩家播报早警雷达发现目标。                     |
| Skynet 武器雷达总开关       | 支持       | 可剧情锁定武器雷达，不影响 EW 情报雷达。               |
| EA-18G / 电子战脚本       | 部分支持     | 取决于任务是否加载相关脚本。                       |
| GPS 干扰 / GPS 欺骗      | 暂不作为公开功能 | 相关实验代码可能存在，但 README 暂不指导启用，公开任务建议关闭。 |

> 注意：GPS 干扰功能仍属于实验方向。DCS 没有稳定公开的原生 GPS 干扰接口，因此本 README 暂时不把它列为可直接使用功能。

### 仓库结构

| 路径                               | 作用                                              |
| -------------------------------- | ----------------------------------------------- |
| `skynet-iads-compiled-ea18g.lua` | DCS 任务中直接导入的完整 Skynet 运行时。普通用户优先使用它。            |
| `my-iads-setup.lua`              | 任务侧 IADS 配置入口。你主要需要修改这个文件。                      |
| `mist_4_5_126.lua`               | MIST 依赖库，必须在 Skynet 之前加载。                       |
| `advanced_jammer_simulation.lua` | DCS 内电子战模拟脚本。                                   |
| `Skynet-IADS/`                   | 定制 Skynet-IADS 源码子仓库。用于开发和重新编译。                 |
| `Skynet-IADS-analysis/`          | 模块图、流程、开发治理和问题记录。                               |
| `advanced_ew_simulator/`         | 高级电子战干扰成功距离模拟器，用于研究干扰参数、成功概率和距离窗口。              |
| `campaign/black_valley/`         | “黑谷行动”展示任务资料。该任务尚未完全完成，但已经提供完整的多层次 IADS 防御体系模板。 |
| `*.miz`                          | 示例或测试任务文件。                                      |

### 快速开始

推荐克隆方式：

```powershell
git clone --recurse-submodules git@github.com:youshangdekongjunsiling-spec/DCS-Advanced-IADS.git
cd DCS-Advanced-IADS
```

如果已经普通克隆：

```powershell
git submodule update --init --recursive
```

### DCS Mission Editor 加载顺序

在任务开始时用 `DO SCRIPT FILE` 按顺序加载：

```text
1. mist_4_5_126.lua
2. skynet-iads-compiled-ea18g.lua
3. advanced_jammer_simulation.lua              可选
4. EA18G_EW_Script_improved_by_flyingsampig.lua 可选，如果你的任务使用它
5. my-iads-setup.lua
```

最小 IADS 测试只需要：

```text
1. mist_4_5_126.lua
2. skynet-iads-compiled-ea18g.lua
3. my-iads-setup.lua
```

规则：

- `my-iads-setup.lua` 必须最后加载。
- 不需要手动嵌入 `.miz`，直接在 Mission Editor 选择脚本文件即可。
- 修改 Skynet 源码后，必须重新编译 `skynet-iads-compiled-ea18g.lua`。

### 群组命名规则

脚本通过 DCS Mission Editor 中的群组名识别单位类型。

| 前缀     | 类型      | 脚本行为                      |
| ------ | ------- | ------------------------- |
| `EW`   | 固定早警雷达  | 提供 IADS 情报。               |
| `MEW`  | 机动早警雷达  | 机动早警扩展预留。                 |
| `SAM`  | 常规防空阵地  | Skynet 管理开关机、接敌和 HARM 反应。 |
| `MSAM` | 机动防空阵地  | 巡逻、部署、兄弟组交接、轮换机动。         |
| 其他名称   | ASAM 候选 | 如果含有效防空单位，可注册为伴随防空。       |

示例：

```text
EW-1-Main-Valley-Radar
SAM-1-SA15-Point-Defence
MSAM-1-SA11-Ambush-North
MSAM-2-SA11-Ambush-North
```

### 如何编写 `my-iads-setup.lua`

`my-iads-setup.lua` 是任务配置文件。你通常不需要改 Skynet 源码，只需要按任务改这个文件。

#### 1. 设置 IADS 名称和前缀

```lua
local IADS_NAME = "RED"
local EW_PREFIXES = { "EW", "MEW" }
local SAM_PREFIXES = { "SAM", "MSAM" }
local RESERVED_IADS_PREFIXES = { "EW", "MEW", "SAM", "MSAM" }
local MOBILE_EW_PREFIX = "MEW"
local MOBILE_SAM_PREFIX = "MSAM"
```

建议：

- 红方防空用 `RED`。
- 蓝方防空可复制一套 setup，改成 `BLUE`。
- 不要随意改前缀，除非你的 Mission Editor 群组名也同步修改。

#### 2. 开关功能模块

```lua
local ENABLE_RADIO_MENU = true
local ENABLE_MOBILE_PATROL = true
local ENABLE_EWR_REPORTER = true
local ENABLE_SIBLING_COORDINATION = true
local ENABLE_TACTICAL_RUNTIME_DEBUG = false
local ENABLE_SKYNET_MASTER_SWITCH = true
```

公开任务建议暂时关闭 GPS 相关功能：

```lua
local ENABLE_GPS_SPOOFING = false
```

说明：

- `ENABLE_RADIO_MENU`：是否创建 F10 菜单。
- `ENABLE_MOBILE_PATROL`：是否启用 MSAM / MEW 机动巡逻。
- `ENABLE_EWR_REPORTER`：是否播报早警雷达目标。
- `ENABLE_SIBLING_COORDINATION`：是否启用兄弟组交接。
- `ENABLE_TACTICAL_RUNTIME_DEBUG`：调试输出，正式任务建议关闭。
- `ENABLE_SKYNET_MASTER_SWITCH`：武器雷达总开关，剧情任务常用。

#### 3. 定义 MSAM family

Family 用来定义哪些 MSAM 是一组，谁主战，谁备用，多久轮换。

```lua
local SIBLING_FAMILIES = {
    {
        name = "North SA-11 Ambush Pair",
        members = {
            "MSAM-1-SA11-Ambush-North",
            "MSAM-2-SA11-Ambush-North",
        },
        mode = "ambush",
        primary = "MSAM-1-SA11-Ambush-North",
        denialAlertDistanceNm = 25,
        passiveAction = "relocate",
        rotationIntervalSeconds = 120,
    },
}
```

字段解释：

| 字段                        | 作用                                  |
| ------------------------- | ----------------------------------- |
| `name`                    | family 名称，只用于日志和识别。                 |
| `members`                 | 必须完整匹配 DCS 群组名。                     |
| `mode`                    | `ambush` 或 `denial`。伏击型建议 `ambush`。 |
| `primary`                 | 默认主战组。后续仲裁会根据距离和状态切换。               |
| `denialAlertDistanceNm`   | 警戒距离，单位海里。                          |
| `passiveAction`           | 非主战成员行为，常用 `relocate`。              |
| `rotationIntervalSeconds` | 部署后多久触发轮换。                          |

常见错误：

- `members` 写的是单位名而不是群组名。
- Mission Editor 里群组名和 Lua 字符串不完全一致。
- MSAM 群组没有航路点，导致无法巡逻。
- 两个 family 引用了同一个 MSAM 群组。

#### 4. 创建 IADS 并设置刷新间隔

```lua
redIADS = SkynetIADS:create(IADS_NAME)
redIADS:setUpdateInterval(1)
```

`setUpdateInterval(1)` 表示 1 秒更新一次。更短会增加性能压力，更长会降低反应速度。

#### 5. 注册 SAM / EW / MSAM / ASAM

当前示例文件已经包含自动注册逻辑。一般使用者只需要按命名规则放置群组。

推荐思路：

- 固定早警雷达命名为 `EW-*`。
- 常规防空命名为 `SAM-*`。
- 需要机动巡逻和部署的防空命名为 `MSAM-*`。
- 伴随地面部队的防空可以保留原群组名，由 ASAM 候选逻辑识别。

#### 6. 调试输出

正式任务建议：

```lua
iadsDebug.warnings = true
iadsDebug.IADSStatus = false
iadsDebug.contacts = false
iadsDebug.radarWentLive = false
iadsDebug.radarWentDark = false
iadsDebug.jammerProbability = false
iadsDebug.harmDefence = false
```

排障时可以临时打开更详细日志，但不要长期开启高频 contact 日志。

#### 7. 最小自定义模板

你可以从这个最小结构开始：

```lua
do
    local IADS_NAME = "RED"
    local ENABLE_MOBILE_PATROL = true
    local ENABLE_SIBLING_COORDINATION = true
    local ENABLE_EWR_REPORTER = true
    local ENABLE_SKYNET_MASTER_SWITCH = true
    local ENABLE_GPS_SPOOFING = false

    local SIBLING_FAMILIES = {
        {
            name = "Example SA-11 Pair",
            members = {
                "MSAM-1-SA11-Ambush",
                "MSAM-2-SA11-Ambush",
            },
            mode = "ambush",
            primary = "MSAM-1-SA11-Ambush",
            denialAlertDistanceNm = 25,
            passiveAction = "relocate",
            rotationIntervalSeconds = 120,
        },
    }

    if not SkynetIADS then
        trigger.action.outText("SkynetIADS not loaded", 10)
        return
    end

    redIADS = SkynetIADS:create(IADS_NAME)
    redIADS:setUpdateInterval(1)

    -- Keep the full repository setup file as the reference for automatic
    -- registration, ASAM, sibling coordination, EWR reporter, and radio menu.
end
```

实际任务建议直接复制仓库里的 `my-iads-setup.lua`，再改顶部配置和 `SIBLING_FAMILIES`。

### 日志与排障

常用日志：

```text
C:\Users\<你的用户名>\Saved Games\DCS\Logs\dcs.log
C:\Users\<你的用户名>\Saved Games\DCS\Logs\Skynet\skynet-order-trace-RED.log
```

常见问题：

| 现象                  | 检查项                                      |
| ------------------- | ---------------------------------------- |
| 完全没有防空响应            | 检查 MIST、compiled Skynet、setup 加载顺序。      |
| 提示 `module missing` | Mission Editor 可能加载了旧版 compiled Lua。     |
| MSAM 不巡逻            | 检查是否有航路点，群组名是否以 `MSAM` 开头。               |
| MSAM family 不工作     | 检查 `SIBLING_FAMILIES.members` 是否完全匹配群组名。 |
| ASAM 没注册            | 检查群组内单位是否被 Skynet 数据库支持。                 |
| SA-15 被 HARM 攻击后不移动 | 可能是 DCS 原生 AI 限制，尤其是发射后停车。               |

### 重新编译 Skynet 运行时

普通用户不需要重新编译。修改 `Skynet-IADS/skynet-iads-source/` 后才需要。

```powershell
cd Skynet-IADS\build-tools
.\build-compiled-script.ps1 ea18g-your-build-name
Copy-Item ..\demo-missions\skynet-iads-compiled.lua ..\..\skynet-iads-compiled-ea18g.lua -Force
```

要求：

- 源码和编译产物必须同步提交。
- 不要只改源码不更新根目录 compiled Lua。
- 每个功能建议单独提交，方便回退。

### 高级电子战模拟器

外部工具位于：

```text
advanced_ew_simulator/
```

可运行版本：

```text
advanced_ew_simulator/dist/AdvancedEWSimulator/AdvancedEWSimulator.exe
```

源码入口：

```text
advanced_ew_simulator/jammer_research_ui.py
advanced_ew_simulator/jammer_research_main.py
advanced_ew_simulator/build_exe.py
```

这个工具的重点不是替代 DCS 内脚本，而是帮助任务制作者在任务外估算电子战参数：

- 不同干扰强度下的有效距离窗口。
- 干扰成功概率随距离和参数变化的趋势。
- 雷达、干扰机和模板参数的对照关系。
- 任务平衡时，玩家需要接近到多远才可能获得有效压制。

如果你只想玩任务，不需要运行它；如果你要调任务难度或设计电子战玩法，建议先用它估算参数，再回到 DCS 里实测。

### 黑谷行动展示任务

`campaign/black_valley/` 是本项目用于展示新 IADS 系统能力的一整套任务设计资料，聚焦于架空的1990年前后的贝卡谷地，以色列-美国联合海空军部队需要应对在某东方国家支持下的一整个苏制装甲师和其完整附属防空部队的挑战。

当前状态：

- 任务1-3已经完成。
- 任务 黑谷行动模板.miz 里面已经有了完整的多层次防御体系模板。
- 适合用来体验固定预警、机动防空、伴随防空、兄弟组交接和任务剧情控制如何组合。
- 也适合作为新制作防空体系时的结构参考。

---

## English Version

### Overview

DCS Advanced IADS is a DCS World mission-scripting project based on Skynet-IADS. It adds mission-oriented behaviour for mobile SAM groups, sibling SAM coordination, rotating deployment, accompanying air defence, EWR reporting, and story-controlled weapon radar activation.

The goal is not to replace DCS AI completely. The goal is to provide a more dynamic, testable, and mission-friendly IADS layer for modern air-to-ground scenarios.

The `Black Valley` campaign materials are included as a showcase mission set for the new IADS system. Missions 1-3 are complete, and the template mission already contains a complete layered IADS defence system for testing and experiencing the system.

### Design Philosophy: Making HARM Matter Again

Traditional DCS air-to-ground missions often fall into one of two extremes.

In the first extreme, ground radars are too easy to kill. The air defence network keeps emitting, a HARM is launched, the key radar dies, and the whole system collapses quickly.

In the second extreme, missions add aggressive HARM interception. Every anti-radiation missile can be intercepted by SA-15s, NASAMS, or other point-defence systems. The SAM network can then stay online for the entire fight, and HARM shots become expensive ammunition with almost no tactical feedback.

This project is designed around a different logic that is closer to real SEAD behaviour:

- HARM should not be a simple button that deletes an entire air defence network.
- SAM systems should not be able to remain online forever while reliably intercepting every HARM.
- Each HARM shot should force the threatened air defence unit to shut down, evade, relocate, or hand off the fight.
- The main value of HARM is to create radar-silence and relocation windows for follow-up penetration, suppression, or strike actions.

In this IADS, an anti-radiation missile does not need to directly destroy its target to matter. If it forces the target to go dark, move, or give up the engagement for a short time, it has created a real tactical opening. The result is a more strategic air-to-ground fight: attackers must plan HARM timing, suppression windows, ingress routes, and follow-up strikes, while defenders survive through shutdown, relocation, sibling takeover, and rotating deployment.

### Original Skynet-IADS Project

This repository is based on and extends Skynet-IADS.

Original project:

```text
https://github.com/walder/Skynet-IADS
```

The `Skynet-IADS/` submodule in this repository contains the customized source history used by this project.

### Public Feature Status

| Feature                           | Status                       | Notes                                                                              |
| --------------------------------- | ---------------------------- | ---------------------------------------------------------------------------------- |
| Base Skynet-IADS network          | Supported                    | Based on the original Skynet-IADS project.                                         |
| Mobile SAM patrol                 | Supported                    | Patrol, deploy, withdraw, redeploy.                                                |
| Sibling SAM coordination          | Supported                    | Primary / standby / takeover / rotation.                                           |
| HARM-driven evasion               | Supported                    | HARM threats force shutdown, evasion, relocation, or handoff.                      |
| ASAM accompanying SAM             | Supported                    | Controls radar and engagement, not movement routes.                                |
| EWR reporting                     | Supported                    | Periodic contact reports for players.                                              |
| Skynet weapon radar master switch | Supported                    | Can disable weapon radars while keeping EW sensors active.                         |
| EA-18G / EW scripts               | Partially supported          | Depends on mission loadout and optional scripts.                                   |
| GPS spoofing / GPS jamming        | Not public-supported for now | Experimental code may exist, but this README does not instruct users to enable it. |

### Repository Layout

| Path                             | Purpose                                                                                                                      |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `skynet-iads-compiled-ea18g.lua` | Single-file runtime imported into DCS missions.                                                                              |
| `my-iads-setup.lua`              | Mission-side configuration. Most users edit this file.                                                                       |
| `mist_4_5_126.lua`               | MIST dependency. Load before Skynet.                                                                                         |
| `advanced_jammer_simulation.lua` | Optional DCS-side EW simulation script.                                                                                      |
| `Skynet-IADS/`                   | Customized Skynet-IADS source submodule.                                                                                     |
| `Skynet-IADS-analysis/`          | Design notes, module maps, runtime flow, and development governance.                                                         |
| `advanced_ew_simulator/`         | External EW jamming success-distance simulator for parameter studies.                                                        |
| `campaign/black_valley/`         | Black Valley showcase mission documents and scripts. Missions 1-3 are complete, and the template mission contains a complete layered IADS defence system. |

### Quick Start

Clone with submodules:

```powershell
git clone --recurse-submodules git@github.com:youshangdekongjunsiling-spec/DCS-Advanced-IADS.git
cd DCS-Advanced-IADS
```

If you already cloned without submodules:

```powershell
git submodule update --init --recursive
```

### Mission Editor Load Order

Use `DO SCRIPT FILE` in this order:

```text
1. mist_4_5_126.lua
2. skynet-iads-compiled-ea18g.lua
3. advanced_jammer_simulation.lua                optional
4. EA18G_EW_Script_improved_by_flyingsampig.lua  optional
5. my-iads-setup.lua
```

Minimal IADS setup:

```text
1. mist_4_5_126.lua
2. skynet-iads-compiled-ea18g.lua
3. my-iads-setup.lua
```

### Group Naming Rules

The setup script identifies DCS groups by name prefix.

| Prefix      | Type                       | Behaviour                                                    |
| ----------- | -------------------------- | ------------------------------------------------------------ |
| `EW`        | Fixed early warning radar  | Provides IADS sensor input.                                  |
| `MEW`       | Mobile early warning radar | Reserved for mobile EWR behaviour.                           |
| `SAM`       | Regular SAM site           | Skynet manages radar, engagement, and HARM reaction.         |
| `MSAM`      | Mobile SAM site            | Patrol, deploy, sibling coordination, rotation.              |
| Other names | ASAM candidate             | May be registered if the group contains supported SAM units. |

Example:

```text
EW-1-Main-Valley-Radar
SAM-1-SA15-Point-Defence
MSAM-1-SA11-Ambush-North
MSAM-2-SA11-Ambush-North
```

### How To Write `my-iads-setup.lua`

`my-iads-setup.lua` is the mission configuration file. In most cases, you should copy the repository version and only edit the top configuration block.

#### 1. Basic IADS Settings

```lua
local IADS_NAME = "RED"
local EW_PREFIXES = { "EW", "MEW" }
local SAM_PREFIXES = { "SAM", "MSAM" }
local MOBILE_EW_PREFIX = "MEW"
local MOBILE_SAM_PREFIX = "MSAM"
```

Use `RED` for a red-side IADS. For a blue-side mission, copy the setup and change the name and group prefixes as needed.

#### 2. Feature Switches

```lua
local ENABLE_RADIO_MENU = true
local ENABLE_MOBILE_PATROL = true
local ENABLE_EWR_REPORTER = true
local ENABLE_SIBLING_COORDINATION = true
local ENABLE_TACTICAL_RUNTIME_DEBUG = false
local ENABLE_SKYNET_MASTER_SWITCH = true
local ENABLE_GPS_SPOOFING = false
```

For public missions, keep GPS spoofing disabled until the feature is validated for your mission.

#### 3. Sibling Families

```lua
local SIBLING_FAMILIES = {
    {
        name = "North SA-11 Ambush Pair",
        members = {
            "MSAM-1-SA11-Ambush-North",
            "MSAM-2-SA11-Ambush-North",
        },
        mode = "ambush",
        primary = "MSAM-1-SA11-Ambush-North",
        denialAlertDistanceNm = 25,
        passiveAction = "relocate",
        rotationIntervalSeconds = 120,
    },
}
```

Important rules:

- `members` must contain DCS group names, not unit names.
- Names must match exactly.
- MSAM groups need route points if you expect them to patrol.
- Do not put the same MSAM group into two families.

#### 4. Create The IADS

```lua
redIADS = SkynetIADS:create(IADS_NAME)
redIADS:setUpdateInterval(1)
```

The repository setup file already contains the full auto-registration logic for SAM, EW, MSAM, ASAM, EWR reporter, radio menus, and sibling coordination.

### Logs And Troubleshooting

Useful log files:

```text
C:\Users\<your user>\Saved Games\DCS\Logs\dcs.log
C:\Users\<your user>\Saved Games\DCS\Logs\Skynet\skynet-order-trace-RED.log
```

Common checks:

| Symptom                                       | Check                                                        |
| --------------------------------------------- | ------------------------------------------------------------ |
| No SAM activity                               | Verify MIST, compiled Skynet, and setup load order.          |
| `module missing` message                      | You probably loaded an old compiled Lua.                     |
| MSAM does not patrol                          | Check route points and `MSAM` prefix.                        |
| Family coordination does not work             | Check exact group names in `SIBLING_FAMILIES`.               |
| ASAM is not registered                        | Check whether the group contains Skynet-supported SAM units. |
| SA-15 shuts down but does not move under HARM | This may be a DCS native AI limitation after firing.         |

### Rebuilding The Compiled Runtime

Only developers need this step.

```powershell
cd Skynet-IADS\build-tools
.\build-compiled-script.ps1 ea18g-your-build-name
Copy-Item ..\demo-missions\skynet-iads-compiled.lua ..\..\skynet-iads-compiled-ea18g.lua -Force
```

Do not commit source changes without updating the compiled root runtime.

### Advanced EW Simulator

The external simulator is located in:

```text
advanced_ew_simulator/
```

Runnable build:

```text
advanced_ew_simulator/dist/AdvancedEWSimulator/AdvancedEWSimulator.exe
```

Source entry points:

```text
advanced_ew_simulator/jammer_research_ui.py
advanced_ew_simulator/jammer_research_main.py
advanced_ew_simulator/build_exe.py
```

Use it to estimate:

- effective jamming distance windows;
- success probability trends under different jammer strengths;
- radar / jammer / template parameter relationships;
- how close players should need to get before jamming becomes effective.

You do not need it to simply play a mission. It is mainly a mission-design and balancing tool.

### Black Valley Showcase

`campaign/black_valley/` contains the Black Valley mission and design materials. It is a fictional late-Cold-War / early-1990s Bekaa Valley scenario in which an Israeli-US joint air and naval force faces a Soviet-style armored division and its attached layered air defence network, supported by an unnamed eastern power.

Current state:

- missions 1-3 are complete;
- the `Black Valley Operation Template.miz` mission already contains a complete layered IADS defence template;
- the mission set is suitable for experiencing how fixed EWRs, mobile SAMs, accompanying air defence, sibling SAM handoff, and story-level IADS control work together;
- it can also be used as a structural reference when building a new air defence system.

The template demonstrates:

- fixed early warning radars;
- mobile SAM patrol and deployment;
- sibling SAM takeover and rotation;
- accompanying air defence;
- story-level IADS control.

Use it as a reference template when building your own mission.

### License

This repository contains original mission scripts, custom tools, and a modified Skynet-IADS subtree. Read:

- `LICENSE`
- `Skynet-IADS/LICENSE.md`

### Credits

- Original Skynet-IADS by walder and contributors.
- DCS Mission Scripting community.
- Mission testing feedback that drove the mobile IADS and sibling coordination work.
