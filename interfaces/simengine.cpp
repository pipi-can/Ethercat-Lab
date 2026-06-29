#include "simengine.h"
#include "esitreemodel.h"

#include <QtMath>
#include <QVariant>
#include <QSet>
#include <algorithm>
#include <cstring>

namespace {

// 统一 PDO 索引格式：#x1701 / 0x1701 → "1701"，方便比较 Exclude 列表
QString normalizePdoIndex(const QString& idx)
{
    QString s = idx.trimmed();
    if (s.startsWith(QLatin1String("#x"), Qt::CaseInsensitive))
        s = s.mid(2);
    else if (s.startsWith(QLatin1String("0x"), Qt::CaseInsensitive))
        s = s.mid(2);
    return s.toUpper();
}

} // namespace

/**
 * @brief 判断两个 PDO 是否互斥（ESI 的 <Exclude> 标签）
 * @note  只有 AKD 这类文件有 Exclude；Copley 没有 Exclude，此函数始终返回 false，
 *        意味着 Copley 的空槽位可以同时勾选多个（符合 CoE 自行配置的行为）
 */
bool SimEngine::pdoIndicesConflict(const SimPdo& a, const SimPdo& b)
{
    const QString ai = normalizePdoIndex(a.index);
    const QString bi = normalizePdoIndex(b.index);
    if (ai.isEmpty() || bi.isEmpty() || ai == bi)
        return false;

    for (const QString& ex : a.excludes) {
        if (normalizePdoIndex(ex) == bi)
            return true;
    }
    for (const QString& ex : b.excludes) {
        if (normalizePdoIndex(ex) == ai)
            return true;
    }
    return false;
}

/**
 * @brief 添加从站时，为 Rx 或 Tx 方向选出默认启用的 PDO
 *
 * 优先级：
 *   1. 有 Sm="2"/"3" 的 → 每个 Sm 编号只启用第一个（厂商默认分配到 Sync Manager）
 *   2. 无 Sm 但有 Entry → 启用第一个有内容的 PDO
 *   3. 全是空槽位 → 启用列表第一个占位
 */
void SimEngine::applyDefaultPdoSelection(std::vector<SimPdo>& pdos)
{
    const bool anySm = std::any_of(pdos.begin(), pdos.end(),
        [](const SimPdo& p) { return !p.sm.isEmpty(); });

    if (anySm) {
        QSet<QString> usedSm;
        for (SimPdo& p : pdos) {
            // 同一 Sm 编号只能分配一个 PDO（如 Sm="2" 对应 Outputs）
            if (!p.sm.isEmpty() && !usedSm.contains(p.sm)) {
                p.enabled = true;
                usedSm.insert(p.sm);
            } else {
                p.enabled = false;
            }
        }
        return;
    }

    bool assigned = false;
    for (SimPdo& p : pdos) {
        if (!assigned && !p.entries.empty()) {
            p.enabled = true;
            assigned = true;
        } else {
            p.enabled = false;
        }
    }
    // 无 Sm、无 Entry 的空槽位设备：启用第一个 PDO 占位
    if (!assigned && !pdos.empty())
        pdos.front().enabled = true;
}

/** @brief 用户勾选一个 PDO 时，自动取消与其 Exclude 冲突的其他 PDO */
void SimEngine::disableConflictingPdos(std::vector<SimPdo>& pdos, int enabledIdx)
{
    if (enabledIdx < 0 || enabledIdx >= static_cast<int>(pdos.size()))
        return;

    const SimPdo& target = pdos[static_cast<size_t>(enabledIdx)];
    for (int i = 0; i < static_cast<int>(pdos.size()); ++i) {
        if (i == enabledIdx)
            continue;
        if (pdos[static_cast<size_t>(i)].enabled
            && pdoIndicesConflict(target, pdos[static_cast<size_t>(i)])) {
            pdos[static_cast<size_t>(i)].enabled = false;
        }
    }
}

SimEngine& SimEngine::getInstance()
{
    static SimEngine instance;
    return instance;
}

