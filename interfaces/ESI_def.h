#ifndef ESI_DEF_H
#define ESI_DEF_H

#include <string>
#include <vector>
#include <map>

// ════════════════════════════════════════════════════════════
// 基础 / 共用结构
// ════════════════════════════════════════════════════════════

struct Flags {
    std::string  access;         // "ro" / "rw" / "wo"
    std::string  pdoMapping;     // "optional" / "mandatory" / "no"
    unsigned int backup;         // 0 / 1

    Flags() : access(""), pdoMapping(""), backup(0) {}
};

// ════════════════════════════════════════════════════════════
// Vendor
// ════════════════════════════════════════════════════════════

struct ESIVendor {
    std::string id;
    std::string name;
    std::string imageData16x14;      // base64 图标（Beckhoff/Copley/Weidmueller 均有）
    std::string fileVersion;         // Vendor 的 FileVersion 属性

    ESIVendor() : id(""), name(""), imageData16x14(""), fileVersion("") {}
    ESIVendor(const std::string &id, const std::string &name)
        : id(id), name(name), imageData16x14(""), fileVersion("") {}
};

// ════════════════════════════════════════════════════════════
// Groups
// ════════════════════════════════════════════════════════════

struct ESIGroup {
    int         sortOrder;       // <Group SortOrder="520">
    std::string type;            // <Type>Drive</Type>
    std::string name;            // <Name LcId="1033">Drives</Name>
    std::string imageData16x14;  // base64 图标（Copley/Weidmueller）
    std::string image16x14;      // 图标引用名（Beckhoff: "TERM_SYS"）

    ESIGroup() : sortOrder(0), type(""), name(""), imageData16x14(""), image16x14("") {}
};

// ════════════════════════════════════════════════════════════
// Device → Info → StateMachine → Timeout
// ════════════════════════════════════════════════════════════

struct ESIInfo {
    std::string  name                = "Timeout Info";
    unsigned int preopTimeout        = 0;
    unsigned int safeopOpTimeout     = 0;
    unsigned int backToInitTimeout   = 0;
    unsigned int backToSafeopTimeout = 0;
};

// ════════════════════════════════════════════════════════════
// SyncManager
// ════════════════════════════════════════════════════════════

struct ESISm {
    bool         enable;
    std::string  startAddress;   // "#x1000"
    std::string  controlBytes;   // "#x26"
    unsigned int minSize;
    unsigned int defaultSize;
    unsigned int maxSize;
    std::string  name;           // "MBoxOut" / "Outputs" ...

    ESISm()
        : enable(false), startAddress(""), controlBytes("")
        , minSize(0), defaultSize(0), maxSize(0), name("") {}
};

// ════════════════════════════════════════════════════════════
// FMMU
// ════════════════════════════════════════════════════════════

struct ESIFmmu {
    std::string name;            // "Outputs" / "Inputs" / "MBoxState"

    ESIFmmu() : name("") {}
    ESIFmmu(std::string name): name(name) {}
};

// ════════════════════════════════════════════════════════════
// PDO Entry
// ════════════════════════════════════════════════════════════
// 注意：DependOnSlot 在 XML 的 <Index> 标签上，不在 <Entry> 上
//       此处存储位置不变，解析时从 <Index> 的属性读取

struct ESIPdoEntry {
    std::string index;           // "#x6040"
    int         subIndex;        // 0
    int         bitLen;          // 16
    std::string name;            // "Control word"
    std::string dataType;        // "UINT"
    int         dependOnSlot;    // -1 = 没有此属性

    ESIPdoEntry()
        : index(""), subIndex(0), bitLen(0), name(""), dataType("")
        , dependOnSlot(-1) {}
};

// ════════════════════════════════════════════════════════════
// RxPdo / TxPdo
// ════════════════════════════════════════════════════════════

struct ESIRxpdo {
    bool    fixed;               // Fixed="0" 可配置 / Fixed="1" 预定义
    std::string sm;              // Sm="2"（Module 的 PDO 才有）
    std::string index;           // "#x1600" 或 <Index DependOnSlot="1"> 的文本
    std::string name;            // "Receive PDO 1"
    int     dependOnSlot;        // <Index> 上的 DependOnSlot 属性，-1 = 无

