QT       += core gui \
            widgets serialport
requires(qtConfig(combobox))

TARGET = ADGUI
TEMPLATE = app

SOURCES += \
        main.cpp \
        mainwindow.cpp \
        settingsdialog.cpp \
        console.cpp

HEADERS += \
        mainwindow.h \
        settingsdialog.h \
        console.h

FORMS += \
        mainwindow.ui \
        settingsdialog.ui

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

RESOURCES += \
    ADGUI.qrc
