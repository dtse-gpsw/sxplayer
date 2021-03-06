NAME = sxplayer

PROJECT_OBJS = async.o          \
               decoder_ffmpeg.o \
               decoders.o       \
               log.o            \
               mod_decoding.o   \
               mod_demuxing.o   \
               mod_filtering.o  \
               msg.o            \
               utils.o          \

DARWIN_OBJS  = decoder_vt.o
ANDROID_OBJS =

PROJECT_PKG_CONFIG_LIBS = libavformat libavfilter libavcodec libavutil
DARWIN_PKG_CONFIG_LIBS  =
ANDROID_PKG_CONFIG_LIBS =

PROJECT_LIBS = -lm -pthread
DARWIN_LIBS  = -framework CoreFoundation -framework VideoToolbox -framework CoreMedia -framework QuartzCore
ANDROID_LIBS =

PREFIX ?= /usr/local
PKG_CONFIG ?= pkg-config

SHARED ?= no
DEBUG  ?= no
TRACE  ?= no

TARGET_OS ?= $(shell uname -s)

EXPORTED_SYMBOLS_FILE = lib$(NAME).symexport

VERSION_SCRIPT = --version-script

DYLIBSUFFIX = so
ifeq ($(TARGET_OS),Darwin)
	DYLIBSUFFIX = dylib
	PROJECT_LIBS            += $(DARWIN_LIBS)
	PROJECT_PKG_CONFIG_LIBS += $(DARWIN_PKG_CONFIG_LIBS)
	PROJECT_OBJS            += $(DARWIN_OBJS)
	VERSION_SCRIPT = -exported_symbols_list
else
ifeq ($(TARGET_OS),Android)
	PROJECT_LIBS            += $(ANDROID_LIBS)
	PROJECT_PKG_CONFIG_LIBS += $(ANDROID_PKG_CONFIG_LIBS)
	PROJECT_OBJS            += $(ANDROID_OBJS)
else
ifeq ($(TARGET_OS),MinGW-w64)
	DYLIBSUFFIX = dll
endif # mingw
endif # android
endif # darwin

ifeq ($(SHARED),yes)
	LIBSUFFIX = $(DYLIBSUFFIX)
else
	LIBSUFFIX = a
endif

LIBNAME = lib$(NAME).$(LIBSUFFIX)
PCNAME  = lib$(NAME).pc

OBJS += $(NAME).o $(PROJECT_OBJS)

CPPFLAGS += -MMD -MP

CFLAGS += -Wall -O2 -Werror=missing-prototypes -fPIC
ifeq ($(DEBUG),yes)
	CFLAGS += -g
endif
ifeq ($(TRACE),yes)
	CFLAGS += -DENABLE_DBG=1
endif
CFLAGS := $(shell $(PKG_CONFIG) --cflags $(PROJECT_PKG_CONFIG_LIBS)) $(CFLAGS)
LDLIBS := $(shell $(PKG_CONFIG) --libs   $(PROJECT_PKG_CONFIG_LIBS)) $(LDLIBS) $(PROJECT_LIBS)

PROGOBJS = player.o
TESTPROG = test-prog
TESTOBJS = $(TESTPROG).o

ALLOBJS = $(OBJS) $(PROGOBJS) $(TESTOBJS)
ALLDEPS = $(ALLOBJS:.o=.d)

$(LIBNAME): LDFLAGS += -Wl,$(VERSION_SCRIPT),$(EXPORTED_SYMBOLS_FILE)
$(LIBNAME): $(EXPORTED_SYMBOLS_FILE) $(OBJS)
ifeq ($(SHARED),yes)
	$(CC) $(LDFLAGS) $(OBJS) -shared -o $@ $(LDLIBS)
else
	$(AR) rcs $@ $(OBJS)
endif

$(EXPORTED_SYMBOLS_FILE):
ifeq ($(TARGET_OS),Darwin)
	$(shell printf "_$(NAME)_*\n" > $(EXPORTED_SYMBOLS_FILE))
else
	$(shell printf "LIBSXPLAYER {\n\tglobal: $(NAME)_*;\n\tlocal: *;\n};\n" > $(EXPORTED_SYMBOLS_FILE))
endif

PLAYER_LIBS =
ifeq ($(TARGET_OS),Darwin)
	PLAYER_LIBS += -framework OpenGL
endif

$(NAME): LDLIBS += $(shell $(PKG_CONFIG) --libs glfw3 glew) $(PLAYER_LIBS)
$(NAME): CFLAGS += $(shell $(PKG_CONFIG) --cflags glfw3 glew)
$(NAME): $(OBJS) $(PROGOBJS)

$(TESTPROG): $(OBJS) $(TESTOBJS)

all: $(LIBNAME) $(PCNAME) $(NAME)

clean:
	$(RM) lib$(NAME).so lib$(NAME).dylib lib$(NAME).a lib$(NAME).dll
	$(RM) $(NAME).hpp $(NAME) $(OBJS) $(ALLDEPS) $(TESTPROG) $(TESTOBJS) $(PROGOBJS) $(PCNAME) $(EXPORTED_SYMBOLS_FILE)
$(PCNAME): $(PCNAME).tpl
ifeq ($(SHARED),yes)
	sed -e "s#PREFIX#$(PREFIX)#;s#DEP_LIBS##;s#DEP_PRIVATE_LIBS#$(LDLIBS)#" $^ > $@
else
	sed -e "s#PREFIX#$(PREFIX)#;s#DEP_LIBS#$(LDLIBS)#;s#DEP_PRIVATE_LIBS##" $^ > $@
endif

# because fuck sanity
$(NAME).hpp: $(NAME).h
	@printf "#warning \"$(NAME) is a C library and C++ is not officially supported\"\nextern \"C\" {\n#include \"$(NAME).h\"\n}\n" > $(NAME).hpp

install: $(LIBNAME) $(PCNAME) $(NAME).hpp
	install -d $(DESTDIR)$(PREFIX)/lib
	install -d $(DESTDIR)$(PREFIX)/lib/pkgconfig
	install -d $(DESTDIR)$(PREFIX)/include
ifeq ($(TARGET_OS),MinGW-w64)
	install -m 644 $(LIBNAME) $(DESTDIR)$(PREFIX)/bin
endif
	install -m 644 $(LIBNAME) $(DESTDIR)$(PREFIX)/lib
	install -m 644 $(PCNAME) $(DESTDIR)$(PREFIX)/lib/pkgconfig
	install -m 644 $(NAME).h $(DESTDIR)$(PREFIX)/include/$(NAME).h
	install -m 644 $(NAME).hpp $(DESTDIR)$(PREFIX)/include/$(NAME).hpp

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/lib/$(LIBNAME)
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).h
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).hpp

test: $(TESTPROG)
	./$(TESTPROG) media.mkv image.jpg
testmem: $(TESTPROG)
	valgrind --leak-check=full --show-leak-kinds=all ./$(TESTPROG) media.mkv image.jpg

.PHONY: all test clean install uninstall player

-include $(ALLDEPS)