SimEngine::SimEngine(QObject* parent)
    : QObject(parent)
{
    connect(&m_runTimer, &QTimer::timeout, this, &SimEngine::stepFrame);
    m_runTimer.setInterval(4);
}

int SimEngine::slaveCount() const { return static_cast<int>(m_slaves.size()); }

int SimEngine::selectedChainIndex() const { return m_selectedChainIndex; }

void SimEngine::setSelectedChainIndex(int index)
{
    if (m_selectedChainIndex == index)
        return;
    m_selectedChainIndex = index;
    emit selectedChainIndexChanged();
}

QVariantList SimEngine::slaves() const
{
    QVariantList list;
    for (int i = 0; i < static_cast<int>(m_slaves.size()); ++i)
        list.append(slaveToVariant(m_slaves[static_cast<size_t>(i)], i));
    return list;
}

int SimEngine::frameCount() const { return m_frameCount; }
QByteArray SimEngine::lastFrame() const { return m_lastFrame; }
QVariantList SimEngine::frameFields() const { return m_frameFields; }
bool SimEngine::running() const { return m_running; }

SimSlave SimEngine::loadSlaveFromEsi(int fileIndex, int deviceIndex)
{
    SimSlave slave;
    slave.fileIndex = fileIndex;
    slave.deviceIndex = deviceIndex;

    QVariantMap detail = ESITreeModel::getInstance().getDeviceDetail(fileIndex, deviceIndex);
    if (detail.isEmpty())
        return slave;

    slave.name       = detail.value(QStringLiteral("name")).toString();
    slave.vendor     = detail.value(QStringLiteral("vendorName")).toString();
    slave.type       = detail.value(QStringLiteral("type")).toString();
    slave.profileNo  = detail.value(QStringLiteral("profileNo")).toString();
    // Copley 等模块化设备：type 显示 Module 名（如 "Cyclic position Mode"）而非 Device 类型名
    const QString moduleName = detail.value(QStringLiteral("moduleName")).toString();
    if (!moduleName.isEmpty())
        slave.type = moduleName;

    auto parsePdos = [](const QVariantList& src) {
        std::vector<SimPdo> pdos;
        for (const QVariant& pv : src) {
            QVariantMap pm = pv.toMap();
            SimPdo pdo;
            pdo.index  = pm.value(QStringLiteral("Index")).toString();
            pdo.name   = pm.value(QStringLiteral("Name")).toString();
            pdo.fixed  = pm.value(QStringLiteral("Fixed")).toString() == QLatin1String("Yes");
            pdo.sm     = pm.value(QStringLiteral("SM")).toString();
            pdo.enabled = false;  // 先全关，applyDefaultPdoSelection 再决定默认开哪个

            // AKD 的 <Exclude>#x1701</Exclude>，勾选互斥用
            const QVariantList exList = pm.value(QStringLiteral("excludes")).toList();
            for (const QVariant& ev : exList)
                pdo.excludes.append(ev.toString());

            const QVariantList entries = pm.value(QStringLiteral("entries")).toList();
            for (const QVariant& ev : entries) {
                QVariantMap em = ev.toMap();
                SimPdoEntry entry;
                entry.index    = em.value(QStringLiteral("Index")).toString();
                entry.name     = em.value(QStringLiteral("Name")).toString();
                entry.dataType = em.value(QStringLiteral("Data Type")).toString();
                entry.subIndex = em.value(QStringLiteral("SubIndex")).toInt();
                entry.bitLen   = em.value(QStringLiteral("Bit Length")).toInt();
                entry.enabled  = true;
                entry.value    = 0;
                pdo.entries.push_back(entry);
            }
            pdos.push_back(pdo);
        }
        return pdos;
    };

    slave.rxPdos = parsePdos(detail.value(QStringLiteral("rxpdos")).toList());
    slave.txPdos = parsePdos(detail.value(QStringLiteral("txpdos")).toList());
    applyDefaultPdoSelection(slave.rxPdos);  // Output 方向（主站→从站）
    applyDefaultPdoSelection(slave.txPdos); // Input  方向（从站→主站）
    slave.rxCount = static_cast<int>(slave.rxPdos.size());
    slave.txCount = static_cast<int>(slave.txPdos.size());
    slave.smCount = slave.rxCount + slave.txCount;
    slave.hasCoe  = detail.value(QStringLiteral("hasCoe")).toBool();
    slave.hasDc   = detail.value(QStringLiteral("hasDc")).toBool();

    return slave;
}

