#include "esitreemodel.h"

#include <QFile>
#include <QFileInfo>
#include <QDebug>

#include "esiparser.h"

// ════════════════════════════════════════════════════════════
// 图标路径辅助 — NodeType → qrc 资源路径
// ════════════════════════════════════════════════════════════
QString ESITreeModel::iconForNodeType(NodeType type)
{
    const QString prefix = QStringLiteral("qrc:/resources/tree-icons/");
    switch (type) {
    case NodeType::Vendor:       return prefix + "vendor.svg";
    case NodeType::Group:        return prefix + "group.svg";
    case NodeType::Device:       return prefix + "device.svg";
    case NodeType::SyncManager:  return prefix + "sm-out.svg";
    case NodeType::Fmmu:         return prefix + "entry.svg";
    case NodeType::RxPdo:        return prefix + "pdo-rx.svg";
    case NodeType::TxPdo:        return prefix + "pdo-tx.svg";
    case NodeType::PdoEntry:     return prefix + "entry.svg";
    case NodeType::Mailbox:      return prefix + "mailbox.svg";
    case NodeType::InitCmd:      return prefix + "entry.svg";
    case NodeType::Eeprom:       return prefix + "entry.svg";
    case NodeType::Dc:           return prefix + "dc.svg";
    case NodeType::DcOpMode:     return prefix + "dc.svg";
    case NodeType::Slot:         return prefix + "module.svg";
    case NodeType::ModuleIdent:  return prefix + "entry.svg";
    case NodeType::Esc:          return prefix + "module.svg";
    case NodeType::Profile:      return prefix + "group.svg";
    case NodeType::Dictionary:   return prefix + "group.svg";
    case NodeType::DataTypeNode: return prefix + "entry.svg";
    case NodeType::Object:       return prefix + "entry.svg";
    case NodeType::SubItem:      return prefix + "entry.svg";
    case NodeType::Module:       return prefix + "module.svg";
    }
    return {};
}

// ════════════════════════════════════════════════════════════
// 图标颜色辅助 — NodeType → 原型配色（warm/accent/green/dim）
// ════════════════════════════════════════════════════════════
QString ESITreeModel::iconColorForNodeType(NodeType type)
{
    switch (type) {
    // warm  #d4844a — 橙色系
    case NodeType::Vendor:
    case NodeType::Mailbox:
    case NodeType::SyncManager:
        return QStringLiteral("#d4844a");
    // accent #5294e2 — 蓝色系
    case NodeType::Group:
    case NodeType::RxPdo:
    case NodeType::Dc:
    case NodeType::DcOpMode:
    case NodeType::Slot:
    case NodeType::Profile:
    case NodeType::Dictionary:
    case NodeType::Esc:
    case NodeType::Module:
        return QStringLiteral("#5294e2");
    // green  #42a85f — 绿色系
    case NodeType::Device:
    case NodeType::TxPdo:
        return QStringLiteral("#42a85f");
    // dim    #88909e — 灰色
    case NodeType::Fmmu:
    case NodeType::PdoEntry:
    case NodeType::InitCmd:
    case NodeType::Eeprom:
    case NodeType::ModuleIdent:
    case NodeType::DataTypeNode:
    case NodeType::Object:
    case NodeType::SubItem:
    default:
        return QStringLiteral("#88909e");
    }
}

// ════════════════════════════════════════════════════════════
// 属性构建辅助 — 每种节点构建完整 QVariantMap
// ════════════════════════════════════════════════════════════

QVariantMap ESITreeModel::buildVendorProps(const ESIVendor& v)
{
    QVariantMap m;
    m["Vendor ID"] = QString::fromStdString(v.id);
    m["Vendor Name"] = QString::fromStdString(v.name);
    m["File Version"] = QString::fromStdString(v.fileVersion);
    m["Has Icon"] = !v.imageData16x14.empty() ? QStringLiteral("Yes") : QStringLiteral("No");
    return m;
}

