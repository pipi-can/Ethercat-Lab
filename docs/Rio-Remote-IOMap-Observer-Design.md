# Rio — Remote IOMap Observer

> **Realtime IOMap, decoded.**  
> 嵌入式 SOEM 主站的 process image → TCP → PC 端 ESI 解析引擎 → GUI 实时数值监控

---

## 1. 一句话定位

一个**非侵入式、多厂商通用**的 EtherCAT process image 远程调试工具。在嵌入式 SOEM 主站侧挂一个轻量级桥接层，通过 TCP 将 IOMap 实时推送到 PC 端，PC 端利用已解析的 ESI 文件自动解码每个 PDO Entry 为有意义的物理值（位置、速度、状态字等），并在 GUI 面板上实时刷新。

---

## 2. 解决什么问题

| 之前 | 之后 |
|------|------|
| 内核 `printk()` → `dmesg` 看裸 hex → 人肉对照 ESI 换算 | TCP 推送 → GUI 自动解码 → 直接看到 "目标位置 = +123.4 mm" |
| 改映射 → 重编内核 → 重刷固件 | PC 端加载新 ESI → 自动匹配新映射 |
| 调试时不知道从站状态 | 面板实时刷新，变化值高亮闪烁 |
| 公司 HAL 工具绑死框架 | 开源、独立、任何 SOEM 主站都能挂 |

---

## 3. 系统架构

```
[嵌入式设备 - SOEM 主站]                           [PC - EtherCAT-Lab]
                                                         
  原有控制代码（不动）                                ┌───────────────────────────┐
  ┌──────────────────────┐                            │  已有                      │
  │  ec_send_processdata │                            │  ESIParser (ESI XML→struct) │
  │  ec_receive_process  │                            │  ESITreeModel (TreeView)    │
  │  (周期循环)          │                            │  ThemeManager (Dark UI)     │
  └──────────┬───────────┘                            │                            │
             │                                        │  新增                      │
             │ ioMap 指针 (只读)                        │  IOMapReceiver (TCP Server) │
  ┌──────────┴───────────┐                            │  PdoDecoder (布局→物理值)    │
  │                      │                            │  LiveMonitorPanel (实时面板)  │
  │  iomap_bridge        │  ──── TCP ────→            │                            │
  │  (新增, ~100 行 C)    │                            └───────────────────────────┘
  │                      │
  │  - 后台线程           │
  │  - memcpy IOMap      │
  │  - TCP 推送到 PC      │
  └──────────────────────┘
```

### 关键设计

- **非侵入式**：桥接层只读 `ioMap` 内存，不修改原有控制逻辑的任何一行代码
- **极简 API**：SOEM 主站只需暴露 `ioMap` 指针和 `ioMapSize` 两个值
- **线程安全**：通过 double-buffer 或 `memcpy` 快照避免读写冲突
- **PC 端决定解码**：设备端只发原始字节 + 设备标识，PC 端用已加载的 ESI 文件决定如何解码

---

## 4. 通信协议

### 4.1 两阶段握手

```
  PC (TCP Server)                    Device (TCP Client)
       ←────  connect ────────────
  Phase 1: 握手
       ←───  "HELLO" ──────────────
       ────  "READY" ──────────────→
       ←───  device_info.json ─────   (设备标识 + ioMapSize + cycleTime)
       ────  mapping_request ────→    (可选：如果 PC 需要设备端发映射)
       ←───  pdo_mapping.json ────   (可选：PDO layout)
  Phase 2: 数据流
       ←───  [ioMap raw bytes] ───    (每周期推送，HZ/ms 可配置)
       ←───  [ioMap raw bytes] ───
       ←───  ...
```

### 4.2 消息格式

#### Handshake — Device Info (JSON)
```json
{
  "type": "device_info",
  "vendor_id": "0x0000006A",
  "product_code": "0x10b0",
  "revision_no": "0x00010004",
  "ioMapSize": 12,
  "ioMapRxSize": 6,
  "ioMapTxSize": 6,
  "cycleTimeUs": 4000,
  "bridgeVersion": "1.0"
}
```

