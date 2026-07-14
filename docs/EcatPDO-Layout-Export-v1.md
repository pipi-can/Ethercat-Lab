# PDO 配置 JSON 导出格式 v1

> 与 INI（`G/S/P/D/R/T/E/F`）结构等价 + **导出时预算 IOmap 偏移**。  
> 内核继续 INI；JSON 供用户态（Rio、回载）。偏移按 **SOEM 默认顺序布局** 计算。

---

## 1. 顶层

```json
{
  "version": "1.0",
  "ioMap": {
    "layoutMode": "soem_sequential",
    "totalSize": 42,
    "outputBytes": 17,
    "inputBytes": 25
  },
  "groups": [],
  "flatEntries": []
}
```

| `ioMap` 字段 | 说明 |
|--------------|------|
| `layoutMode` | 固定 `"soem_sequential"`：先整链 outputs，再整链 inputs（`ec_config_map` 默认） |
| `totalSize` | `outputBytes + inputBytes` |
| `outputBytes` | 所有 Rx/Outputs 区字节数（= SOEM `Obytes`） |
| `inputBytes` | 所有 Tx/Inputs 区字节数（= SOEM `Ibytes`） |

**Rio / `PdoDecoder` 只读 `flatEntries[].byteOff`，不必再猜内核怎么排。**

---

## 2. 偏移计算规则（工具导出时执行）

与 SOEM `ecx_main_config_map_group` 一致：

### 2.1 遍历顺序

```
阶段 A（outputs / 主站写 / RxPDO）：
  for group in groups（文件顺序）:
    if group.type == "SERVO":
      for slave in group.slaves:
        for channel in 0 .. slave.channelCnt-1:
          for pdo in group.template.pdo where dir=="R":
            for entry in pdo.entries:
              分配 byteOff/bitOff
    if group.type == "IO":
      if slave.points.rxBlocks == 0: 跳过
      for slave in group.slaves:
        for pdo in slave.pdo where dir=="R":
          for entry in pdo.entries:
            分配 byteOff/bitOff

阶段 B（inputs / 主站读 / TxPDO）：
  bitPos 从 outputBytes * 8 继续（或 A 结束后的 bitPos）
  遍历顺序同 A，改 dir=="T"
```

### 2.2 单条 entry 分配

```text
entry.byteOff = bitPos / 8
entry.bitOff  = bitPos % 8
bitPos       += entry.bits
若 bitPos % 8 != 0：
    bitPos = ((bitPos + 7) / 8) * 8    // 字节对齐（与 SimEngine::recomputeLayout 相同）
```

### 2.3 伺服的 OD 索引

模板 entry 的 `index` 在展开时加通道偏移：

```text
实际 index = parseHex(template.index) + channel * slave.channelOfs
```

`mapping` 对象号同理：`mappingIndex + channel * 0x100`（与内核 `rxpdo_index_offset` 一致时注明；你们内核若固定 0x100 则写死）。

### 2.4 IO 不配 PDO

`points.rxBlocks == 0 && points.txBlocks == 0`：**不参与**布局计算（不占 ioMap 字节）。走 SII 默认的从站，工具无法预算偏移，`flatEntries` 不含该从站。

### 2.5 写回 JSON 的方式

| 位置 | 内容 |
|------|------|
| 每条 `flatEntries[]` | 展开后的 entry + `byteOff` / `bitOff` |
| `slaves[].layout` | 该从站在 ioMap 中的摘要（见 §4.4） |
| `ioMap` 顶层 | 全链汇总 |

**`template` / `pdo` 里的原始 entry 可不带 offset**；导出时统一写入 `flatEntries`。

---

## 3. `flatEntries[]` — Rio 直接消费

```json
{
  "group": 2,
  "slave": 1,
  "channel": 0,
  "dir": "R",
  "mapping": "0x1600",
  "index": "0x6040",
  "sub": "0x00",
  "bits": 16,
  "type": "U16",
  "name": "ControlWord",
  "byteOff": 0,
  "bitOff": 0
}
```

| 字段 | 说明 |
|------|------|
| `dir` | `"R"` outputs 区；`"T"` inputs 区 |
| `byteOff` | **相对 IOmap[0]** 的字节偏移 |
| `bitOff` | 字节内起始位，当前对齐规则下多为 `0` |
| `group` / `slave` / `channel` | 溯源，面板分组显示用 |

解码：`ioMap[byteOff]` 起按 `bits`/`type` 抠值（同 `PdoDecoder` / `readEntryFromImage`）。

---

## 4. 组与从站（INI 等价部分）

### 4.1 组 `groups[]`

```json
{
  "index": 2,
  "name": "组1",
  "type": "SERVO",
  "template": { "rxBlocks": 1, "txBlocks": 1, "pdo": [] },
  "slaves": []
}
```

SERVO 组有 `template`；IO 组没有。

