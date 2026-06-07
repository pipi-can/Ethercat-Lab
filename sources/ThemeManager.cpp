#include "ThemeManager.h"
#include <QMutex>
#include <QMutexLocker>

// ── DarkTheme ─────────────────────────────────────────────────────────
QString DarkTheme::type() { return "Dark"; }

// ── LightTheme ────────────────────────────────────────────────────────
QString LightTheme::type() { return "Light"; }

// ── ThemeManager singleton ────────────────────────────────────────────

ThemeManager* ThemeManager::mInstance = nullptr;
QMutex        ThemeManager::mMutex;

ThemeManager* ThemeManager::instance()
{
    if (!mInstance) {
        QMutexLocker locker(&mMutex);
        if (!mInstance) {
            mInstance = new ThemeManager();
        }
    }
    return mInstance;
}

ThemeManager::ThemeManager(QObject* parent)
    : QObject(parent)
{
    mThemeMap.insert("Dark",  new DarkTheme());
    mThemeMap.insert("Light", new LightTheme());
    mCurrentTheme = mThemeMap.value("Dark");
}

ThemeManager::~ThemeManager()
{
    qDeleteAll(mThemeMap);
    mThemeMap.clear();
}

void ThemeManager::setCurrentTheme(const QString& name)
{
    Theme* t = mThemeMap.value(name, nullptr);
    if (!t || t == mCurrentTheme)
        return;
    mCurrentTheme = t;
    emit currentThemeChanged(name);
}

QString ThemeManager::themeType()
{
    return mCurrentTheme ? mCurrentTheme->type() : QString();
}
