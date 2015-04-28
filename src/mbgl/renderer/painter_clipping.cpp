#include <mbgl/renderer/painter.hpp>
#include <mbgl/renderer/fill_bucket.hpp>
#include <mbgl/map/map.hpp>
#include <mbgl/map/tile.hpp>
#include <mbgl/map/source.hpp>
#include <mbgl/util/clip_id.hpp>

using namespace mbgl;

void Painter::drawClippingMasks(const std::set<Source*>& sources) {
    gl::group group("clipping masks");

    useProgram(plainShader->program);
    MBGL_CHECK_ERROR(glDisable(GL_DEPTH_TEST));
    depthMask(false);
    MBGL_CHECK_ERROR(glColorMask(false, false, false, false));
    depthRange(1.0f, 1.0f);

    coveringPlainArray.bind(*plainShader, tileStencilBuffer, BUFFER_OFFSET(0));

    for (const auto& source : sources) {
        source->drawClippingMasks(*this);
    }

    MBGL_CHECK_ERROR(glEnable(GL_DEPTH_TEST));
    MBGL_CHECK_ERROR(glColorMask(true, true, true, true));
    depthMask(true);
    MBGL_CHECK_ERROR(glStencilMask(0x0));
}

void Painter::drawClippingMask(const mat4& matrix, const ClipID &clip) {
    plainShader->u_matrix = matrix;

    const GLint ref = (GLint)(clip.reference.to_ulong());
    const GLuint mask = (GLuint)(clip.mask.to_ulong());
    MBGL_CHECK_ERROR(glStencilFunc(GL_ALWAYS, ref, mask));
    MBGL_CHECK_ERROR(glStencilMask(mask));

    MBGL_CHECK_ERROR(glDrawArrays(GL_TRIANGLES, 0, (GLsizei)tileStencilBuffer.index()));
}