QVariantMap ESITreeModel::buildGroupProps(const ESIGroup& g)
{
    QVariantMap m;
    m["Type"] = QString::fromStdString(g.type);
    m["Name"] = QString::fromStdString(g.name);
    m["Sort Order"] = g.sortOrder;
    m["Has Icon"] = (!g.imageData16x14.empty() || !g.image16x14.empty())
        ? QStringLiteral("Yes") : QStringLiteral("No");
    return m;
}

QVariantMap ESITreeModel::buildDeviceProps(const ESIDevice& d)
{
    QVariantMap m;
    m["Product Code"] = QString::fromStdString(d.productCode);
    m["Revision No"] = QString::fromStdString(d.revisionNo);
    m["Physics"] = QString::fromStdString(d.physics);
    m["Type"] = QString::fromStdString(d.type);
    m["Name"] = QString::fromStdString(d.name);
    m["Group Type"] = QString::fromStdString(d.groupType);
    return m;
}

QVariantMap ESITreeModel::buildSmProps(const ESISm& sm)
{
    QVariantMap m;
    m["Name"] = QString::fromStdString(sm.name);
    m["Enable"] = sm.enable ? QStringLiteral("Yes") : QStringLiteral("No");
    m["Start Address"] = QString::fromStdString(sm.startAddress);
    m["Control Byte"] = QString::fromStdString(sm.controlBytes);
    m["Min Size"] = sm.minSize;
    m["Default Size"] = sm.defaultSize;
    m["Max Size"] = sm.maxSize;
    return m;
}

QVariantMap ESITreeModel::buildFmmuProps(const ESIFmmu& f)
{
    QVariantMap m;
    m["Name"] = QString::fromStdString(f.name);
    return m;
}

QVariantMap ESITreeModel::buildRxpdoProps(const ESIRxpdo& p)
{
    QVariantMap m;
    m["Index"] = QString::fromStdString(p.index);
    m["Name"] = QString::fromStdString(p.name);
    m["Fixed"] = p.fixed ? QStringLiteral("Yes") : QStringLiteral("No");
    m["SM"] = QString::fromStdString(p.sm);
    m["Depend On Slot"] = p.dependOnSlot;

    // 子项列表 — 供详情面板的 Entry 表格使用
    QVariantList entries;
    for (const auto& e : p.entries) {
        entries.append(buildPdoEntryProps(e));
    }
    m["entries"] = entries;
    return m;
}

QVariantMap ESITreeModel::buildTxpdoProps(const ESITxpdo& p)
{
    QVariantMap m;
    m["Index"] = QString::fromStdString(p.index);
    m["Name"] = QString::fromStdString(p.name);
    m["Fixed"] = p.fixed ? QStringLiteral("Yes") : QStringLiteral("No");
    m["SM"] = QString::fromStdString(p.sm);
    m["Depend On Slot"] = p.dependOnSlot;

    QVariantList entries;
    for (const auto& e : p.entries) {
        entries.append(buildPdoEntryProps(e));
    }
    m["entries"] = entries;
    return m;
}

QVariantMap ESITreeModel::buildPdoEntryProps(const ESIPdoEntry& e)
{
    QVariantMap m;
    m["Index"] = QString::fromStdString(e.index);
    m["SubIndex"] = e.subIndex;
    m["Name"] = QString::fromStdString(e.name);
    m["Data Type"] = QString::fromStdString(e.dataType);
    m["Bit Length"] = e.bitLen;
    return m;
}

QVariantMap ESITreeModel::buildMailboxProps(const ESIMailBox& mb)
{
    QVariantMap m;
    m["Data Link Layer"] = mb.dataLinkLayer ? QStringLiteral("Yes") : QStringLiteral("No");
    m["EoE"] = mb.eoe ? QStringLiteral("Supported") : QStringLiteral("No");
    m["CoE"] = mb.coe ? QStringLiteral("Supported") : QStringLiteral("No");
    m["FoE"] = mb.foe ? QStringLiteral("Supported") : QStringLiteral("No");
    m["AoE"] = mb.aoe ? QStringLiteral("Supported") : QStringLiteral("No");
    m["SoE"] = mb.soe ? QStringLiteral("Supported") : QStringLiteral("No");
    m["VoE"] = mb.voe ? QStringLiteral("Supported") : QStringLiteral("No");
    if (mb.coe) {
        m["PDO Assign"] = mb.coePdoAssign;
        m["PDO Config"] = mb.coePdoConfig;
        m["SDO Info"] = mb.coeSdoInfo;
        m["Complete Access"] = mb.coeCompleteAccess;
        m["Segmented SDO"] = mb.coeSegmentedSdo;
    }
    return m;
}

