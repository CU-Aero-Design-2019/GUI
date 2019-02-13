#include "mainwindow.h"
#include "qml_classes/RaceTypeClass.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    w.show();

    RaceTypeClass::init();

    return a.exec();
}