#### PDO Mapping (JSON, 可选)
```json
{
  "type": "pdo_mapping",
  "rxpdos": [
    {
      "index": "0x1701",
      "name": "Cyclic position Outputs",
      "entries": [
        { "index": "0x6040", "subIndex": 0, "name": "Control Word",  "type": "UINT16", "bitLen": 16, "byteOffset": 0, "bitOffset": 0 },
        { "index": "0x607A", "subIndex": 0, "name": "Target Position","type": "INT32",  "bitLen": 32, "byteOffset": 2, "bitOffset": 0 }
      ]
    }
  ],
  "txpdos": [
    {
      "index": "0x1B01",
      "name": "Cyclic position Inputs",
      "entries": [
        { "index": "0x6041", "subIndex": 0, "name": "Status Word",     "type": "UINT16", "bitLen": 16, "byteOffset": 0, "bitOffset": 0 },
        { "index": "0x6064", "subIndex": 0, "name": "Actual Position", "type": "INT32",  "bitLen": 32, "byteOffset": 2, "bitOffset": 0 }
      ]
    }
  ]
}
```

#### Data Frame (Binary)
```
┌─────────────┬───────────┬─────────────────┐
│ Header (8B) │ Timestamp │ IOMap raw bytes │
├─────────────┼───────────┼─────────────────┤
│ Magic:0xR10 │ 8B u64 ns │ ioMapSize bytes │
│ SeqNum:4B   │           │                 │
│ Length:2B   │           │                 │
│ Flags:2B    │           │                 │
└─────────────┴───────────┴─────────────────┘
```

---

## 5. 实现计划

### 5.1 嵌入式侧 — `iomap_bridge.h / iomap_bridge.c`

| 函数 | 功能 |
|------|------|
| `iomap_bridge_init(ioMap*, ioMapSize, port, periodUs)` | 初始化：绑定 ioMap 指针、TCP 目标、推送周期 |
| `iomap_bridge_start()` | 启动后台线程：握手 → 周期 pub |
| `iomap_bridge_stop()` | 停止线程 + 清理 |
| `iomap_bridge_get_state()` | 返回连接状态（disconnected/handshaking/streaming） |

**依赖**：pthread + POSIX socket + 标准 C 库。零 Qt 依赖。

**集成方式**：原有 SOEM 代码在初始化完成后调用：
```c
// 原有代码
ioMap = ioMapPtr;
ec_config_map_group(...);

// 新增一行
iomap_bridge_init(ioMap, ioMapSize, 9527, 4000);
iomap_bridge_start();

// 原有循环不动
while (running) {
    ec_send_processdata();
    ec_receive_processdata(EC_TIMEOUTRET);
    // 桥接层在后台线程自动推，不影响这个循环
    usleep(4000);
}
```

### 5.2 PC 侧 — `IOMapReceiver` (C++/Qt)

```cpp
class IOMapReceiver : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
public:
    explicit IOMapReceiver(QObject* parent = nullptr);
    
    bool start(int port = 9527);   // 启动 TCP Server 监听
    void stop();
    bool connected() const;

signals:
    void connectedChanged();
    void deviceInfoReceived(const QVariantMap& info);    // 设备已握手
    void pdoMappingReceived(const QVariantMap& mapping);  // 收到 PDO layout
    void dataFrameReceived(const QByteArray& ioMap);      // 每帧 IOMap

private:
    QTcpServer* m_server;
    QTcpSocket* m_clientSocket;
    DataProtocol parser;  // 解析二进制帧格式
};
```

### 5.3 PC 侧 — `PdoDecoder` (C++/Qt)

```cpp
class PdoDecoder : public QObject {
    Q_OBJECT
public:
    // 设置 PDO 布局（来自 ESI 解析或设备端发送的 mapping）
    void setLayout(const QVariantMap& mapping);
    
    // 解码一帧 IOMap → 每个 Entry 的当前值
    QVariantMap decode(const QByteArray& ioMap) const;

private:
    struct DecodeSlot {
        int byteOffset, bitOffset, bitLen;
        QString index, name, dataType;
    };
    std::vector<DecodeSlot> m_slots;  // 已排序的解码槽
};
```

解码时直接用 `memcpy` + mask 提取位域：
```cpp
QVariant PdoDecoder::decodeSlot(const QByteArray& ioMap, const DecodeSlot& slot) const
{
    quint64 raw = 0;
    for (int b = 0; b < slot.bitLen; ++b) {
        int absBit = slot.byteOffset * 8 + slot.bitOffset + b;
        int byteIdx = absBit / 8, bitIdx = absBit % 8;
        if (ioMap[byteIdx] & (1 << bitIdx))
            raw |= (quint64(1) << b);
    }
    
    if (slot.dataType.contains("INT") || slot.dataType.contains("DINT"))
        return static_cast<qint64>(raw);  // 有符号
    return static_cast<quint64>(raw);     // 无符号
}
```