QVariantMap ESITreeModel::buildInitCmdProps(const ESIInitCmd& c)
{
    QVariantMap m;
    m["Transition"] = QString::fromStdString(c.transition);
    m["Index"] = QString::fromStdString(c.index);
    m["SubIndex"] = c.subIndex;
    m["Data"] = QString::fromStdString(c.data);
    m["Comment"] = QString::fromStdString(c.comment);
    m["Depend On Slot"] = c.dependOnSlot;
    return m;
}

QVariantMap ESITreeModel::buildEepromProps(const ESIEeprom& e)
{
    QVariantMap m;
    m["Enable"] = e.enable ? QStringLiteral("Yes") : QStringLiteral("No");
    m["Byte Size"] = e.byteSize;
    m["Config Data"] = QString::fromStdString(e.configData);
    m["Bootstrap"] = QString::fromStdString(e.bootStrap);
    return m;
}

QVariantMap ESITreeModel::buildDcProps(const ESIDcOpMode& dc)
{
    QVariantMap m;
    m["Name"] = QString::fromStdString(dc.name);
    m["Description"] = QString::fromStdString(dc.desc);
    m["Assign Activate"] = QString::fromStdString(dc.assignActivate);
    m["Cycle Time Sync0"] = dc.cycleTimeSync0;
    m["Shift Time Sync0"] = dc.shiftTimeSync0;
    m["Factor"] = dc.factor;
    return m;
}

QVariantMap ESITreeModel::buildSlotProps(const ESISlot& s)
{
    QVariantMap m;
    m["Name"] = QString::fromStdString(s.name);
    m["Max Instances"] = s.maxInstances;
    m["Min Instances"] = s.minInstances;
    return m;
}

QVariantMap ESITreeModel::buildEscProps(const ESIESC& e)
{
    QVariantMap m;
    m["Reg 0108"] = e.reg0108;
    m["Reg 0400"] = e.reg0400;
    m["Reg 0410"] = e.reg0410;
    m["Reg 0420"] = e.reg0420;
    for (const auto& [key, val] : e.extraRegs) {
        m[QString::fromStdString(key)] = val;
    }
    return m;
}

QVariantMap ESITreeModel::buildProfileProps(const ESIProfile& p)
{
    QVariantMap m;
    m["Profile No"] = QString::fromStdString(p.profileNo);
    if (!p.addInfo.empty())
        m["Add Info"] = QString::fromStdString(p.addInfo);
    m["Dictionary"] = p.dictionary.enable ? QStringLiteral("Yes") : QStringLiteral("No");
    m["DataTypes"] = static_cast<int>(p.dictionary.dataTypes.size());
    m["Objects"] = static_cast<int>(p.dictionary.objects.size());
    return m;
}

QVariantMap ESITreeModel::buildDataTypeProps(const ESIDataType& dt)
{
    QVariantMap m;
    m["Name"] = QString::fromStdString(dt.name);
    m["Base Type"] = QString::fromStdString(dt.baseType);
    m["Bit Size"] = dt.bitSize;
    m["Comment"] = QString::fromStdString(dt.comment);
    return m;
}

