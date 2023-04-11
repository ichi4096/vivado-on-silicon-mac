# Container for running Vivado on M1/M2 macs
# though it should work equally on Intel macs
FROM --platform=linux/amd64 ubuntu
RUN apt update && apt upgrade -y

# install gui
RUN apt install -y --no-install-recommends --allow-unauthenticated \
dbus dbus-x11 x11-utils xorg alsa-utils mesa-utils net-tools \
libgl1-mesa-dri gtk2-engines lxappearance fonts-droid-fallback sudo firefox \
ubuntu-gnome-default-settings ca-certificates curl gnupg lxde arc-theme \
gtk2-engines-murrine gtk2-engines-pixbuf gnome-themes-standard nano xterm

# dependencies for Vivado
RUN apt install -y --no-install-recommends --allow-unauthenticated \
python3-pip python3-dev build-essential git gcc-multilib g++ \
ocl-icd-opencl-dev libjpeg62-dev libc6-dev-i386 graphviz make \
unzip libtinfo5 xvfb libncursesw5 locales

# create user "user" with password "pass"
RUN useradd --create-home --shell /bin/bash --user-group --groups adm,sudo user
RUN sh -c 'echo "user:pass" | chpasswd'
# RUN cp -r /root/{.config,.gtkrc-2.0,.asoundrc} /home/user
RUN chown -R user:user /home/user
RUN mkdir -p /home/user/.config/pcmanfm/LXDE/
RUN ln -sf /usr/local/share/doro-lxde-wallpapers/desktop-items-0.conf \
/home/user/.config/pcmanfm/LXDE/

# Set the locale, because Vivado crashes otherwise
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Without this, XQuartz doesn't display the window correctly
# if it doesn't work, add -Dsun.java2d.pmoffscreen=false, but this breaks something else
ENV JAVA_TOOL_OPTIONS -Dsun.java2d.xrender=false
ENV JAVA_OPTS -Dsun.java2d.xrender=false
ENV DISPLAY host.docker.internal:0

# Without this, Vivado will crash when synthesizing
ENV LD_PRELOAD /lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libselinux.so.1