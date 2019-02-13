#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QTimer>
#include <QSerialPortInfo>
#include <bitset>
#include <QTime>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    serial = new Serial(this);

    gliderShortcut = new QShortcut(this);
    gliderShortcut->setKey(Qt::Key_1);
    habShortcut = new QShortcut(this);
    habShortcut->setKey(Qt::Key_2);
    waterShortcut = new QShortcut(this);
    waterShortcut->setKey(Qt::Key_3);

    graphInit();

    updateCOM_comboBox();

    portOpen = false;
    commandSignals[0] = 0b00000000;
    commandSignals[1] = 0b10000000;
    zeroAlt = false;
    sendOrigin = false;
    originSignal = false;
    armSignal = false;
    autonomousSignal= false;
    dropGliderASignal = false;
    dropGliderBSignal = false;
    dropHabLSignal = false;
    dropHabRSignal = false;
    dropWaterSignal= false;

    gliderADropped = false;
    gliderBDropped = false;
    habLDropped = false;
    habRDropped = false;
    waterDropped = false;

    dropTimesFile.setFileName("dropTimes.txt");
    originPointFile.setFileName("originPoint.txt");

    receive_timer = new QTimer(this);
    connect (receive_timer,&QTimer::timeout,this,&MainWindow::updateUI);
    receive_timer->start(10); // for a .01 second interval
    receive_timer->stop();

    send_timer = new QTimer(this);
    connect (send_timer,&QTimer::timeout,this,&MainWindow::sendCommand);
    send_timer->start(10); //for a .01 second interval
    send_timer->stop();

    connect (ui->connect_button, &QPushButton::clicked,this,&MainWindow::connectSP);
    connect (ui->disconnect_button, &QPushButton::clicked,this,&MainWindow::disconnectSP);
    connect (ui->refresh_Button, &QPushButton::clicked, this, &MainWindow::updateCOM_comboBox);
    connect (ui->zeroAlt_button, &QPushButton::clicked, this, &MainWindow::setZeroAltSignal);
    connect (ui->sendOrigin_button, &QPushButton::clicked, this, &MainWindow::setSendOriginSignal);
    connect (ui->setOriginActive_button, &QPushButton::toggled, this, &MainWindow::setOriginSignal);
    connect (ui->armed_button, &QRadioButton::toggled, this, &MainWindow::setArmSignal);
    connect (ui->autonomous_button, &QRadioButton::toggled, this, &MainWindow::setAutonomousSignal);

    connect (ui->gliderAR_button, &QRadioButton::toggled, this, &MainWindow::setDropGliderASignal);
    connect (ui->gliderBR_button, &QRadioButton::toggled, this, &MainWindow::setDropGliderBSignal);
    connect (ui->habLR_button, &QRadioButton::toggled, this, &MainWindow::setDropHabLSignal);
    connect (ui->habRR_button, &QRadioButton::toggled, this, &MainWindow::setDropHabRSignal);
    connect (ui->waterR_button, &QRadioButton::toggled, this, &MainWindow::setDropWaterSignal);

    connect (gliderShortcut, &QShortcut::activated, this, &MainWindow::shortcutGlider);
    connect (habShortcut, &QShortcut::activated, this, &MainWindow::shortcutHabs);
    connect (waterShortcut, &QShortcut::activated, this, &MainWindow::shortcutWater);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::updateUI()
{
    if (portOpen)
    {
        QString data = serial->readData();
        telemetry = updateBuffer(data);
        if(lastSerialTime + 150 < QTime::currentTime().msecsSinceStartOfDay()){
            ui->alt_disp->setStyleSheet("QLabel { color : red; }");
        }else{
            ui->alt_disp->setStyleSheet("QLabel { color : green; }");
        }
        if(!telemetry.isEmpty() && telemetry.length() >= 10)
        {
            lastSerialTime = QTime::currentTime().msecsSinceStartOfDay();
            ui->gpsTime_label->setText(telemetry.at(0));
            ui->speed_label->setText(telemetry.at(1));
            ui->gpsLat_label->setText(telemetry.at(2));
            ui->gpsLong_label->setText(telemetry.at(3));
            ui->baroAlt_label->setText(telemetry.at(4));
            ui->startTime_label->setText(telemetry.at(5));
            ui->targetEast_label->setText(telemetry.at(6));
            ui->targetNorth_label->setText(telemetry.at(7));

            logDropTimes(telemetry);

            int alt_in_feet = mStr2FtInt(telemetry.at(4));
            QString altDisplay = QString::number(alt_in_feet);
            ui->alt_disp->setText(altDisplay + "'");

            updateGraph();
            updateCommandSignals();

//            ui->plainTextEdit->moveCursor (QTextCursor::End);
//            ui->plainTextEdit->appendPlainText("[");

//            for(int i=0; i<telemetry.size(); i++)
//            {
//                ui->plainTextEdit->moveCursor (QTextCursor::End);
//                ui->plainTextEdit->insertPlainText(telemetry.at(i));
//                ui->plainTextEdit->moveCursor (QTextCursor::End);
//                ui->plainTextEdit->insertPlainText(" ");
//            }
//            ui->plainTextEdit->insertPlainText("]");
        }
    }
}