QVariantMap ESITreeModel::buildObjectProps(const ESIObject& o)
{
    QVariantMap m;
    m["Index"] = QString::fromStdString(o.index);
    m["Name"] = QString::fromStdString(o.name);
    m["Type"] = QString::fromStdString(o.type);
    m["Bit Size"] = o.bitSize;
    m["Access"] = QString::fromStdString(o.flags.access);
    m["PDO Mapping"] = QString::fromStdString(o.flags.pdoMapping);
    m["Backup"] = o.flags.backup;

    // 子项列表
    QVariantList subItems;
    for (const auto& si : o.subItems) {
        QVariantMap sm;
        sm["SubIndex"] = si.subIndex;
        sm["Name"] = QString::fromStdString(si.name);
        sm["Type"] = QString::fromStdString(si.type);
        sm["Bit Size"] = si.bitSize;
        sm["Bit Offset"] = si.bitOffs;
        sm["Access"] = QString::fromStdString(si.flags.access);
        subItems.append(sm);
    }
    m["subItems"] = subItems;
    return m;
}

QVariantMap ESITreeModel::buildModuleProps(const ESIModule& m)
{
    QVariantMap p;
    p["Module Ident"] = QString::fromStdString(m.moduleIdent);
    p["Module Class"] = QString::fromStdString(m.moduleClass);
    p["PDO Group"] = m.modulePdoGroup;
    p["Type"] = QString::fromStdString(m.type);
    p["Name"] = QString::fromStdString(m.name);
    p["RxPDOs"] = static_cast<int>(m.rxpdos.size());
    p["TxPDOs"] = static_cast<int>(m.txpdos.size());
    return p;
}

// ════════════════════════════════════════════════════════════
// 单例 & 构造
// ════════════════════════════════════════════════════════════

ESITreeModel::ESITreeModel(QObject *parent)
    : QStandardItemModel(parent)
{}

ESITreeModel::~ESITreeModel()
{}

ESITreeModel &ESITreeModel::getInstance()
{
    static ESITreeModel instance;
    return instance;
}

bool ESITreeModel::hasData() const
{
    return invisibleRootItem() && invisibleRootItem()->hasChildren();
}

int ESITreeModel::fileCount() const
{
    return static_cast<int>(m_loadedFiles.size());
}

QHash<int, QByteArray> ESITreeModel::roleNames() const
{
    auto roles = QStandardItemModel::roleNames();
    roles.insert(EsiRole::NodeType,   "nodeType");
    roles.insert(EsiRole::Detail,     "detail");
    roles.insert(EsiRole::ObjIndex,   "objIndex");
    roles.insert(EsiRole::Access,     "access");
    roles.insert(EsiRole::DataType,   "objType");
    roles.insert(EsiRole::BitSize,    "bitSize");
    roles.insert(EsiRole::IconSource, "iconSource");
    roles.insert(EsiRole::Properties, "properties");
    roles.insert(EsiRole::FileIndex,  "fileIndex");
    roles.insert(EsiRole::IconColor,  "iconColor");
    return roles;
}

// ════════════════════════════════════════════════════════════
// 加载文件 — 多文件支持（追加而非清除）
// ════════════════════════════════════════════════════════════

bool ESITreeModel::loadFile(const QString &filePath)
{
    if (!QFile::exists(filePath)) {
        qWarning() << "File does not exist:" << filePath;
        return false;
    }

    ECATInfo info = ESIParser::getInstance().parseECATInfo(filePath);
    if (info.devices.empty() && info.modules.empty()) {
        qWarning() << "ESI info has no device and no module!";
        return false;
    }

    // 存入多文件存储
    int fileIdx = static_cast<int>(m_loadedFiles.size());
    m_loadedFiles.push_back(std::move(info));
    const ECATInfo& cur = m_loadedFiles.back();

    QStandardItem* root = invisibleRootItem();

    // 文件标签 — 用文件名作为顶级节点便于区分多文件
    QString fileLabel = QFileInfo(filePath).fileName();
    QStandardItem* fileRootItem = makeItem(fileLabel, NodeType::Vendor,
                                            QString("File #%1").arg(fileIdx + 1),
                                            {}, {}, -1,
                                            buildVendorProps(cur.vendor),
                                            fileIdx);

    QStandardItem* vendorItem = makeItem(
        QString::fromStdString(cur.vendor.name),
        NodeType::Vendor,
        QString("ID: %1").arg(QString::fromStdString(cur.vendor.id)),
        {}, {}, -1,
        buildVendorProps(cur.vendor),
        fileIdx);

    if (!cur.groups.empty()) {
        QStandardItem* groupGroup = makeItem("Groups", NodeType::Group,
                                              {}, {}, {}, -1, {}, fileIdx);
        for (const auto& group : cur.groups) {
            groupGroup->appendRow(buildGroup(group, fileIdx));
        }
        vendorItem->appendRow(groupGroup);
    }

    if (!cur.devices.empty()) {
        QStandardItem* deviceGroup = makeItem("Devices", NodeType::Device,
                                               {}, {}, {}, -1, {}, fileIdx);
        for (const auto& dev : cur.devices) {
            deviceGroup->appendRow(buildDevice(dev, fileIdx));
        }
        vendorItem->appendRow(deviceGroup);
    }

    if (!cur.modules.empty()) {
        QStandardItem* moduleGroup = makeItem("Modules", NodeType::Module,
                                               {}, {}, {}, -1, {}, fileIdx);
        for (const auto& mod : cur.modules) {
            moduleGroup->appendRow(buildModule(mod, fileIdx));
        }
        vendorItem->appendRow(moduleGroup);
    }

    fileRootItem->appendRow(vendorItem);
    root->appendRow(fileRootItem);

    emit hasDataChanged();
    emit fileCountChanged();
    return true;
}

