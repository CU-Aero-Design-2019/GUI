#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow),
	m_status(new Qlabel),
	m_console(new Console),
	m_settings(new SettingsDialog),
    m_serial(new QSerialPort(this))
{
    ui->setupUi(this);
	m_serial(new QSerialPort(this));
	connect(m_serial, &QSerialPort::readyRead, this, &MainWindow::readData);
}

void MainWindow::openSerialPort()
{
	const SettingsDialog::Settings p = m_settings->settings();
	m_serial->setPortName(p.name);
	m_serial->setBaudRate(p.baudRate);
	m_serial->setDataBits(p.dataBits);
	m_serial->setParity(p.parity);
	m_serial->setStopBits(p.stopBits);
	m_serial->setFlowControl(p.flowControl);
	if (m_serial-> open(QIODevice::ReadWrite))
	{
		m_console->setEnabled(true);
		m_console->setLocalEchoEnabled(p.localEchoEnabled);
		m_ui->actionConnect->setEnabled(false);
		m_ui->actionDisconnect->setEnabled(true);
		m_ui->actionConfigure->setEnabled(false);
		showStatusMessage(tr("Connected to %1 : %2 : %3 : %4 : %5 : %6")
							.arg(p.name).arg(p.stringBaudRate).arg(p.stringDataBits)
							.arg(p.stringParity).arg(p.stringStopBits).arg(p.stringFlowControl));
	}
	else
	{
		QMessageBox::critical(this, tr("Error"), m_serial->errorString());
		
		showStatusMessage(tr("Open error"));
	}
}

void MainWindow::closeSerialPort()
{
	if (m_serial->isOpen())
	{
		m_serial->close();
	}
	m_console->setEnabled(false);
	m_ui->actionConnect->setEnabled(true);
	m_ui->actionDisconnect->setEnabled(false);
	m_ui->actionConfigure->setEnabled(true);
	showStatusMessage(tr("Disconnected"));
}

void MainWindow::writeData(const QByteArray &data)
{
	m_serial->write(data);
}

void MainWindow::readData()

{
	const QByteArray data = m_serial->readAll();
	m_console->putData(data);
}

MainWindow::~MainWindow()
{
    delete ui;
}
