# Dotfiles

i3wm rice on Debian Trixie (ThinkPad T14)

![clean](screenshots/clean.png)
![busy](screenshots/busy.png)

## Stack

- **WM:** i3
- **Bar:** Polybar
- **Compositor:** Picom (shadows, fading, rounded corners)
- **Terminal:** Kitty
- **Launcher:** Rofi
- **Font:** JetBrainsMono Nerd Font
- **Wallpaper:** Custom Win XP / Linux mashup

## Polybar Modules

| Module | Description |
|--------|-------------|
| Network | Wi-Fi SSID via nmcli, click opens nm-connection-editor |
| Bluetooth | Status via bluetoothctl, click opens blueman-manager |
| CPU | Usage % |
| Temperature | Thermal zone with warning threshold |
| Fan | RPM from ThinkPad hwmon |
| Memory | RAM usage % |
| Battery | Charge %, state icon, time remaining |
| Volume | PulseAudio, click opens pavucontrol |
| Weather | wttr.in, city + temp + wind |

## Scripts

| Script | Description |
|--------|-------------|
| `bat-lifetime.sh` | Battery status with dynamic Nerd Font icons |
| `bat-low-alert.sh` | Low battery notification |
| `bat-low-alert-keyboard.sh` | Bluetooth keyboard battery alert |
| `bat-low-alert-mouse.sh` | Bluetooth mouse battery alert |
| `fan-speed.sh` | ThinkPad fan RPM monitor |
| `get-my-weather.sh` | Weather via wttr.in |
| `hdmi-output.sh` | HDMI display auto-config |

## Dependencies

```bash
sudo apt install i3 polybar picom kitty rofi feh flameshot \
    blueman network-manager brightnessctl pulseaudio-utils \
    fonts-jetbrains-mono
```

## Install

```bash
git clone https://github.com/USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## Structure

```
dotfiles/
├── i3/
│   ├── config
│   └── i3status.conf
├── polybar/
│   ├── config.ini
│   └── launch.sh
├── picom/
│   └── picom.conf
├── kitty/
│   └── kitty.conf
├── scripts/
│   ├── bat-lifetime.sh
│   ├── bat-low-alert.sh
│   ├── fan-speed.sh
│   ├── get-my-weather.sh
│   └── ...
├── wallpapers/
│   ├── win-xp-linux.png
│   └── win-xp-linux-blur.png
├── install.sh
└── README.md
```
