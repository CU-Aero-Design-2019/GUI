#ifndef SERIAL_H
#define SERIAL_H

#include <QSerialPort>
#include <QString>
#include <QTimer>

class Serial : public QObject
{
    Q_OBJECT

public:
    Serial(QObject *parent);
    ~Serial();
    bool openPort(QString portName);
    void closePort();
    QString readData();
    void writeData(QByteArray controlSignals);
    QObject* mainWindowptr;

public slots:

private:
    QSerialPort* port;

};

#endif // SERIAL_H