void SimEngine::addSlave(int fileIndex, int deviceIndex, int insertAt)
{
    SimSlave slave = loadSlaveFromEsi(fileIndex, deviceIndex);
    if (slave.name.isEmpty())
        return;

    if (insertAt < 0 || insertAt >= static_cast<int>(m_slaves.size()))
        m_slaves.push_back(std::move(slave));
    else
        m_slaves.insert(m_slaves.begin() + insertAt, std::move(slave));

    recomputeLayout();
    emit slavesChanged();
}

void SimEngine::removeSlave(int chainIndex)
{
    if (chainIndex < 0 || chainIndex >= static_cast<int>(m_slaves.size()))
        return;

    m_slaves.erase(m_slaves.begin() + chainIndex);

    if (m_selectedChainIndex == chainIndex)
        m_selectedChainIndex = -1;
    else if (m_selectedChainIndex > chainIndex)
        --m_selectedChainIndex;

    recomputeLayout();
    emit slavesChanged();
    emit selectedChainIndexChanged();
}

void SimEngine::selectSlave(int chainIndex)
{
    setSelectedChainIndex(chainIndex);
}

int SimEngine::countEnabledBits(const SimSlave& slave, bool isRx) const
{
    int bits = 0;
    const auto& pdos = isRx ? slave.rxPdos : slave.txPdos;
    for (const SimPdo& pdo : pdos) {
        if (!pdo.enabled)
            continue;
        for (const SimPdoEntry& e : pdo.entries) {
            if (e.enabled)
                bits += e.bitLen;
        }
    }
    return bits;
}

void SimEngine::recomputeLayout()
{
    int bitPos = 0;

    for (SimSlave& slave : m_slaves) {
        for (SimPdo& pdo : slave.rxPdos) {
            if (!pdo.enabled)
                continue;
            for (SimPdoEntry& entry : pdo.entries) {
                if (!entry.enabled)
                    continue;
                entry.byteOffset = bitPos / 8;
                entry.bitOffset  = bitPos % 8;
                bitPos += entry.bitLen;
                if (bitPos % 8 != 0)
                    bitPos = ((bitPos + 7) / 8) * 8;
            }
        }
        for (SimPdo& pdo : slave.txPdos) {
            if (!pdo.enabled)
                continue;
            for (SimPdoEntry& entry : pdo.entries) {
                if (!entry.enabled)
                    continue;
                entry.byteOffset = bitPos / 8;
                entry.bitOffset  = bitPos % 8;
                bitPos += entry.bitLen;
                if (bitPos % 8 != 0)
                    bitPos = ((bitPos + 7) / 8) * 8;
            }
        }

        slave.outputBytes = (countEnabledBits(slave, true) + 7) / 8;
        slave.inputBytes  = (countEnabledBits(slave, false) + 7) / 8;
    }

    m_processImage.resize((bitPos + 7) / 8);
    m_processImage.fill(0);

    emit pdoConfigChanged();
}

QVariantMap SimEngine::pdoToVariant(const SimPdo& pdo, bool isRx) const
{
    Q_UNUSED(isRx)
    QVariantMap m;
    m[QStringLiteral("index")]   = pdo.index;
    m[QStringLiteral("name")]    = pdo.name;
    m[QStringLiteral("fixed")]   = pdo.fixed;
    m[QStringLiteral("enabled")] = pdo.enabled;

    QVariantList entries;
    for (const SimPdoEntry& e : pdo.entries) {
        QVariantMap em;
        em[QStringLiteral("index")]      = e.index;
        em[QStringLiteral("name")]       = e.name;
        em[QStringLiteral("dataType")]   = e.dataType;
        em[QStringLiteral("subIndex")]   = e.subIndex;
        em[QStringLiteral("bitLen")]     = e.bitLen;
        em[QStringLiteral("enabled")]    = e.enabled;
        em[QStringLiteral("byteOffset")] = e.byteOffset;
        em[QStringLiteral("bitOffset")]  = e.bitOffset;
        em[QStringLiteral("value")]      = e.value;
        entries.append(em);
    }
    m[QStringLiteral("entries")] = entries;
    return m;
}

