#!/bin/bash

# ---------------------------------------------------------
# Full-Featured Linux Setup Script
# ---------------------------------------------------------

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -eq 0 ]]; then
  echo -e "${RED}Bu script root olarak çalıştırılmamalı.${NC}"
  exit 1
fi

LOGFILE="$HOME/linux-setup.log"
exec > >(tee -i "$LOGFILE")
exec 2>&1

echo -e "${BLUE}=== Gelişmiş İnteraktif Linux Kurulumu ===${NC}"
echo -e "${YELLOW}İpucu: Bir bölümü kurmak istemiyorsanız hiçbir şey yazmadan ENTER'a basın.${NC}\n"

# -----------------------------
# Yardımcı Fonksiyonlar
# -----------------------------

multi_select() {
    echo -e "${CYAN}$1${NC}"
    read -p "Seçim (örn: 1,3 veya Atlamak için ENTER): " choices
    echo "$choices"
}

is_installed() {
    pacman -Qq "$1" &> /dev/null
}

install_aur_helper() {
    local helper=$1
    if is_installed "$helper"; then
        echo -e "${GREEN}$helper zaten mevcut.${NC}"
        return
    fi
    echo -e "${BLUE}$helper kuruluyor...${NC}"
    sudo pacman -S --needed base-devel git --noconfirm
    git clone https://aur.archlinux.org/$helper.git
    cd $helper && makepkg -si --noconfirm
    cd .. && rm -rf $helper
}

install_pkg() {
    local pkgs="$1"
    local manager="$2"
    if [[ -z "${pkgs// }" ]]; then return; fi

    echo -e "${BLUE}[Kontrol ediliyor ve Kuruluyor]: $pkgs${NC}"

    case $manager in
        yay)
            yay -S --noconfirm --needed --batchinstall "$pkgs"
            ;;
        paru)
            paru -S --noconfirm --needed "$pkgs"
            ;;
        *)
            sudo pacman -S --noconfirm --needed $pkgs
            ;;
    esac
    if [ $? -ne 0 ]; then
        echo -e "${RED}[Uyarı] Bazı paketlerin kurulumunda sorun çıkmış olabilir. Log dosyasını kontrol edin.${NC}"
    fi
}

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_LIKE=$ID_LIKE
else
    echo -e "${RED}Dağıtım tespit edilemedi!${NC}"
    exit 1
fi

echo -e "${CYAN}Tespit Edilen Sistem: ${GREEN}$NAME${NC}"

# -----------------------------
# 0. Adım: Sistem Optimizasyonu
# -----------------------------
echo -e "${YELLOW}>> 0. Adım: Sistem Optimizasyonu${NC}"

read -p "Pacman paralel indirme aktif edilsin mi? [y/N]: " para_ask
if [[ $para_ask == "y" ]]; then
    read -p "Kaç kanal aynı anda indirsin? (Önerilen: 5-10) [Varsayılan: 5]: " para_count
    para_count=${para_count:-5}
    sudo sed -i "s/^[#]*ParallelDownloads = .*/ParallelDownloads = $para_count/" /etc/pacman.conf
    echo -e "${GREEN}Paralel indirme $para_count kanal olarak aktif edildi.${NC}"
fi

read -p "Reflector ile en hızlı aynalar taransın mı? [y/N]: " ref_choice
if [[ $ref_choice == "y" ]]; then
    echo -e "${BLUE}En hızlı aynalar test ediliyor, bu biraz zaman alabilir...${NC}"
    sudo pacman -S --needed --noconfirm reflector
    sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    echo -e "${GREEN}Ayna listesi güncellendi.${NC}"
fi

echo -e "\n${CYAN}İşlemci Mimariniz:${NC}"
echo "1) Intel | 2) AMD | [ENTER: Atla]"
read -p "Seçim: " cpu_choice
[[ $cpu_choice == 1 ]] && install_pkg "intel-ucode" "pacman"
[[ $cpu_choice == 2 ]] && install_pkg "amd-ucode" "pacman"

if lspci | grep -i nvidia &> /dev/null; then
    echo -e "\n${YELLOW}[Donanım Notu] Nvidia GPU tespit edildi!${NC}"
    read -p "Sürücüler kurulsun mu? [y/N]: " nv_choice
    [[ $nv_choice == "y" ]] && install_pkg "nvidia nvidia-utils nvidia-settings" "pacman"
