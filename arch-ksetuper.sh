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
echo -e "                                     ${WHITE}v1.2 - Gelişmiş Kurulum Asistanı${NC}"
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

shell_choice=$(multi_select "[KABUK] ➜ Shell Ortamı" "1: bash, 2: zsh, 3: fish, 4: Dash, 5: Tcsh")
shell_pkgs=""
has_choice "$shell_choice" "1" && shell_pkgs+=" bash"
has_choice "$shell_choice" "2" && shell_pkgs+=" zsh"
has_choice "$shell_choice" "3" && shell_pkgs+=" fish"
has_choice "$shell_choice" "4" && shell_pkgs+=" dash"
has_choice "$shell_choice" "5" && shell_pkgs+=" tcsh"
install_pkg "$shell_pkgs" "$manager"


custom_shell_choice=$(multi_select "[ÖZELLEŞTİRME] ➜ Shell Framework & Prompt" "1: Oh My Zsh (Zsh gerektirir), 2: Oh My Posh (Evrensel Prompt), 3: Zsh Syntax Highlighting, 4: Zsh Autosuggestions")
zsh_addon_pkgs=""
has_choice "$custom_shell_choice" "3" && zsh_addon_pkgs+=" zsh-syntax-highlighting"
has_choice "$custom_shell_choice" "4" && zsh_addon_pkgs+=" zsh-autosuggestions"
[[ -n "$zsh_addon_pkgs" ]] && install_pkg "$zsh_addon_pkgs" "$manager"
if has_choice "$custom_shell_choice" "1"; then
    if is_installed "zsh"; then
        echo -e "${YELLOW}⚙ Oh My Zsh kuruluyor...${NC}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    else
        echo -e "${RED}󰚌 Oh My Zsh için önce Zsh kurmalısınız!${NC}"
    fi
fi
if has_choice "$custom_shell_choice" "2"; then
    echo -e "${YELLOW}⚙ Oh My Posh kuruluyor...${NC}"
    install_pkg "oh-my-posh" "$manager"
    echo -e "${BLUE}ℹ Oh My Posh'u aktif etmek için config dosyanıza init satırını eklemeyi unutmayın.${NC}"
fi

browser_choice=$(multi_select "[WEB] ➜ İnternet Tarayıcıları" "1: Firefox, 2:Firefox-esr, 3:Waterfox, 4:GNU IceCat, 5: Zen, 6: Floorp, 7: Brave, 8: LibreWolf, 9: Vivaldi")
browser_pkgs=""
has_choice "$browser_choice" "1" && browser_pkgs+=" firefox"
has_choice "$browser_choice" "2" && browser_pkgs+=" firefox-esr-bin"
has_choice "$browser_choice" "3" && browser_pkgs+=" waterfox-bin"
has_choice "$browser_choice" "4" && browser_pkgs+=" icecat-bin"
has_choice "$browser_choice" "5" && browser_pkgs+=" zen-browser-bin"
has_choice "$browser_choice" "6" && browser_pkgs+=" floorp-bin"
has_choice "$browser_choice" "7" && browser_pkgs+=" brave-bin"
has_choice "$browser_choice" "8" && browser_pkgs+=" librewolf-bin"
has_choice "$browser_choice" "9" && browser_pkgs+=" vivaldi-bin"
install_pkg "$browser_pkgs" "$manager"

img_choice=$(multi_select "[GÖRSEL] ➜ Medya Görüntüleyici" "1: Gwenview (KDE), 2: Loupe (Gnome), 3: feh (Hafif), 4: Ristretto 5: gimp 6: inkscape 7: xviewer 8: eog 9: gthumb 10: davinci-resolve 11: darktable 12: shotwell")
img_pkgs=""
has_choice "$img_choice" "1" && img_pkgs+=" gwenview"
has_choice "$img_choice" "2" && img_pkgs+=" loupe"
has_choice "$img_choice" "3" && img_pkgs+=" feh"
has_choice "$img_choice" "4" && img_pkgs+=" ristretto"
has_choice "$img_choice" "5" && img_pkgs+=" gimp"
has_choice "$img_choice" "6" && img_pkgs+=" inkscape-gimp"
has_choice "$img_choice" "7" && img_pkgs+=" xviewer"
has_choice "$img_choice" "8" && img_pkgs+=" eog"
has_choice "$img_choice" "9" && img_pkgs+=" gthumb"
has_choice "$img_choice" "10" && img_pkgs+=" davinci-resolve"
has_choice "$img_choice" "11" && img_pkgs+=" darktable"
has_choice "$img_choice" "12" && img_pkgs+=" shotwell"
install_pkg "$img_pkgs" "$manager"

