#ifndef ESIPARSER_H
#define ESIPARSER_H

#include <QObject>
#include <QXmlStreamReader>
#include "ESI_def.h"


class ESIParser : public QObject
{
    Q_OBJECT
public:
    explicit ESIParser(QObject *parent = nullptr);

    ECATInfo parseECATInfo(const QString& filePath);

signals:

private:
    void parseVendor(QXmlStreamReader &xml, ECATInfo &info);
    void parseGroups(QXmlStreamReader &xml, ECATInfo &info);
    void parseDevices(QXmlStreamReader &xml, ECATInfo &info);
    void parseModules(QXmlStreamReader &xml, ECATInfo &info);
    void parseDeviceInfo(QXmlStreamReader &xml, ESIDevice &device);

    ESIModule parseModule(QXmlStreamReader& xml);
    ESIRxpdo parseRxpdo(QXmlStreamReader& xml);
    ESIPdoEntry parsePdoEntry(QXmlStreamReader& xml);
    ESIMailBox parseMailBox(QXmlStreamReader& xml);
    ESIInitCmd parseInitCmd(QXmlStreamReader& xml);
    ESIEeprom parseEeprom(QXmlStreamReader& xml);
    ESIProfile parseProfile(QXmlStreamReader& xml);
    ESIDictionary parseDictionary(QXmlStreamReader& xml);
    std::vector<ESIDataType> parseDataTypes(QXmlStreamReader& xml);
    ESIDataType parseDataType(QXmlStreamReader& xml);
    ESIDataType::ArrayInfo parseArrayInfo(QXmlStreamReader& xml);
    ESIDataType::SubItem parseSubItem(QXmlStreamReader& xml);
    Flags parseFlags(QXmlStreamReader& xml);
    std::vector<ESIObject> parseObjects(QXmlStreamReader& xml);
    ESIObject parseObject(QXmlStreamReader& xml);
    ESIObject::SubItem parseObjectSubItem(QXmlStreamReader& xml);
    ESIEnum parseEnum(QXmlStreamReader& xml);
    ESIEnumInfo parseEnumInfo(QXmlStreamReader& xml);

    std::vector<ESIDcOpMode> parseDcOpModes(QXmlStreamReader& xml);
    ESIDcOpMode parseDcOpMode(QXmlStreamReader& xml);
    ESISlots parseSlots(QXmlStreamReader& xml);
    ESIESC parseESC(QXmlStreamReader& xml);
};

#endif // ESIPARSER_H
