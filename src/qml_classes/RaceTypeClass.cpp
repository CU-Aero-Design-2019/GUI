#include "qml_classes/RaceTypeClass.h"
#include <QtQml>

RaceTypeClass::RaceTypeClass() {
    // Structure of qt enums requires this constructor. At least, it doesn't
    // work without it right now
}

void RaceTypeClass::init() {
    qRegisterMetaType<RaceType>("RaceType");
    qmlRegisterUncreatableType<RaceTypeClass>("RaceEnum", 1, 0, "RaceType", "Cannot instantiate enum type");
}