v_choice=$(multi_select "[MEDYA] ➜ Video & Render" "1: mpv , 2: Celluloid, 3: Kodi, 4: Haruna, 5: OBS Studio 6: VLC 7: Kdenlive")
v_pkgs=""
has_choice "$v_choice" "1" && v_pkgs+=" mpv yt-dlp ffmpeg"
has_choice "$v_choice" "2" && v_pkgs+=" celluloid mpv"
has_choice "$v_choice" "3" && v_pkgs+=" kodi"
has_choice "$v_choice" "4" && v_pkgs+=" haruna"
has_choice "$v_choice" "5" && v_pkgs+=" obs-studio"
has_choice "$v_choice" "6" && v_pkgs+=" vlc"
has_choice "$v_choice" "7" && v_pkgs+=" kdenlive"
install_pkg "$v_pkgs" "$manager"

util_choice=$(multi_select "[ARAÇLAR] ➜ Arşiv & Dosya Manipülasyonu" "1: Temel (zip), 2: Gelişmiş (ImageMagick)")
util_pkgs=""
has_choice "$util_choice" "1" && util_pkgs+=" unzip zip p7zip unrar"
has_choice "$util_choice" "2" && util_pkgs+=" unzip zip p7zip unrar imagemagick exiftool"
install_pkg "$util_pkgs" "$manager"
util_choice_gui=$(multi_select "[ARAÇLAR] ➜ Arşiv & Dosya Manipülasyonu GUI" "1: Ark, 2: File Roller 3: Thunar 4: Xarchiver 5: Engrampa 6: PeaZip")
util_pkgs_gui=""
has_choice "$util_choice_gui" "1" && util_pkgs_gui+=" ark"
has_choice "$util_choice_gui" "2" && util_pkgs_gui+=" file-roller"
has_choice "$util_choice_gui" "3" && util_pkgs_gui+=" thunar-archive-plugin"
has_choice "$util_choice_gui" "4" && util_pkgs_gui+=" xarchiver"
has_choice "$util_choice_gui" "5" && util_pkgs_gui+=" engrampa"
has_choice "$util_choice_gui" "6" && util_pkgs_gui+=" peazip"
install_pkg "$util_pkgs_gui" "$manager"

a_choice=$(multi_select "[AUDİO] ➜ Müzik & Ses Prodüksiyonu" "1: CLI (ncmpcpp), 2: DeaDBeeF, 3: Audacity, 4: Ardour, 5: Qtractor, 6: LMMS")
a_pkgs=""
has_choice "$a_choice" "1" && a_pkgs+=" mpd ncmpcpp"
has_choice "$a_choice" "2" && a_pkgs+=" deadbeef-git"
has_choice "$a_choice" "3" && a_pkgs+=" audacity"
has_choice "$a_choice" "4" && a_pkgs+=" ardour"
has_choice "$a_choice" "5" && a_pkgs+=" qtractor"
has_choice "$a_choice" "6" && a_pkgs+=" lmms"
install_pkg "$a_pkgs" "$manager"

d_choice=$(multi_select "[OFİS] ➜ Belge Yönetimi & PDF" "1: Zathura, 2: Evince, 3: LibreOffice 4: Okular 5: PDF Studio 6: PDFsam Basic 7: PDF-XChange Viewer")
d_pkgs=""
has_choice "$d_choice" "1" && d_pkgs+=" zathura zathura-pdf-mupdf"
has_choice "$d_choice" "2" && d_pkgs+=" evince"
has_choice "$d_choice" "3" && d_pkgs+=" libreoffice-fresh"
has_choice "$d_choice" "3" && d_pkgs+=" okular"
has_choice "$d_choice" "5" && d_pkgs+=" pdfstudio"
has_choice "$d_choice" "6" && d_pkgs+=" pdfsam-basic"
has_choice "$d_choice" "7" && d_pkgs+=" pdf-xchange-viewer"
install_pkg "$d_pkgs" "$manager"

fm_choice=$(multi_select "[DOSYA] ➜ File Explorer Seçenekleri" "1: Thunar, 2: Dolphin, 3: Yazi 4: Nautilus 5: Nemo")
fm_pkgs=""
has_choice "$fm_choice" "1" && fm_pkgs+=" thunar thunar-archive-plugin gvfs"
has_choice "$fm_choice" "2" && fm_pkgs+=" dolphin ffmpegthumbs"
has_choice "$fm_choice" "3" && fm_pkgs+=" yazi ffmpegthumbnailer jq"
has_choice "$fm_choice" "4" && fm_pkgs+=" nautilus"
has_choice "$fm_choice" "5" && fm_pkgs+=" nemo"
install_pkg "$fm_pkgs" "$manager"

