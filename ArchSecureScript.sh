#!/usr/bin/env bash
# ArchSecureScript. Copyright (c) 2016, by Nicolas Briand & Anthony Thuilliez        #
################################################################################

# set -o xtrace #Enable it to trace what gets executed. Useful for developpement

echo "╔═╗┬─┐┌─┐┬ ┬╔═╗┌─┐┌─┐┬ ┬┬─┐┌─┐╔═╗┌─┐┬─┐┬┌─┐┌┬┐"
echo "╠═╣├┬┘│  ├─┤╚═╗├┤ │  │ │├┬┘├┤ ╚═╗│  ├┬┘│├─┘ │ "
echo "╩ ╩┴└─└─┘┴ ┴╚═╝└─┘└─┘└─┘┴└─└─┘╚═╝└─┘┴└─┴┴   ┴ "

__editor="Nicolas Briand, Anthony Thuilliez, Daniele Pedone"
__version="1.0.13"

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__root="$(cd "$(dirname "${__dir}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

# Set magic global variables for installation process
DNAME="lvm"
DGROUP="arch"
LANG="it_IT.UTF-8"
KEYMAP="it"
CONTINENT="Europe"
CITY="Rome"

echo "ArchSecureScript (ASS) installer. by ${__editor} version ${__version}."
echo ""

# ### Debugging stuff begin here ### #
set -o errexit #script exit if failure occure #We call allow failure by adding || true after commands

#set -o nounset #TODO try script with this

function _fmt (){
  #Initialize color variables
  local color_ok="\x1b[32m"
  local color_bad="\x1b[31m"
  local color_reset="\x1b[0m"

  #color_bad (red) is the default color.
  local color="${color_bad}"
  #Debug, info and notice will be in green
  if [ "${1}" = "debug" ] || [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then
    color="${color_ok}"
  fi

  echo -e "${color}$(printf "[%9s]" ${1})${color_reset}";
}

#Exemple : emergency is a function. This function call the logger command.
#This command will have __base (__base return the script's name) as prefix.
#The option -s will output the message to STDERR and the syslog
#Then, the function will echo "emergency" in red color define in _fmt function
#Followed by each arguments you type.
#So, emergency "foobar" will return :
#[time information] [ emergency] foobar <-- each words you type
#       ^               ^
#       |               |
#  logger function   _fmt function
#Then we redirectect stdout(1) to stderr(2)
#Or if the function file, we return true ( || true)
#For the emergency case, we exit the script with error code 1
function emergency () { logger -s -t ${__base} $(echo "$(_fmt emergency) ${@}") 1>&2 || true; exit 1; }
function alert ()     { logger -s -t ${__base} $(echo "$(_fmt alert) ${@}") >&2 || true; }
function critical ()  { logger -s -t ${__base} $(echo "$(_fmt critical) ${@}") 1>&2 || true; }
function error ()     { logger -s -t ${__base} $(echo "$(_fmt error) ${@}") 1>&2 || true; }
function warning ()   { logger -s -t ${__base} $(echo "$(_fmt warning) ${@}") 1>&2 || true; }
function notice ()    { logger -s -t ${__base} $(echo "$(_fmt notice) ${@}") 1>&2 || true; }
function info ()      { logger -s -t ${__base} $(echo "$(_fmt info) ${@}") || true; }
function debug ()     { logger -s -t ${__base} $(echo "$(_fmt debug) ${@}") 1>&2 || true; }

# ### End of debugging stuff ### #

function setup(){
  info "Installation launched !"

  parted -l #List partition to help user to choose
  notice "You can see your hard drives and partitions above"
  read -p "Select disk where install Archlinux : " -i "/dev/sd" -e DISK # -i "/dev/sd" allow autocompletion with tabulation

  while [[ -z $YN ]]; do
    read -p "Type a password for the encryption : " -s PASSWORD
    echo ""
    read -p "Retype a password for the encryption : " -s PASSWORD_RETYPE
    echo ""
    if [[ "$PASSWORD" = "$PASSWORD_RETYPE" ]]; then
      local YN=true
    else
      echo ""
      echo "Password mismatch. Try again."
      echo ""
    fi
  done
  unset YN
  unset PASSWORD_RETYPE

  read -p "Type a hostname for computers name : " -e HOSTNAME
  read -p "Type a username for basic user : " -e USERNAME

  while [[ -z $YN ]]; do
    read -p "Type a password for the user : " -s USER_PASSWORD
    echo ""
    read -p "Retype a password for the user : " -s USER_PASSWORD_RETYPE
    echo ""
    if [[ "$USER_PASSWORD" = "$USER_PASSWORD_RETYPE" ]]; then
      local YN=true
    else
      echo ""
      echo "Password mismatch. Try again."
      echo ""
    fi
  done
  unset YN
  unset USER_PASSWORD_RETYPE

  while [[ -z ${YN} ]]; do
    read -p "UEFI mode ? [Y/N] " response
    case $response in
        Y|YES|yes|y|Yes)
          local YN=true
          UEFI=true
            ;;
        N|NO|no|n|No)
          local YN=true
          UEFI=false
          ;;
        *)
          echo "Mmmmh... don't understand, only Y or N are authorized. And I'm sure you can do it."
            ;;
    esac
  done
  unset YN
  unset response

  while [[ -z ${YN} ]]; do
    read -p "Which environment do you want : [kde,gnome,lxde,xfce,cinnamon,budgie,mate,deepin] " response
    case $response in
        kde|Kde|KDE)
          local YN=true
          GRAPH_ENV="kde"
            ;;
        gnome|Gnome|GNOME)
          local YN=true
          GRAPH_ENV="gnome"
          ;;
        lxde|Lxde|LXDE)
          local YN=true
          GRAPH_ENV="lxde"
          ;;
        xfce|Xfce|XFCE)
          local YN=true
          GRAPH_ENV="xfce"
          ;;
        cinnamon|Cinnamon|CINNAMON)
          local YN=true
          GRAPH_ENV="cinnamon"
          ;;
        budgie|Budgie|BUDGIE)
          local YN=true
          GRAPH_ENV="budgie"
          ;;
        mate|Mate|MATE)
          local YN=true
          GRAPH_ENV="mate"
          ;;
        deepin|Deepin|DEEPIN)
          local YN=true
          GRAPH_ENV="deepin"
          ;;
        *)
          echo "Mmmmh... don't understand, only Y or N are authorized. And I'm sure you can do it."
            ;;
    esac
  done
  unset YN
  unset response

  #Print informations and ask for confirmation
  info "Disk: ${DISK}"
  info "Username: ${USERNAME}"
  info "Hostname: ${HOSTNAME}"
  info "Graphic environment: ${GRAPH_ENV}"
  info "UEFI: ${UEFI}"
  if [[ -e ${DISK} ]]; then #Test if the choosen disk exist
    while [ -z ${YN} ]
    do
      read -p "$(warning Are you okay with this? It will erase EVERYTHING in this disk and you will not be able to change the password. [y/N]) " response
      case $response in
          [yY][eE][sS][oO]|[yY])
            local YN=true

            info "Disk is formatting..."
            format_disk
            info "Disk formatted sucessful"

            info "Creating partition"
            create_partitions
            info "Partition created sucessful"

            info "Preparing disk"
            prepare_disk
            info "Disk prepared sucessful"

            info "Preparing LVM"
            prepare_lvm
            info "LVM prepared"

            info "Mounting FileSystem"
            mount_fs
            info "FileSystem mounted sucessful"

            info "Preparing boot"
            prepare_boot
            info "Boot prepared sucessful"

            info "Installing base"
            install_base
            info "Base installed sucessful"

            info "Generate fstab"
            generate_fstab
            info "fstab generated sucessful"

            info 'Chrooting into installed system to continue setup...'
            prepare_chroot
              ;;
          [nN])
            local YN=true
            info "Okay... Good Bye !"
            exit 0
            ;;
          *)
            echo "Mmmmh... don't understand, only Y or N are authorized. And I'm sure you can do it. "
              ;;
      esac
    done
  else
    echo "Selected disk does not exist"
  fi
}