QVariantMap SimEngine::slaveToVariant(const SimSlave& s, int chainIndex) const
{
    QVariantMap m;
    m[QStringLiteral("chainIndex")]  = chainIndex;
    m[QStringLiteral("fileIndex")]   = s.fileIndex;
    m[QStringLiteral("deviceIndex")] = s.deviceIndex;
    m[QStringLiteral("name")]        = s.name;
    m[QStringLiteral("vendor")]      = s.vendor;
    m[QStringLiteral("type")]        = s.type;
    m[QStringLiteral("smCount")]     = s.smCount;
    m[QStringLiteral("rxCount")]     = s.rxCount;
    m[QStringLiteral("txCount")]     = s.txCount;
    m[QStringLiteral("hasCoe")]      = s.hasCoe;
    m[QStringLiteral("hasDc")]       = s.hasDc;
    m[QStringLiteral("deviceIndexDisplay")] = s.deviceIndex + 1;
    return m;
}

QVariantMap SimEngine::getSlavePdoConfig(int chainIndex)
{
    QVariantMap result;
    if (chainIndex < 0 || chainIndex >= static_cast<int>(m_slaves.size()))
        return result;

    const SimSlave& slave = m_slaves[static_cast<size_t>(chainIndex)];

    result[QStringLiteral("name")]        = slave.name;
    result[QStringLiteral("vendor")]      = slave.vendor;
    result[QStringLiteral("profileNo")]   = slave.profileNo;
    result[QStringLiteral("outputBytes")] = slave.outputBytes;
    result[QStringLiteral("inputBytes")]  = slave.inputBytes;
    result[QStringLiteral("totalBytes")]  = slave.outputBytes + slave.inputBytes;

    QVariantList rxList;
    for (const SimPdo& p : slave.rxPdos)
        rxList.append(pdoToVariant(p, true));
    result[QStringLiteral("rxpdos")] = rxList;

    QVariantList txList;
    for (const SimPdo& p : slave.txPdos)
        txList.append(pdoToVariant(p, false));
    result[QStringLiteral("txpdos")] = txList;

    return result;
}

void SimEngine::setPdoEnabled(int chainIndex, bool isRx, int pdoIdx, bool on)
{
    if (chainIndex < 0 || chainIndex >= static_cast<int>(m_slaves.size()))
        return;

    SimSlave& slave = m_slaves[static_cast<size_t>(chainIndex)];
    auto& pdos = isRx ? slave.rxPdos : slave.txPdos;
    if (pdoIdx < 0 || pdoIdx >= static_cast<int>(pdos.size()))
        return;

    if (on)
        disableConflictingPdos(pdos, pdoIdx);  // 有 Exclude 则互斥；无 Exclude 则 no-op

    pdos[static_cast<size_t>(pdoIdx)].enabled = on;
    recomputeLayout();
    emit pdoConfigChanged();
}

void SimEngine::setEntryEnabled(int chainIndex, bool isRx, int pdoIdx, int entryIdx, bool on)
{
    if (chainIndex < 0 || chainIndex >= static_cast<int>(m_slaves.size()))
        return;

    SimSlave& slave = m_slaves[static_cast<size_t>(chainIndex)];
    auto& pdos = isRx ? slave.rxPdos : slave.txPdos;
    if (pdoIdx < 0 || pdoIdx >= static_cast<int>(pdos.size()))
        return;

    SimPdo& pdo = pdos[static_cast<size_t>(pdoIdx)];
    if (entryIdx < 0 || entryIdx >= static_cast<int>(pdo.entries.size()))
        return;

    pdo.entries[static_cast<size_t>(entryIdx)].enabled = on;
    recomputeLayout();
    emit pdoConfigChanged();
}