### 4.2 PDO 块 / entry（配置用，可无 offset）

```json
{
  "mapping": "0x1600",
  "dir": "R",
  "entries": [
    { "index": "0x6040", "sub": "0x00", "bits": 16, "type": "U16", "name": "ControlWord" }
  ]
}
```

| INI | JSON |
|-----|------|
| `D 0x1600 6 R` | `mapping` + `dir` + `entries.length` |
| `R 0x6040 0x00 16 U16 ControlWord` | `entries[]` 一项 |

### 4.3 从站 `S` 行

```json
{
  "index": 1,
  "type": "SERVO",
  "channelCnt": 1,
  "name": "从站1",
  "channelOfs": "0x800"
}
```

IO 从站额外字段：

```json
"points": { "input": 32, "output": 32, "rxBlocks": 0, "txBlocks": 0 },
"pdo": []
```

### 4.4 从站布局摘要 `slaves[].layout`（导出时填入）

```json
"layout": {
  "rxOffset": 0,
  "txOffset": 17,
  "outputBytes": 17,
  "inputBytes": 25
}
```

| 字段 | 说明 |
|------|------|
| `rxOffset` | 该从站**第一个** output entry 的 `byteOff`；无 output 则为 `-1` |
| `txOffset` | 该从站**第一个** input entry 的 `byteOff`；无 input 则为 `-1` |
| `outputBytes` / `inputBytes` | 该从站占用的 process data 字节数 |

---

## 5. 完整示例（你的实机线路 + 已算偏移）

组 1 IO 不配 PDO → 不占 ioMap。组 2 单轴伺服 → 17B out + 25B in = 42B。

```json
{
  "version": "1.0",
  "ioMap": {
    "layoutMode": "soem_sequential",
    "totalSize": 42,
    "outputBytes": 17,
    "inputBytes": 25
  },
  "groups": [
    {
      "index": 1,
      "name": "IO组",
      "type": "IO",
      "slaves": [
        {
          "index": 1,
          "type": "IO",
          "channelCnt": 0,
          "name": "TerminalCoupler",
          "channelOfs": "0x0",
          "points": { "input": 32, "output": 32, "rxBlocks": 0, "txBlocks": 0 },
          "pdo": []
        }
      ]
    },
    {
      "index": 2,
      "name": "组1",
      "type": "SERVO",
      "template": {
        "rxBlocks": 1,
        "txBlocks": 1,
        "pdo": [
          {
            "mapping": "0x1600",
            "dir": "R",
            "entries": [
              { "index": "0x6040", "sub": "0x00", "bits": 16, "type": "U16", "name": "ControlWord" },
              { "index": "0x607A", "sub": "0x00", "bits": 32, "type": "S32", "name": "TargetPosition" },
              { "index": "0x6060", "sub": "0x00", "bits": 8,  "type": "U8",  "name": "ModeOfOperation" },
              { "index": "0x60FF", "sub": "0x00", "bits": 32, "type": "S32", "name": "TargetVelocity" },
              { "index": "0x60B8", "sub": "0x00", "bits": 16, "type": "U16", "name": "TouchProbeFunc" },
              { "index": "0x60FE", "sub": "0x01", "bits": 32, "type": "U32", "name": "PhysicalOutput" }
            ]
          },
          {
            "mapping": "0x1A00",
            "dir": "T",
            "entries": [
              { "index": "0x6041", "sub": "0x00", "bits": 16, "type": "U16", "name": "StatusWord" },
              { "index": "0x6064", "sub": "0x00", "bits": 32, "type": "S32", "name": "PositionActualValue" },
              { "index": "0x603F", "sub": "0x00", "bits": 16, "type": "U16", "name": "ServoErrorCode" },
              { "index": "0x6077", "sub": "0x00", "bits": 16, "type": "S16", "name": "TorqueActualValue" },
              { "index": "0x606C", "sub": "0x00", "bits": 32, "type": "S32", "name": "VelocityActualValue" },
              { "index": "0x60B9", "sub": "0x00", "bits": 16, "type": "U16", "name": "TouchPeobeStatus" },
              { "index": "0x60BA", "sub": "0x00", "bits": 32, "type": "U32", "name": "TouchProbePos1" },
              { "index": "0x6061", "sub": "0x00", "bits": 8,  "type": "U8",  "name": "ModeOfOperation" },
              { "index": "0x60FD", "sub": "0x00", "bits": 32, "type": "U32", "name": "DigitalInput" }
            ]
          }
        ]
      },
      "slaves": [
        {
          "index": 1,
          "type": "SERVO",
          "channelCnt": 1,
          "name": "从站1",
          "channelOfs": "0x800",
          "layout": {
            "rxOffset": 0,
            "txOffset": 17,
            "outputBytes": 17,
            "inputBytes": 25
          }
        }
      ]
    }
  ],
  "flatEntries": [
    { "group": 2, "slave": 1, "channel": 0, "dir": "R", "mapping": "0x1600", "index": "0x6040", "sub": "0x00", "bits": 16, "type": "U16", "name": "ControlWord",         "byteOff": 0,  "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "R", "mapping": "0x1600", "index": "0x607A", "sub": "0x00", "bits": 32, "type": "S32", "name": "TargetPosition",      "byteOff": 2,  "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "R", "mapping": "0x1600", "index": "0x6060", "sub": "0x00", "bits": 8,  "type": "U8",  "name": "ModeOfOperation",     "byteOff": 6,  "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "R", "mapping": "0x1600", "index": "0x60FF", "sub": "0x00", "bits": 32, "type": "S32", "name": "TargetVelocity",      "byteOff": 7,  "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "R", "mapping": "0x1600", "index": "0x60B8", "sub": "0x00", "bits": 16, "type": "U16", "name": "TouchProbeFunc",      "byteOff": 11, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "R", "mapping": "0x1600", "index": "0x60FE", "sub": "0x01", "bits": 32, "type": "U32", "name": "PhysicalOutput",      "byteOff": 13, "bitOff": 0 },

    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x6041", "sub": "0x00", "bits": 16, "type": "U16", "name": "StatusWord",          "byteOff": 17, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x6064", "sub": "0x00", "bits": 32, "type": "S32", "name": "PositionActualValue", "byteOff": 19, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x603F", "sub": "0x00", "bits": 16, "type": "U16", "name": "ServoErrorCode",      "byteOff": 23, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x6077", "sub": "0x00", "bits": 16, "type": "S16", "name": "TorqueActualValue",   "byteOff": 25, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x606C", "sub": "0x00", "bits": 32, "type": "S32", "name": "VelocityActualValue", "byteOff": 27, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x60B9", "sub": "0x00", "bits": 16, "type": "U16", "name": "TouchPeobeStatus",    "byteOff": 31, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x60BA", "sub": "0x00", "bits": 32, "type": "U32", "name": "TouchProbePos1",      "byteOff": 33, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x6061", "sub": "0x00", "bits": 8,  "type": "U8",  "name": "ModeOfOperation",     "byteOff": 37, "bitOff": 0 },
    { "group": 2, "slave": 1, "channel": 0, "dir": "T", "mapping": "0x1A00", "index": "0x60FD", "sub": "0x00", "bits": 32, "type": "U32", "name": "DigitalInput",        "byteOff": 38, "bitOff": 0 }
  ]
}
```

