#ifndef MBGL_MAP_UPDATE
#define MBGL_MAP_UPDATE

#include <cstdint>

namespace mbgl {

using UpdateType = uint32_t;

enum class Update : UpdateType {
    Nothing                   = 0,
    StyleInfo                 = 1 << 0,
    Debug                     = 1 << 1,
    DefaultTransitionDuration = 1 << 2,
    Classes                   = 1 << 3,
    Zoom                      = 1 << 4,
    RenderStill               = 1 << 5,
};

}

#endif
