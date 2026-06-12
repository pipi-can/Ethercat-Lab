#ifndef ESITREEMODEL_H
#define ESITREEMODEL_H

#include <QStandardItemModel>
#include "ESI_def.h"

// Role 常量
namespace EsiRole {
    constexpr int NodeType = Qt::UserRole + 1;
    constexpr int Detail   = Qt::UserRole + 2;
    constexpr int ObjIndex = Qt::UserRole + 3;
    constexpr int Access   = Qt::UserRole + 4;
    constexpr int DataType = Qt::UserRole + 5;
    constexpr int BitSize  = Qt::UserRole + 6;
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

public:

    ESITreeModel(const ESITreeModel& other) = delete;
    void operator=(const ESITreeModel& other) = delete;

    static ESITreeModel& getInstance();

    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE bool loadFile(const QString& filePath);


private:

    explicit ESITreeModel(QObject *parent = nullptr);
    ~ESITreeModel();

    QStandardItem* makeItem(const QString& text, NodeType type,
                            const QString& detail = {},
                            const QString& index = {},
                            const QString& access = {},
                            int bitSize = -1);

    QStandardItem* buildGroup(const ESIGroup& group);

    QStandardItem* buildDevice(const ESIDevice& device);

    QStandardItem* buildSyncManager(const ESISm& sm);

    QStandardItem* buildFmmu(const ESIFmmu& fmmu);

    QStandardItem* buildRxpdo(const ESIRxpdo& rxpdo);

    QStandardItem* buildTxpdo(const ESITxpdo& txpdo);

    QStandardItem* buildProfile(const ESIProfile& profile);

    QStandardItem* buildDcOpMode(const ESIDcOpMode& dcOpMode);

    QStandardItem* buildSlots(const ESISlots& esiSlots);

    QStandardItem* buildModule(const ESIModule& module);

    QStandardItem* buildMailbox(const ESIMailBox& mb);
};

#endif // ESITREEMODEL_H
