#ifndef SETTINGSDIALOG_H
#define SETTINGSDIALOG_H

#include <QWidget>

namespace Ui {
class settingsdialog;
}

class settingsdialog : public QWidget
{
    Q_OBJECT

public:
    explicit settingsdialog(QWidget *parent = nullptr);
    ~settingsdialog();

private:
    Ui::settingsdialog *ui;
};

#endif // SETTINGSDIALOG_H
