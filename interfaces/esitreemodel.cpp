#include "esitreemodel.h"

#include <QFile>
#include <QFileInfo>
#include <QDebug>

#include "esiparser.h"

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

QHash<int, QByteArray> ESITreeModel::roleNames() const
{
    return {
            {EsiRole::NodeType, "nodeType"},
            {EsiRole::Detail,   "detail"},
            {EsiRole::ObjIndex, "objIndex"},
            {EsiRole::Access,   "access"},
            {EsiRole::DataType, "objType"},
            {EsiRole::BitSize,  "bitSize"},
    };
}

bool ESITreeModel::loadFile(const QString &filePath)
{
    if (QFile::exists(filePath) == false) {
        qWarning() << "file donot exists" << filePath;
        return false;
    }
    qDebug() << "file exists" << filePath;
    ECATInfo info = ESIParser::getInstance().parseECATInfo(filePath);
    if (info.devices.size() == 0 && info.modules.size() == 0) {
        qWarning() << "the esi info donot have device and module !!!!!!";
        return false;
    }

    clear();

    QStandardItem* root = invisibleRootItem();

    QStandardItem* vendorGroup = makeItem(QString::fromStdString(info.vendor.name),
                                          NodeType::Vendor,
                                          QString("ID: %1").arg(info.vendor.id));

    if (!info.groups.empty()) {
        QStandardItem* groupGroup = makeItem("Groups", NodeType::Group);
        for (auto& group : info.groups) {
            groupGroup->appendRow(buildGroup(group));
        }
        vendorGroup->appendRow(groupGroup);
    }

    if (!info.devices.empty()) {
        QStandardItem* deviceGroup = makeItem("Devices", NodeType::Device);
        for (auto& device : info.devices) {
            deviceGroup->appendRow(buildDevice(device));
        }
        vendorGroup->appendRow(deviceGroup);
    }

    if (!info.modules.empty()) {
        QStandardItem* moduleGroup = makeItem("Modules", NodeType::Module);
        for (auto& module : info.modules) {
            moduleGroup->appendRow(buildModule(module));
        }
        vendorGroup->appendRow(moduleGroup);
    }

    root->appendRow(vendorGroup);
    return true;
}

QStandardItem* ESITreeModel::makeItem(const QString& text, NodeType type,
                                      const QString& detail,
                                      const QString& index,
                                      const QString& access, int bitSize)
{
    auto* item = new QStandardItem(text);
    item->setData(int(type), EsiRole::NodeType);
    item->setData(detail,     EsiRole::Detail);
    item->setData(index,      EsiRole::ObjIndex);
    item->setData(access,     EsiRole::Access);
    item->setData(bitSize,    EsiRole::BitSize);
    item->setEditable(false);
    return item;
}

QStandardItem *ESITreeModel::buildGroup(const ESIGroup &group)
{
    return makeItem(QString::fromStdString(group.type), NodeType::Group,
                    QString::fromStdString(group.name));
}

QStandardItem *ESITreeModel::buildDevice(const ESIDevice &device)
{
    QStandardItem* deviceItem = makeItem(QString::fromStdString(device.name),
                                         NodeType::Device,
                                         QString("Physics: %1 ProductCode: %2 RevisionNo: %3 GroupType: %4")
                                             .arg(device.physics).arg(device.productCode).arg(device.revisionNo).arg(device.groupType));

    QStandardItem* infoItem = makeItem(QString::fromStdString(device.info.name),
                                       NodeType::Device);
    deviceItem->appendRow(infoItem);

    if (!device.syncManagers.empty()) {
        QStandardItem* smItem = makeItem(QString::fromStdString("Sync Manager"),
                                         NodeType::SyncManager);
        for (auto& sm : device.syncManagers) {
            smItem->appendRow(buildSyncManager(sm));
        }
        deviceItem->appendRow(smItem);
    }

    if (!device.fmmus.empty()) {
        QStandardItem* fmmuItem = makeItem(QString::fromStdString("Fmmu"),
                                           NodeType::Fmmu);
        for (auto& fmmu : device.fmmus) {
            fmmuItem->appendRow(buildFmmu(fmmu));
        }
        deviceItem->appendRow(fmmuItem);
    }

    if (!device.rxpdos.empty()) {
        QStandardItem* rxpdoItem = makeItem("Rxpdo", NodeType::RxPdo);

        for (auto& rxpdo : device.rxpdos) {
            rxpdoItem->appendRow(buildRxpdo(rxpdo));
        }
        deviceItem->appendRow(rxpdoItem);
    }

    if (!device.txpdos.empty()) {
        QStandardItem* txpdoItem = makeItem("Txpdo", NodeType::TxPdo);
        for (auto& txpdo : device.txpdos) {
            txpdoItem->appendRow(buildTxpdo(txpdo));
        }
        deviceItem->appendRow(txpdoItem);
    }

    deviceItem->appendRow(buildMailbox(device.mailBox));
    deviceItem->appendRow(makeItem("Eeprom", NodeType::Eeprom));

    if (!device.profiles.empty()) {
        QStandardItem* profileItem = makeItem("Profiles", NodeType::Profile);
        for (auto& profile : device.profiles) {
            profileItem->appendRow(buildProfile(profile));
        }
        deviceItem->appendRow(profileItem);
    }

    if (!device.dcOpModes.empty()) {
        QStandardItem* dcModeItem = makeItem("DcOpMode", NodeType::DcOpMode);
        for (auto& dcOpMode : device.dcOpModes) {
            dcModeItem->appendRow(buildDcOpMode(dcOpMode));
        }
        deviceItem->appendRow(dcModeItem);
    }

    deviceItem->appendRow(buildSlots(device.slotConfig));

    deviceItem->appendRow(makeItem("ESC", NodeType::Esc));
    return deviceItem;
}

