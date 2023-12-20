FROM python:3.11-slim-bullseye

# This flag is important to output python logs correctly in docker!
ENV PYTHONUNBUFFERED 1
# Flag to optimize container size a bit by removing runtime python cache
ENV PYTHONDONTWRITEBYTECODE 1

# Install required packages
RUN apt-get update && \
    apt-get --fix-missing install -y --no-install-recommends \
        xrdp \
        xorgxrdp \
        xfce4 \
        xfce4-terminal \
        xfce4-goodies \
        dbus-x11 \
        sudo \
        locales \
        chromium \
        x11-xserver-utils \
        gnupg2 \
        cabextract \
        p7zip \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Install required packages for adding the WineHQ repository
RUN apt-get update && \
    apt-get --fix-missing install -y --no-install-recommends \
        wget \
        software-properties-common

# Add the WineHQ repository for Ubuntu 20.04 (Focal Fossa)
RUN dpkg --add-architecture i386 && \
    apt-add-repository -y 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main'

# Download and install the WineHQ repository key
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key

# Install Wine 8.1.0 and Mono
RUN apt-get update && apt-get install -y \
    --install-recommends winehq-stable=8.1.0 \
    mono-devel

# Download and install winetricks manually
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Download and install Wine Mono
RUN wget https://dl.winehq.org/wine/wine-mono/8.1.0/wine-mono-8.1.0-x86.msi -P /tmp && \
    wine msiexec /i /tmp/wine-mono-8.1.0-x86.msi

# Cleanup
RUN rm /tmp/wine-mono-8.1.0-x86.msi


## Download and install winetricks manually
#RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
#    chmod +x winetricks && \
#    mv winetricks /usr/local/bin

# Use winetricks to install Microsoft Core Fonts in the Wine environment
RUN winetricks corefonts

RUN locale-gen en_US.UTF-8 && locale-gen ru_RU.UTF-8
ENV LANGUAGE ru_RU.UTF-8
ENV LANG en_US.UTF-8

COPY entrypoint.sh /usr/bin/entrypoint
RUN chmod +x /usr/bin/entrypoint

COPY ./Metatrader /home/Metatrader

# Add wineboot and start the wine server in the entrypoint script
RUN echo "wineboot && wineserver -w" >> /usr/bin/entrypoint

EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]