    std::vector<ESIPdoEntry> entries;

    ESIRxpdo()
        : fixed(false), sm(""), index(""), name("")
        , dependOnSlot(-1), entries() {}
};

struct ESITxpdo {
    bool    fixed;
    std::string sm;
    std::string index;
    std::string name;
    int     dependOnSlot;

    std::vector<ESIPdoEntry> entries;

    ESITxpdo()
        : fixed(false), sm(""), index(""), name("")
        , dependOnSlot(-1), entries() {}
};

// ════════════════════════════════════════════════════════════
// InitCmd（Module → Mailbox → CoE 下）
// ════════════════════════════════════════════════════════════

struct ESIInitCmd {
    std::string transition;      // "IP" / "PS" / "SO" / "OP"
    std::string index;           // "#x6060"
    int         subIndex;        // 0
    std::string data;            // "0B"（hex 字符串）
    std::string comment;         // "Modes of Operation"
    int         dependOnSlot;    // -1 = 无

    ESIInitCmd()
        : transition(""), index(""), subIndex(0), data(""), comment("")
        , dependOnSlot(-1) {}
};

// ════════════════════════════════════════════════════════════
// Mailbox
// ════════════════════════════════════════════════════════════

struct ESIMailBox {
    bool dataLinkLayer;          // Device 的 Mailbox 属性，Module 的无

    // 六个协议：子标签存在即 true
    bool eoe = false;            // <EoE/>
    bool coe = false;            // <CoE ...> 或 <CoE>...</CoE>
    bool foe = false;            // <FoE/>
    bool aoe = false;            // <AoE/>
    bool soe = false;            // <SoE/>
    bool voe = false;            // <VoE/>

    // CoE 的属性（coe==true 时才有效，自闭合 <CoE .../>）
    int  coePdoAssign      = 0;  // PdoAssign
    int  coePdoConfig      = 0;  // PdoConfig
    int  coeSdoInfo        = 0;  // SdoInfo
    int  coeCompleteAccess = 0;  // CompleteAccess
    int  coeSegmentedSdo   = 0;  // SegmentedSdo
    int  coeDiagHistory    = -1; // DiagHistory，-1=不存在

    // CoE 的子元素（Module 的 Mailbox，<CoE> 非自闭合时）
    std::vector<ESIInitCmd> initCmds;

    ESIMailBox() : dataLinkLayer(false) {}
};

// ════════════════════════════════════════════════════════════
// EEPROM
// ════════════════════════════════════════════════════════════

struct ESIEeprom {
    bool         enable;
    unsigned int byteSize;
    std::string  configData;     // hex 字符串
    std::string  bootStrap;      // hex 字符串

    ESIEeprom() : enable(false), byteSize(0), configData(""), bootStrap("") {}
};

// ════════════════════════════════════════════════════════════
// Distributed Clocks
// ════════════════════════════════════════════════════════════

struct ESIDcOpMode {
    std::string  name;              // "DcSync" / "Free"
    std::string  desc;              // "DC Cyclic"
    std::string  assignActivate;    // "#x0330"
    unsigned int cycleTimeSync0;    // 0
    unsigned int shiftTimeSync0;    // 0
    int          factor;            // CycleTimeSync0 的 Factor 属性，默认 1

    ESIDcOpMode()
        : name(""), desc(""), assignActivate("")
        , cycleTimeSync0(0), shiftTimeSync0(0), factor(1) {}
};

// ════════════════════════════════════════════════════════════
// Slot / ModuleIdent
// ════════════════════════════════════════════════════════════

struct ESIModuleIdent {
    bool        isDefault;       // Default="1" 属性
    std::string value;           // "#x10b00100"

    ESIModuleIdent() : isDefault(false), value("") {}
};