QStringList MainWindow::updateBuffer(QString data)
{
    QStringList result = {};
    buffer += data;
    if(buffer.contains('!'))
    {
        QStringList temp = buffer.split('!');
        data = temp.at(0);
        result = data.split(' ');
        buffer = buffer.chopped(buffer.indexOf("!"));
    }
    return result;
}

void MainWindow::updateGraph()
{
    int east, north, impactEast, impactNorth;
    east = mStr2FtInt(telemetry.at(2));
    north = mStr2FtInt(telemetry.at(3));
    impactEast = mStr2FtInt(telemetry.at(6));
    impactNorth = mStr2FtInt(telemetry.at(7));

    ui->mapWidget->graph(3)->addData(east, north);
    ui->mapWidget->replot();

    //ui->mapWidget->graph(4)->addData(impactEast, impactNorth);
    //ui->mapWidget->replot();
}

void MainWindow::logDropTimes(QStringList telemetry)
{
    int value  = telemetry.at(8).toInt(nullptr, 16);
    systemClock = systemClock.currentDateTime();
    QString timeString = systemClock.toString();

    QStringList temp = {};
    temp = timeString.split(' ');

    timeString = temp.at(3);

    QString alt = QString::number(mStr2FtInt(telemetry.at(4)));

    if (value <= 'f' && value >= 0)
    {
        if (value % 2 != 0 && waterDropped == false)
        {
            ui->plainTextEdit->moveCursor (QTextCursor::End);
            ui->plainTextEdit->appendPlainText("Water dropped at timestamp: ");
            ui->plainTextEdit->insertPlainText(timeString);

            ui->dropAltitudes_display->appendPlainText("W: " + alt + "'");

            if ( dropTimesFile.open(QIODevice::WriteOnly|QIODevice::Text) || dropTimesFile.isOpen())
            {
                QTextStream stream( &dropTimesFile );
                stream << "Water dropped at timestamp: " << timeString << endl;
                stream << " Altitude: " << alt << endl;
                stream << " East: " << telemetry.at(2) << endl;
                stream << " North: " << telemetry.at(3) << endl;
                stream << " Velocity: " << telemetry.at(1) << endl;
            }

            waterDropped = true;
        }

        value = value >> 1;

        if (value % 2 != 0 && habLDropped == false)
        {
            ui->plainTextEdit->moveCursor (QTextCursor::End);
            ui->plainTextEdit->appendPlainText("Left habitations dropped at timestamp: ");
            ui->plainTextEdit->insertPlainText(timeString);

            ui->dropAltitudes_display->appendPlainText("Hl: " + alt + "'");

            if ( dropTimesFile.open(QIODevice::WriteOnly|QIODevice::Text) || dropTimesFile.isOpen())
            {
                QTextStream stream( &dropTimesFile );
                stream << "Left habitiations dropped at timestamp: " << timeString << endl;
                stream << " Altitude: " << alt << endl;
                stream << " East: " << telemetry.at(2) << endl;
                stream << " North: " << telemetry.at(3) << endl;
                stream << " Velocity: " << telemetry.at(1) << endl;
            }

            habLDropped = true;
        }

        if (value % 2 != 0 && habRDropped == false)
        {
            ui->plainTextEdit->moveCursor (QTextCursor::End);
            ui->plainTextEdit->appendPlainText("Right habitations dropped at timestamp: ");
            ui->plainTextEdit->insertPlainText(timeString);

            ui->dropAltitudes_display->appendPlainText("Hr: " + alt + "'");

            if ( dropTimesFile.open(QIODevice::WriteOnly|QIODevice::Text) || dropTimesFile.isOpen())
            {
                QTextStream stream( &dropTimesFile );
                stream << "Right habitiations dropped at timestamp: " << timeString << endl;
                stream << " Altitude: " << alt << endl;
                stream << " East: " << telemetry.at(2) << endl;
                stream << " North: " << telemetry.at(3) << endl;
                stream << " Velocity: " << telemetry.at(1) << endl;
            }

            habRDropped = true;
        }

        value = value >> 1;

        if (value % 2 != 0 && gliderBDropped == false)
        {
            ui->plainTextEdit->moveCursor (QTextCursor::End);
            ui->plainTextEdit->appendPlainText("Glider B dropped at timestamp: ");
            ui->plainTextEdit->insertPlainText(timeString);

            ui->dropAltitudes_display->appendPlainText("Gb: " + alt + "'");

            if ( dropTimesFile.open(QIODevice::WriteOnly|QIODevice::Text) || dropTimesFile.isOpen())
            {
                QTextStream stream( &dropTimesFile );
                stream << "Glider B dropped at timestamp: " << timeString << endl;
                stream << " Altitude: " << alt << endl;
                stream << " East: " << telemetry.at(2) << endl;
                stream << " North: " << telemetry.at(3) << endl;
                stream << " Velocity: " << telemetry.at(1) << endl;
            }

            gliderBDropped = true;
        }

        value = value >> 1;

        if (value % 2 != 0 && gliderADropped == false)
        {
            ui->plainTextEdit->moveCursor (QTextCursor::End);
            ui->plainTextEdit->appendPlainText("Glider A dropped at timestamp: ");
            ui->plainTextEdit->insertPlainText(timeString);

            ui->dropAltitudes_display->appendPlainText("Ga: " + alt + "'");

            if ( dropTimesFile.open(QIODevice::WriteOnly|QIODevice::Text) || dropTimesFile.isOpen())
            {
                QTextStream stream( &dropTimesFile );
                stream << "Glider A dropped at timestamp: " << timeString << endl;
                stream << " Altitude: " << alt << endl;
                stream << " East: " << telemetry.at(2) << endl;
                stream << " North: " << telemetry.at(3) << endl;
                stream << " Velocity: " << telemetry.at(1) << endl;
            }

            gliderADropped = true;
        }
    }
}

