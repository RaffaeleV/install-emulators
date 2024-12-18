#!/bin/bash

set -e
clear

# Set some variables
RPI_VERS=4             # Raspberry version (4 or 5)
VICE_VERS=3.7.1        # VICE version
AMI_VERS=5.7.4         # Amiberry version
USER_N=pi              # Username
USER_PWD=raspberry     # Password

error_exit() {
    echo "Error on line $1. Exiting script."
    exit 1
}
trap 'error_exit $LINENO' ERR


# Step 0: Message Before Start
echo "========================================================"
echo "Emulators installation!"
echo "To copy files from your Windows machine using this address: \\\\$(hostname -I | cut -d' ' -f1)\\share"
echo "Login credentials: Username: ${USER_N} | Password: ${USER_PWD}"
echo "========================================================"
read -p "Press any key to start..." -n1 -s

echo

# Step 1: Update system
echo "Updating system..."
sudo apt update -y > /dev/null 2>&1 || error_exit $LINENO
sudo apt upgrade -y > /dev/null 2>&1 || error_exit $LINENO

# Step 2: Create the menu.sh file
cat << 'EOF' > ~/menu.sh
#!/bin/bash
# Function to display the IP address of the machine
get_ip_address() {
   # Use the 'hostname' command to get the local IP address
   local_ip=$(hostname -I | cut -d' ' -f1)
   echo "IP: $local_ip"
}

# Function to display the Retro Emulator menu
show_menu() {
    clear
    echo "-------------------"
    echo "Retro Emulator Menu"
    get_ip_address
    echo "-------------------"
    echo "1 - Atari 2600"
    echo "2 - ZX Spectrum"
    echo "3 - Vic 20"
    echo "4 - Commodore 64"
    echo "5 - Amiga"
    echo "-------------------"
    echo "6 - Exit"
    echo "-------------------"
}

# Loop to continuously display the menu
while true; do
    show_menu
    read -p "Enter your choice: " choice

    case $choice in
        1) echo "Launching Atari 2600 emulator..." && cd ~/Atari && stella ;;
        2) echo "Launching ZX Spectrum emulator..." && cd ~/ZXSpectrum && fuse-sdl --full-screen --graphic-filter tv4x --pal-tv2x ;;
        3) echo "Launching Vic 20 emulator..." && cd ~/C64 && ~/${VICE_VERS}/bin/xvic ;;
        4) echo "Launching Commodore 64 emulator..." && cd ~/C64 && ~/${VICE_VERS}/bin/x64 ;;
        5) echo "Starting Amiga emulator..." && cd ~/amiberry && ~/amiberry/amiberry ;;
        6) echo "Goodbye!" && exit 0 ;;
        *) echo "Invalid choice. Please select a valid option." ;;
    esac
done
EOF

# Step 3: Make the script executable
chmod +x ~/menu.sh > /dev/null 2>&1 || error_exit $LINENO

# Step 4: Enable autologin for pi user
echo "Enabling autologin for user ${USER_N}..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d || error_exit $LINENO
cat << EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null 2>&1
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${USER_N} --noclear %I \$TERM
EOF
sudo systemctl daemon-reload > /dev/null 2>&1 || error_exit $LINENO
sudo systemctl restart getty@tty1 > /dev/null 2>&1 || error_exit $LINENO

# Step 5: Append menu.sh to .bashrc for autostart
echo "~/menu.sh" >> ~/.bashrc > /dev/null 2>&1 || error_exit $LINENO

# Step 7: Install Amiberry
echo "Downloading and installing Amiberry..."
sudo apt install -y \
  cmake \
  libsdl2-2.0-0 libsdl2-ttf-2.0-0 libsdl2-image-2.0-0 \
  flac mpg123 libmpeg2-4 libserialport0 libportmidi0 \
  mesa-utils mesa-vulkan-drivers \
  libegl-mesa0 raspi-gpio libgl1-mesa-dri libgl1-mesa-glx libgles2-mesa alsa-utils \
  libasound2 libasound2-dev libportaudio2 libasound2-plugins alsa-oss \
  samba samba-common-bin > /dev/null 2>&1 || error_exit $LINENO
