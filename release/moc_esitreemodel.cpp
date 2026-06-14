/****************************************************************************
** Meta object code from reading C++ file 'esitreemodel.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.5.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../interfaces/esitreemodel.h"
#include <QtCore/qmetatype.h>

#if __has_include(<QtCore/qtmochelpers.h>)
#include <QtCore/qtmochelpers.h>
#else
QT_BEGIN_MOC_NAMESPACE
#endif


#include <memory>

#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'esitreemodel.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.5.3. It"
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

#ifdef QT_MOC_HAS_STRINGDATA
struct qt_meta_stringdata_CLASSESITreeModelENDCLASS_t {};
static constexpr auto qt_meta_stringdata_CLASSESITreeModelENDCLASS = QtMocHelpers::stringData(
    "ESITreeModel",
    "hasDataChanged",
    "",
    "fileCountChanged",
    "loadFile",
    "filePath",
    "findMatchRow",
    "query",
    "hasData",
    "fileCount"
);
#else  // !QT_MOC_HAS_STRING_DATA
struct qt_meta_stringdata_CLASSESITreeModelENDCLASS_t {
    uint offsetsAndSizes[20];
    char stringdata0[13];
    char stringdata1[15];
    char stringdata2[1];
    char stringdata3[17];
    char stringdata4[9];
    char stringdata5[9];
    char stringdata6[13];
    char stringdata7[6];
    char stringdata8[8];
    char stringdata9[10];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_CLASSESITreeModelENDCLASS_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_CLASSESITreeModelENDCLASS_t qt_meta_stringdata_CLASSESITreeModelENDCLASS = {
    {
        QT_MOC_LITERAL(0, 12),  // "ESITreeModel"
        QT_MOC_LITERAL(13, 14),  // "hasDataChanged"
        QT_MOC_LITERAL(28, 0),  // ""
        QT_MOC_LITERAL(29, 16),  // "fileCountChanged"
        QT_MOC_LITERAL(46, 8),  // "loadFile"
        QT_MOC_LITERAL(55, 8),  // "filePath"
        QT_MOC_LITERAL(64, 12),  // "findMatchRow"
        QT_MOC_LITERAL(77, 5),  // "query"
        QT_MOC_LITERAL(83, 7),  // "hasData"
        QT_MOC_LITERAL(91, 9)   // "fileCount"
    },
    "ESITreeModel",
    "hasDataChanged",
    "",
    "fileCountChanged",
    "loadFile",
    "filePath",
    "findMatchRow",
    "query",
    "hasData",
    "fileCount"
};
#undef QT_MOC_LITERAL
#endif // !QT_MOC_HAS_STRING_DATA
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_CLASSESITreeModelENDCLASS[] = {

 // content:
      11,       // revision
       0,       // classname
       0,    0, // classinfo
       4,   14, // methods
       2,   46, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       2,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    0,   38,    2, 0x06,    3 /* Public */,
       3,    0,   39,    2, 0x06,    4 /* Public */,

 // methods: name, argc, parameters, tag, flags, initial metatype offsets
       4,    1,   40,    2, 0x02,    5 /* Public */,
       6,    1,   43,    2, 0x102,    7 /* Public | MethodIsConst  */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,

 // methods: parameters
    QMetaType::Bool, QMetaType::QString,    5,
    QMetaType::Int, QMetaType::QString,    7,

 // properties: name, type, flags
       8, QMetaType::Bool, 0x00015001, uint(0), 0,
       9, QMetaType::Int, 0x00015001, uint(1), 0,

       0        // eod
};

Q_CONSTINIT const QMetaObject ESITreeModel::staticMetaObject = { {
    QMetaObject::SuperData::link<QStandardItemModel::staticMetaObject>(),
    qt_meta_stringdata_CLASSESITreeModelENDCLASS.offsetsAndSizes,
    qt_meta_data_CLASSESITreeModelENDCLASS,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_CLASSESITreeModelENDCLASS_t,
        // property 'hasData'
        QtPrivate::TypeAndForceComplete<bool, std::true_type>,
        // property 'fileCount'
        QtPrivate::TypeAndForceComplete<int, std::true_type>,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<ESITreeModel, std::true_type>,
        // method 'hasDataChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'fileCountChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'loadFile'
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        // method 'findMatchRow'
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>
    >,
    nullptr
} };

void ESITreeModel::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<ESITreeModel *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->hasDataChanged(); break;
        case 1: _t->fileCountChanged(); break;
        case 2: { bool _r = _t->loadFile((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 3: { int _r = _t->findMatchRow((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast< int*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (ESITreeModel::*)();
            if (_t _q_method = &ESITreeModel::hasDataChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (ESITreeModel::*)();
            if (_t _q_method = &ESITreeModel::fileCountChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 1;
                return;
            }
        }
    }else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<ESITreeModel *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< bool*>(_v) = _t->hasData(); break;
        case 1: *reinterpret_cast< int*>(_v) = _t->fileCount(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
    } else if (_c == QMetaObject::ResetProperty) {
    } else if (_c == QMetaObject::BindableProperty) {
    }
}

const QMetaObject *ESITreeModel::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *ESITreeModel::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_CLASSESITreeModelENDCLASS.stringdata0))
        return static_cast<void*>(this);
    return QStandardItemModel::qt_metacast(_clname);
}

int ESITreeModel::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QStandardItemModel::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 4)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 4)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 4;
    }else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 2;
    }
    return _id;
}

// SIGNAL 0
void ESITreeModel::hasDataChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void ESITreeModel::fileCountChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}
QT_WARNING_POP