fi

# -----------------------------
# 1. Adım: AUR Yardımcısı
# -----------------------------
echo -e "${YELLOW}>> 1. Adım: AUR Yardımcısı Hazırlığı${NC}"
echo "1) yay | 2) paru | [ENTER: Atla]"
read -p "Seçim: " aur_setup_choice
case $aur_setup_choice in
    1) install_aur_helper "yay" ;;
    2) install_aur_helper "paru" ;;
esac

# -----------------------------
# 2. Adım: Yönetici Belirleme
# -----------------------------
echo -e "\n${YELLOW}>> 2. Adım(bazı paketler repolarda bulunmayabilir): Paket Yöneticisi Seçimi${NC}"
echo "1) pacman | 2) yay | 3) paru | [ENTER: pacman]"
read -p "Seçim: " pm_choice
manager="pacman"
[[ $pm_choice == 2 ]] && manager="yay"
[[ $pm_choice == 3 ]] && manager="paru"
echo -e "Kullanılan: ${GREEN}$manager${NC}"

# -----------------------------
# 3. Adım: Terminal
# -----------------------------
term_choice=$(multi_select ">> 3. Adım: Terminal Emulator Seçimi (1: WezTerm, 2: Kitty, 3: Alacritty, 4: konsole)")
term_pkgs=""
[[ $term_choice == *1* ]] && term_pkgs+=" wezterm"
[[ $term_choice == *2* ]] && term_pkgs+=" kitty"
[[ $term_choice == *3* ]] && term_pkgs+=" alacritty"
[[ $term_choice == *4* ]] && term_pkgs+=" konsole"
install_pkg "$term_pkgs" "$manager"

# -----------------------------
# 4. Adım: Shell
# -----------------------------
shell_choice=$(multi_select ">> 4. Adım: Shell Seçimi (1: bash, 2: zsh, 3: fish)")
shell_pkgs=""
[[ $shell_choice == *1* ]] && shell_pkgs+=" bash"
[[ $shell_choice == *2* ]] && shell_pkgs+=" zsh"
[[ $shell_choice == *3* ]] && shell_pkgs+=" fish"
install_pkg "$shell_pkgs" "$manager"

if [[ -n "$shell_pkgs" ]]; then
    echo -e "\n== Prompt Seçimi =="
    echo "1) Starship | [ENTER: Atla]"
    read -p "Seçim: " prompt_choice
    [[ $prompt_choice == 1 ]] && install_pkg "starship" "$manager"
fi

# -----------------------------
# 5. Adım: Tarayıcılar
# -----------------------------
browser_choice=$(multi_select ">> 5. Adım: Tarayıcı Seçimi (1: Firefox, 2: Zen, 3: Floorp, 4: Brave, 5: LibreWolf, 6: vivaldi)")
browser_pkgs=""
[[ $browser_choice == *1* ]] && browser_pkgs+=" firefox"
[[ $browser_choice == *2* ]] && browser_pkgs+=" zen-browser-bin"
[[ $browser_choice == *3* ]] && browser_pkgs+=" floorp-bin"
[[ $browser_choice == *4* ]] && browser_pkgs+=" brave-bin"
[[ $browser_choice == *5* ]] && browser_pkgs+=" librewolf-bin"
[[ $browser_choice == *6* ]] && browser_pkgs+=" vivaldi"
install_pkg "$browser_pkgs" "$manager"

# -----------------------------
# 6. Adım: Video / Media
# -----------------------------
v_choice=$(multi_select ">> 6. Adım: Video / Media (1: Minimal, 2: GUI, 3: Kodi)")
v_pkgs=""
case $v_choice in
    1) v_pkgs="mpv yt-dlp ffmpeg" ;;
    2) v_pkgs="celluloid haruna mpv" ;;
    3) v_pkgs="kodi" ;;
esac
install_pkg "$v_pkgs" "$manager"

# -----------------------------
# 6.5 Adım: Arşiv & Medya Yardımcıları
# -----------------------------
util_choice=$(multi_select ">> 6.5 Adım: Arşiv & Medya Yardımcıları (1: Temel, 2: Gelişmiş)")
util_pkgs=""

[[ $util_choice == *1* ]] && util_pkgs+=" unzip zip p7zip unrar"
[[ $util_choice == *2* ]] && util_pkgs+=" unzip zip p7zip unrar imagemagick exiftool"

