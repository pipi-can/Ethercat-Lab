#include "esiparser.h"

#include <QFile>
#include <QDebug>
#include <QStringView>

ESIParser::ESIParser(QObject *parent)
    : QObject{parent}
{}

ECATInfo ESIParser::parseECATInfo(const QString &filePath)
{
    // Bug 2 fix: QFile + QXmlStreamReader 正确构造
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Cannot open file:" << filePath;
        return ECATInfo();
    }

    ECATInfo result;
    QXmlStreamReader xml(&file);

    if (xml.readNextStartElement() && xml.name() == QStringView(u"EtherCATInfo")) {
        while (xml.readNextStartElement()) {
            if (xml.name() == QStringView(u"Vendor")) {
                parseVendor(xml, result);
            } else if (xml.name() == QStringView(u"Descriptions")) {
                // Groups / Devices / Modules 都在 Descriptions 里
                while (xml.readNextStartElement()) {
                    if (xml.name() == QStringView(u"Groups")) {
                        parseGroups(xml, result);
                    } else if (xml.name() == QStringView(u"Devices")) {
                        parseDevices(xml, result);
                    } else if (xml.name() == QStringView(u"Modules")) {
                        parseModules(xml, result);
                    } else {
                        xml.skipCurrentElement();
                    }
                }
            } else {
                xml.skipCurrentElement();
            }
        }
    }

    // Bug 1 fix: 返回结果
    return result;
}

void ESIParser::parseVendor(QXmlStreamReader &xml, ECATInfo &info)
{
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"Id")) {
            info.vendor.id = xml.readElementText().toStdString();
        } else if (xml.name() == QStringView(u"Name")) {
            info.vendor.name = xml.readElementText().toStdString();
        } else {
            xml.skipCurrentElement();
        }
    }
}

void ESIParser::parseGroups(QXmlStreamReader &xml, ECATInfo &info)
{
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"Group")) {
            ESIGroup group;
            group.sortOrder = xml.attributes().value("SortOrder").toString().toInt();

            // Bug 4 fix: 内层变量改叫 childName
            while (xml.readNextStartElement()) {
                if (xml.name() == QStringView(u"Type")) {
                    group.type = xml.readElementText().toStdString();
                } else if (xml.name() == QStringView(u"Name")) {
                    group.name = xml.readElementText().toStdString();
                } else {
                    xml.skipCurrentElement();
                }
            }

            info.groups.push_back(std::move(group));
        } else {
            xml.skipCurrentElement();
        }
    }
}