// ════════════════════════════════════════════════════════════
// 搜索 — 返回完全展开树中首个匹配节点的行号，-1=未找到
// ════════════════════════════════════════════════════════════
int ESITreeModel::findMatchRow(const QString &query) const
{
    if (query.isEmpty()) return -1;
    const QString q = query.toLower();
    int counter = 0;

    std::function<int(const QStandardItem*)> walk = [&](const QStandardItem* item) -> int {
        if (!item) return -1;
        // 当前节点
        if (item->text().toLower().contains(q))
            return counter;
        counter++;
        // 遍历子节点
        for (int r = 0; r < item->rowCount(); ++r) {
            int found = walk(item->child(r));
            if (found >= 0) return found;
        }
        return -1;
    };

    return walk(invisibleRootItem());
}

// ════════════════════════════════════════════════════════════
// makeItem — 统一工厂，带图标 & 属性
// ════════════════════════════════════════════════════════════

QStandardItem* ESITreeModel::makeItem(const QString& text, NodeType type,
                                       const QString& detail,
                                       const QString& index,
                                       const QString& access,
                                       int bitSize,
                                       const QVariantMap& properties,
                                       int fileIndex)
{
    auto* item = new QStandardItem(text);
    item->setData(int(type), EsiRole::NodeType);
    item->setData(detail,     EsiRole::Detail);
    item->setData(index,      EsiRole::ObjIndex);
    item->setData(access,     EsiRole::Access);
    item->setData(bitSize,    EsiRole::BitSize);
    item->setData(iconForNodeType(type),  EsiRole::IconSource);
    item->setData(iconColorForNodeType(type), EsiRole::IconColor);
    item->setData(properties,  EsiRole::Properties);
    item->setData(fileIndex,   EsiRole::FileIndex);
    item->setEditable(false);
    return item;
}

// ════════════════════════════════════════════════════════════
// 树构建函数 — 每个都传递 fileIdx + properties
// ════════════════════════════════════════════════════════════

QStandardItem* ESITreeModel::buildGroup(const ESIGroup& group, int fileIdx)
{
    return makeItem(QString::fromStdString(group.type), NodeType::Group,
                    QString::fromStdString(group.name),
                    {}, {}, -1,
                    buildGroupProps(group), fileIdx);
}