void MainWindow::connectSP()
{
    if (!portOpen && !ui->COM_comboBox->currentText().isEmpty())
    {
        ui->mapWidget->graph(3)->data()->clear();
        ui->mapWidget->graph(4)->data()->clear();
        ui->mapWidget->replot();
        portOpen = serial->openPort(ui->COM_comboBox->currentText());
        if (portOpen)
        {
            ui->plainTextEdit->appendPlainText("Port Open");
            send_timer->start();
            receive_timer->start();
        }
        else
        {
            ui->plainTextEdit->appendPlainText("Port Failed to Open");
        }
    }
}

void MainWindow::disconnectSP()
{
    if(portOpen)
    {
        serial->closePort();
        ui->plainTextEdit->appendPlainText("Port Closed");
        portOpen = false;
        buffer = "";
        send_timer->stop();
        receive_timer->stop();
    }
}

void MainWindow::updateCOM_comboBox()
{
    ui->COM_comboBox->clear();
    const auto infos = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &info : infos)
    {
        QStringList list;
        list << info.portName();

        ui->COM_comboBox->addItem(list.first(), list);
    }
}

void MainWindow::sendCommand()
{
    serial->writeData(commandSignals);
}

void MainWindow::updateCommandSignals()
{
    if (originSignal)
    {
        commandSignals[0] = commandSignals[0] | 0b01000000;
    }
    else
    {
        commandSignals[0] = commandSignals[0] & 0b10111111;
    }

    if (armSignal)
    {
        commandSignals[0] = commandSignals[0] | 0b00100000;
    }
    else
    {
        commandSignals[0] = commandSignals[0] & 0b11011111;
    }

    if (autonomousSignal)
    {
        commandSignals[0] = commandSignals[0] | 0b00010000;
    }
    else
    {
        commandSignals[0] = commandSignals[0] & 0b11101111;
    }

    if (dropGliderASignal)
    {
        commandSignals[0] = commandSignals[0] | 0b00001000;
    }
    else
    {
        commandSignals[0] = commandSignals[0] & 0b11110111;
    }

    if (dropGliderBSignal)
    {
        commandSignals[0] = commandSignals[0] | 0b00000100;
    }
    else
    {
        commandSignals[0] = commandSignals[0] & 0b11111011;
    }

    if (dropHabLSignal)
    {
        commandSignals[0] = commandSignals[0] | 0b00000010;
    }
    else
    {
        commandSignals[0] = commandSignals[0] & 0b11111101;
    }

    if (dropWaterSignal)
    {
        commandSignals[0] = commandSignals[0] | 0b00000001;
    }
    else
    {
        commandSignals[0] = commandSignals[0] & 0b11111110;
    }

    if (zeroAlt)
    {
        commandSignals[1] = commandSignals[1] | 0b00100000;
        zeroAlt = false;
    }
    else
    {
        commandSignals[1] = commandSignals[1] & 0b11011111;
    }

    if (sendOrigin)
    {
        commandSignals[1] = commandSignals[1] | 0b00010000;
        sendOrigin = false;
    }
    else
    {
        commandSignals[1] = commandSignals[1] & 0b11101111;
    }

    if (dropHabRSignal)
    {
        commandSignals[1] = commandSignals[1] | 0b00000010;
    }
    else
    {
        commandSignals[1] = commandSignals[1] & 0b11111101;
    }
}