void ESIParser::parseDevices(QXmlStreamReader &xml, ECATInfo &info)
{
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"Device")) {
            ESIDevice device;
            device.physics = xml.attributes().value("Physics").toString().toStdString();

            while (xml.readNextStartElement()) {
                if (xml.name() == QStringView(u"Type")) {
                    device.productCode = xml.attributes().value("ProductCode").toString().toStdString();
                    device.revisionNo  = xml.attributes().value("RevisionNo").toString().toStdString();
                    device.type        = xml.readElementText().toStdString();

                } else if (xml.name() == QStringView(u"Name")) {
                    device.name = xml.readElementText().toStdString();

                } else if (xml.name() == QStringView(u"Info")) {
                    parseDeviceInfo(xml, device);

                } else if (xml.name() == QStringView(u"GroupType")) {
                    device.groupType = xml.readElementText().toStdString();

                } else if (xml.name() == QStringView(u"Fmmu")) {
                    device.fmmus.emplace_back(xml.readElementText().toStdString());

                } else if (xml.name() == QStringView(u"Sm")) {
                    ESISm sm;
                    sm.enable       = xml.attributes().value("Enable").toString() == QString("1");
                    sm.startAddress = xml.attributes().value("StartAddress").toString().toStdString();
                    sm.controlBytes = xml.attributes().value("ControlByte").toString().toStdString();
                    sm.minSize      = xml.attributes().value("MinSize").toString().toUInt();
                    sm.defaultSize  = xml.attributes().value("DefaultSize").toString().toUInt();
                    sm.maxSize      = xml.attributes().value("MaxSize").toString().toUInt();
                    sm.name         = xml.readElementText().toStdString();
                    device.syncManagers.push_back(std::move(sm));

                } else if (xml.name() == QStringView(u"RxPdo")) {
                    // TODO: 完整的 RxPdo 解析
                    bool fixed = xml.attributes().value("Fixed").toString() == QString("1");
                    std::string sm = xml.attributes().value("Sm").toString().toStdString();
                    ESIRxpdo rxpdo = parseRxpdo(xml);
                    rxpdo.fixed = fixed;
                    rxpdo.sm = sm;
                    device.rxpdos.push_back(std::move(rxpdo));
                } else if (xml.name() == QStringView(u"TxPdo")) {
                    // TODO: 完整的 TxPdo 解析
                    bool fixed = xml.attributes().value("Fixed").toString() == QString("1");
                    std::string sm = xml.attributes().value("Sm").toString().toStdString();
                    // TxPdo 的解析与 RxPdo 类似，先调用 parseRxpdo 解析公共部分，再修改特有部分
                    ESIRxpdo rxpdo = parseRxpdo(xml);
                    ESITxpdo txpdo;
                    txpdo.fixed = fixed;
                    txpdo.sm = sm;
                    txpdo.index = rxpdo.index;
                    txpdo.name = rxpdo.name;
                    txpdo.dependOnSlot = rxpdo.dependOnSlot;
                    txpdo.entries = std::move(rxpdo.entries);
                    device.txpdos.push_back(std::move(txpdo));
                } else if (xml.name() == QStringView(u"Mailbox")) {
                    // TODO: 完整的 Mailbox 解析
                    device.mailBox = parseMailBox(xml);
                } else if (xml.name() == QStringView(u"Eeprom")) {
                    // TODO: 完整的 Eeprom 解析
                    device.eeprom = parseEeprom(xml);
                } else if (xml.name() == QStringView(u"Profile")) {
                    // TODO: 完整的 Profile 解析
                    device.profiles.emplace_back(parseProfile(xml));
                } else if (xml.name() == QStringView(u"Dc")) {
                    device.dcOpModes = parseDcOpModes(xml);
                } else if (xml.name() == QStringView(u"Slots")) {
                    device.slotConfig = parseSlots(xml);
                } else if (xml.name() == QStringView(u"ESC")) {
                    device.esc = parseESC(xml);
                } else if (xml.name() == QStringView(u"ImageData16x14")) {
                    device.imageData16x14 = xml.readElementText().toStdString();
                } else {
                    xml.skipCurrentElement();
                }
            }

            info.devices.push_back(std::move(device));
        } else {
            xml.skipCurrentElement();
        }
    }
}

void ESIParser::parseDeviceInfo(QXmlStreamReader &xml, ESIDevice &device)
{
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"StateMachine")) {
            while (xml.readNextStartElement()) {
                if (xml.name() == QStringView(u"Timeout")) {
                    // Bug 3 fix: Timeout 的子元素是子标签，不是属性
                    while (xml.readNextStartElement()) {
                        if (xml.name() == QStringView(u"PreopTimeout")) {
                            device.info.preopTimeout = xml.readElementText().toUInt();
                        } else if (xml.name() == QStringView(u"SafeopOpTimeout")) {
                            device.info.safeopOpTimeout = xml.readElementText().toUInt();
                        } else if (xml.name() == QStringView(u"BackToInitTimeout")) {
                            device.info.backToInitTimeout = xml.readElementText().toUInt();
                        } else if (xml.name() == QStringView(u"BackToSafeopTimeout")) {
                            device.info.backToSafeopTimeout = xml.readElementText().toUInt();
                        } else {
                            xml.skipCurrentElement();
                        }
                    }
                } else {
                    xml.skipCurrentElement();
                }
            }
        } else {
            xml.skipCurrentElement();
        }
    }
}