QStandardItem* ESITreeModel::buildDevice(const ESIDevice& device, int fileIdx)
{
    auto props = buildDeviceProps(device);
    QStandardItem* deviceItem = makeItem(
        QString::fromStdString(device.name),
        NodeType::Device,
        QString("Physics: %1  ProductCode: %2  RevisionNo: %3  GroupType: %4")
            .arg(QString::fromStdString(device.physics))
            .arg(QString::fromStdString(device.productCode))
            .arg(QString::fromStdString(device.revisionNo))
            .arg(QString::fromStdString(device.groupType)),
        {}, {}, -1, props, fileIdx);

    QStandardItem* infoItem = makeItem(
        QString::fromStdString(device.info.name),
        NodeType::Device, {}, {}, {}, -1, {}, fileIdx);
    deviceItem->appendRow(infoItem);

    if (!device.syncManagers.empty()) {
        QStandardItem* smGroup = makeItem("Sync Managers", NodeType::SyncManager,
                                           {}, {}, {}, -1, {}, fileIdx);
        for (const auto& sm : device.syncManagers) {
            smGroup->appendRow(buildSyncManager(sm, fileIdx));
        }
        deviceItem->appendRow(smGroup);
    }

    if (!device.fmmus.empty()) {
        QStandardItem* fmmuGroup = makeItem("FMMUs", NodeType::Fmmu,
                                             {}, {}, {}, -1, {}, fileIdx);
        for (const auto& f : device.fmmus) {
            fmmuGroup->appendRow(buildFmmu(f, fileIdx));
        }
        deviceItem->appendRow(fmmuGroup);
    }

    if (!device.rxpdos.empty()) {
        QStandardItem* rxpdoGroup = makeItem("RxPDOs", NodeType::RxPdo,
                                              {}, {}, {}, -1, {}, fileIdx);
        for (const auto& p : device.rxpdos) {
            rxpdoGroup->appendRow(buildRxpdo(p, fileIdx));
        }
        deviceItem->appendRow(rxpdoGroup);
    }

    if (!device.txpdos.empty()) {
        QStandardItem* txpdoGroup = makeItem("TxPDOs", NodeType::TxPdo,
                                              {}, {}, {}, -1, {}, fileIdx);
        for (const auto& p : device.txpdos) {
            txpdoGroup->appendRow(buildTxpdo(p, fileIdx));
        }
        deviceItem->appendRow(txpdoGroup);
    }

    deviceItem->appendRow(buildMailbox(device.mailBox, fileIdx));

    deviceItem->appendRow(makeItem("EEPROM", NodeType::Eeprom,
                                    {}, {}, {}, -1,
                                    buildEepromProps(device.eeprom), fileIdx));

    if (!device.profiles.empty()) {
        QStandardItem* profileGroup = makeItem("Profiles", NodeType::Profile,
                                                {}, {}, {}, -1, {}, fileIdx);
        for (const auto& prof : device.profiles) {
            profileGroup->appendRow(buildProfile(prof, fileIdx));
        }
        deviceItem->appendRow(profileGroup);
    }

    if (!device.dcOpModes.empty()) {
        QStandardItem* dcGroup = makeItem("DC OpModes", NodeType::DcOpMode,
                                           {}, {}, {}, -1, {}, fileIdx);
        for (const auto& dc : device.dcOpModes) {
            dcGroup->appendRow(buildDcOpMode(dc, fileIdx));
        }
        deviceItem->appendRow(dcGroup);
    }

    deviceItem->appendRow(buildSlots(device.slotConfig, fileIdx));

    deviceItem->appendRow(makeItem("ESC", NodeType::Esc,
                                    {}, {}, {}, -1,
                                    buildEscProps(device.esc), fileIdx));
    return deviceItem;
}

QStandardItem* ESITreeModel::buildSyncManager(const ESISm& sm, int fileIdx)
{
    return makeItem(QString::fromStdString(sm.name), NodeType::SyncManager,
                    QString("%1").arg(sm.enable ? "enable" : "disable"),
                    {}, {}, -1,
                    buildSmProps(sm), fileIdx);
}

QStandardItem* ESITreeModel::buildFmmu(const ESIFmmu& fmmu, int fileIdx)
{
    return makeItem(QString::fromStdString(fmmu.name), NodeType::Fmmu,
                    {}, {}, {}, -1,
                    buildFmmuProps(fmmu), fileIdx);
}