void MainWindow::setZeroAltSignal()
{
    zeroAlt = true;
    updateCommandSignals();
}

void MainWindow::setOriginSignal()
{
    originSignal = ui->setOriginActive_button->isChecked();
    if (!originSignal && !telemetry.isEmpty() && telemetry.length() >= 10)
    {
        ui->plainTextEdit->appendPlainText("Origin Point: ");
        ui->plainTextEdit->insertPlainText(telemetry.at(2));
        ui->plainTextEdit->insertPlainText(",");
        ui->plainTextEdit->insertPlainText(telemetry.at(3));

        if ( originPointFile.open(QIODevice::WriteOnly|QIODevice::Text) || originPointFile.isOpen())
        {
            QTextStream stream( &originPointFile );
            stream << telemetry.at(2) << endl << telemetry.at(3);
        }
        originPointFile.close();
    }
    updateCommandSignals();
}

void MainWindow::setSendOriginSignal()
{
    sendOrigin = true;
    updateCommandSignals();
}

//void MainWindow::receivingSignal(){} not sure what this will be yet

void MainWindow::setArmSignal()
{
    armSignal = ui->armed_button->isChecked();
    updateCommandSignals();
    if (!armSignal)
    {
        commandSignals[0] = 0b00000000;
        commandSignals[1] = 0b10000000;
        gliderADropped = false;
        gliderBDropped = false;
        habLDropped = false;
        habRDropped = false;
        waterDropped = false;
        dropTimesFile.close();
    }
}

