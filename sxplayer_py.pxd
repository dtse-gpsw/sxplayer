cdef extern from "sxplayer.h":
    struct sxplayer_ctx:
        pass

    struct sxplayer_info:
        int width
        int height
        double duration

    ctypedef signed char uint8_t
    struct sxplayer_frame:
        uint8_t* data
        int width
        int height

    sxplayer_ctx* sxplayer_create(const char* filename)
    void sxplayer_free(sxplayer_ctx** ctx)

    int sxplayer_get_info(sxplayer_ctx* ctx, sxplayer_info* info)
    int sxplayer_get_duration(sxplayer_ctx* ctx, double* result)

    sxplayer_frame* sxplayer_get_frame(sxplayer_ctx* ctx, double t)
    void sxplayer_release_frame(sxplayer_frame* frame)

    int sxplayer_start(sxplayer_ctx* ctx)
    int sxplayer_seek(sxplayer_ctx* ctx, double t)

    sxplayer_frame* sxplayer_get_next_frame(sxplayer_ctx* ctx)
