#
# Makefile for building xvcd
#
#
# Default options: USE_ASYNC and USE_LIBFTDI1
#
#
# libftdi1 is a newer version of the libftdi library and is the
# default library to build against. However, if you want to build
# against the older libftdi library, run make with the USE_LIBFTDI=0
# argument, like:
#
#    make USE_LIBFTDI=0
#
# If want to build with the synchronous ftdi_write function, which may
# make JTAG accesses really, really slow, use the USE_SYNC=0 argument:
#
#    make USE_SYNC=0
#
# Both options can be combined, if desired:
#
#    make USE_SYNC=0 USE_LIBFTDI=0
#
#
# If desire to change the USB Latency Timer value from the default
# defined in io_ftdi.c, can do so by supplying it on the make command
# line as seen below where the latency timer is being set to 6 ms. A
# lower number may make the JTAG programming finish quicker but could
# have a determental impact on the host system as it has to also
# service the other USB devices. In some cases, the host system may
# not be able to handle the default value and you may desire to
# increase this value.
#
#    make LATENCY_TIMER=6
#


O ?= .
OBJ ?= $(O)/obj

# It doesn't compile with recent versions of libftdi if the last flag is omitted.
BUILD_FLAGS=-Werror -Wall -Os -Wno-deprecated

# Can change LATENCY_TIMER value by including it on the make command as: LATENCY_TIMER=12
ifdef LATENCY_TIMER
   LATENCY=-DLATENCY_TIMER=$(LATENCY_TIMER)
else
   LATENCY=
endif


# Want USE_ASYNC to be the default
ifdef USE_SYNC
   SYNC=-UUSE_ASYNC
else
   SYNC=-DUSE_ASYNC
endif

# Added the include path of libftdi and libusb on macOS (using homebrew)
# Added the libraries/frameworks libusb links to dynamically
# Want libftdi1 to be the default
ifdef USE_LIBFTDI
   CFLAGS=$(BUILD_FLAGS) $(LATENCY) $(SYNC) -UUSE_LIBFTDI1 -I/opt/homebrew/include
   LDFLAGS=$(BUILD_FLAGS) -framework IOKit -framework CoreFoundation -framework Security
else
   CFLAGS=$(BUILD_FLAGS) $(LATENCY) $(SYNC) -DUSE_LIBFTDI1 -I/opt/homebrew/include
   LDFLAGS=$(BUILD_FLAGS) -framework IOKit -framework CoreFoundation -framework Security
endif

all: $(O) $(O)/xvcd

.PHONY: $(O) $(OBJ)

$(O):
	mkdir -p $(O)

$(OBJ):
	mkdir -p $(OBJ)

# Added libftdi and libusb to be statically linked to the xvcd executable
# Requires homebrew
$(O)/xvcd: $(OBJ)/io_ftdi.o $(OBJ)/xvcd.o
	$(CC) -o $@ $^ $(LDFLAGS) /opt/homebrew/opt/libftdi/lib/libftdi1.a /opt/homebrew/opt/libusb/lib/libusb-1.0.a

$(OBJ)/%.o: %.c $(OBJ) io_ftdi.h
	$(CC) -c $< -o $@ $(CFLAGS)