struct ESISlot {
    std::string  name;           // "Axis A"
    int          maxInstances;   // MaxInstances="1"
    int          minInstances;   // MinInstances="1"
    std::vector<ESIModuleIdent> moduleIdents;

    ESISlot() : name(""), maxInstances(1), minInstances(1), moduleIdents() {}
};

struct ESISlots {
    unsigned int slotPdoIncrement;     // SlotPdoIncrement="64"
    unsigned int slotIndexIncrement;   // SlotIndexIncrement="#x800"，存十进制
    std::vector<ESISlot> slotList;     // 不能叫"slots"，会和 Qt 的 slots 宏冲突

    ESISlots() : slotPdoIncrement(0), slotIndexIncrement(0), slotList() {}
};

// ════════════════════════════════════════════════════════════
// ESC 寄存器
// ════════════════════════════════════════════════════════════

struct ESIESC {
    unsigned int reg0108 = 0;
    unsigned int reg0400 = 0;
    unsigned int reg0410 = 0;
    unsigned int reg0420 = 0;
    // ESI 中可能出现其他 RegXXXX，用 map 兜底
    std::map<std::string, unsigned int> extraRegs;

    ESIESC() = default;
};

// ════════════════════════════════════════════════════════════
// Enum（对象字典值的枚举标注）— 贝克霍夫等厂商常用
// ════════════════════════════════════════════════════════════

struct ESIEnumInfo {
    std::string value;           // "0"
    std::string label;           // "No mode change"

    ESIEnumInfo() : value(""), label("") {}
};

struct ESIEnum {
    std::vector<ESIEnumInfo> enumInfos;

    // 判空即表示不存在此元素
    bool isEmpty() const { return enumInfos.empty(); }
};

// ════════════════════════════════════════════════════════════
// DataType / Object → Dictionary → Profile
// ════════════════════════════════════════════════════════════

struct ESIDataType {
    bool         enable;
    std::string  name;           // "UINT" / "ARRAY [0..13] OF UINT" / "DT1010"
    std::string  comment;        // "Unsigned integer"
    std::string  baseType;       // 数组/别名才有，如 "UINT"；基本类型为空
    unsigned short bitSize;

    struct ArrayInfo {
        int lBound;              // <LBound>0</LBound>
        int elements;            // <Elements>14</Elements>

        ArrayInfo() : lBound(0), elements(0) {}
    };

    struct SubItem {
        int          subIndex;   // <SubIdx>0</SubIdx>
        std::string  name;
        std::string  type;
        unsigned int bitSize;
        unsigned int bitOffs;

        Flags flags;

        // 位域标注（贝克霍夫系，可选）
        ESIEnum denotation;      // 每个值的含义
        ESIEnum indication;      // 反向标注

        SubItem()
            : subIndex(0), name(""), type(""), bitSize(0), bitOffs(0)
            , flags(), denotation(), indication() {}
    };

    ArrayInfo info;
    std::vector<SubItem> subItems;

    ESIDataType()
        : enable(false), name(""), comment(""), baseType(""), bitSize(0)
        , info(), subItems() {}
};

struct ESIObject {
    std::string  index;          // "#x1000"
    std::string  name;           // "Device type"
    std::string  type;           // "UDINT"
    unsigned int bitSize;

    // 对象值枚举（贝克霍夫系，如 0=No mode change, 1=PP mode ...）
    ESIEnum objEnum;             // 判空：objEnum.isEmpty()

    struct SubItem {
        int          subIndex;   // <SubIdx>0</SubIdx>
        std::string  name;
        std::string  type;
        unsigned int bitSize;
        unsigned int bitOffs;

        Flags flags;

        // 位域标注（贝克霍夫系，可选）
        ESIEnum denotation;      // 每个值的含义
        ESIEnum indication;      // 反向标注

        SubItem()
            : subIndex(0), name(""), type(""), bitSize(0), bitOffs(0)
            , flags(), denotation(), indication() {}
    };

    std::vector<SubItem> subItems;
    Flags flags;

    ESIObject()
        : index(""), name(""), type(""), bitSize(0)
        , objEnum(), subItems(), flags() {}
};

