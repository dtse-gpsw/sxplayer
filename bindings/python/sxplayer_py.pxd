ctypedef unsigned char uint8_t
ctypedef unsigned long long uint64_t
ctypedef signed int int32_t
ctypedef signed short int16_t
ctypedef unsigned short uint16_t
ctypedef struct AVMotionVector:
    int32_t source
    uint8_t w, h
    int16_t src_x, src_y
    int16_t dst_x, dst_y

    uint64_t flags

    int32_t motion_x, motion_y
    uint16_t motion_scale

cdef extern from "sxplayer.h":
    struct sxplayer_ctx:
        pass

    struct sxplayer_info:
        int width
        int height
        double duration

    struct sxplayer_frame:
        uint8_t* data
        int width
        int height

        void* mvs
        int nb_mvs

    sxplayer_ctx* sxplayer_create(const char* filename)
    void sxplayer_free(sxplayer_ctx** ctx)

    int sxplayer_get_info(sxplayer_ctx* ctx, sxplayer_info* info)
    int sxplayer_get_duration(sxplayer_ctx* ctx, double* result)

    sxplayer_frame* sxplayer_get_frame(sxplayer_ctx* ctx, double t)
    void sxplayer_release_frame(sxplayer_frame* frame)

    int sxplayer_start(sxplayer_ctx* ctx)
    int sxplayer_seek(sxplayer_ctx* ctx, double t)

    sxplayer_frame* sxplayer_get_next_frame(sxplayer_ctx* ctx)

    int sxplayer_set_option(sxplayer_ctx* ctx, const char* key, int value)
