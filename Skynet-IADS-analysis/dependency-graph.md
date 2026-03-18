# Skynet-IADS 依赖关系可视化

## 文件级逻辑依赖

```mermaid
flowchart LR
    Build["build-tools/build-compiled-script.ps1"]

    subgraph Data["数据层"]
        Types["skynet-iads-supported-types.lua"]
    end

    subgraph Core["总控层"]
        IADS["skynet-iads.lua"]
        Logger["skynet-iads-logger.lua"]
        Delegator["skynet-iads-table-delegator.lua"]
        Moose["skynet-mooose-a2a-dispatcher-connector.lua"]
    end

    subgraph Base["抽象层"]
        Wrapper["skynet-iads-abstract-dcs-object-wrapper.lua"]
        Element["skynet-iads-abstract-element.lua"]
        RadarBase["skynet-iads-abstract-radar-element.lua"]
    end

    subgraph Entities["实体层"]
        EWR["skynet-iads-early-warning-radar.lua"]
        AWACS["skynet-iads-awacs-radar.lua"]
        SamSite["skynet-iads-sam-site.lua"]
        Cmd["skynet-iads-command-center.lua"]
        Search["skynet-iads-sam-search-radar.lua"]
        Track["skynet-iads-sam-tracking-radar.lua"]
        Launcher["syknet-iads-sam-launcher.lua"]
        Contact["skynet-iads-contact.lua"]
    end

    subgraph Subs["辅助子系统"]
        Harm["skynet-iads-harm-detection.lua"]
        Jammer["skynet-iads-jammer.lua"]
    end

    Build --> Types
    Build --> Logger
    Build --> IADS
    Build --> Moose
    Build --> Delegator
    Build --> Wrapper
    Build --> Element
    Build --> RadarBase
    Build --> AWACS
    Build --> Cmd
    Build --> Contact
    Build --> EWR
    Build --> Jammer
    Build --> Search
    Build --> SamSite
    Build --> Track
    Build --> Launcher
    Build --> Harm

    Types --> IADS
    Logger --> IADS
    Delegator --> IADS
    Moose --> IADS

    Wrapper --> Element
    Element --> RadarBase

    Wrapper --> Search
    Search --> Track
    Search --> Launcher

    Wrapper --> Contact

    RadarBase --> EWR
    RadarBase --> AWACS
    RadarBase --> SamSite
    RadarBase --> Cmd

    Search --> EWR
    Search --> AWACS
    Search --> SamSite

    Contact --> IADS
    Contact --> Harm
    Contact --> RadarBase

    Harm --> IADS
    Jammer --> RadarBase
    Jammer --> IADS

    IADS --> EWR
    IADS --> AWACS
    IADS --> SamSite
    IADS --> Cmd
    IADS --> Harm
    IADS --> Logger
    IADS --> Moose
```

## 继承关系

```mermaid
classDiagram
    class SkynetIADS
    class SkynetIADSAbstractDCSObjectWrapper
    class SkynetIADSAbstractElement
    class SkynetIADSAbstractRadarElement
    class SkynetIADSEWRadar
    class SkynetIADSAWACSRadar
    class SkynetIADSSamSite
    class SkynetIADSCommandCenter
    class SkynetIADSSAMSearchRadar
    class SkynetIADSSAMTrackingRadar
    class SkynetIADSSAMLauncher
    class SkynetIADSContact

    SkynetIADSAbstractElement --|> SkynetIADSAbstractDCSObjectWrapper
    SkynetIADSAbstractRadarElement --|> SkynetIADSAbstractElement

    SkynetIADSEWRadar --|> SkynetIADSAbstractRadarElement
    SkynetIADSAWACSRadar --|> SkynetIADSAbstractRadarElement
    SkynetIADSSamSite --|> SkynetIADSAbstractRadarElement
    SkynetIADSCommandCenter --|> SkynetIADSAbstractRadarElement

    SkynetIADSSAMSearchRadar --|> SkynetIADSAbstractDCSObjectWrapper
    SkynetIADSSAMTrackingRadar --|> SkynetIADSSAMSearchRadar
    SkynetIADSSAMLauncher --|> SkynetIADSSAMSearchRadar
    SkynetIADSContact --|> SkynetIADSAbstractDCSObjectWrapper
```

## 如何读这张图

先抓 3 个重点：

1. `SkynetIADS` 是调度器，不是全部行为本体。
2. `SkynetIADSAbstractRadarElement` 是行为最重的基类。
3. `supported-types.lua` 不是行为逻辑，但它决定“哪些单位能进入系统”。

如果你要找“真正动刀的地方”，优先级通常是：

1. `skynet-iads.lua`
2. `skynet-iads-abstract-radar-element.lua`
3. `skynet-iads-sam-site.lua`
4. `skynet-iads-harm-detection.lua`
5. `skynet-iads-supported-types.lua`
