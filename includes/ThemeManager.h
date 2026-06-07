#ifndef THEMEMANAGER_H
#define THEMEMANAGER_H

#include <QObject>
#include <QMap>

class QMutex;

// ── Abstract theme interface ──────────────────────────────────────────
class Theme {
public:
    explicit Theme() {}
    virtual ~Theme() {}

    virtual QString type() = 0;
};

// ── Concrete themes ───────────────────────────────────────────────────
class DarkTheme : public Theme {
public:
    explicit DarkTheme() {}
    QString type() override;
};

class LightTheme : public Theme {
public:
    explicit LightTheme() {}
    QString type() override;
};

// ── ThemeManager singleton ────────────────────────────────────────────
class ThemeManager : public QObject
{
    Q_OBJECT

public:
    static ThemeManager* instance();

    Q_INVOKABLE void setCurrentTheme(const QString& name);
    Q_INVOKABLE QString themeType();

signals:
    void currentThemeChanged(const QString& newTheme);

private:
    explicit ThemeManager(QObject* parent = nullptr);
    ~ThemeManager() override;

    QMap<QString, Theme*> mThemeMap;
    Theme* mCurrentTheme = nullptr;

    static ThemeManager* mInstance;
    static QMutex        mMutex;
};

#endif // THEMEMANAGER_H