QStandardItem* ESITreeModel::buildRxpdo(const ESIRxpdo& rxpdo, int fileIdx)
{
    auto props = buildRxpdoProps(rxpdo);
    QStandardItem* item = makeItem(
        QString::fromStdString(rxpdo.name), NodeType::RxPdo,
        QString("Fixed: %1  SM: %2  Index: %3")
            .arg(rxpdo.fixed ? 1 : 0)
            .arg(QString::fromStdString(rxpdo.sm))
            .arg(QString::fromStdString(rxpdo.index)),
        QString::fromStdString(rxpdo.index), {}, -1,
        props, fileIdx);

    // PDO Entry 子节点
    for (const auto& e : rxpdo.entries) {
        item->appendRow(makeItem(
            QString("%1:%2  %3")
                .arg(QString::fromStdString(e.index))
                .arg(e.subIndex)
                .arg(QString::fromStdString(e.name)),
            NodeType::PdoEntry,
            QString("%1  %2 bit").arg(QString::fromStdString(e.dataType)).arg(e.bitLen),
            QString::fromStdString(e.index), {}, e.bitLen,
            buildPdoEntryProps(e), fileIdx));
    }
    return item;
}

QStandardItem* ESITreeModel::buildTxpdo(const ESITxpdo& txpdo, int fileIdx)
{
    auto props = buildTxpdoProps(txpdo);
    QStandardItem* item = makeItem(
        QString::fromStdString(txpdo.name), NodeType::TxPdo,
        QString("Fixed: %1  SM: %2  Index: %3")
            .arg(txpdo.fixed ? 1 : 0)
            .arg(QString::fromStdString(txpdo.sm))
            .arg(QString::fromStdString(txpdo.index)),
        QString::fromStdString(txpdo.index), {}, -1,
        props, fileIdx);

    for (const auto& e : txpdo.entries) {
        item->appendRow(makeItem(
            QString("%1:%2  %3")
                .arg(QString::fromStdString(e.index))
                .arg(e.subIndex)
                .arg(QString::fromStdString(e.name)),
            NodeType::PdoEntry,
            QString("%1  %2 bit").arg(QString::fromStdString(e.dataType)).arg(e.bitLen),
            QString::fromStdString(e.index), {}, e.bitLen,
            buildPdoEntryProps(e), fileIdx));
    }
    return item;
}

QStandardItem* ESITreeModel::buildProfile(const ESIProfile& profile, int fileIdx)
{
    auto props = buildProfileProps(profile);
    QStandardItem* profileItem = makeItem(
        QString("Profile %1").arg(QString::fromStdString(profile.profileNo)),
        NodeType::Profile, {}, {}, {}, -1, props, fileIdx);

    if (profile.dictionary.enable) {
        if (!profile.dictionary.dataTypes.empty()) {
            QStandardItem* dtGroup = makeItem("DataTypes", NodeType::DataTypeNode,
                                               {}, {}, {}, -1, {}, fileIdx);
            for (const auto& dt : profile.dictionary.dataTypes) {
                dtGroup->appendRow(makeItem(
                    QString::fromStdString(dt.name), NodeType::DataTypeNode,
                    QString::fromStdString(dt.comment),
                    {}, {}, dt.bitSize,
                    buildDataTypeProps(dt), fileIdx));
            }
            profileItem->appendRow(dtGroup);
        }

        if (!profile.dictionary.objects.empty()) {
            QStandardItem* objGroup = makeItem("Objects", NodeType::Object,
                                                {}, {}, {}, -1, {}, fileIdx);
            for (const auto& obj : profile.dictionary.objects) {
                objGroup->appendRow(makeItem(
                    QString("%1  %2")
                        .arg(QString::fromStdString(obj.index))
                        .arg(QString::fromStdString(obj.name)),
                    NodeType::Object,
                    QString::fromStdString(obj.type),
                    QString::fromStdString(obj.index),
                    QString::fromStdString(obj.flags.access),
                    obj.bitSize,
                    buildObjectProps(obj), fileIdx));
            }
            profileItem->appendRow(objGroup);
        }
    }

    return profileItem;
}

QStandardItem* ESITreeModel::buildDcOpMode(const ESIDcOpMode& dc, int fileIdx)
{
    return makeItem(QString::fromStdString(dc.name), NodeType::DcOpMode,
                    QString::fromStdString(dc.desc),
                    {}, {}, -1,
                    buildDcProps(dc), fileIdx);
}

