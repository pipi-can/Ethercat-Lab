#include "networkmanager.h"

#include <QTcpServer>
#include <QTcpSocket>
#include <QHostAddress>
#include <QDateTime>
#include <QtGlobal>

namespace {

quint32 readBe32(const char* p)
{
    const auto* u = reinterpret_cast<const uchar*>(p);
    return (quint32(u[0]) << 24) | (quint32(u[1]) << 16) | (quint32(u[2]) << 8) | quint32(u[3]);
}

quint64 readBe64(const char* p)
{
    return (quint64(readBe32(p)) << 32) | readBe32(p + 4);
}

QString formatHex(quint64 val, int bitLen)
{
    const int hexWidth = qMax(2, (bitLen + 3) / 4);
    return QStringLiteral("0x") + QString::number(val, 16).toUpper().rightJustified(hexWidth, QLatin1Char('0'));
}

} // namespace

NetworkManager& NetworkManager::getInstance()
{
    static NetworkManager instance;
    return instance;
}

NetworkManager::NetworkManager(QObject* parent)
    : QObject(parent)
{
}

NetworkManager::~NetworkManager()
{
    disconnect();
}

QString NetworkManager::clientState() const { return m_clientState; }
QString NetworkManager::bridgeState() const { return m_bridgeState; }
bool NetworkManager::receiving() const { return m_receiving; }
quint64 NetworkManager::seq() const { return m_seq; }
qint64 NetworkManager::delta() const { return m_delta; }
double NetworkManager::hz() const { return m_hz; }
int NetworkManager::frameCount() const { return m_frameCount; }
QString NetworkManager::checkStatus() const { return m_checkStatus; }
QVariantMap NetworkManager::liveValues() const { return m_liveValues; }
int NetworkManager::liveRevision() const { return m_liveRevision; }
QVariantList NetworkManager::logModel() const { return m_logModel; }

void NetworkManager::setClientState(const QString& state)
{
    if (m_clientState == state)
        return;
    m_clientState = state;
    emit clientStateChanged();
}

void NetworkManager::setBridgeState(const QString& state)
{
    if (m_bridgeState == state)
        return;
    m_bridgeState = state;
    emit bridgeStateChanged();
}

void NetworkManager::setReceiving(bool on)
{
    if (m_receiving == on)
        return;
    m_receiving = on;
    emit receivingChanged();
}

