#include "serial.h"
#include <QSerialPort>
#include "mainwindow.h"
#include <QString>

Serial::Serial(QObject *parent) : QObject(parent)
{
    port = new QSerialPort();
}

Serial::~Serial()
{
    delete port;
}

bool Serial::openPort(QString portName)
{
    port = new QSerialPort();
    port->setPortName(portName);
    port->setBaudRate(57600);
    port->setDataBits(QSerialPort::Data8);
    port->setParity(QSerialPort::NoParity);
    port->setStopBits(QSerialPort::OneStop);
    port->setFlowControl(QSerialPort::NoFlowControl);

    if (port->open(QIODevice::ReadWrite))
    {
        return true;
    }
    else
    {
        return false;
    }
}

void Serial::closePort()
{
    port->close();
}

QString Serial::readData()
{
    QString data;
    data = port->readAll();
    return data;
}

void Serial::writeData(QByteArray controlSignals)
{
    port->write(controlSignals);
}