sudo apt update -y > /dev/null 2>&1 || error_exit $LINENO
sudo apt install pulseaudio pavucontrol pulseaudio-utils -y > /dev/null 2>&1 || error_exit $LINENO
systemctl --user enable pulseaudio > /dev/null 2>&1 || error_exit $LINENO
systemctl --user start pulseaudio > /dev/null 2>&1 || error_exit $LINENO
wget https://github.com/BlitterStudio/amiberry/releases/download/v${AMI_VERS}/amiberry-v${AMI_VERS}-debian-bookworm-aarch64-rpi${RPI_VERS}.zip > /dev/null 2>&1 || error_exit $LINENO
unzip amiberry-v${AMI_VERS}-debian-bookworm-aarch64-rpi${RPI_VERS}.zip -d amiberry > /dev/null 2>&1 || error_exit $LINENO
sudo chmod +x amiberry/amiberry > /dev/null 2>&1 || error_exit $LINENO
rm ~/amiberry-v${AMI_VERS}-debian-bookworm-aarch64-rpi${RPI_VERS}.zip > /dev/null 2>&1 || error_exit $LINENO

# Download KSs, Amiberry default configuration and Workchbench disks
wget -q https://github.com/RaffaeleV/installAmiberry/raw/refs/heads/main/ks.zip > /dev/null 2>&1 || error_exit $LINENO
unzip -q -o ks.zip -d ~/amiberry/kickstarts > /dev/null 2>&1 || error_exit $LINENO
rm ks.zip > /dev/null 2>&1 || error_exit $LINENO
wget -q https://github.com/RaffaeleV/installAmiberry/raw/refs/heads/main/default.uae > /dev/null 2>&1 || error_exit $LINENO
sudo mv default.uae ~/amiberry/conf/default.uae > /dev/null 2>&1 || error_exit $LINENO
wget -q https://github.com/RaffaeleV/installAmiberry/raw/refs/heads/main/Workbench.v1.3.3.rev.34.34.Extras.adf > /dev/null 2>&1 || error_exit $LINENO
wget -q https://github.com/RaffaeleV/installAmiberry/raw/refs/heads/main/Workbench.v1.3.3.rev.34.34.adf > /dev/null 2>&1 || error_exit $LINENO
sudo mv Workbench.v1.3.3.rev.34.34.Extras.adf ~/amiberry/floppies/ > /dev/null 2>&1 || error_exit $LINENO
sudo mv Workbench.v1.3.3.rev.34.34.adf ~/amiberry/floppies/ > /dev/null 2>&1 || error_exit $LINENO

# Step 8: Create necessary directories
mkdir -p ~/C64 ~/ZXSpectrum ~/Atari > /dev/null 2>&1 || error_exit $LINENO
sudo chown -R ${USER_N}:${USER_N} ~/amiberry ~/C64 ~/ZXSpectrum ~/Atari > /dev/null 2>&1 || error_exit $LINENO

# Step 9: Install Other Emulators (ZX Spectrum and Atari)
echo "Installing ZX Spectrum and Atari emulators..."
sudo apt install fuse-emulator-sdl spectrum-roms fuse-emulator-utils stella -y > /dev/null 2>&1 || error_exit $LINENO

# Step 10: Install VICE (Commodore emulators)
echo "Installing VICE emulator..."
sudo apt update -y > /dev/null 2>&1 || error_exit $LINENO
sudo apt upgrade -y > /dev/null 2>&1 || error_exit $LINENO

sudo apt-get install -y lsb-release git dialog wget gcc g++ build-essential unzip xmlstarlet \
  python3-pyudev ca-certificates libasound2-dev libudev-dev libibus-1.0-dev libdbus-1-dev \
  fcitx-libs-dev libsndio-dev libx11-dev libxcursor-dev libxext-dev libxi-dev libxinerama-dev \
  libxkbcommon-dev libxrandr-dev libxss-dev libxt-dev libxv-dev libxxf86vm-dev libgl1-mesa-dev \
  libegl1-mesa-dev libgles2-mesa-dev libgl1-mesa-dev libglu1-mesa-dev libdrm-dev libgbm-dev libcurl4 libcurl4-openssl-dev \
  devscripts debhelper dh-autoreconf libraspberrypi-dev libpulse-dev > /dev/null 2>&1 || error_exit $LINENO