void NetworkManager::appendLog(const QString& text, const QString& level)
{
    QVariantMap line;
    line.insert(QStringLiteral("time"), QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss")));
    line.insert(QStringLiteral("text"), text);
    line.insert(QStringLiteral("level"), level);
    m_logModel.append(line);
    emit logChanged();
}

void NetworkManager::resetMetrics()
{
    m_seq = 0;
    m_lastSeq = 0;
    m_delta = 0;
    m_hz = 0.0;
    m_frameCount = 0;
    m_checkStatus = QStringLiteral("—");
    m_lastFrameMs = 0;
    emit metricsChanged();
}

void NetworkManager::closeSocket()
{
    if (!m_socket)
        return;
    m_socket->disconnect(this);
    if (m_socket->state() != QAbstractSocket::UnconnectedState)
        m_socket->disconnectFromHost();
    m_socket->deleteLater();
    m_socket = nullptr;
    m_rxBuffer.clear();
}

void NetworkManager::stopServer()
{
    if (!m_server)
        return;
    m_server->close();
    m_server->deleteLater();
    m_server = nullptr;
}

bool NetworkManager::peerMatchesBridge(const QHostAddress& peer) const
{
    if (m_bridgeIp.isEmpty() || m_bridgeIp == QStringLiteral("0.0.0.0"))
        return true;

    const QHostAddress expected(m_bridgeIp);
    if (expected.isNull())
        return false;
    if (peer == expected)
        return true;

    const quint32 peer4 = peer.toIPv4Address();
    const quint32 expect4 = expected.toIPv4Address();
    return peer4 != 0 && expect4 != 0 && peer4 == expect4;
}

bool NetworkManager::startListen(const QString& listenIp, quint16 port, const QString& bridgeIp)
{
    if (m_clientState != QStringLiteral("idle")) {
        appendLog(QStringLiteral("当前非空闲状态，请先断开"), QStringLiteral("warn"));
        return false;
    }
    if (port == 0) {
        appendLog(QStringLiteral("端口无效"), QStringLiteral("err"));
        return false;
    }

    m_bridgeIp = bridgeIp.trimmed();
    if (!m_bridgeIp.isEmpty() && m_bridgeIp != QStringLiteral("0.0.0.0")) {
        const QHostAddress bridgeAddr(m_bridgeIp);
        if (bridgeAddr.isNull() || bridgeAddr.protocol() != QAbstractSocket::IPv4Protocol) {
            appendLog(QStringLiteral("桥接器 IP 无效: ") + m_bridgeIp, QStringLiteral("err"));
            return false;
        }
        m_bridgeIp = bridgeAddr.toString();
    }

    stopServer();
    m_server = new QTcpServer(this);
    connect(m_server, &QTcpServer::newConnection, this, [this]() {
        QTcpSocket* pending = m_server->nextPendingConnection();
        if (!pending)
            return;

        const QHostAddress peer = pending->peerAddress();

        if (m_socket) {
            pending->disconnectFromHost();
            pending->deleteLater();
            appendLog(QStringLiteral("已有连接，拒绝新连接"), QStringLiteral("warn"));
            return;
        }

        if (!peerMatchesBridge(peer)) {
            appendLog(QStringLiteral("桥接层 IP 不匹配: 期望 %1，实际 %2")
                          .arg(m_bridgeIp, peer.toString()),
                      QStringLiteral("err"));
            pending->disconnectFromHost();
            pending->deleteLater();
            return;
        }

        m_socket = pending;
        connect(m_socket, &QTcpSocket::readyRead, this, &NetworkManager::onSocketReadyRead);
        connect(m_socket, &QTcpSocket::disconnected, this, [this]() {
            appendLog(QStringLiteral("桥接层 TCP 断开"), QStringLiteral("warn"));
            if (m_receiving)
                stopReceive();
            closeSocket();
            setBridgeState(QStringLiteral("disconnected"));
            if (m_clientState != QStringLiteral("idle"))
                setClientState(QStringLiteral("listening"));
        });
        m_rxBuffer.clear();
        setBridgeState(QStringLiteral("connected"));
        setClientState(QStringLiteral("connected"));
        appendLog(QStringLiteral("桥接层 TCP 连接成功 (%1)").arg(peer.toString()),
                  QStringLiteral("ok"));
    });

    QHostAddress addr = listenIp.isEmpty() || listenIp == QStringLiteral("0.0.0.0")
                            ? QHostAddress::AnyIPv4
                            : QHostAddress(listenIp);
    if (!m_server->listen(addr, port)) {    // 设置监听IP和端口
        appendLog(QStringLiteral("监听失败: ") + m_server->errorString(), QStringLiteral("err"));
        stopServer();
        return false;
    }

    resetMetrics();
    setBridgeState(QStringLiteral("disconnected"));
    setClientState(QStringLiteral("listening"));
    if (m_bridgeIp.isEmpty() || m_bridgeIp == QStringLiteral("0.0.0.0"))
        appendLog(QStringLiteral("客户端开始监听 %1:%2，未限定桥接器 IP")
                      .arg(listenIp.isEmpty() ? QStringLiteral("0.0.0.0") : listenIp)
                      .arg(port),
                  QStringLiteral("info"));
    else
        appendLog(QStringLiteral("客户端开始监听 %1:%2，仅接受桥接器 %3")
                      .arg(listenIp.isEmpty() ? QStringLiteral("0.0.0.0") : listenIp)
                      .arg(port)
                      .arg(m_bridgeIp),
                  QStringLiteral("info"));
    return true;
}

void NetworkManager::buildDecodePlan(const QVariantMap& config)
{
    m_slots.clear();
    m_expect.obytes = config.value(QStringLiteral("Obytes")).toInt();
    m_expect.ibytes = config.value(QStringLiteral("Ibytes")).toInt();
    m_expect.total = config.value(QStringLiteral("total")).toInt();

    const QVariantList slaves = config.value(QStringLiteral("slaves")).toList();
    for (const QVariant& sv : slaves) {
        const QVariantMap slave = sv.toMap();
        const QString id = slave.value(QStringLiteral("id")).toString();
        const QString type = slave.value(QStringLiteral("type")).toString();

        if (type == QStringLiteral("io")) {
            const int outN = slave.value(QStringLiteral("outBytes")).toInt();
            const int inN = slave.value(QStringLiteral("inBytes")).toInt();
            const int outOff = slave.value(QStringLiteral("_outByteOff")).toInt();
            const int inOff = slave.value(QStringLiteral("_inByteOff")).toInt();
            for (int b = 0; b < outN; ++b) {
                DecodeSlot slot;
                slot.key = id + QStringLiteral("_out_") + QString::number(b);
                slot.byteOff = outOff + b;
                slot.bitLen = 8;
                slot.dataType = QStringLiteral("UINT8");
                m_slots.push_back(slot);
            }
            for (int b = 0; b < inN; ++b) {
                DecodeSlot slot;
                slot.key = id + QStringLiteral("_in_") + QString::number(b);
                slot.byteOff = inOff + b;
                slot.bitLen = 8;
                slot.dataType = QStringLiteral("UINT8");
                m_slots.push_back(slot);
            }
        } else {
            const QVariantList rx = slave.value(QStringLiteral("rxEntries")).toList();
            for (int i = 0; i < rx.size(); ++i) {
                const QVariantMap e = rx.at(i).toMap();
                DecodeSlot slot;
                slot.key = id + QStringLiteral("_rx_") + QString::number(i);
                slot.index = e.value(QStringLiteral("index")).toString();
                slot.subIndex = e.value(QStringLiteral("subIndex")).toString();
                if (slot.subIndex.isEmpty())
                    slot.subIndex = QStringLiteral("0x00");
                slot.byteOff = e.value(QStringLiteral("byteOff")).toInt();
                slot.bitLen = e.value(QStringLiteral("bitLen")).toInt();
                slot.dataType = e.value(QStringLiteral("dataType")).toString();
                m_slots.push_back(slot);
            }
            const QVariantList tx = slave.value(QStringLiteral("txEntries")).toList();
            for (int i = 0; i < tx.size(); ++i) {
                const QVariantMap e = tx.at(i).toMap();
                DecodeSlot slot;
                slot.key = id + QStringLiteral("_tx_") + QString::number(i);
                slot.index = e.value(QStringLiteral("index")).toString();
                slot.subIndex = e.value(QStringLiteral("subIndex")).toString();
                if (slot.subIndex.isEmpty())
                    slot.subIndex = QStringLiteral("0x00");
                slot.byteOff = e.value(QStringLiteral("byteOff")).toInt();
                slot.bitLen = e.value(QStringLiteral("bitLen")).toInt();
                slot.dataType = e.value(QStringLiteral("dataType")).toString();
                m_slots.push_back(slot);
            }
        }
    }
}

bool NetworkManager::startReceive(const QVariantMap& config)
{
    if (!m_socket || m_socket->state() != QAbstractSocket::ConnectedState) {
        appendLog(QStringLiteral("尚未建立 TCP 连接，无法开始接收"), QStringLiteral("warn"));
        return false;
    }

    buildDecodePlan(config);
    if (m_expect.total <= 0) {
        appendLog(QStringLiteral("从站配置为空或 total=0"), QStringLiteral("warn"));
        return false;
    }

    const QByteArray handshake(1, '\x01');
    const qint64 sent = m_socket->write(handshake);
    if (sent != 1) {
        appendLog(QStringLiteral("发送握手字节失败"), QStringLiteral("err"));
        return false;
    }
    m_socket->flush();

    m_frameCount = 0;
    m_lastSeq = 0;
    m_lastFrameMs = 0;
    m_checkStatus = QStringLiteral("—");
    m_liveValues.clear();
    ++m_liveRevision;

    setClientState(QStringLiteral("handshaked"));
    setBridgeState(QStringLiteral("streaming"));
    setReceiving(true);

    appendLog(QStringLiteral("客户端发送握手字节 0x01"), QStringLiteral("info"));
    appendLog(QStringLiteral("开始接收，期望 Obytes=%1 Ibytes=%2 total=%3")
                  .arg(m_expect.obytes)
                  .arg(m_expect.ibytes)
                  .arg(m_expect.total),
              QStringLiteral("ok"));

    emit metricsChanged();
    emit liveDataChanged();
    return true;
}

void NetworkManager::stopReceive()
{
    if (!m_receiving)
        return;

    setReceiving(false);
    if (m_bridgeState == QStringLiteral("streaming"))
        setBridgeState(QStringLiteral("handshaked"));
    if (m_clientState == QStringLiteral("handshaked") || m_clientState == QStringLiteral("connected"))
        setClientState(QStringLiteral("handshaked"));

    m_liveValues.clear();
    ++m_liveRevision;
    emit liveDataChanged();
    appendLog(QStringLiteral("已停止接收（连接保持）"), QStringLiteral("warn"));
}

void NetworkManager::disconnect()
{
    if (m_receiving)
        stopReceive();

    closeSocket();
    stopServer();
    resetMetrics();
    m_liveValues.clear();
    ++m_liveRevision;
    m_slots.clear();
    m_expect = {};
    m_bridgeIp.clear();

    setClientState(QStringLiteral("idle"));
    setBridgeState(QStringLiteral("disconnected"));
    emit liveDataChanged();
    appendLog(QStringLiteral("连接已断开"), QStringLiteral("warn"));
}

void NetworkManager::clearLog()
{
    m_logModel.clear();
    emit logChanged();
}

void NetworkManager::injectNextFrameError()
{
    appendLog(QStringLiteral("注入错误帧需桥接层配合发送错误 Obytes（当前仅记录）"), QStringLiteral("warn"));
}

bool NetworkManager::parseHeader(const QByteArray& buf, IomapFrameHdr& hdr) const
{
    if (buf.size() < kHdrSize)
        return false;
    const char* p = buf.constData();
    hdr.magic = readBe32(p);
    hdr.version = readBe32(p + 4);
    hdr.seq = readBe64(p + 8);
    hdr.totalSize = readBe32(p + 16);
    hdr.obytes = readBe32(p + 20);
    hdr.ibytes = readBe32(p + 24);
    hdr.layout = readBe32(p + 28);
    hdr.frontIdx = readBe32(p + 32);
    hdr.hostTsNs = readBe64(p + 36);
    return true;
}

QString NetworkManager::validateFrame(const IomapFrameHdr& hdr, int payloadLen) const
{
    if (hdr.magic != kMagic)
        return QStringLiteral("magic 无效，期望 0x494F4D54");
    if (hdr.version != kVersion)
        return QStringLiteral("version 无效，期望 1");
    if (hdr.totalSize != hdr.obytes + hdr.ibytes)
        return QStringLiteral("total_size 不一致: %1 != %2+%3")
            .arg(hdr.totalSize)
            .arg(hdr.obytes)
            .arg(hdr.ibytes);
    if (payloadLen != static_cast<int>(hdr.totalSize))
        return QStringLiteral("payload 长度 %1 != total_size %2").arg(payloadLen).arg(hdr.totalSize);

    if (static_cast<int>(hdr.obytes) != m_expect.obytes)
        return QStringLiteral("Obytes 不匹配: 帧=%1 配置=%2").arg(hdr.obytes).arg(m_expect.obytes);
    if (static_cast<int>(hdr.ibytes) != m_expect.ibytes)
        return QStringLiteral("Ibytes 不匹配: 帧=%1 配置=%2").arg(hdr.ibytes).arg(m_expect.ibytes);
    if (m_expect.total <= 0)
        return QStringLiteral("本地从站配置为空");
    return {};
}

QVariantMap NetworkManager::readValue(const QByteArray& payload, int byteOff,
                                      int bitLen, const QString& dataType)
{
    quint64 val = 0;
    const int bytes = (bitLen + 7) / 8;
    for (int i = 0; i < bytes && byteOff + i < payload.size(); ++i)
        val |= static_cast<quint64>(static_cast<quint8>(payload.at(byteOff + i))) << (i * 8);

    const int bits = bitLen > 0 ? bitLen : 8;
    if (bits < 64)
        val &= ((quint64(1) << bits) - 1);

    qint64 dec = static_cast<qint64>(val);
    if (dataType.startsWith(QLatin1String("INT")) && bits > 0 && bits < 64) {
        const quint64 signBit = quint64(1) << (bits - 1);
        if (val & signBit)
            dec -= qint64(1) << bits;
    }

    QVariantMap out;
    out.insert(QStringLiteral("hex"), formatHex(val, bits));
    out.insert(QStringLiteral("dec"), dec);
    out.insert(QStringLiteral("bitLen"), bits);
    return out;
}

QVariantMap NetworkManager::decodePayload(const QByteArray& payload) const
{
    QVariantMap live;
    for (const DecodeSlot& slot : m_slots)
        live.insert(slot.key, readValue(payload, slot.byteOff, slot.bitLen, slot.dataType));
    return live;
}

void NetworkManager::processFrame(const IomapFrameHdr& hdr, const QByteArray& payload)
{
    m_seq = hdr.seq;
    m_delta = m_lastSeq ? static_cast<qint64>(hdr.seq - m_lastSeq) : 0;
    m_lastSeq = hdr.seq;
    ++m_frameCount;

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    if (m_lastFrameMs > 0) {
        const double dt = (nowMs - m_lastFrameMs) / 1000.0;
        if (dt > 0) {
            const double inst = 1.0 / dt;
            m_hz = m_hz > 0 ? m_hz * 0.9 + inst * 0.1 : inst;
        }
    }
    m_lastFrameMs = nowMs;

    const QString err = validateFrame(hdr, payload.size());
    if (!err.isEmpty()) {
        m_checkStatus = QStringLiteral("失败");
        appendLog(QStringLiteral("校验失败: ") + err, QStringLiteral("err"));
        emit metricsChanged();
        emit frameValidationFailed(err);
        stopReceive();
        return;
    }

    m_checkStatus = QStringLiteral("通过");
    m_liveValues = decodePayload(payload);
    ++m_liveRevision;
    emit metricsChanged();
    emit liveDataChanged();

    if (m_frameCount % 30 == 0)
        appendLog(QStringLiteral("seq=%1 O+I=%2+%3 front=%4")
                      .arg(hdr.seq)
                      .arg(hdr.obytes)
                      .arg(hdr.ibytes)
                      .arg(hdr.frontIdx),
                  QStringLiteral("frame"));
}

void NetworkManager::onSocketReadyRead()
{
    if (!m_socket)
        return;

    m_rxBuffer.append(m_socket->readAll());

    while (m_rxBuffer.size() >= kHdrSize) {
        IomapFrameHdr hdr;
        if (!parseHeader(m_rxBuffer, hdr))
            break;

        const int frameSize = kHdrSize + static_cast<int>(hdr.totalSize);
        if (m_rxBuffer.size() < frameSize)
            break;

        const QByteArray payload = m_rxBuffer.mid(kHdrSize, static_cast<int>(hdr.totalSize));
        m_rxBuffer.remove(0, frameSize);

        if (m_receiving)
            processFrame(hdr, payload);
    }
}