ESIRxpdo ESIParser::parseRxpdo(QXmlStreamReader &xml)
{
    ESIRxpdo result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Index") {
            result.dependOnSlot = xml.attributes().value("DependOnSlot").toString().toInt();
            result.index = xml.readElementText().toStdString();
        } else if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "Entry") {
            ESIPdoEntry pdoEntry = parsePdoEntry(xml);
            result.entries.emplace_back(pdoEntry);
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIPdoEntry ESIParser::parsePdoEntry(QXmlStreamReader &xml)
{
    ESIPdoEntry result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Index") {
            result.dependOnSlot = xml.attributes().value("DependOnSlot").toString().toInt();
            result.index = xml.readElementText().toStdString();
        } else if (name == "SubIndex") {
            result.subIndex = xml.readElementText().toInt();
        } else if (name == "BitLen") {
            result.bitLen = xml.readElementText().toInt();
        } else if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "DataType") {
            result.dataType = xml.readElementText().toStdString();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIMailBox ESIParser::parseMailBox(QXmlStreamReader &xml)
{
    ESIMailBox result;
    result.dataLinkLayer = xml.attributes().value("DataLinkLayer").toString().toStdString() == "true" ? true : false;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "EoE") {
            result.eoe = true;
            xml.skipCurrentElement();
        } else if (name == "CoE") {
            result.coe = true;
            result.coePdoAssign = xml.attributes().value("PdoAssign").toString().toInt();
            result.coePdoConfig = xml.attributes().value("PdoConfig").toString().toInt();
            result.coeSdoInfo = xml.attributes().value("SdoInfo").toString().toInt();
            result.coeCompleteAccess = xml.attributes().value("CompleteAccess").toString().toInt();
            result.coeSegmentedSdo = xml.attributes().value("SegmentedSdo").toString().toInt();
            result.coeDiagHistory = xml.attributes().value("DiagHistory").toString().toInt();

            // 读取 CoE 子元素：自闭合 <CoE .../> 已经没有子元素，
            // 非自闭合 <CoE> 才有 InitCmd；readNextStartElement() 会正确区分
            while (xml.readNextStartElement()) {
                if (xml.name() == QStringView(u"InitCmd")) {
                    result.initCmds.push_back(parseInitCmd(xml));
                } else {
                    xml.skipCurrentElement();
                }
            }
        } else if (name == "FoE") {
            result.foe = true;
            xml.skipCurrentElement();
        } else if (name == "AoE") {
            result.aoe = true;
            xml.skipCurrentElement();
        } else if (name == "SoE") {
            result.soe = true;
            xml.skipCurrentElement();
        } else if (name == "VoE") {
            result.voe = true;
            xml.skipCurrentElement();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIInitCmd ESIParser::parseInitCmd(QXmlStreamReader &xml)
{
    ESIInitCmd result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Transition") {
            result.transition = xml.readElementText().toStdString();
        } else if (name == "Index") {
            result.dependOnSlot = xml.attributes().value("DependOnSlot").toString().toInt();
            result.index = xml.readElementText().toStdString();
        } else if (name == "SubIndex") {
            result.subIndex = xml.readElementText().toInt();
        } else if (name == "Data") {
            result.data = xml.readElementText().toStdString();
        } else if (name == "Comment") {
            result.comment = xml.readElementText().toStdString();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIEeprom ESIParser::parseEeprom(QXmlStreamReader &xml)
{
    ESIEeprom result;
    result.enable = true;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "ByteSize") {
            result.byteSize = xml.readElementText().toUInt();
        } else if (name == "ConfigData") {
            result.configData = xml.readElementText().toStdString();
        } else if (name == "BootStrap") {
            result.bootStrap = xml.readElementText().toStdString();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIProfile ESIParser::parseProfile(QXmlStreamReader &xml)
{
    ESIProfile result;
    result.enable = true;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "ProfileNo") {
            result.profileNo = xml.readElementText().toStdString();
        } else if (name == "Dictionary") {
            result.dictionary = parseDictionary(xml);
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIDictionary ESIParser::parseDictionary(QXmlStreamReader &xml)
{
    ESIDictionary result;
    result.enable = true;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "DataTypes") {
            result.dataTypes = parseDataTypes(xml);
        } else if (name == "Objects") {
            result.objects = parseObjects(xml);
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

std::vector<ESIDataType> ESIParser::parseDataTypes(QXmlStreamReader &xml)
{
    std::vector<ESIDataType> result;
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"DataType")) {
            result.emplace_back(parseDataType(xml));
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIDataType ESIParser::parseDataType(QXmlStreamReader &xml)
{
    ESIDataType result;
    result.enable = true;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "Comment") {
            result.comment = xml.readElementText().toStdString();
        } else if (name == "BaseType") {
            result.baseType = xml.readElementText().toStdString();
        } else if (name == "BitSize") {
            result.bitSize = xml.readElementText().toUInt();
        } else if (name == "ArrayInfo") {
            result.info = parseArrayInfo(xml);
        } else if (name == "SubItem") {
            result.subItems.emplace_back(parseSubItem(xml));
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIDataType::ArrayInfo ESIParser::parseArrayInfo(QXmlStreamReader &xml)
{
    ESIDataType::ArrayInfo result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "LBound") {
            result.lBound = xml.readElementText().toInt();
        } else if (name == "Elements") {
            result.elements = xml.readElementText().toInt();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIDataType::SubItem ESIParser::parseSubItem(QXmlStreamReader &xml)
{
    ESIDataType::SubItem result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "SubIdx") {
            result.subIndex = xml.readElementText().toInt();
        } else if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "Type") {
            result.type = xml.readElementText().toStdString();
        } else if (name == "BitSize") {
            result.bitSize = xml.readElementText().toUInt();
        } else if (name == "BitOffs") {
            result.bitOffs = xml.readElementText().toUInt();
        } else if (name == "Flags") {
            result.flags = parseFlags(xml);
        } else if (name == "Denotation") {
            result.denotation = parseEnum(xml);
        } else if (name == "Indication") {
            result.indication = parseEnum(xml);
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

Flags ESIParser::parseFlags(QXmlStreamReader &xml)
{
    Flags result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Access") {
            result.access = xml.readElementText().toStdString();
        } else if (name == "PdoMapping") {
            result.pdoMapping = xml.readElementText().toStdString();
        } else if (name == "Backup") {
            result.backup = xml.readElementText().toUInt();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

std::vector<ESIObject> ESIParser::parseObjects(QXmlStreamReader &xml)
{
    std::vector<ESIObject> result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Object") {
            result.emplace_back(parseObject(xml));
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIObject ESIParser::parseObject(QXmlStreamReader &xml)
{
    ESIObject result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Index") {
            result.index = xml.readElementText().toStdString();
        } else if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "Type") {
            result.type = xml.readElementText().toStdString();
        } else if (name == "BitSize") {
            result.bitSize = xml.readElementText().toUInt();
        } else if (name == "Flags") {
            result.flags = parseFlags(xml);
        } else if (name == "Enum") {
            result.objEnum = parseEnum(xml);
        } else if (name == "Info") {
            while (xml.readNextStartElement()) {
                QString name = xml.name().toString();
                if (name == "SubItem") {
                    result.subItems.emplace_back(parseObjectSubItem(xml));
                } else {
                    xml.skipCurrentElement();
                }
            }
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIObject::SubItem ESIParser::parseObjectSubItem(QXmlStreamReader &xml)
{
    ESIObject::SubItem result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "SubIdx") {
            result.subIndex = xml.readElementText().toInt();
        } else if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "Type") {
            result.type = xml.readElementText().toStdString();
        } else if (name == "BitSize") {
            result.bitSize = xml.readElementText().toUInt();
        } else if (name == "BitOffs") {
            result.bitOffs = xml.readElementText().toUInt();
        } else if (name == "Flags") {
            result.flags = parseFlags(xml);
        } else if (name == "Denotation") {
            result.denotation = parseEnum(xml);
        } else if (name == "Indication") {
            result.indication = parseEnum(xml);
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

std::vector<ESIDcOpMode> ESIParser::parseDcOpModes(QXmlStreamReader &xml)
{
    std::vector<ESIDcOpMode> result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == QStringView(u"OpMode")) {
            result.emplace_back(parseDcOpMode(xml));
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIDcOpMode ESIParser::parseDcOpMode(QXmlStreamReader &xml)
{
    ESIDcOpMode result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "Desc") {
            result.desc = xml.readElementText().toStdString();
        } else if (name == "AssignActivate") {
            result.assignActivate = xml.readElementText().toStdString();
        } else if (name == "CycleTimeSync0") {
            result.cycleTimeSync0 = xml.readElementText().toUInt();
            result.factor = xml.attributes().value("Factor").toString().toInt();
        } else if (name == "ShiftTimeSync0") {
            result.shiftTimeSync0 = xml.readElementText().toUInt();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESISlots ESIParser::parseSlots(QXmlStreamReader &xml)
{
    ESISlots result;
    result.slotPdoIncrement = xml.attributes().value("SlotPdoIncrement").toString().toUInt();
    QString idxIncStr = xml.attributes().value("SlotIndexIncrement").toString();
    result.slotIndexIncrement = idxIncStr.startsWith("#x") || idxIncStr.startsWith("#X")
        ? idxIncStr.mid(2).toUInt(nullptr, 16) : idxIncStr.toUInt();
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Slot") {
            ESISlot slot;
            slot.maxInstances = xml.attributes().value("MaxInstances").toString().toInt();
            slot.minInstances = xml.attributes().value("MinInstances").toString().toInt();

            while (xml.readNextStartElement()) {
                if (xml.name() == QStringView(u"ModuleIdent")) {
                    ESIModuleIdent moduleIdent;
                    moduleIdent.isDefault = xml.attributes().value("Default").toString() == QString("1");
                    moduleIdent.value = xml.readElementText().toStdString();
                    slot.moduleIdents.push_back(std::move(moduleIdent));
                } else if (xml.name() == QStringView(u"Name")) {
                    slot.name = xml.readElementText().toStdString();
                } else {
                    xml.skipCurrentElement();
                }
            }

            result.slotList.push_back(std::move(slot));
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIESC ESIParser::parseESC(QXmlStreamReader &xml)
{
    ESIESC result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Reg0108") {
            result.reg0108 = xml.readElementText().toUInt();
        } else if (name == "Reg0400") {
            result.reg0400 = xml.readElementText().toUInt();
        } else if (name == "Reg0410") {
            result.reg0410 = xml.readElementText().toUInt();
        } else if (name == "Reg0420") {
            result.reg0420 = xml.readElementText().toUInt();
        } else if (name.startsWith("Reg")) {
            // 未知寄存器存入 extraRegs map（key = "RegXXXX"）
            result.extraRegs[name.toStdString()] = xml.readElementText().toUInt();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

void ESIParser::parseModules(QXmlStreamReader &xml, ECATInfo &info)
{
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"Module")) {
            info.modules.push_back(parseModule(xml));
        } else {
            xml.skipCurrentElement();
        }
    }
}

ESIModule ESIParser::parseModule(QXmlStreamReader &xml)
{
    ESIModule result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Type") {
            result.moduleIdent = xml.attributes().value("ModuleIdent").toString().toStdString();
            result.type = xml.readElementText().toStdString();
        } else if (name == "Name") {
            result.name = xml.readElementText().toStdString();
        } else if (name == "RxPdo") {
            bool fixed = xml.attributes().value("Fixed").toString() == QString("1");
            std::string sm = xml.attributes().value("Sm").toString().toStdString();
            ESIRxpdo rxpdo = parseRxpdo(xml);
            rxpdo.fixed = fixed;
            rxpdo.sm = sm;
            result.rxpdos.push_back(std::move(rxpdo));
        } else if (name == "TxPdo") {
            bool fixed = xml.attributes().value("Fixed").toString() == QString("1");
            std::string sm = xml.attributes().value("Sm").toString().toStdString();
            ESIRxpdo rxpdo = parseRxpdo(xml);
            ESITxpdo txpdo;
            txpdo.fixed = fixed;
            txpdo.sm = sm;
            txpdo.index = rxpdo.index;
            txpdo.name = rxpdo.name;
            txpdo.dependOnSlot = rxpdo.dependOnSlot;
            txpdo.entries = std::move(rxpdo.entries);
            result.txpdos.push_back(std::move(txpdo));
        } else if (name == "Mailbox") {
            result.mailBox = parseMailBox(xml);
        } else if (name == "Profile") {
            result.profile = parseProfile(xml);
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIEnum ESIParser::parseEnum(QXmlStreamReader &xml)
{
    ESIEnum result;
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"Info")) {
            result.enumInfos.push_back(parseEnumInfo(xml));
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}

ESIEnumInfo ESIParser::parseEnumInfo(QXmlStreamReader &xml)
{
    ESIEnumInfo result;
    while (xml.readNextStartElement()) {
        QString name = xml.name().toString();
        if (name == "Value") {
            result.value = xml.readElementText().toStdString();
        } else if (name == "Label") {
            result.label = xml.readElementText().toStdString();
        } else {
            xml.skipCurrentElement();
        }
    }
    return result;
}
