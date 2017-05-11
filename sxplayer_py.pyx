cimport sxplayer_py
import numpy as np

class Frame(object):
    def get_mat(self):
        return self.ndarray

    def __init__(self, ndarray):
        self.ndarray = ndarray

cdef class Decoder(object):
    cdef sxplayer_py.sxplayer_ctx* ctx
    cdef int started

    cdef str fn
    cdef double assumed_fps

    def __init__(self, fn):
        self.fn = fn
        self.assumed_fps = 30.

    def __cinit__(self, fn):
        self.ctx = sxplayer_create(fn)
        self.started = False

    def __dealloc__(self):
        sxplayer_free(&self.ctx)

    def nframes(self):
        cdef int n = 0
        while True:
            frame = sxplayer_get_next_frame(self.ctx)
            if frame == NULL:
                break

            sxplayer_release_frame(frame)

            n += 1
        return n

    def info(self):
        cdef sxplayer_py.sxplayer_info info
        sxplayer_get_info(self.ctx, &info)

        return {
            'width': info.width,
            'height': info.height,
            'duration': info.duration,
            'fps': 30.0,
            'first_frame': 1,
            'last_frame': self.nframes(),
            'frames': self.nframes()
        }

    def duration(self):
        cdef double result
        sxplayer_get_duration(self.ctx, &result)
        return result

    def get_frame(self, t):
        if not self.started:
            sxplayer_start(self.ctx)
            self.started = True

        cdef sxplayer_py.sxplayer_frame* frame
        frame = sxplayer_get_frame(self.ctx, t)

        if frame == NULL:
            sxplayer_seek(self.ctx, t)
            frame = sxplayer_get_frame(self.ctx, t)

        cdef uint8_t[:, :, :] data
        if frame != NULL:
            data = <uint8_t[:frame.height, :frame.width, :4]> frame.data
            result = Frame(np.asarray(data[:, :, :3]).copy())
            sxplayer_release_frame(frame)
            return result
        else:
            return None

    def decode(self, frame_number, resolution=480):
        return self.get_frame(frame_number / self.assumed_fps)