void MainWindow::setAutonomousSignal()
{
    autonomousSignal = ui->autonomous_button->isChecked();
    updateCommandSignals();
}

void MainWindow::setDropGliderASignal()
{
    dropGliderASignal = ui->gliderAR_button->isChecked();
    updateCommandSignals();
}

void MainWindow::setDropGliderBSignal()
{
    dropGliderBSignal = ui->gliderBR_button->isChecked();
    updateCommandSignals();
}

void MainWindow::setDropHabLSignal()
{
    dropHabLSignal = ui->habLR_button->isChecked();
    updateCommandSignals();
}

void MainWindow::setDropHabRSignal()
{
    dropHabRSignal = ui->habRR_button->isChecked();
    updateCommandSignals();
}

void MainWindow::setDropWaterSignal()
{
    dropWaterSignal = ui->waterR_button->isChecked();
    updateCommandSignals();
}

void MainWindow::shortcutGlider()
{
    ui->gliderAR_button->setChecked(true);
    ui->gliderBR_button->setChecked(true);
}

void MainWindow::shortcutHabs()
{
    ui->habLR_button->setChecked(true);
    ui->habRR_button->setChecked(true);
}

void MainWindow::shortcutWater()
{
    ui->waterR_button->setChecked(true);
}

int MainWindow::mStr2FtInt(QString meters)
{
    int feet = (meters.toDouble() * 3.281);
    return feet;
}

void MainWindow::graphInit()
{
    ui->mapWidget->addGraph(); //0, top half of circle
    ui->mapWidget->addGraph(); //1, lower half of circle
    ui->mapWidget->addGraph(); //2, glider boundaries
    ui->mapWidget->addGraph(); //3, plane history
    ui->mapWidget->addGraph(); //4, hab prediction
    ui->mapWidget->addGraph(); //5, water prediction
    ui->mapWidget->addGraph(); //6, plane icon

    ui->mapWidget->xAxis->setRange(-700, 700);
    ui->mapWidget->yAxis->setRange(-170, 170);

    pen0.setColor(QColor(255,0,0));
    ui->mapWidget->graph(0)->setPen(pen0);
    ui->mapWidget->graph(1)->setPen(pen0);
    ui->mapWidget->graph(0)->addData(50, 0);
    ui->mapWidget->graph(0)->addData(48.3, 12.94);
    ui->mapWidget->graph(0)->addData(43.3, 25);
    ui->mapWidget->graph(0)->addData(35.355, 35.355);
    ui->mapWidget->graph(0)->addData(25, 43.3);
    ui->mapWidget->graph(0)->addData(12.94, 48.3);
    ui->mapWidget->graph(0)->addData(0, 50);
    ui->mapWidget->graph(0)->addData(-12.94, 48.3);
    ui->mapWidget->graph(0)->addData(-25, 43.3);
    ui->mapWidget->graph(0)->addData(-35.355, 35.355);
    ui->mapWidget->graph(0)->addData(-43.3, 25);
    ui->mapWidget->graph(0)->addData(-48.3, 12.94);
    ui->mapWidget->graph(0)->addData(-50, 0);
    ui->mapWidget->graph(1)->addData(-50, 0);
    ui->mapWidget->graph(1)->addData(-48.3, -12.94);
    ui->mapWidget->graph(1)->addData(-43.3, -25);
    ui->mapWidget->graph(1)->addData(-35.355, -35.355);
    ui->mapWidget->graph(1)->addData(-25, -43.3);
    ui->mapWidget->graph(1)->addData(-12.94, -48.3);
    ui->mapWidget->graph(1)->addData(0, -50);
    ui->mapWidget->graph(1)->addData(12.94, -48.3);
    ui->mapWidget->graph(1)->addData(25, -43.3);
    ui->mapWidget->graph(1)->addData(35.355, -35.355);
    ui->mapWidget->graph(1)->addData(43.3, -25);
    ui->mapWidget->graph(1)->addData(48.3, -12.94);
    ui->mapWidget->graph(1)->addData(50, 0);
    ui->mapWidget->graph(0)->setScatterStyle(QCPScatterStyle::ssDot);
    ui->mapWidget->graph(1)->setScatterStyle(QCPScatterStyle::ssDot);

    pen2.setColor(QColor(0,0,0));
    ui->mapWidget->graph(2)->setPen(pen2);
    ui->mapWidget->graph(2)->addData(-200, -200);
    ui->mapWidget->graph(2)->addData(-200, 200);
    ui->mapWidget->graph(2)->addData(200, -200);
    ui->mapWidget->graph(2)->addData(200, 200);
    ui->mapWidget->graph(2)->setLineStyle(QCPGraph::lsImpulse);
    ui->mapWidget->graph(2)->setScatterStyle(QCPScatterStyle::ssDot);

    pen3.setColor(QColor(242,138,0));
    ui->mapWidget->graph(3)->setPen(pen3);
    ui->mapWidget->graph(3)->setScatterStyle(QCPScatterStyle::ssDot);

    createPlaneSprite();

    QCPScatterStyle plane = planePixMap;
    ui->mapWidget->graph(6)->setScatterStyle(plane);
    ui->mapWidget->replot();
}