snap_choice=$(multi_select "[GÜVENLİK] ➜ Snapshot & Geri Yükleme" "1: Timeshift, 2: Snapper")
snap_pkgs=""
has_choice "$snap_choice" "1" && snap_pkgs+=" timeshift"
has_choice "$snap_choice" "2" && snap_pkgs+=" snapper btrfs-progs"
install_pkg "$snap_pkgs" "$manager"

sys_choice=$(multi_select "[SERVİS] ➜ Arka Plan Hizmetleri" "1: Bluetooth, 2: Network Manager")
has_choice "$sys_choice" "1" && { install_pkg "bluez bluez-utils" "$manager"; sudo systemctl enable --now bluetooth; }
has_choice "$sys_choice" "2" && { install_pkg "networkmanager network-manager-applet" "$manager"; sudo systemctl enable --now NetworkManager; }

security_choice=$(multi_select "[GÜVENLİK] ➜ Sisttem Güvenlik" "1: Fail2ban, 2: UFW, 3: Firewalld, 4: Clamav, 5: Dynafire, 6: dnsmasq")
has_choice "$security_choice" "1" && install_pkg "fail2ban" "$manager"
has_choice "$security_choice" "2" && install_pkg "ufw" "$manager"
has_choice "$security_choice" "3" && install_pkg "firewalld" "$manager"
has_choice "$security_choice" "4" && install_pkg "clamav clamav-daemon" "$manager"
has_choice "$security_choice" "5" && install_pkg "dynafire" "$manager"
has_choice "$security_choice" "6" && install_pkg "dnsmasq" "$manager"

font_choice=$(multi_select "[ESTETİK] ➜ Tipografi & Font Setleri" "1: JetBrains Nerd, 2: Noto Emoji, 3: Noto Sans, 4: Noto Sans CJK")
has_choice "$font_choice" "1" && install_pkg "ttf-jetbrains-mono-nerd" "$manager"
has_choice "$font_choice" "2" && install_pkg "noto-fonts-emoji" "$manager"
has_choice "$font_choice" "3" && install_pkg "noto-fonts" "$manager"
has_choice "$font_choice" "4" && install_pkg "noto-fonts-cjk" "$manager"

comm_choice=$(multi_select "[SOSYAL] ➜ İletişim Kanalları" "1: Discord, 2: Telegram, 3: Slack, 4: Whatsie, 5: Signal, 6: Element")
comm_pkgs=""
has_choice "$comm_choice" "1" && comm_pkgs+=" discord"
has_choice "$comm_choice" "2" && comm_pkgs+=" telegram-desktop"
has_choice "$comm_choice" "3" && comm_pkgs+=" slack-desktop"
has_choice "$comm_choice" "4" && comm_pkgs+=" whatsie"
has_choice "$comm_choice" "5" && comm_pkgs+=" signal-desktop"
has_choice "$comm_choice" "6" && comm_pkgs+=" element-desktop"
install_pkg "$comm_pkgs" "$manager"

Network_choice=$(multi_select "[SERVİS] ➜ Arka Plan Hizmetleri" "1: Openvpn, 2: dnscrypt-proxy, 3: wireguard-tools, 4: tor, 5: tinc, 6: openresolv, 7: stunnel, 8: Wireshark, 9: nginx, 10: certbot")
Network_pkgs=""
has_choice "$Network_choice" "1" && Network_pkgs+=" openvpn"
has_choice "$Network_choice" "2" && Network_pkgs+=" dnscrypt-proxy"
has_choice "$Network_choice" "3" && Network_pkgs+=" wireguard-tools"
has_choice "$Network_choice" "4" && Network_pkgs+=" tor"
has_choice "$Network_choice" "5" && Network_pkgs+=" tinc"
has_choice "$Network_choice" "6" && Network_pkgs+=" openresolv"
has_choice "$Network_choice" "7" && Network_pkgs+=" stunnel"
has_choice "$Network_choice" "8" && Network_pkgs+=" wireshark"
has_choice "$Network_choice" "9" && Network_pkgs+=" nginx"
has_choice "$Network_choice" "10" && Network_pkgs+=" certbot"
install_pkg "$Network_pkgs" "$manager"

echo -e "\n${YELLOW}󰃢 [BİTİŞ] ➜ Sistem Hijyeni${NC}"
read -p "  󰄶 Önbellek temizlensin mi? (y/n): " clean_up
[[ $clean_up == "y" ]] && sudo pacman -Sc --noconfirm

echo -e "\n${BLUE}================================================================================${NC}"
echo -e "${GREEN}${BOLD} Arch KSetuper operasyonu başarıyla tamamladı!${NC}"
echo -e "${BLUE}================================================================================${NC}"
