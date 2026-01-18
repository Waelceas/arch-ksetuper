#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

if [[ $EUID -eq 0 ]]; then
  echo -e "${RED}󰚌 Bu script root olarak çalıştırılmamalı.${NC}"
  exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo -e "${RED}󰚌 Dağıtım tespit edilemedi!${NC}"
    exit 1
fi

clear
echo -e "${CYAN}${BOLD}"
echo "  █████╗ ██████╗  ██████╗██╗  ██╗    ██╗  ██╗███████╗███████╗████████╗██╗   ██╗██████╗ ███████╗██████╗ "
echo " ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║ ██╔╝██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗██╔════╝██╔══██╗"
echo " ███████║██████╔╝██║     ███████║    █████╔╝ ███████╗█████╗     ██║   ██║   ██║██████╔╝█████╗  ██████╔╝"
echo " ██╔══██║██╔══██╗██║     ██╔══██║    ██╔═██╗ ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗"
echo " ██║  ██║██║  ██║╚██████╗██║  ██║    ██║  ██╗███████║███████╗   ██║   ╚██████╔╝██║     ███████╗██║  ██║"
echo " ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝"
echo -e "                                     ${WHITE}v1.0 - Gelişmiş Kurulum Asistanı${NC}"
echo -e "${BLUE}================================================================================${NC}"
echo -e "${CYAN}➜ Sistem:${GREEN} $NAME${NC} | ${CYAN}➜ Kullanıcı:${GREEN} $USER${NC}"
echo -e "${BLUE}================================================================================${NC}"

LOGFILE="$HOME/ksetuper.log"
exec > >(tee -i "$LOGFILE")
exec 2>&1

multi_select() {
    echo -e "\n${BOLD}${PURPLE}󱓞 $1${NC}" >&2
    echo -e "${WHITE}$2${NC}" >&2
    read -p "  ╰─➤ Seçim: " choices
    echo "$choices"
}

has_choice() {
    local input="$1"
    local target="$2"
    [[ -z "$input" ]] && return 1
    [[ " $input " =~ [,\ ]"$target"[,\ ] ]] || [[ "$input" == "$target" ]] || [[ "$input" == *,"$target",* ]] || [[ "$input" == "$target",* ]] || [[ "$input" == *,"$target" ]]
}

is_installed() {
    pacman -Qq "$1" &> /dev/null
}

install_aur_helper() {
    local helper=$1
    if is_installed "$helper"; then
        echo -e "${GREEN}✔ $helper zaten mevcut.${NC}"
        return
    fi
    echo -e "${YELLOW}⚙ $helper derleniyor...${NC}"
    sudo pacman -S --needed base-devel git --noconfirm
    git clone https://aur.archlinux.org/$helper.git
    cd $helper && makepkg -si --noconfirm
    cd .. && rm -rf $helper
}

install_pkg() {
    local pkgs="$1"
    local manager="$2"
    [[ -z "${pkgs// }" ]] && return

    echo -e "${BLUE} Kuruluyor:${NC} ${WHITE}$pkgs${NC}"
    case $manager in
        yay)  yay -S --noconfirm --needed $pkgs ;;
        paru) paru -S --noconfirm --needed $pkgs ;;
        *)    sudo pacman -S --noconfirm --needed $pkgs ;;
    esac
}

echo -e "${YELLOW}󰒓 [KATMAN 0] ➜ Çekirdek Optimizasyonu${NC}"
read -p "  󰄶 Paralel indirme (y/N): " para_ask
if [[ $para_ask == "y" ]]; then
    read -p "  󰄶 Kanal sayısı [5]: " para_count
    para_count=${para_count:-5}
    sudo sed -i "s/^[#]*ParallelDownloads = .*/ParallelDownloads = $para_count/" /etc/pacman.conf
fi

echo -e "\n${CYAN}󰻠 [DONANIM] ➜ İşlemci Mikro Kodları${NC}"
echo "  1) Intel"
echo "  2) AMD"
read -p "  ╰─➤ Seçim: " cpu_choice
[[ $cpu_choice == 1 ]] && install_pkg "intel-ucode" "pacman"
[[ $cpu_choice == 2 ]] && install_pkg "amd-ucode" "pacman"

echo -e "\n${YELLOW}󰇚 [ALTYAPI] ➜ AUR Bridge Kurulumu${NC}"
echo "  1) yay"
echo "  2) paru"
read -p "  ╰─➤ Seçim: " aur_setup_choice
case $aur_setup_choice in
    1) install_aur_helper "yay" ;;
    2) install_aur_helper "paru" ;;
esac

echo -e "\n${YELLOW}󰮔 [YÖNETİM] ➜ Birincil Paket Yöneticisi${NC}"
echo "  1) pacman"
echo "  2) yay"
echo "  3) paru"
read -p "  ╰─➤ Kullanılacak: " pm_choice
manager="pacman"
[[ $pm_choice == 2 ]] && manager="yay"
[[ $pm_choice == 3 ]] && manager="paru"

term_choice=$(multi_select "[KABUK] ➜ Terminal Emulator" "1: WezTerm, 2: Kitty, 3: Alacritty, 4: Konsole")
term_pkgs=""
has_choice "$term_choice" "1" && term_pkgs+=" wezterm"
has_choice "$term_choice" "2" && term_pkgs+=" kitty"
has_choice "$term_choice" "3" && term_pkgs+=" alacritty"
has_choice "$term_choice" "4" && term_pkgs+=" konsole"
install_pkg "$term_pkgs" "$manager"