void SimEngine::setEntryValue(int chainIndex, bool isRx, int pdoIdx, int entryIdx, qint64 value)
{
    if (chainIndex < 0 || chainIndex >= static_cast<int>(m_slaves.size()))
        return;

    SimSlave& slave = m_slaves[static_cast<size_t>(chainIndex)];
    auto& pdos = isRx ? slave.rxPdos : slave.txPdos;
    if (pdoIdx < 0 || pdoIdx >= static_cast<int>(pdos.size()))
        return;

    SimPdo& pdo = pdos[static_cast<size_t>(pdoIdx)];
    if (entryIdx < 0 || entryIdx >= static_cast<int>(pdo.entries.size()))
        return;

    pdo.entries[static_cast<size_t>(entryIdx)].value = value;
    emit pdoConfigChanged();
}

void SimEngine::packEntryToImage(QByteArray& image, const SimPdoEntry& entry) const
{
    if (entry.bitLen <= 0 || entry.byteOffset >= image.size())
        return;

    quint64 mask = (entry.bitLen >= 64) ? ~quint64(0)
                                        : ((quint64(1) << entry.bitLen) - 1);
    quint64 val  = static_cast<quint64>(entry.value) & mask;

    for (int b = 0; b < entry.bitLen; ++b) {
        int absBit = entry.byteOffset * 8 + entry.bitOffset + b;
        int byteIdx = absBit / 8;
        int bitIdx  = absBit % 8;
        if (byteIdx >= image.size())
            break;
        if (val & (quint64(1) << b))
            image[byteIdx] = static_cast<char>(image[byteIdx] | (1 << bitIdx));
        else
            image[byteIdx] = static_cast<char>(image[byteIdx] & ~(1 << bitIdx));
    }
}

qint64 SimEngine::readEntryFromImage(const QByteArray& image, const SimPdoEntry& entry) const
{
    if (entry.bitLen <= 0 || entry.byteOffset >= image.size())
        return 0;

    quint64 val = 0;
    for (int b = 0; b < entry.bitLen && b < 64; ++b) {
        int absBit = entry.byteOffset * 8 + entry.bitOffset + b;
        int byteIdx = absBit / 8;
        int bitIdx  = absBit % 8;
        if (byteIdx >= image.size())
            break;
        if (image[byteIdx] & (1 << bitIdx))
            val |= (quint64(1) << b);
    }
    return static_cast<qint64>(val);
}

static bool entryIndexIs(const SimPdoEntry& e, const char* hexIndex)
{
    QString idx = e.index;
    idx.remove(QLatin1Char('#'));
    return idx.compare(QString::fromLatin1(hexIndex), Qt::CaseInsensitive) == 0;
}

void SimEngine::simulateSlaves()
{
    m_processImage.fill(0);

    // Pack Rx (master outputs) into process image
    for (const SimSlave& slave : m_slaves) {
        for (const SimPdo& pdo : slave.rxPdos) {
            if (!pdo.enabled) continue;
            for (const SimPdoEntry& entry : pdo.entries) {
                if (entry.enabled)
                    packEntryToImage(m_processImage, entry);
            }
        }
    }

    // CiA 402 简易模拟 + 读取 Tx 初始值
    for (SimSlave& slave : m_slaves) {
        qint64 targetPos = 0;
        qint64 controlWord = 0;

        for (SimPdo& pdo : slave.rxPdos) {
            if (!pdo.enabled) continue;
            for (SimPdoEntry& entry : pdo.entries) {
                if (!entry.enabled) continue;
                qint64 v = readEntryFromImage(m_processImage, entry);
                entry.value = v;
                if (entryIndexIs(entry, "607A"))
                    targetPos = v;
                if (entryIndexIs(entry, "6040"))
                    controlWord = v;
            }
        }

        if (slave.profileNo == QLatin1String("402")) {
            for (SimPdo& pdo : slave.txPdos) {
                if (!pdo.enabled) continue;
                for (SimPdoEntry& entry : pdo.entries) {
                    if (!entry.enabled) continue;
                    if (entryIndexIs(entry, "6064")) {
                        qint64 cur = entry.value;
                        qint64 delta = targetPos - cur;
                        if (qAbs(delta) > 100)
                            entry.value = cur + delta / 10;
                        else
                            entry.value = targetPos;
                    }
                    if (entryIndexIs(entry, "6041")) {
                        entry.value = (controlWord & 0x000F) ? 0x0237 : 0x0250;
                    }
                }
            }
        }

        for (SimPdo& pdo : slave.txPdos) {
            if (!pdo.enabled) continue;
            for (const SimPdoEntry& entry : pdo.entries) {
                if (entry.enabled)
                    packEntryToImage(m_processImage, entry);
            }
        }
    }
}