QStandardItem *ESITreeModel::buildSyncManager(const ESISm &sm)
{
    return makeItem(QString::fromStdString(sm.name), NodeType::SyncManager,
                    QString("%1").arg(sm.enable ? "enable" : "disable"));
}

QStandardItem *ESITreeModel::buildFmmu(const ESIFmmu &fmmu)
{
    return makeItem(QString::fromStdString(fmmu.name), NodeType::Fmmu);
}

QStandardItem *ESITreeModel::buildRxpdo(const ESIRxpdo &rxpdo)
{
    return makeItem(QString::fromStdString(rxpdo.name), NodeType::RxPdo,
                    QString("Fixed: %1").arg(rxpdo.fixed ? 1 : 0));
}

QStandardItem *ESITreeModel::buildTxpdo(const ESITxpdo &txpdo)
{
    return makeItem(QString::fromStdString(txpdo.name), NodeType::TxPdo,
                    QString("Fixed: %1").arg(txpdo.fixed ? 1 : 0));
}

QStandardItem *ESITreeModel::buildProfile(const ESIProfile &profile)
{
    QStandardItem* profileItem = makeItem(QString::fromStdString(profile.profileNo), NodeType::Profile);

    if (profile.dictionary.enable) {
        if (!profile.dictionary.dataTypes.empty()) {
            QStandardItem* dataTypesItem = makeItem("DataTypes", NodeType::DataTypeNode);
            for (auto& dataType : profile.dictionary.dataTypes) {
                dataTypesItem->appendRow(makeItem(QString::fromStdString(dataType.name),
                                                  NodeType::DataTypeNode,
                                                  QString::fromStdString(dataType.comment),
                                                  "", "", dataType.bitSize));
            }
            profileItem->appendRow(dataTypesItem);
        }

        if (!profile.dictionary.objects.empty()) {
            QStandardItem* objsItem = makeItem("Objects", NodeType::Object);
            for (auto& obj : profile.dictionary.objects) {
                objsItem->appendRow(makeItem(QString::fromStdString(obj.name),
                                             NodeType::Object,
                                             QString::fromStdString(obj.type),
                                             QString::fromStdString(obj.index),
                                             QString::fromStdString(obj.flags.access),
                                             obj.bitSize));
            }
            profileItem->appendRow(objsItem);
        }
    }

    return profileItem;
}

QStandardItem *ESITreeModel::buildDcOpMode(const ESIDcOpMode &dcOpMode)
{
    return makeItem(QString::fromStdString(dcOpMode.name), NodeType::DcOpMode);
}

QStandardItem *ESITreeModel::buildSlots(const ESISlots &esiSlots)
{
    QStandardItem* slotsItem = makeItem("Slots", NodeType::Slot);

    if (!esiSlots.slotList.empty()) {
        for (auto& slot : esiSlots.slotList) {
            slotsItem->appendRow(makeItem(QString::fromStdString(slot.name), NodeType::Slot));
        }
    }
    return slotsItem;

}

QStandardItem *ESITreeModel::buildModule(const ESIModule &module)
{
    QStandardItem* moduleItem = makeItem(
        QString::fromStdString(module.name),
        NodeType::Module,
        QString("%1 (Ident: %2)")
            .arg(QString::fromStdString(module.type))
            .arg(QString::fromStdString(module.moduleIdent))
    );

    if (!module.rxpdos.empty()) {
        QStandardItem* rxpdoItem = makeItem("RxPDOs", NodeType::RxPdo);
        for (auto& rxpdo : module.rxpdos) {
            rxpdoItem->appendRow(buildRxpdo(rxpdo));
        }
        moduleItem->appendRow(rxpdoItem);
    }

    if (!module.txpdos.empty()) {
        QStandardItem* txpdoItem = makeItem("TxPDOs", NodeType::TxPdo);
        for (auto& txpdo : module.txpdos) {
            txpdoItem->appendRow(buildTxpdo(txpdo));
        }
        moduleItem->appendRow(txpdoItem);
    }

    moduleItem->appendRow(buildMailbox(module.mailBox));

    if (!module.profile.profileNo.empty()) {
        moduleItem->appendRow(buildProfile(module.profile));
    }

    return moduleItem;
}

QStandardItem *ESITreeModel::buildMailbox(const ESIMailBox &mb)
{
    QStandardItem* mbItem = makeItem("Mailbox", NodeType::Mailbox);

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
            NodeType::Mailbox));
    }

    if (!mb.initCmds.empty()) {
        QStandardItem* cmdGroup = makeItem(
            QString("InitCmds (%1)").arg(mb.initCmds.size()),
            NodeType::InitCmd);
        for (auto& cmd : mb.initCmds) {
            cmdGroup->appendRow(makeItem(
                QString("%1 → %2:%3 = %4")
                    .arg(QString::fromStdString(cmd.transition))
                    .arg(QString::fromStdString(cmd.index))
                    .arg(cmd.subIndex)
                    .arg(QString::fromStdString(cmd.data)),
                NodeType::InitCmd,
                QString::fromStdString(cmd.comment)));
        }
        mbItem->appendRow(cmdGroup);
    }

    return mbItem;
}