#include "esiparser.h"

#include <QFile>
#include <QDebug>
#include <QStringView>

ESIParser::ESIParser(QObject *parent)
    : QObject{parent}
{}

ECATInfo ESIParser::parseDevice(const QString &filePath)
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
                    xml.skipCurrentElement();

                } else if (xml.name() == QStringView(u"TxPdo")) {
                    // TODO: 完整的 TxPdo 解析
                    xml.skipCurrentElement();

                } else if (xml.name() == QStringView(u"Mailbox")) {
                    // TODO: 完整的 Mailbox 解析
                    xml.skipCurrentElement();

                } else if (xml.name() == QStringView(u"Eeprom")) {
                    // TODO: 完整的 Eeprom 解析
                    xml.skipCurrentElement();

                } else if (xml.name() == QStringView(u"Profile")) {
                    // TODO: 完整的 Profile 解析
                    xml.skipCurrentElement();

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
