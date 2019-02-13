#pragma once
#include <QObject>

class RaceTypeClass {
    Q_GADGET
public:
    enum Value {
        BACK_FORTH,
        CIRCULAR,
        START_FINISH
    };
    Q_ENUM(Value)

    static void init();

private:
    explicit RaceTypeClass();
};

typedef RaceTypeClass::Value RaceType;