QStandardItem* ESITreeModel::buildSlots(const ESISlots& esiSlots, int fileIdx)
{
    QStandardItem* slotsItem = makeItem("Slots", NodeType::Slot,
                                         {}, {}, {}, -1, {}, fileIdx);

    for (const auto& slot : esiSlots.slotList) {
        slotsItem->appendRow(makeItem(
            QString::fromStdString(slot.name), NodeType::Slot,
            QString("Instances: %1–%2").arg(slot.minInstances).arg(slot.maxInstances),
            {}, {}, -1,
            buildSlotProps(slot), fileIdx));
    }
    return slotsItem;
}

QStandardItem* ESITreeModel::buildModule(const ESIModule& module, int fileIdx)
{
    auto props = buildModuleProps(module);
    QStandardItem* moduleItem = makeItem(
        QString::fromStdString(module.name),
        NodeType::Module,
        QString("%1  (Ident: %2%3)")
            .arg(QString::fromStdString(module.type))
            .arg(QString::fromStdString(module.moduleIdent))
            .arg(module.moduleClass.empty() ? QString() : QString(", Class: %1").arg(QString::fromStdString(module.moduleClass))),
        {}, {}, -1, props, fileIdx);

    if (!module.rxpdos.empty()) {
        QStandardItem* rxGroup = makeItem("RxPDOs", NodeType::RxPdo,
                                           {}, {}, {}, -1, {}, fileIdx);
        for (const auto& p : module.rxpdos) {
            rxGroup->appendRow(buildRxpdo(p, fileIdx));
        }
        moduleItem->appendRow(rxGroup);
    }

    if (!module.txpdos.empty()) {
        QStandardItem* txGroup = makeItem("TxPDOs", NodeType::TxPdo,
                                           {}, {}, {}, -1, {}, fileIdx);
        for (const auto& p : module.txpdos) {
            txGroup->appendRow(buildTxpdo(p, fileIdx));
        }
        moduleItem->appendRow(txGroup);
    }

    moduleItem->appendRow(buildMailbox(module.mailBox, fileIdx));

    if (!module.profile.profileNo.empty()) {
        moduleItem->appendRow(buildProfile(module.profile, fileIdx));
    }

    return moduleItem;
}

QStandardItem* ESITreeModel::buildMailbox(const ESIMailBox& mb, int fileIdx)
{
    auto props = buildMailboxProps(mb);
    QStandardItem* mbItem = makeItem("Mailbox", NodeType::Mailbox,
                                      {}, {}, {}, -1, props, fileIdx);

    QStringList protos;
    if (mb.eoe) protos << "EoE";
    if (mb.coe) protos << "CoE";
    if (mb.foe) protos << "FoE";
    if (mb.aoe) protos << "AoE";
    if (mb.soe) protos << "SoE";
    if (mb.voe) protos << "VoE";

    if (!protos.isEmpty()) {
        mbItem->appendRow(makeItem(
            QString("Protocols: %1").arg(protos.join(", ")),
            NodeType::Mailbox, {}, {}, {}, -1, {}, fileIdx));
    }

    if (!mb.initCmds.empty()) {
        QStandardItem* cmdGroup = makeItem(
            QString("InitCmds (%1)").arg(mb.initCmds.size()),
            NodeType::InitCmd, {}, {}, {}, -1, {}, fileIdx);
        for (const auto& cmd : mb.initCmds) {
            cmdGroup->appendRow(makeItem(
                QString("%1 → %2:%3 = %4")
                    .arg(QString::fromStdString(cmd.transition))
                    .arg(QString::fromStdString(cmd.index))
                    .arg(cmd.subIndex)
                    .arg(QString::fromStdString(cmd.data)),
                NodeType::InitCmd,
                QString::fromStdString(cmd.comment),
                {}, {}, -1,
                buildInitCmdProps(cmd), fileIdx));
        }
        mbItem->appendRow(cmdGroup);
    }

    return mbItem;
}