void MainWindow::createPlaneSprite()
{
    QImage planeSprite(16, 16, QImage::Format_RGB32);
    QRgb value;

    value = qRgb(165, 160, 0); // yellow
    planeSprite.setPixel(0, 7, value);
    planeSprite.setPixel(15, 7, value);
    planeSprite.setPixel(8, 14, value);

    value = qRgb(0, 31, 124); // blue
    planeSprite.setPixel(1, 6, value);
    planeSprite.setPixel(2, 6, value);
    planeSprite.setPixel(3, 6, value);
    planeSprite.setPixel(4, 6, value);
    planeSprite.setPixel(5, 6, value);
    planeSprite.setPixel(6, 6, value);
    planeSprite.setPixel(7, 6, value);
    planeSprite.setPixel(8, 6, value);
    planeSprite.setPixel(9, 6, value);
    planeSprite.setPixel(10, 6, value);
    planeSprite.setPixel(11, 6, value);
    planeSprite.setPixel(12, 6, value);
    planeSprite.setPixel(13, 6, value);
    planeSprite.setPixel(14, 6, value);
    planeSprite.setPixel(1, 7, value);
    planeSprite.setPixel(2, 7, value);
    planeSprite.setPixel(3, 7, value);
    planeSprite.setPixel(4, 7, value);
    planeSprite.setPixel(5, 7, value);
    planeSprite.setPixel(6, 7, value);
    planeSprite.setPixel(7, 7, value);
    planeSprite.setPixel(8, 7, value);
    planeSprite.setPixel(9, 7, value);
    planeSprite.setPixel(10, 7, value);
    planeSprite.setPixel(11, 7, value);
    planeSprite.setPixel(12, 7, value);
    planeSprite.setPixel(13, 7, value);
    planeSprite.setPixel(14, 7, value);
    planeSprite.setPixel(7, 13, value);
    planeSprite.setPixel(9, 13, value);
    planeSprite.setPixel(6, 14, value);
    planeSprite.setPixel(7, 14, value);
    planeSprite.setPixel(9, 14, value);
    planeSprite.setPixel(10, 14, value);

    value = qRgb(36, 36, 36); // grey
    planeSprite.setPixel(7, 4, value);
    planeSprite.setPixel(5, 5, value);
    planeSprite.setPixel(7, 5, value);
    planeSprite.setPixel(8, 5, value);
    planeSprite.setPixel(10, 5, value);
    planeSprite.setPixel(7, 8, value);
    planeSprite.setPixel(8, 8, value);
    planeSprite.setPixel(7, 9, value);
    planeSprite.setPixel(8, 9, value);
    planeSprite.setPixel(8, 10, value);
    planeSprite.setPixel(8, 11, value);
    planeSprite.setPixel(8, 12, value);
    planeSprite.setPixel(8, 13, value);

    planePixMap.convertFromImage(planeSprite);
}