struct ESIDictionary {
    bool enable;
    std::vector<ESIDataType> dataTypes;
    std::vector<ESIObject>   objects;

    ESIDictionary() : enable(false), dataTypes(), objects() {}
};

struct ESIProfile {
    bool          enable;
    std::string   profileNo;     // "402"
    std::string   addInfo;       // Weidmueller: <AddInfo>0</AddInfo>
    ESIDictionary dictionary;

    ESIProfile() : enable(false), profileNo(""), addInfo(""), dictionary() {}
};

// ════════════════════════════════════════════════════════════
// Device
// ════════════════════════════════════════════════════════════

struct ESIDevice {
    // <Device Physics="YY">
    std::string physics;

    // <Type ProductCode="#x10b0" RevisionNo="#x00010004">XE2</Type>
    std::string type;
    std::string productCode;
    std::string revisionNo;

    // <Name LcId="1033">XE2</Name>
    std::string name;

    // <GroupType>Drive</GroupType>
    std::string groupType;

    // <Info> → StateMachine → Timeout
    ESIInfo info;

    // SM / FMMU
    std::vector<ESISm>   syncManagers;
    std::vector<ESIFmmu> fmmus;

    // PDO（Device 层级：Fixed="0" 的可配置占位 PDO）
    std::vector<ESIRxpdo> rxpdos;
    std::vector<ESITxpdo> txpdos;

    // Mailbox / EEPROM
    ESIMailBox mailBox;
    ESIEeprom  eeprom;

    // Profile（CiA 402 等设备行规 + 完整 Dictionary，一个 Device 可有多个）
    std::vector<ESIProfile> profiles;

    // Distributed Clocks
    std::vector<ESIDcOpMode> dcOpModes;

    // Slot 架构（多轴设备）
    ESISlots slotConfig;          // 不能叫"slots"

    // ESC 寄存器
    ESIESC esc;

    // 设备图标（base64）
    std::string imageData16x14;

    ESIDevice()
        : physics(""), type(""), productCode(""), revisionNo("")
        , name(""), groupType("")
        , info(), syncManagers(), fmmus(), rxpdos(), txpdos()
        , mailBox(), eeprom(), profiles()
        , dcOpModes(), slotConfig(), esc(), imageData16x14("") {}
};

// ════════════════════════════════════════════════════════════
// Module（预定义 PDO 配置，一种工作模式对应一个 Module）
// ════════════════════════════════════════════════════════════

struct ESIModule {
    // <Type ModuleIdent="#x10b00100" ModuleClass="Di" ModulePdoGroup="1">Cyclic position Mode</Type>
    std::string moduleIdent;
    std::string moduleClass;      // 模块分类（Weidmueller: "Di", "Do", "Ai", "Ao"）
    int         modulePdoGroup;   // PDO 分组编号（Weidmueller，-1 = 不存在）
    std::string type;

    // <Name>Cyclic position Mode</Name>
    std::string name;

    // PDO（Module 层级：Fixed="1" + Sm 属性 + DependOnSlot）
    std::vector<ESIRxpdo> rxpdos;
    std::vector<ESITxpdo> txpdos;

    // Mailbox（无 DataLinkLayer，CoE 下含 InitCmd）
    ESIMailBox mailBox;

    // Profile（可选，引用行规编号）
    ESIProfile profile;

    ESIModule()
        : moduleIdent(""), moduleClass(""), modulePdoGroup(-1)
        , type(""), name("")
        , rxpdos(), txpdos(), mailBox(), profile() {}
};

// ════════════════════════════════════════════════════════════
// 顶层容器 — 一个完整 ESI 文件的解析结果
// ════════════════════════════════════════════════════════════

struct ECATInfo {
    ESIVendor vendor;

    std::vector<ESIGroup>  groups;
    std::vector<ESIDevice> devices;
    std::vector<ESIModule> modules;

    ECATInfo() : vendor(), groups(), devices(), modules() {}
};

#endif // ESI_DEF_H
