cimport sxplayer_py
import numpy as np
cimport numpy as cnp

class DecodeError(RuntimeError): pass

cdef class FrameFinaliser:
    cdef sxplayer_py.sxplayer_frame* frame
    cdef int frame_no

    def __dealloc__(self):
        if self.frame is not NULL:
            sxplayer_release_frame(self.frame)

cdef class Frame(object):
    cdef cnp.ndarray ndarray

    def get_mat(self):
        return self.ndarray

    def __cinit__(self, cnp.ndarray ndarray):
        self.ndarray = ndarray

cdef void set_base(cnp.ndarray ndarray,
    sxplayer_py.sxplayer_frame* frame,
    int frame_no):

    cdef FrameFinaliser fin = FrameFinaliser()
    fin.frame_no = frame_no
    fin.frame = frame

    cnp.set_array_base(ndarray, fin)

cdef class Decoder(object):
    cdef sxplayer_py.sxplayer_ctx* ctx
    cdef int started

    cdef str fn
    cdef double assumed_fps

    cdef int _nframes

    def __init__(self, fn):
        self.fn = fn
        self.assumed_fps = 30.

    def __cinit__(self, fn):
        self.ctx = sxplayer_create(fn)
        self.started = False

        self._nframes = -1

    def set_option(self, key, value):
        return sxplayer_set_option(self.ctx, key, value)

    def __dealloc__(self):
        sxplayer_free(&self.ctx)

    @property
    def nframes(self):
        cdef int n = 0
        if self._nframes == -1:
            while True:
                frame = sxplayer_get_next_frame(self.ctx)
                if frame == NULL:
                    break

                sxplayer_release_frame(frame)

                n += 1
            self._nframes = n

        return self._nframes

    @property
    def fps(self):
        return self.nframes / self.info()['duration']

    def info(self):
        cdef sxplayer_py.sxplayer_info info
        if sxplayer_get_info(self.ctx, &info) < 0:
            raise DecodeError('sxplayer_get_info() < 0')

        nframes = self.nframes

        return {
            'width': info.width,
            'height': info.height,
            'duration': info.duration,
            'fps': nframes / info.duration,
            'first_frame': 1,
            'last_frame': nframes,
            'frames': nframes
        }

    def duration(self):
        cdef double result
        sxplayer_get_duration(self.ctx, &result)
        return result

    def get_mvs(self, double t):
        if not self.started:
            sxplayer_start(self.ctx)
            self.started = True

        cdef sxplayer_py.sxplayer_frame* frame
        frame = sxplayer_get_frame(self.ctx, t)

        if frame == NULL:
            if sxplayer_seek(self.ctx, t) < 0:
                raise DecodeError('sxplayer_seek() < 0')
            frame = sxplayer_get_frame(self.ctx, t)

        cdef AVMotionVector[:] data
        if frame.nb_mvs == 0:
            sxplayer_release_frame(frame)
            return None
        else:
            data = <AVMotionVector[:frame.nb_mvs]> frame.mvs
            data_copy = np.asarray(data).copy()

            sxplayer_release_frame(frame)

            return data_copy

    def get_frame(self, double t):
        if not self.started:
            sxplayer_start(self.ctx)
            self.started = True

        cdef sxplayer_py.sxplayer_frame* frame
        frame = sxplayer_get_frame(self.ctx, t)

        if frame == NULL:
            if sxplayer_seek(self.ctx, t) < 0:
                raise DecodeError('sxplayer_seek() < 0')
            frame = sxplayer_get_frame(self.ctx, t)

        cdef uint8_t[:, :, :] data
        cdef cnp.ndarray ndarray
        if frame != NULL:
            data = <uint8_t[:frame.height, :frame.width, :4]> frame.data
            ndarray = np.asarray(data[:, :, :3])

            # attach a finaliser to the ndarray to release the frame
            set_base(ndarray, frame, int(t * self.fps))

            return Frame(ndarray)
        else:
            return None

    def decode(self, int frame_number, int resolution=480):
        # print 'decode(%d) = %f' % (frame_number, frame_number/self.fps)
        return self.get_frame(frame_number / self.fps)