shell_choice=$(multi_select "[KABUK] ➜ Shell Ortamı" "1: bash, 2: zsh, 3: fish")
shell_pkgs=""
has_choice "$shell_choice" "1" && shell_pkgs+=" bash"
has_choice "$shell_choice" "2" && shell_pkgs+=" zsh"
has_choice "$shell_choice" "3" && shell_pkgs+=" fish"
install_pkg "$shell_pkgs" "$manager"

browser_choice=$(multi_select "[WEB] ➜ İnternet Tarayıcıları" "1: Firefox, 2: Zen, 3: Floorp, 4: Brave, 5: LibreWolf, 6: Vivaldi")
browser_pkgs=""
has_choice "$browser_choice" "1" && browser_pkgs+=" firefox"
has_choice "$browser_choice" "2" && browser_pkgs+=" zen-browser-bin"
has_choice "$browser_choice" "3" && browser_pkgs+=" floorp-bin"
has_choice "$browser_choice" "4" && browser_pkgs+=" brave-bin"
has_choice "$browser_choice" "5" && browser_pkgs+=" librewolf-bin"
has_choice "$browser_choice" "6" && browser_pkgs+=" vivaldi"
install_pkg "$browser_pkgs" "$manager"

v_choice=$(multi_select "[MEDYA] ➜ Video & Render" "1: Minimal (mpv), 2: GUI (Celluloid), 3: Kodi")
v_pkgs=""
has_choice "$v_choice" "1" && v_pkgs+=" mpv yt-dlp ffmpeg"
has_choice "$v_choice" "2" && v_pkgs+=" celluloid haruna mpv"
has_choice "$v_choice" "3" && v_pkgs+=" kodi"
install_pkg "$v_pkgs" "$manager"

util_choice=$(multi_select "[ARAÇLAR] ➜ Arşiv & Dosya Manipülasyonu" "1: Temel (zip), 2: Gelişmiş (ImageMagick)")
util_pkgs=""
has_choice "$util_choice" "1" && util_pkgs+=" unzip zip p7zip unrar"
has_choice "$util_choice" "2" && util_pkgs+=" unzip zip p7zip unrar imagemagick exiftool"
install_pkg "$util_pkgs" "$manager"

a_choice=$(multi_select "[AUDİO] ➜ Müzik & Ses Prodüksiyonu" "1: CLI (ncmpcpp), 2: DeaDBeeF, 3: Audacity")
a_pkgs=""
has_choice "$a_choice" "1" && a_pkgs+=" mpd ncmpcpp"
has_choice "$a_choice" "2" && a_pkgs+=" deadbeef-git"
has_choice "$a_choice" "3" && a_pkgs+=" audacity"
install_pkg "$a_pkgs" "$manager"

d_choice=$(multi_select "[OFİS] ➜ Belge Yönetimi & PDF" "1: Zathura, 2: Evince, 3: LibreOffice")
d_pkgs=""
has_choice "$d_choice" "1" && d_pkgs+=" zathura zathura-pdf-mupdf"
has_choice "$d_choice" "2" && d_pkgs+=" evince"
has_choice "$d_choice" "3" && d_pkgs+=" libreoffice-fresh"
install_pkg "$d_pkgs" "$manager"

fm_choice=$(multi_select "[DOSYA] ➜ File Explorer Seçenekleri" "1: Thunar, 2: Dolphin, 3: Yazi")
fm_pkgs=""
has_choice "$fm_choice" "1" && fm_pkgs+=" thunar thunar-archive-plugin gvfs"
has_choice "$fm_choice" "2" && fm_pkgs+=" dolphin ffmpegthumbs"
has_choice "$fm_choice" "3" && fm_pkgs+=" yazi ffmpegthumbnailer jq"
install_pkg "$fm_pkgs" "$manager"

snap_choice=$(multi_select "[GÜVENLİK] ➜ Snapshot & Geri Yükleme" "1: Timeshift, 2: Snapper")
snap_pkgs=""
has_choice "$snap_choice" "1" && snap_pkgs+=" timeshift"
has_choice "$snap_choice" "2" && snap_pkgs+=" snapper btrfs-progs"
install_pkg "$snap_pkgs" "$manager"

sys_choice=$(multi_select "[SERVİS] ➜ Arka Plan Hizmetleri" "1: Bluetooth, 2: Firewall")
has_choice "$sys_choice" "1" && { install_pkg "bluez bluez-utils" "$manager"; sudo systemctl enable --now bluetooth; }
has_choice "$sys_choice" "2" && { install_pkg "ufw" "$manager"; sudo ufw enable; }

font_choice=$(multi_select "[ESTETİK] ➜ Tipografi & Font Setleri" "1: JetBrains Nerd, 2: Noto Emoji")
has_choice "$font_choice" "1" && install_pkg "ttf-jetbrains-mono-nerd" "$manager"
has_choice "$font_choice" "2" && install_pkg "noto-fonts-emoji" "$manager"

comm_choice=$(multi_select "[SOSYAL] ➜ İletişim Kanalları" "1: Discord, 2: Telegram, 3: Slack")
comm_pkgs=""
has_choice "$comm_choice" "1" && comm_pkgs+=" discord"
has_choice "$comm_choice" "2" && comm_pkgs+=" telegram-desktop"
has_choice "$comm_choice" "3" && comm_pkgs+=" slack-desktop"
install_pkg "$comm_pkgs" "$manager"

echo -e "\n${YELLOW}󰃢 [BİTİŞ] ➜ Sistem Hijyeni${NC}"
read -p "  󰄶 Önbellek temizlensin mi? (y/n): " clean_up
[[ $clean_up == "y" ]] && sudo pacman -Sc --noconfirm

echo -e "\n${BLUE}================================================================================${NC}"
echo -e "${GREEN}${BOLD} Arch KSetuper operasyonu başarıyla tamamladı!${NC}"
echo -e "${BLUE}================================================================================${NC}"