sudo apt install libmpg123-dev libpng-dev zlib1g-dev libasound2-dev libvorbis-dev libflac-dev \
 libpcap-dev automake bison flex subversion libjpeg-dev portaudio19-dev texinfo xa65 dos2unix \
 libsdl2-image-dev libsdl2-dev libsdl2-2.0-0 -y > /dev/null 2>&1 || error_exit $LINENO

mkdir ~/vice-src > /dev/null 2>&1 || error_exit $LINENO

wget -O vice-${VICE_VERS}.tar.gz https://sourceforge.net/projects/vice-emu/files/releases/vice-${VICE_VERS}.tar.gz/download > /dev/null 2>&1 || error_exit $LINENO
tar xvfz vice-${VICE_VERS}.tar.gz > /dev/null 2>&1 || error_exit $LINENO
cd vice-${VICE_VERS} > /dev/null 2>&1 || error_exit $LINENO
./autogen.sh > /dev/null 2>&1 || error_exit $LINENO
./configure --prefix=${HOME}/vice-${VICE_VERS} --enable-sdl2ui --without-oss --enable-ethernet \
 --disable-catweasel --without-pulse --enable-x64 --disable-pdf-docs --with-fastsid > /dev/null 2>&1 || error_exit $LINENO
 
make -j $(nproc) > /dev/null 2>&1 || error_exit $LINENO
make install > /dev/null 2>&1 || error_exit $LINENO

rm -rf ~/vice-src > /dev/null 2>&1 || error_exit $LINENO
rm ~/vice-${VICE_VERS}.tar.gz > /dev/null 2>&1 || error_exit $LINENO

# Step 11: Remove boot logo, bootscreen and initial messages
echo "Removing boot logo and boot messages..."
CMDLINE_FILE="/boot/firmware/cmdline.txt"
sudo sed -i 's/$/ logo.nologo quiet/' "$CMDLINE_FILE" > /dev/null 2>&1 || error_exit $LINENO
sudo sed -i '/^# disable_splash=1/ s/^#//' /boot/firmware/config.txt > /dev/null 2>&1 || error_exit $LINENO
sudo sed -i '/^disable_splash=1/ s/.*//' /boot/firmware/config.txt > /dev/null 2>&1 || error_exit $LINENO
echo "disable_splash=1" | sudo tee -a /boot/firmware/config.txt > /dev/null 2>&1 || error_exit $LINENO
sudo rm /etc/motd > /dev/null 2>&1 || error_exit $LINENO

# Insert custom splash-screen (Requires Plymouth)
# curl -O https://raw.githubusercontent.com/RaffaeleV/installAmiberry/refs/heads/main/splash.png > /dev/null 2>&1 || error_exit $LINENO
# sudo mv splash.png /usr/share/plymouth/themes/pix/splash.png > /dev/null 2>&1 || error_exit $LINENO
# sudo plymouth-set-default-theme -R pix > /dev/null 2>&1 || error_exit $LINENO

# Step 12: Configure SAMBA for home directory access
echo "Configuring SAMBA for Home directory..."
cat << 'EOF' | sudo tee /etc/samba/smb.conf > /dev/null 2>&1 || error_exit $LINENO
[global]
   workgroup = WORKGROUP
   security = user
   guest account = nobody
   map to guest = bad user

[share]
   path = /home/${USER_N}
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0755
EOF
sudo systemctl restart smbd > /dev/null 2>&1 || error_exit $LINENO
sudo smbpasswd -a ${USER_N} << EOF > /dev/null 2>&1
${USER_PWD}
${USER_PWD}
EOF

# Step 13: Reboot the Raspberry Pi
echo "Rebooting the Raspberry Pi..."
sudo reboot > /dev/null 2>&1 || error_exit $LINENO