#Partitions creating functions
function format_disk(){
  #This function format the disk with best practices
  #It takes a long time, so you can disable it for time saving
  echo "Format disk desactivate, not good !"

  #Uncomment line below to enable formatting
  # shred --verbose --random-source=/dev/urandom --iterations=3 ${DISK}
}

function create_partitions(){
  #It makes 2 partitions :
  #boot of 400Mb for /boot
  #home of 100% free for /home
  # +-----------------------------------------------------------------------+ +----------------+
  # | Logical volume1       | Logical volume2       | Logical volume3       | |                |
  # |/dev/storage/swapvol   |/dev/storage/rootvol   |/dev/storage/homevol   | | Boot partition |
  # |_ _ _ _ _ _ _ _ _ _ _ _|_ _ _ _ _ _ _ _ _ _ _ _|_ _ _ _ _ _ _ _ _ _ _ _| | (may be on     |
  # |                                                                       | | other device)  |
  # |                        LUKS encrypted partition                       | |                |
  # |                          /dev/sdaX                                    | | /dev/sdbY      |
  # +-----------------------------------------------------------------------+ +----------------+
  if [[ ${UEFI} == true ]]; then
    parted -s ${DISK}\
    mklabel gpt \
    mkpart primary fat32 4096s 512MB \
    mkpart primary ext4 512MB 100% \
    set 1 boot on \
    set 2 lvm on \
    name 1 boot \
    name 2 root_lvm || emergency "Something went wrong with partitioning. You can investigate. Exit 1. "
  elif [[ ${UEFI} == false ]]; then
    parted -s ${DISK}\
    mklabel msdos \
    mkpart primary ext4 1MB 200MB \
    mkpart primary ext4 200MB 100% \
    set 1 boot on \
    set 2 lvm on
  fi
}

