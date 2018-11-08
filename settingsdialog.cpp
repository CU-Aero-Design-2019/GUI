#include "settingsdialog.h"
#include "ui_settingsdialog.h"

settingsdialog::settingsdialog(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::settingsdialog)
{
    ui->setupUi(this);
}

settingsdialog::~settingsdialog()
{
    delete ui;
}