---

## 6. IO 带 PDO 时的偏移（接在伺服 outputs 区之后）

若组 1 有 IO 且 `rxBlocks=1`，则 IO 的 Rx entry 排在**所有伺服 outputs 之前**（按 groups 文件顺序），例如 IO Rx `byteOff=0`，伺服从 `byteOff=4` 起；inputs 区仍在 `outputBytes` 之后。

双轴伺服（`channelCnt=2`）时，通道 1 的 `0x6040` 变为 `0x6840`，outputs 区**连续追加** 17B，再进入 inputs 区。

---

## 7. 导出流程（PDO 配置工具）

```
1. 收集 groups（与写 INI 相同数据源）
2. 按 §2 遍历，生成 flatEntries + ioMap 汇总 + slaves[].layout
3. 写 JSON（含配置 + 偏移）
4. 可选：同一份数据写 INI 给内核
```

Rio 握手：发送 `ioMap` 摘要 + 整份 JSON 或仅 `flatEntries`；每帧只推 `ioMap[0..totalSize-1]` 原始字节。

---

## 8. 限制与假设

| 假设 | 不满足时 |
|------|----------|
| `layoutMode = soem_sequential` | overlap 模式需另算，不能沿用本 JSON |
| 从站顺序 = JSON 中 groups→slaves 顺序 | 与总线扫描序不一致时，应以 `ec_config_map` 后实测为准 |
| IO `rxBlocks=0` 不占字节 | SII 默认映射的 IO 无 `flatEntries` |
| entry 按 §2.2 对齐 | 与内核 `packedMode` 不一致时偏移会有偏差 |

上线前建议：内核 `ec_config_map` 后对比一次 `ec_slave[k].outputs - IOmap` 与 JSON `rxOffset`。

---

## 9. INI ↔ JSON 对照

| INI | JSON |
|-----|------|
| `G 2 组1 SERVO 1` | `groups[]` |
| `P 0 0 1 1` | `template.rxBlocks/txBlocks` |
| `P 32 32 0 0` | `slaves[].points` |
| `S/E/D/R/T` | `slaves` / `template` / `pdo` / `entries` |
| （无） | `flatEntries` / `byteOff` / `ioMap` |

---

## 10. 数据类型

`Bit` `U8` `S8` `U16` `S16` `U32` `S32` `U64` `S64` — 与 INI 一致。`S*` 有符号解码，其余无符号。