function prepare_disk(){
    # Encrypt the LVM using LUKS format with cipher aes-xts-plain64
    echo "${PASSWORD}" | cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat ${DISK}2
    # Open the lvm, the decrypted container is now available at /dev/mapper/lvm.
    echo "${PASSWORD}" | cryptsetup luksOpen ${DISK}2 ${DNAME}
}

function prepare_lvm(){
  pvcreate /dev/mapper/${DNAME} #Create a physical volume on top of the opened LUKS container
  vgcreate ${DGROUP} /dev/mapper/${DNAME} #Create the volume group named MyStorage, adding the previously created physical volume to it

  #Create all logical volumes on the volume group
  lvcreate -l 3%VG ${DGROUP} -n swap
  lvcreate -l 25%VG ${DGROUP} -n root
  lvcreate -l +100%FREE ${DGROUP} -n home

  #Format filesystems on each logical volume
  mkfs.ext4 /dev/mapper/${DGROUP}-root
  mkfs.ext4 /dev/mapper/${DGROUP}-home
  mkswap /dev/mapper/${DGROUP}-swap
}

function mount_fs(){
  #Mount each filesystems
  mount /dev/${DGROUP}/root /mnt
  mkdir /mnt/home
  mount /dev/${DGROUP}/home /mnt/home
  swapon /dev/${DGROUP}/swap
}

function prepare_boot(){
  if [[ ${UEFI} == true ]]; then
    mkfs.fat -F32 ${DISK}1
    mkdir -p /mnt/boot/efi
    mount ${DISK}1 /mnt/boot/efi
  elif [[ ${UEFI} == false ]]; then
    #Convert /boot to ext2 format which is the standard for MBR boot partition
    mkfs.ext2 ${DISK}1
    mkdir /mnt/boot
    mount ${DISK}1 /mnt/boot
  fi
}

function install_base(){
  #Install the basic system (GNU)
  #You need to add base-devel for some stuff like Yaourt

  if [[ ${UEFI} == true ]]; then
    pacstrap /mnt base base-devel grub xdg-user-dirs git efibootmgr
  elif [[ ${UEFI} == false ]]; then
    pacstrap /mnt base base-devel grub xdg-user-dirs git
  fi
}

function generate_fstab(){
  #It generate the fstab to be enable to boot
  genfstab -U -p /mnt >> /mnt/etc/fstab
}

function prepare_chroot(){
  #Chrooting in the new system
  info "Preparing chroot"
  cp $0 /mnt/ArchSecure.sh
  arch-chroot /mnt ./ArchSecure.sh --configure ${DISK} ${PASSWORD} ${HOSTNAME} ${USERNAME} ${USER_PASSWORD} ${GRAPH_ENV} ${UEFI}
}

