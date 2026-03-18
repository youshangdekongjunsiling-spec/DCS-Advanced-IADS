# Skynet-IADS 运行流程图

## 启动流程

```mermaid
flowchart TD
    A["任务脚本创建 IADS<br/>SkynetIADS:create(name)"] --> B["注册 EW / SAM / Command Center"]
    B --> C["activate()"]
    C --> D["启动 MIST 定时器<br/>schedule evaluateContacts"]
    C --> E["buildRadarCoverage()"]
    E --> F["清空旧 parent/child 关系"]
    F --> G["遍历 EW + SAM"]
    G --> H["按探测范围建立覆盖关系"]
    H --> I["把雷达加入 Command Center"]
    I --> J["更新 SAM 自治/联网状态"]
```

## 主循环

```mermaid
flowchart TD
    A["evaluateContacts()"] --> B["获取可用 EW / 可用 SAM"]
    B --> C["SAM 目标周期开始<br/>targetCycleUpdateStart"]
    C --> D["活动中的非 EW SAM 直接贡献 contacts"]
    D --> E["actAsEW 的 SAM 加入 EW 列表"]
    E --> F["遍历 EW / AWACS / actAsEW SAM"]
    F --> G["EW goLive()"]
    G --> H{"AWACS 位置变化超过阈值?"}
    H -- 是 --> I["局部重建 coverage"]
    H -- 否 --> J["读取 EW detectedTargets"]
    I --> J
    J --> K["收集覆盖下的可用 SAM"]
    K --> L["把 EW contacts 合并进全局 track file"]
    L --> M["cleanAgedTargets()"]
    M --> N["把全局 contacts 分发给待触发 SAM"]
    N --> O["SAM: informOfContact(contact)"]
    O --> P["SAM 目标周期结束<br/>targetCycleUpdateEnd"]
    P --> Q["HARMDetection:evaluateContacts()"]
    Q --> R["Logger: printSystemStatus()"]
```

## SAM 上线决策

```mermaid
flowchart TD
    A["SAM: informOfContact(contact)"] --> B{"已有目标在射程内?"}
    B -- 是 --> Z["保持当前状态"]
    B -- 否 --> C{"goLive constraints 满足?"}
    C -- 否 --> Z
    C -- 是 --> D["isTargetInRange(contact)"]
    D --> E{"搜索雷达/跟踪雷达/发射架满足射程?"}
    E -- 否 --> Z
    E -- 是 --> F{"目标是否被识别为 HARM?"}
    F -- 否 --> G["goLive()"]
    F -- 是 --> H{"本站允许打 HARM?"}
    H -- 否 --> Z
    H -- 是 --> G
```

## HARM 防御流程

```mermaid
flowchart TD
    A["HARMDetection:evaluateContacts()"] --> B["按速度与轨迹筛选疑似 HARM"]
    B --> C["按多雷达概率合成识别概率"]
    C --> D{"识别成功?"}
    D -- 否 --> E["标记 NOT_HARM"]
    D -- 是 --> F["标记 HARM"]
    F --> G["informRadarsOfHARM(contact)"]
    G --> H["各站点 informOfHARM"]
    H --> I{"HARM 航向进入 20nm / 15deg 区域?"}
    I -- 否 --> J["不反应"]
    I -- 是 --> K{"点防御足够?"}
    K -- 是 --> L["点防御上线，可选择不停机"]
    K -- 否 --> M["goSilentToEvadeHARM"]
```

## 阅读建议

如果你只想理解最小闭环，可以顺着这条链读：

1. `SkynetIADS.activate`
2. `SkynetIADS.evaluateContacts`
3. `SkynetIADSSamSite:informOfContact`
4. `SkynetIADSAbstractRadarElement:isTargetInRange`
5. `SkynetIADSAbstractRadarElement:goLive / goDark`

如果你想理解“为什么联网被破坏后站点会变化”，再补这条链：

1. `SkynetIADS:buildRadarCoverage`
2. `SkynetIADS:buildRadarAssociation`
3. `SkynetIADSAbstractRadarElement:setToCorrectAutonomousState`

如果你想理解“为什么会躲 HARM”，再补：

1. `SkynetIADSHARMDetection:evaluateContacts`
2. `SkynetIADSAbstractRadarElement:informOfHARM`
