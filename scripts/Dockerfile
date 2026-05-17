# Container for running Vivado on Apple Silicon (M1/M2/M3/M4) Macs.
# Uses linux/amd64 platform accelerated by Rosetta 2 via the Apple Virtualization Framework.
FROM --platform=linux/amd64 ubuntu:24.04

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install ALL packages in a single layer and clean up immediately to keep the
# image well under 8 GiB.  Package notes for Ubuntu 24.04:
#   - libtinfo5 / libncursesw5 are gone → replaced by libtinfo6 / libncursesw6
#     (backward-compat symlinks are created in the next step)
#   - libjpeg62-dev is gone → replaced by libjpeg-dev
#   - libgtk2.0-0 is now libgtk2.0-0t64 (64-bit time_t transition)
#   - firefox removed (large, not needed inside the container)
#   - libswt-gtk-4-jni removed (bundled inside Vivado 2025.x)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Core utilities
        ca-certificates curl gnupg sudo nano \
        # D-Bus and X11 infrastructure
        dbus dbus-x11 x11-utils xorg xvfb net-tools \
        # OpenGL / display
        libgl1-mesa-dri libglu1-mesa \
        # Lightweight desktop (LXDE) and supporting themes/tools
        lxde lxappearance lxterminal xterm \
        gtk2-engines-murrine gtk2-engines-pixbuf \
        gnome-themes-extra \
        # Audio support
        alsa-utils \
        # Vivado build and runtime dependencies
        python3-pip python3-dev build-essential git \
        gcc-multilib g++ \
        ocl-icd-opencl-dev libjpeg-dev libc6-dev-i386 \
        graphviz make unzip \
        # ncurses / terminal libs (Ubuntu 24.04 names)
        libtinfo6 libncurses6 libncursesw6 \
        # GTK2 runtime required by Vivado GUI (t64 transition package in 24.04)
        libgtk2.0-0t64 \
        # Locale support (Vivado crashes without a proper locale)
        locales \
        # TigerVNC server for remote GUI access
        # tigervnc-tools is required explicitly — it provides vncpasswd in Ubuntu 24.04
        tigervnc-standalone-server tigervnc-xorg-extension tigervnc-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create backward-compatible symlinks so that Vivado binaries that reference
# the old .so.5 names still resolve correctly under Ubuntu 24.04.
RUN ln -sf /lib/x86_64-linux-gnu/libtinfo.so.6    /lib/x86_64-linux-gnu/libtinfo.so.5 && \
    ln -sf /lib/x86_64-linux-gnu/libncursesw.so.6 /lib/x86_64-linux-gnu/libncursesw.so.5

# Create user "user" with password "password".
# The password is intentionally weak — the VNC server only accepts connections
# from the macOS host (127.0.0.1 binding in the docker run command).
RUN useradd --create-home --shell /bin/bash --user-group --groups adm,sudo user && \
    echo "user:password" | chpasswd && \
    chown -R user:user /home/user

# Setup LXDE desktop configuration
RUN mkdir -p /home/user/.config/pcmanfm/LXDE/ && \
    if [ -f /usr/local/share/doro-lxde-wallpapers/desktop-items-0.conf ]; then \
        ln -sf /usr/local/share/doro-lxde-wallpapers/desktop-items-0.conf \
               /home/user/.config/pcmanfm/LXDE/; \
    fi && \
    # Disable lxpolkit to prevent authentication pop-ups on desktop start
    if [ -f /usr/bin/lxpolkit ]; then mv /usr/bin/lxpolkit /usr/bin/lxpolkit.bak; fi

# Setup TigerVNC
RUN sed -i 's/-iconic/-nowin/g' /etc/X11/Xtigervnc-session && \
    mkdir -p /home/user/.vnc && \
    echo "password" | vncpasswd -f > /vncpasswd && \
    chown user /vncpasswd && \
    chmod 600 /vncpasswd

# Generate locale — Vivado crashes at startup without en_US.UTF-8
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Cap Java heap at 4 GiB.
# Vivado and its installer are Java-based. Without a limit the JVM can
# claim far more than available RAM, causing OOM kills inside the container.
# JAVA_TOOL_OPTIONS is the portable, standard variable respected by all
# JVM implementations (Java 8+).
ENV JAVA_TOOL_OPTIONS="-Xmx4096m -Xms512m"

# LD_PRELOAD workaround for Vivado stability under Rosetta 2.
# - libudev / libselinux / libz: prevent crashes during synthesis
# - libgdk-x11-2.0: prevents GUI crashes on startup
# NOTE: libgdk moved to /usr/lib in Ubuntu 24.04 (libgtk2.0-0t64 package).
# de_start.sh resolves the exact path at runtime to handle any layout variation.
ENV LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libselinux.so.1 /lib/x86_64-linux-gnu/libz.so.1"

