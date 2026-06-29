#ifndef SIMENGINE_H
#define SIMENGINE_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QByteArray>
#include <QStringList>
#include <vector>

struct SimPdoEntry {
    bool enabled = true;
    int  subIndex = 0;
    int  bitLen = 0;
    int  byteOffset = 0;
    int  bitOffset = 0;
    QString index;
    QString name;
    QString dataType;
    qint64  value = 0;   // 运行时模拟值
};

struct SimPdo {
    bool enabled = false;
    bool fixed = false;       // ESI Fixed="1"：厂商预定义映射，Entry 不可改
    QString index;            // 如 #x1701
    QString name;             // 如 "Outputs" / "Cyclic position Outputs"
    QString sm;               // ESI Sm="2"：默认分配到哪个 Sync Manager
    QStringList excludes;     // ESI <Exclude>：与这些 PDO 索引互斥（AKD 有，Copley 无）
    std::vector<SimPdoEntry> entries;
};

struct SimSlave {
    int fileIndex = -1;
    int deviceIndex = -1;
    QString name;
    QString vendor;
    QString type;
    int smCount = 0;
    int rxCount = 0;
    int txCount = 0;
    bool hasCoe = false;
    bool hasDc = false;
    QString profileNo;
    std::vector<SimPdo> rxPdos;
    std::vector<SimPdo> txPdos;
    int outputBytes = 0;  // 本从站 Rx 启用 entry 总字节
    int inputBytes = 0;   // 本从站 Tx 启用 entry 总字节
};

class SimEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int slaveCount READ slaveCount NOTIFY slavesChanged)
    Q_PROPERTY(int selectedChainIndex READ selectedChainIndex WRITE setSelectedChainIndex NOTIFY selectedChainIndexChanged)
    Q_PROPERTY(QVariantList slaves READ slaves NOTIFY slavesChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY frameCountChanged)
    Q_PROPERTY(QByteArray lastFrame READ lastFrame NOTIFY lastFrameChanged)
    Q_PROPERTY(QVariantList frameFields READ frameFields NOTIFY lastFrameChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    static SimEngine& getInstance();

    SimEngine(const SimEngine& other) = delete;
    void operator=(const SimEngine& other) = delete;

    int slaveCount() const;
    int selectedChainIndex() const;
    void setSelectedChainIndex(int index);
    QVariantList slaves() const;
    int frameCount() const;
    QByteArray lastFrame() const;
    QVariantList frameFields() const;
    bool running() const;

    Q_INVOKABLE void addSlave(int fileIndex, int deviceIndex, int insertAt = -1);
    Q_INVOKABLE void removeSlave(int chainIndex);
    Q_INVOKABLE void selectSlave(int chainIndex);
    Q_INVOKABLE QVariantMap getSlavePdoConfig(int chainIndex);
    Q_INVOKABLE void setPdoEnabled(int chainIndex, bool isRx, int pdoIdx, bool on);
    Q_INVOKABLE void setEntryEnabled(int chainIndex, bool isRx, int pdoIdx, int entryIdx, bool on);
    Q_INVOKABLE void setEntryValue(int chainIndex, bool isRx, int pdoIdx, int entryIdx, qint64 value);
    Q_INVOKABLE void stepFrame();
    Q_INVOKABLE void runSimulation();
    Q_INVOKABLE void pauseSimulation();
    Q_INVOKABLE void resetSimulation();
    Q_INVOKABLE QVariantList getLastFrameBytes() const;

signals:
    void slavesChanged();
    void selectedChainIndexChanged();
    void pdoConfigChanged();
    void frameCountChanged();
    void lastFrameChanged();
    void runningChanged();

private:
    explicit SimEngine(QObject* parent = nullptr);
    ~SimEngine() = default;

    SimSlave loadSlaveFromEsi(int fileIndex, int deviceIndex);
    void applyDefaultPdoSelection(std::vector<SimPdo>& pdos);
    void disableConflictingPdos(std::vector<SimPdo>& pdos, int enabledIdx);
    static bool pdoIndicesConflict(const SimPdo& a, const SimPdo& b);
    void recomputeLayout();
    void simulateSlaves();
    void buildLrwFrame();
    void packEntryToImage(QByteArray& image, const SimPdoEntry& entry) const;
    qint64 readEntryFromImage(const QByteArray& image, const SimPdoEntry& entry) const;
    QVariantMap pdoToVariant(const SimPdo& pdo, bool isRx) const;
    QVariantMap slaveToVariant(const SimSlave& s, int chainIndex) const;
    int countEnabledBits(const SimSlave& slave, bool isRx) const;

    std::vector<SimSlave> m_slaves;
    int m_selectedChainIndex = -1;
    QByteArray m_processImage;
    QByteArray m_lastFrame;
    QVariantList m_frameFields;
    int m_frameCount = 0;
    bool m_running = false;
    QTimer m_runTimer;
};

#endif // SIMENGINE_H