install_pkg "$util_pkgs" "$manager"

# -----------------------------
# 7. Adım: Ses / Müzik
# -----------------------------
a_choice=$(multi_select ">> 7. Adım: Ses / Müzik (1: CLI, 2: DeaDBeeF-git, 3: Audacity)")
a_pkgs=""
[[ $a_choice == *1* ]] && a_pkgs+=" mpd ncmpcpp"
[[ $a_choice == *2* ]] && a_pkgs+=" deadbeef-git"
[[ $a_choice == *3* ]] && a_pkgs+=" audacity"
install_pkg "$a_pkgs" "$manager"

[[ $a_pkgs == *"mpd"* ]] && systemctl --user enable --now mpd

# -----------------------------
# 8. Adım: Ofis / PDF
# -----------------------------
d_choice=$(multi_select ">> 8. Adım: PDF & Ofis (1: Zathura, 2: Evince, 3: LibreOffice)")
d_pkgs=""
[[ $d_choice == *1* ]] && d_pkgs+=" zathura zathura-pdf-mupdf"
[[ $d_choice == *2* ]] && d_pkgs+=" evince"
[[ $d_choice == *3* ]] && d_pkgs+=" libreoffice-fresh"
install_pkg "$d_pkgs" "$manager"

# -----------------------------
# 9. Adım: Dosya Yöneticisi
# -----------------------------
fm_choice=$(multi_select ">> 9. Adım: Dosya Yöneticisi (1: Thunar, 2: Dolphin, 3: Yazi)")
fm_pkgs=""
[[ $fm_choice == *1* ]] && fm_pkgs+=" thunar thunar-archive-plugin gvfs"
[[ $fm_choice == *2* ]] && fm_pkgs+=" dolphin ffmpegthumbs"
[[ $fm_choice == *3* ]] && fm_pkgs+=" yazi ffmpegthumbnailer jq"
install_pkg "$fm_pkgs" "$manager"

# -----------------------------
# 9.5 Adım: Snapshot / Kurtarma
# -----------------------------
snap_choice=$(multi_select ">> 9.5 Adım: Sistem Kurtarma (1: Timeshift, 2: Btrfs Snapper)")
snap_pkgs=""

[[ $snap_choice == *1* ]] && snap_pkgs+=" timeshift"
[[ $snap_choice == *2* ]] && snap_pkgs+=" snapper btrfs-progs"

install_pkg "$snap_pkgs" "$manager"


# -----------------------------
# 10. Adım: Sistem Servisleri
# -----------------------------
sys_choice=$(multi_select ">> 10. Adım: Sistem Servisleri (1: Bluetooth, 2: Firewall)")
[[ $sys_choice == *1* ]] && { install_pkg "bluez bluez-utils" "$manager"; sudo systemctl enable --now bluetooth; }
[[ $sys_choice == *2* ]] && { install_pkg "ufw" "$manager"; sudo ufw enable; }

# -----------------------------
# 11. Adım: Fontlar
# -----------------------------
font_choice=$(multi_select ">> 11. Adım: Fontlar (1: Nerd Font, 2: Emoji)")
[[ $font_choice == *1* ]] && install_pkg "ttf-jetbrains-mono-nerd" "$manager"
[[ $font_choice == *2* ]] && install_pkg "noto-fonts-emoji" "$manager"

# -----------------------------
# 12. Adım: İletişim
# -----------------------------
comm_choice=$(multi_select ">> 12. Adım: İletişim (1: Discord, 2: Telegram, 3: Slack)")
comm_pkgs=""
[[ $comm_choice == *1* ]] && comm_pkgs+=" discord"
[[ $comm_choice == *2* ]] && comm_pkgs+=" telegram-desktop"
[[ $comm_choice == *3* ]] && comm_pkgs+=" slack-desktop"
install_pkg "$comm_pkgs" "$manager"

# -----------------------------
# 13. Adım: Temizlik
# -----------------------------
echo -e "\n${YELLOW}>> 13. Adım: Temizlik${NC}"
read -p "Paket önbelleği temizlensin mi? (y/n) [ENTER: Hayır]: " clean_up
[[ $clean_up == "y" ]] && sudo pacman -Sc --noconfirm

echo -e "\n${GREEN}=== Kurulum başarıyla tamamlandı! ===${NC}"