function configure(){
  #Here we are in chroot
  local DISK=$2
  local PASSWORD=$3
  local HOSTNAME=$4
  local USERNAME=$5
  local USER_PASSWORD=$6
  local GRAPH_ENV=$7
  local UEFI=$8

  echo "Prepare bootloader"
  local CRYPTDEVICE="$(blkid -s UUID -o value ${DISK}2)" #Get UUID of the encrypted device
  install_bootloader ${DISK} ${CRYPTDEVICE} ${PASSWORD}

  echo "Change base settings"
  change_base_settings

  echo "Change Hostname"
  change_hostname ${HOSTNAME}

  echo "Create basic user"
  create_basic_user ${USERNAME} ${USER_PASSWORD}

  echo "Disable root login"
  disable_root

  echo "Adding sudo to wheel group"
  install_sudo

  echo "Install network manager"
  install_network

  echo "Install yaourt"
  install_yaourt

  echo "Install xorg"
  install_xorg

  echo "Install graphic drivers"
  install_graphic_drivers

  echo "Install display manager"
  install_display_manager

  echo "Install graphic environment"
  install_graphic_environment ${GRAPH_ENV} ${USERNAME}

  echo "Clean up installation"
  clean_desktop
}

function install_bootloader(){
  local DISK=$1
  local CRYPTDEVICE=$2
  local PASSWORD=$3

  #Enable lvm2-lvmetad which is a requierement to boot on encrypted lvm
  systemctl enable lvm2-lvmetad.service

  #Install grub on disk
  if [[ ${UEFI} == true ]]; then
    #In order for GRUB to open the LUKS partition without having the user enter his passphrase twice, we will use a keyfile
    dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
    chmod 000 /crypto_keyfile.bin
    echo "${PASSWORD}" | cryptsetup luksAddKey ${DISK}2 /crypto_keyfile.bin

    sed -i 's|base udev|base udev encrypt lvm2|g' /etc/mkinitcpio.conf
    sed -i 's|FILES="|FILES="/crypto_keyfile.bin|g' /etc/mkinitcpio.conf

    #Edit grub config to inform it where is the encrypted device and the root device
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
    sed -i "s|GRUB_CMDLINE_LINUX\=\"|GRUB_CMDLINE_LINUX\=\"cryptdevice=/dev/disk/by-uuid/${CRYPTDEVICE}:${DNAME} root=/dev/mapper/${DGROUP}-root|g" /etc/default/grub

    mkinitcpio -p linux
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --removable --recheck
  elif [[ ${UEFI} == false ]]; then
    grub-install --target=i386-pc ${DISK}
    #Edit mkinitcpio configuration to add encrypt and lvm2 module to HOOKS
    sed -i 's|base udev|base udev encrypt lvm2|g' /etc/mkinitcpio.conf

    #Edit grub config to inform it where is the encrypted device and the root device
    sed -i "s|GRUB_CMDLINE_LINUX\=\"|GRUB_CMDLINE_LINUX\=\"cryptdevice=UUID=${CRYPTDEVICE}:${DGROUP} root=/dev/mapper/${DGROUP}-root|g" /etc/default/grub

    #mkinitcpio will generate initramfs-linux.img and initramfs-linux-fallback.img to be able to boot
    mkinitcpio -p linux

    #Make the grub configuration
    grub-mkconfig -o /boot/grub/grub.cfg
  fi
}

function change_base_settings(){
    echo "Exporting timezone"
    export LANG=${LANG}
    sed -i "s|#${LANG}|${LANG}|g" /etc/locale.gen
    locale-gen
    echo "LANG=${LANG}" > /etc/locale.conf
    echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
    ln -s /usr/share/zoneinfo/${CONTINENT}/${CITY} /etc/localtime
}

function change_hostname(){
    local HOSTNAME=$1;
    echo "${HOSTNAME}" > /etc/hostname #Set up the new hostname
    export HOSTNAME=${HOSTNAME} #Export the hostname for the current session.
}

function create_basic_user(){
  local USERNAME=$1
  local PASSWORD=$2
  useradd -m -g users -G wheel,games,power,optical,storage,disk,scanner,lp,sys,audio,video,network,http,ftp,mail -s /bin/bash ${USERNAME} #Add a basic user
  sleep 1
  echo -en "${PASSWORD}\n${PASSWORD}" | passwd "${USERNAME}" #Change the password of the user

  #Create base folder like Document, Pictures, Desktop...etc
  su ${USERNAME} -c "xdg-user-dirs-update"
}

function disable_root(){
  passwd -l root
}

function install_sudo(){
  pacman -S sudo --noconfirm
  #Allow members of group wheel the sudo access
  sed -i 's|# %wheel ALL=(ALL) ALL|%wheel ALL=(ALL) ALL|g' /etc/sudoers
}

