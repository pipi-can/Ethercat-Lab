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

    ECATInfo parseDevice(const QString& filePath);

signals:

private:
    void parseVendor(QXmlStreamReader &xml, ECATInfo &info);
    void parseGroups(QXmlStreamReader &xml, ECATInfo &info);
    void parseDevices(QXmlStreamReader &xml, ECATInfo &info);
    void parseDeviceInfo(QXmlStreamReader &xml, ESIDevice &device);
};

#endif // ESIPARSER_H
