#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QByteArray>
#include <QString>
#include <vector>

class QHostAddress;

class QTcpServer;
class QTcpSocket;

struct IomapFrameHdr {
    quint32 magic = 0;
    quint32 version = 0;
    quint64 seq = 0;
    quint32 totalSize = 0;
    quint32 obytes = 0;
    quint32 ibytes = 0;
    quint32 layout = 0;
    quint32 frontIdx = 0;
    quint64 hostTsNs = 0;
};

struct DecodeSlot {
    QString key;
    QString index;
    QString subIndex;
    int byteOff = 0;
    int bitLen = 8;
    QString dataType;
};

struct LayoutExpect {
    int obytes = 0;
    int ibytes = 0;
    int total = 0;
};

/**
 * @brief: IOMap TCP 接收、IOMT 帧解析与按用户配置解码。
 */
class NetworkManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString clientState READ clientState NOTIFY clientStateChanged)
    Q_PROPERTY(QString bridgeState READ bridgeState NOTIFY bridgeStateChanged)
    Q_PROPERTY(bool receiving READ receiving NOTIFY receivingChanged)
    Q_PROPERTY(quint64 seq READ seq NOTIFY metricsChanged)
    Q_PROPERTY(qint64 delta READ delta NOTIFY metricsChanged)
    Q_PROPERTY(double hz READ hz NOTIFY metricsChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY metricsChanged)
    Q_PROPERTY(QString checkStatus READ checkStatus NOTIFY metricsChanged)
    Q_PROPERTY(QVariantMap liveValues READ liveValues NOTIFY liveDataChanged)
    Q_PROPERTY(int liveRevision READ liveRevision NOTIFY liveDataChanged)
    Q_PROPERTY(QVariantList logModel READ logModel NOTIFY logChanged)

public:
    static NetworkManager& getInstance();

    NetworkManager(const NetworkManager& other) = delete;
    void operator=(const NetworkManager& other) = delete;

    QString clientState() const;
    QString bridgeState() const;
    bool receiving() const;
    quint64 seq() const;
    qint64 delta() const;
    double hz() const;
    int frameCount() const;
    QString checkStatus() const;
    QVariantMap liveValues() const;
    int liveRevision() const;
    QVariantList logModel() const;

    Q_INVOKABLE bool startListen(const QString& listenIp, quint16 port, const QString& bridgeIp);
    Q_INVOKABLE bool startReceive(const QVariantMap& config);
    Q_INVOKABLE void stopReceive();
    Q_INVOKABLE void disconnect();
    Q_INVOKABLE void clearLog();
    Q_INVOKABLE void injectNextFrameError();

signals:
    void clientStateChanged();
    void bridgeStateChanged();
    void receivingChanged();
    void metricsChanged();
    void liveDataChanged();
    void logChanged();
    void frameValidationFailed(const QString& reason);

private:
    explicit NetworkManager(QObject* parent = nullptr);
    ~NetworkManager() override;

    void setClientState(const QString& state);
    void setBridgeState(const QString& state);
    void setReceiving(bool on);
    void appendLog(const QString& text, const QString& level);
    void resetMetrics();
    void closeSocket();
    void stopServer();
    bool peerMatchesBridge(const QHostAddress& peer) const;

    bool parseHeader(const QByteArray& buf, IomapFrameHdr& hdr) const;
    QString validateFrame(const IomapFrameHdr& hdr, int payloadLen) const;
    void onSocketReadyRead();
    void processFrame(const IomapFrameHdr& hdr, const QByteArray& payload);
    void buildDecodePlan(const QVariantMap& config);
    QVariantMap decodePayload(const QByteArray& payload) const;
    static QVariantMap readValue(const QByteArray& payload, int byteOff,
                                 int bitLen, const QString& dataType);

    static constexpr int kHdrSize = 44;
    static constexpr quint32 kMagic = 0x494F4D54u;
    static constexpr quint32 kVersion = 1u;

    QTcpServer* m_server = nullptr;
    QTcpSocket* m_socket = nullptr;
    QByteArray m_rxBuffer;
    QString m_bridgeIp;

    QString m_clientState = QStringLiteral("idle");
    QString m_bridgeState = QStringLiteral("disconnected");
    bool m_receiving = false;

    LayoutExpect m_expect;
    std::vector<DecodeSlot> m_slots;

    quint64 m_seq = 0;
    quint64 m_lastSeq = 0;
    qint64 m_delta = 0;
    double m_hz = 0.0;
    int m_frameCount = 0;
    QString m_checkStatus = QStringLiteral("—");
    qint64 m_lastFrameMs = 0;

    QVariantMap m_liveValues;
    int m_liveRevision = 0;
    QVariantList m_logModel;
};

#endif // NETWORKMANAGER_H