void SimEngine::buildLrwFrame()
{
    m_frameFields.clear();

    // Ethernet(14) + EtherCAT header(2) + LRW datagram header(10) + data + WKC(2)
    const int ethLen = 14;
    const int ecHdr  = 2;
    const int dgHdr  = 10;
    const int dataLen = m_processImage.size();
    const int wkcLen = 2;
    const int total = ethLen + ecHdr + dgHdr + dataLen + wkcLen;

    m_lastFrame.resize(total);
    m_lastFrame.fill(0);

    // Dst MAC broadcast
    m_lastFrame[0] = m_lastFrame[1] = m_lastFrame[2] = m_lastFrame[3] = m_lastFrame[4] = m_lastFrame[5] = static_cast<char>(0xFF);
    // Src MAC placeholder
    m_lastFrame[6] = m_lastFrame[7] = m_lastFrame[8] = m_lastFrame[9] = m_lastFrame[10] = m_lastFrame[11] = 0x01;
    // EtherType 0x88A4
    m_lastFrame[12] = static_cast<char>(0x88);
    m_lastFrame[13] = static_cast<char>(0xA4);

    int pos = ethLen;
    // Length
    int ecDataLen = dgHdr + dataLen + wkcLen;
    m_lastFrame[pos++] = static_cast<char>(ecDataLen & 0xFF);
    m_lastFrame[pos++] = static_cast<char>((ecDataLen >> 8) & 0xFF);

    // LRW command 0x0C
    m_lastFrame[pos++] = 0x0C;
    m_lastFrame[pos++] = 0x00; // index
    m_lastFrame[pos++] = 0x00; m_lastFrame[pos++] = 0x00; // address
    m_lastFrame[pos++] = 0x00; m_lastFrame[pos++] = 0x00;
    m_lastFrame[pos++] = static_cast<char>(dataLen & 0xFF);
    m_lastFrame[pos++] = static_cast<char>((dataLen >> 8) & 0xFF);
    m_lastFrame[pos++] = 0x00;
    m_lastFrame[pos++] = 0x00;

    auto addField = [this](int offset, int len, const QString& dir, const QString& name, const QString& desc) {
        QVariantMap f;
        f[QStringLiteral("offset")] = offset;
        f[QStringLiteral("length")] = len;
        f[QStringLiteral("dir")]    = dir;
        f[QStringLiteral("name")]   = name;
        f[QStringLiteral("desc")]   = desc;
        m_frameFields.append(f);
    };

    const int dgStart  = ethLen + ecHdr;
    const int dataStart = dgStart + dgHdr;

    // ── Ethernet II ──────────────────────────────────────────
    addField(0,  6, QStringLiteral("hdr"), QStringLiteral("Dst MAC"),  QStringLiteral("Broadcast FF:FF:FF:FF:FF:FF"));
    addField(6,  6, QStringLiteral("hdr"), QStringLiteral("Src MAC"),  QStringLiteral("Master 01:01:01:01:01:01"));
    addField(12, 2, QStringLiteral("hdr"), QStringLiteral("EtherType"), QStringLiteral("0x88A4 EtherCAT"));

    // ── EtherCAT 长度头 ──────────────────────────────────────
    addField(ethLen, 2, QStringLiteral("hdr"), QStringLiteral("EC Length"),
             QStringLiteral("Datagram+%1 B").arg(ecDataLen));

    // ── LRW Datagram 头（10 字节）────────────────────────────
    addField(dgStart + 0, 1, QStringLiteral("hdr"), QStringLiteral("Command"), QStringLiteral("LRW 0x0C"));
    addField(dgStart + 1, 1, QStringLiteral("hdr"), QStringLiteral("Index"),   QStringLiteral("Datagram index"));
    addField(dgStart + 2, 4, QStringLiteral("hdr"), QStringLiteral("Address"), QStringLiteral("Logical address 0"));
    addField(dgStart + 6, 2, QStringLiteral("hdr"), QStringLiteral("Length"),  QStringLiteral("Data bytes %1").arg(dataLen));
    addField(dgStart + 8, 2, QStringLiteral("hdr"), QStringLiteral("IRQ"),     QStringLiteral("Reserved"));

    // ── 过程数据 ─────────────────────────────────────────────
    if (dataLen > 0) {
        addField(dataStart, dataLen, QStringLiteral("hdr"), QStringLiteral("Process Data"),
                 QStringLiteral("LRW logical memory %1 B").arg(dataLen));

        for (size_t si = 0; si < m_slaves.size(); ++si) {
            const SimSlave& slave = m_slaves[static_cast<size_t>(si)];
            auto annotate = [&](bool isRx) {
                const auto& pdos = isRx ? slave.rxPdos : slave.txPdos;
                const QString dir = isRx ? QStringLiteral("rx") : QStringLiteral("tx");
                for (const SimPdo& pdo : pdos) {
                    if (!pdo.enabled) continue;
                    for (const SimPdoEntry& entry : pdo.entries) {
                        if (!entry.enabled) continue;
                        int byteLen = (entry.bitLen + 7) / 8;
                        int frameOff = dataStart + entry.byteOffset;
                        addField(frameOff, byteLen, dir,
                                 QStringLiteral("S%1 %2").arg(si).arg(entry.name),
                                 QStringLiteral("%1:%2").arg(entry.index).arg(entry.subIndex));
                    }
                }
            };
            annotate(true);
            annotate(false);
        }

        memcpy(m_lastFrame.data() + pos, m_processImage.constData(), static_cast<size_t>(dataLen));
    }
    pos += dataLen;

    // ── Working Counter ──────────────────────────────────────
    int wkc = static_cast<int>(m_slaves.size());
    m_lastFrame[pos++] = static_cast<char>(wkc & 0xFF);
    m_lastFrame[pos++] = static_cast<char>((wkc >> 8) & 0xFF);
    addField(pos - 2, 2, QStringLiteral("hdr"), QStringLiteral("WKC"),
             QStringLiteral("Working Counter = %1").arg(wkc));
}

void SimEngine::stepFrame()
{
    simulateSlaves();
    buildLrwFrame();
    ++m_frameCount;
    emit frameCountChanged();
    emit lastFrameChanged();
    emit pdoConfigChanged();
}

void SimEngine::runSimulation()
{
    if (m_running)
        return;
    m_running = true;
    m_runTimer.start();
    emit runningChanged();
}

void SimEngine::pauseSimulation()
{
    if (!m_running)
        return;
    m_running = false;
    m_runTimer.stop();
    emit runningChanged();
}

void SimEngine::resetSimulation()
{
    pauseSimulation();
    m_frameCount = 0;
    m_lastFrame.clear();
    m_frameFields.clear();
    m_processImage.clear();
    emit frameCountChanged();
    emit lastFrameChanged();
}

QVariantList SimEngine::getLastFrameBytes() const
{
    QVariantList list;
    list.reserve(m_lastFrame.size());
    for (char c : m_lastFrame)
        list.append(static_cast<int>(static_cast<uchar>(c)));
    return list;
}
