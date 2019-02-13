#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "serial.h"
#include <QSerialPortInfo>
#include <QtQml/QQmlEngine>
#include <QtQuickWidgets>
#include <QShortcut>

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT
    Serial* serial;

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    QDateTime systemClock;

    QTimer* receive_timer;
    QTimer* send_timer;
    bool portOpen;

    bool zeroAlt;
    bool sendOrigin;
    bool originSignal;
    //bool receivingSignal; not sure what this will be yet
    bool armSignal;
    bool autonomousSignal;
    bool dropGliderASignal;
    bool dropGliderBSignal;
    bool dropHabLSignal;
    bool dropHabRSignal;
    bool dropWaterSignal;

public slots:
    void updateUI();

    void connectSP();
    void disconnectSP();

    void updateCOM_comboBox();

    void sendCommand();
    void updateCommandSignals();

    void setZeroAltSignal();
    void setSendOriginSignal();
    void setOriginSignal();
    //void receivingSignal(); not sure what this will be yet
    void setArmSignal();
    void setAutonomousSignal();
    void setDropGliderASignal();
    void setDropGliderBSignal();
    void setDropHabLSignal();
    void setDropHabRSignal();
    void setDropWaterSignal();
    void shortcutGlider();
    void shortcutHabs();
    void shortcutWater();

private:
    Ui::MainWindow *ui;
    QStringList telemetry;
    QStringList updateBuffer(QString);
    void updateGraph();
    void logDropTimes(QStringList);
    void graphInit();
    void createPlaneSprite();
    int mStr2FtInt(QString);
    QString buffer;
    QByteArray commandSignals;
    bool gliderADropped;
    bool gliderBDropped;
    bool habLDropped;
    bool habRDropped;
    bool waterDropped;

    int lastSerialTime = 0;

    QPixmap planePixMap;

    QFile dropTimesFile;
    QFile originPointFile;

    QQuickWidget* mapView;

    QPen pen0, pen2, pen3;

    QShortcut* gliderShortcut;
    QShortcut* habShortcut;
    QShortcut* waterShortcut;
};

#endif // MAINWINDOW_H
