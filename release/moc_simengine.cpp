/****************************************************************************
** Meta object code from reading C++ file 'simengine.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../interfaces/simengine.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'simengine.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN9SimEngineE_t {};
} // unnamed namespace

template <> constexpr inline auto SimEngine::qt_create_metaobjectdata<qt_meta_tag_ZN9SimEngineE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "SimEngine",
        "slavesChanged",
        "",
        "selectedChainIndexChanged",
        "pdoConfigChanged",
        "frameCountChanged",
        "lastFrameChanged",
        "runningChanged",
        "addSlave",
        "fileIndex",
        "deviceIndex",
        "insertAt",
        "removeSlave",
        "chainIndex",
        "selectSlave",
        "getSlavePdoConfig",
        "QVariantMap",
        "setPdoEnabled",
        "isRx",
        "pdoIdx",
        "on",
        "setEntryEnabled",
        "entryIdx",
        "setEntryValue",
        "value",
        "stepFrame",
        "runSimulation",
        "pauseSimulation",
        "resetSimulation",
        "getLastFrameBytes",
        "QVariantList",
        "slaveCount",
        "selectedChainIndex",
        "slaves",
        "frameCount",
        "lastFrame",
        "frameFields",
        "running"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'slavesChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'selectedChainIndexChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pdoConfigChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'frameCountChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'lastFrameChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'runningChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addSlave'
        QtMocHelpers::MethodData<void(int, int, int)>(8, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 9 }, { QMetaType::Int, 10 }, { QMetaType::Int, 11 },
        }}),
        // Method 'addSlave'
        QtMocHelpers::MethodData<void(int, int)>(8, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::Int, 9 }, { QMetaType::Int, 10 },
        }}),
        // Method 'removeSlave'
        QtMocHelpers::MethodData<void(int)>(12, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 13 },
        }}),
        // Method 'selectSlave'
        QtMocHelpers::MethodData<void(int)>(14, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 13 },
        }}),
        // Method 'getSlavePdoConfig'
        QtMocHelpers::MethodData<QVariantMap(int)>(15, 2, QMC::AccessPublic, 0x80000000 | 16, {{
            { QMetaType::Int, 13 },
        }}),
        // Method 'setPdoEnabled'
        QtMocHelpers::MethodData<void(int, bool, int, bool)>(17, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 13 }, { QMetaType::Bool, 18 }, { QMetaType::Int, 19 }, { QMetaType::Bool, 20 },
        }}),
        // Method 'setEntryEnabled'
        QtMocHelpers::MethodData<void(int, bool, int, int, bool)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 13 }, { QMetaType::Bool, 18 }, { QMetaType::Int, 19 }, { QMetaType::Int, 22 },
            { QMetaType::Bool, 20 },
        }}),
        // Method 'setEntryValue'
        QtMocHelpers::MethodData<void(int, bool, int, int, qint64)>(23, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 13 }, { QMetaType::Bool, 18 }, { QMetaType::Int, 19 }, { QMetaType::Int, 22 },
            { QMetaType::LongLong, 24 },
        }}),
        // Method 'stepFrame'
        QtMocHelpers::MethodData<void()>(25, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'runSimulation'
        QtMocHelpers::MethodData<void()>(26, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'pauseSimulation'
        QtMocHelpers::MethodData<void()>(27, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'resetSimulation'
        QtMocHelpers::MethodData<void()>(28, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getLastFrameBytes'
        QtMocHelpers::MethodData<QVariantList() const>(29, 2, QMC::AccessPublic, 0x80000000 | 30),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'slaveCount'
        QtMocHelpers::PropertyData<int>(31, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'selectedChainIndex'
        QtMocHelpers::PropertyData<int>(32, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'slaves'
        QtMocHelpers::PropertyData<QVariantList>(33, 0x80000000 | 30, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 0),
        // property 'frameCount'
        QtMocHelpers::PropertyData<int>(34, QMetaType::Int, QMC::DefaultPropertyFlags, 3),
        // property 'lastFrame'
        QtMocHelpers::PropertyData<QByteArray>(35, QMetaType::QByteArray, QMC::DefaultPropertyFlags, 4),
        // property 'frameFields'
        QtMocHelpers::PropertyData<QVariantList>(36, 0x80000000 | 30, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 4),
        // property 'running'
        QtMocHelpers::PropertyData<bool>(37, QMetaType::Bool, QMC::DefaultPropertyFlags, 5),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<SimEngine, qt_meta_tag_ZN9SimEngineE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject SimEngine::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9SimEngineE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9SimEngineE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN9SimEngineE_t>.metaTypes,
    nullptr
} };

void SimEngine::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<SimEngine *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->slavesChanged(); break;
        case 1: _t->selectedChainIndexChanged(); break;
        case 2: _t->pdoConfigChanged(); break;
        case 3: _t->frameCountChanged(); break;
        case 4: _t->lastFrameChanged(); break;
        case 5: _t->runningChanged(); break;
        case 6: _t->addSlave((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 7: _t->addSlave((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 8: _t->removeSlave((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 9: _t->selectSlave((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 10: { QVariantMap _r = _t->getSlavePdoConfig((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 11: _t->setPdoEnabled((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[4]))); break;
        case 12: _t->setEntryEnabled((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[5]))); break;
        case 13: _t->setEntryValue((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<qint64>>(_a[5]))); break;
        case 14: _t->stepFrame(); break;
        case 15: _t->runSimulation(); break;
        case 16: _t->pauseSimulation(); break;
        case 17: _t->resetSimulation(); break;
        case 18: { QVariantList _r = _t->getLastFrameBytes();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (SimEngine::*)()>(_a, &SimEngine::slavesChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (SimEngine::*)()>(_a, &SimEngine::selectedChainIndexChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (SimEngine::*)()>(_a, &SimEngine::pdoConfigChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (SimEngine::*)()>(_a, &SimEngine::frameCountChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (SimEngine::*)()>(_a, &SimEngine::lastFrameChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (SimEngine::*)()>(_a, &SimEngine::runningChanged, 5))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<int*>(_v) = _t->slaveCount(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->selectedChainIndex(); break;
        case 2: *reinterpret_cast<QVariantList*>(_v) = _t->slaves(); break;
        case 3: *reinterpret_cast<int*>(_v) = _t->frameCount(); break;
        case 4: *reinterpret_cast<QByteArray*>(_v) = _t->lastFrame(); break;
        case 5: *reinterpret_cast<QVariantList*>(_v) = _t->frameFields(); break;
        case 6: *reinterpret_cast<bool*>(_v) = _t->running(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 1: _t->setSelectedChainIndex(*reinterpret_cast<int*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *SimEngine::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *SimEngine::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9SimEngineE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int SimEngine::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 19)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 19;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 19)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 19;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 7;
    }
    return _id;
}

// SIGNAL 0
void SimEngine::slavesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void SimEngine::selectedChainIndexChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void SimEngine::pdoConfigChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void SimEngine::frameCountChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void SimEngine::lastFrameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void SimEngine::runningChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}
QT_WARNING_POP