### 5.4 PC 侧 — `LiveMonitorPanel.qml` (QML)

布局：

```
┌──────────────────────────────────────────────────────┐
│  🔴 CONNECTED    Copley XE2    Cycle: 250 Hz        │
│  Rx 6B / Tx 6B   ioMap: 12B                         │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌─ RxPDO: Cyclic position Outputs ──────────────┐  │
│  │  Control Word    0x6040:00    0x0006    Shutdown│  │
│  │  Target Position 0x607A:00    +123.4    mm    │  │  ← 变化时背景闪绿
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌─ TxPDO: Cyclic position Inputs ───────────────┐  │
│  │  Status Word     0x6041:00    0x0237    OE│SO │  │
│  │  Actual Position 0x6064:00    +120.1    mm    │  │  ← 变化时背景闪绿
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌─ Raw Bytes ───────────────────────────────────┐  │
│  │  06 00 00 00 00 00  37 02 00 00  00 00 00     │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

- 每个 Entry 一行：名称 + 索引 + 实时值 + 单位
- 值变化时**背景短暂闪绿色**（300ms 渐隐），方便捕捉快速变化
- 底部折叠的 raw bytes 面板
- 连接断开时自动灰屏 + 重连倒计时

---

## 6. 文件清单

```
嵌入式侧 (独立 C 库, 无 Qt 依赖)
├── iomap_bridge.h         (~50 行)   头文件 + API 声明
├── iomap_bridge.c        (~150 行)   实现：TCP + 线程 + 帧封装
└── CMakeLists.txt         可选独立编译

PC 侧 (EtherCAT-Lab 项目内新增)
interfaces/
├── iomapreceiver.h       (~40 行)   TCP Server + 协议解析
├── iomapreceiver.cpp     (~120 行)  实现
├── pdodecoder.h          (~35 行)   PDO 解码引擎
├── pdodecoder.cpp        (~100 行)  实现

layouts/
├── LiveMonitorPanel.qml  (~250 行)  实时监控面板

docs/
└── Rio-Remote-IOMap-Observer-Design.md  本文档
```

---

## 7. 工作量

| 序号 | 任务 | 预计 |
|------|------|------|
| 1 | `iomap_bridge.h/c` — 嵌入式侧 C 库 | 1.5h |
| 2 | `IOMapReceiver` — PC 端 TCP Server | 1.5h |
| 3 | `PdoDecoder` — 解码引擎 | 1.5h |
| 4 | 协议文档 + 帧格式定义 | 0.5h |
| 5 | `LiveMonitorPanel.qml` — 实时面板 | 3h |
| 6 | main.qml 集成 — 导航栏增加第三个入口 | 0.5h |
| 7 | 测试 — 用 loopback + 模拟 IOMap 数据 | 1.5h |
| **合计** | | **~10h** |

---

## 8. 面试叙事

> 「实习做 EtherCAT 主站的时候，调试 PDO 数据只能靠内核 printk 打 hex dump，然后人肉对照 ESI 文件逐字节解码。我写了一个叫 Rio 的工具——在 SOEM 主站侧挂一个 150 行的桥接层，通过 TCP 把 process image 实时推到 PC 端。PC 端用我之前写的 ESI 解析引擎自动匹配 PDO mapping，把裸字节解码成有意义的值——位置、速度、控制字、状态字——然后在 GUI 面板上实时刷新。因为 IOMap 是 SOEM 的标准机制，这个工具对任何 SOEM 主站都通用，不绑死某一个厂商的 HAL。」

一句总结：**它把 EtherCAT 调试从「看 hex dump」升级成「看物理值」。**

---

## 9. 与非功能需求的契合

- **不修改原有代码**：`iomap_bridge` 只读共享内存，不碰原控制逻辑
- **不依赖特定厂商**：基于 SOEM 标准 `ioMap`，任何 SOEM 主站可用
- **不依赖特定电脑**：嵌入式侧只需 POSIX socket + pthread
- **不重复实习工作**：实习工具生成配置，Rio 调试运行时数据——互补
