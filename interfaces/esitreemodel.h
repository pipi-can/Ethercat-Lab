#ifndef ESITREEMODEL_H
#define ESITREEMODEL_H

#include <QStandardItemModel>
#include "ESI_def.h"

// Role 常量
namespace EsiRole {
    constexpr int NodeType   = Qt::UserRole + 1;
    constexpr int Detail     = Qt::UserRole + 2;
    constexpr int ObjIndex   = Qt::UserRole + 3;
    constexpr int Access     = Qt::UserRole + 4;
    constexpr int DataType   = Qt::UserRole + 5;
    constexpr int BitSize    = Qt::UserRole + 6;
    constexpr int IconSource = Qt::UserRole + 7;
    constexpr int Properties = Qt::UserRole + 8;
    constexpr int FileIndex  = Qt::UserRole + 9;
    constexpr int IconColor  = Qt::UserRole + 10;
}

enum class NodeType {
    Device, SyncManager, Fmmu,
    RxPdo, TxPdo, PdoEntry,
    Mailbox, InitCmd, Eeprom,
    Dc, DcOpMode, Slot, ModuleIdent, Esc,
    Profile, Dictionary, DataTypeNode, Object, SubItem,
    Module, Group, Vendor
};

class ESITreeModel : public QStandardItemModel
{
    Q_OBJECT
    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)
    Q_PROPERTY(int fileCount READ fileCount NOTIFY fileCountChanged)

public:

    ESITreeModel(const ESITreeModel& other) = delete;
    void operator=(const ESITreeModel& other) = delete;

    static ESITreeModel& getInstance();

    bool hasData() const;
    int fileCount() const;

    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE bool loadFile(const QString& filePath);
    Q_INVOKABLE int findMatchRow(const QString& query) const;

signals:
    void hasDataChanged();
    void fileCountChanged();


private:

    explicit ESITreeModel(QObject *parent = nullptr);
    ~ESITreeModel();

    // 多文件存储 — 每个文件对应一个 ECATInfo
    std::vector<ECATInfo> m_loadedFiles;

    // 图标路径辅助
    static QString iconForNodeType(NodeType type);
    // 图标颜色辅助（原型配色：warm/accent/green/dim）
    static QString iconColorForNodeType(NodeType type);

    // 属性构建辅助 — 为每种节点构建完整的 QVariantMap
    static QVariantMap buildVendorProps(const ESIVendor& v);
    static QVariantMap buildGroupProps(const ESIGroup& g);
    static QVariantMap buildDeviceProps(const ESIDevice& d);
    static QVariantMap buildSmProps(const ESISm& sm);
    static QVariantMap buildFmmuProps(const ESIFmmu& f);
    static QVariantMap buildRxpdoProps(const ESIRxpdo& p);
    static QVariantMap buildTxpdoProps(const ESITxpdo& p);
    static QVariantMap buildPdoEntryProps(const ESIPdoEntry& e);
    static QVariantMap buildMailboxProps(const ESIMailBox& mb);
    static QVariantMap buildInitCmdProps(const ESIInitCmd& c);
    static QVariantMap buildEepromProps(const ESIEeprom& e);
    static QVariantMap buildDcProps(const ESIDcOpMode& dc);
    static QVariantMap buildSlotProps(const ESISlot& s);
    static QVariantMap buildEscProps(const ESIESC& e);
    static QVariantMap buildProfileProps(const ESIProfile& p);
    static QVariantMap buildDataTypeProps(const ESIDataType& dt);
    static QVariantMap buildObjectProps(const ESIObject& o);
    static QVariantMap buildModuleProps(const ESIModule& m);

    QStandardItem* makeItem(const QString& text, NodeType type,
                            const QString& detail = {},
                            const QString& index = {},
                            const QString& access = {},
                            int bitSize = -1,
                            const QVariantMap& properties = {},
                            int fileIndex = -1);

    QStandardItem* buildGroup(const ESIGroup& group, int fileIdx);
    QStandardItem* buildDevice(const ESIDevice& device, int fileIdx);
    QStandardItem* buildSyncManager(const ESISm& sm, int fileIdx);
    QStandardItem* buildFmmu(const ESIFmmu& fmmu, int fileIdx);
    QStandardItem* buildRxpdo(const ESIRxpdo& rxpdo, int fileIdx);
    QStandardItem* buildTxpdo(const ESITxpdo& txpdo, int fileIdx);
    QStandardItem* buildProfile(const ESIProfile& profile, int fileIdx);
    QStandardItem* buildDcOpMode(const ESIDcOpMode& dcOpMode, int fileIdx);
    QStandardItem* buildSlots(const ESISlots& esiSlots, int fileIdx);
    QStandardItem* buildModule(const ESIModule& module, int fileIdx);
    QStandardItem* buildMailbox(const ESIMailBox& mb, int fileIdx);
};

#endif // ESITREEMODEL_H