function install_network(){
  pacman -Sy dhclient wicd wicd-gtk --noconfirm
  systemctl enable wicd
}

function install_yaourt(){
  echo "" >> /etc/pacman.conf
  echo "[archlinuxfr]" >> /etc/pacman.conf
  echo "SigLevel = Never" >> /etc/pacman.conf
  echo "Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf
  pacman -Sy yaourt --noconfirm
}

function install_xorg(){
  pacman -Syu xorg-server xorg-xinit xorg-server-utils xorg-twm xorg-xclock xterm --noconfirm
}

function install_graphic_drivers(){
    pacman -Syu xf86-video-vesa xf86-video-nouveau xf86-video-intel xf86-video-amdgpu --noconfirm
}

function install_display_manager(){
    pacman -S lxdm --noconfirm
    systemctl enable lxdm
}

function install_graphic_environment(){
  local GRAPH_ENV=$1
  local USERNAME=$2

  #Install the graphic environment
  if [[ ${GRAPH_ENV} == "kde" ]]; then
    change_dmrc ${USERNAME} "plasma"
    pacman -Syu plasma kde-applications kde-gtk-config --noconfirm
  elif [[ ${GRAPH_ENV} == "gnome" ]]; then
    change_dmrc ${USERNAME} "gnome"
    pacman -Syu gnome gnome-extra --noconfirm
  elif [[ ${GRAPH_ENV} == "lxde" ]]; then
    change_dmrc ${USERNAME} "lxde"
    pacman -S lxde --noconfirm
  elif [[ ${GRAPH_ENV} == "xfce" ]]; then
    change_dmrc ${USERNAME} "xfce"
    pacman -Syu xfce4 xfce4-goodies --noconfirm
  elif [[ ${GRAPH_ENV} == "cinnamon" ]]; then
    change_dmrc ${USERNAME} "cinnamon"
    pacman -Syu cinnamon nemo-fileroller --noconfirm
  elif [[ ${GRAPH_ENV} == "budgie" ]]; then
    change_dmrc ${USERNAME} "budgie-desktop"
    pacman -Syu budgie-desktop --noconfirm
  elif [[ ${GRAPH_ENV} == "mate" ]]; then
    change_dmrc ${USERNAME} "mate"
    pacman -Syu mate mate-extra --noconfirm
  elif [[ ${GRAPH_ENV} == "deepin" ]]; then
    change_dmrc ${USERNAME} "deepin"
    pacman -Syu deepin deepin-extra --noconfirm
  fi
}

function change_dmrc(){
  local USERNAME=$1
  local DESKTOP_SESSION=$2

  # Change the Desktop session
  echo "[Desktop]" >> /home/${USERNAME}/.dmrc
  echo "Session=${DESKTOP_SESSION}" >> /home/${USERNAME}/.dmrc
  echo "Language=${LANG}" >> /home/${USERNAME}/.dmrc

  chmod +x /home/${USERNAME}/.dmrc
  chown ${USERNAME}:users /home/${USERNAME}/.dmrc
}

function clean_desktop(){
  echo "Deleting script"
  rm /$0
  echo "Archlinux installed sucessful, thanks to use this script ! :)"
}

function help(){
  echo "usage: $0 [COMMAND]"
  echo ""
  echo "Install a secure Archlinux."
  echo ""
  echo "Commands:"
  echo "-i / --install       Install a secure Archlinux"
  echo "-v /--version        Print version of ArchSecure"
  echo "-h /--help           Print this help"
  exit 0
}

#Arguments parsing
case "$1" in
    -i|--install) setup;;
    -v|--version) echo "ArchSecureScript version ${__version}" && exit 0;;
    -c|--configure) configure $1 $2 $3 $4 $5 $6 $7 $8;;
    -h|--help) help;;
     *) echo >&2 \
     "usage: $0 [--install]"
    exit 1;;
    *)  echo "usage: $0 [--install]";;	# terminate while loop
esac
shift

#Delete the script
function cleanup_before_exit () {
  exit
  swapoff /dev/${DGROUP}/swap
  umount -R /mnt || true
  cryptsetup luksClose ${DNAME}
  info "Cleaning up. Done"
  # reboot
}
#It will be launch each time the script exit. For any reason.
#Now, we can handle what's appening when the script exiting
#For each EXIT status, it will launch the cleanup_before_exit function
trap cleanup_before_exit EXIT

exit 0
