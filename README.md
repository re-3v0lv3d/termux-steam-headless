# termux-steam-headless

Steam + escritorio XFCE en **Termux (Android)**, accesible desde el **navegador** vía noVNC. Un solo comando instala, configura y arranca todo.

Inspirado en [docker-steam-headless](https://github.com/Steam-Headless/docker-steam-headless), adaptado a proot en móvil.

---

## Instalación — un solo comando

Abre **Termux** (desde [F-Droid](https://f-droid.org/packages/com.termux/)) y pega:

```bash
curl -fsSL https://raw.githubusercontent.com/re-3v0lv3d/termux-steam-headless/main/install.sh | bash
```

Eso hace **todo automáticamente**:

1. Clona este repositorio en `~/termux-steam-headless`
2. Instala paquetes de Termux y Ubuntu (proot-distro)
3. Configura XFCE, Wine, Steam, x11vnc y noVNC
4. Abre Termux:X11
5. Arranca el escritorio y el servidor web
6. Muestra la URL para el navegador

**Primera instalación:** 15–40 minutos.  
**No cierres Termux** hasta que termine.

---

## Acceso desde el navegador

Al finalizar verás algo como:

```
http://192.168.1.42:6080/vnc.html
Contraseña: steamheadless
```

Funciona en:

- El navegador del mismo móvil
- Cualquier PC/tablet en la misma red WiFi

```bash
steam-headless url      # ver URL y contraseña
steam-headless status   # comprobar servicios
steam-headless stop     # detener
steam-headless start    # volver a arrancar
```

---

## Requisitos

| Requisito | Mínimo | Recomendado |
|-----------|--------|-------------|
| Android | 8+ | 11+ |
| RAM | 4 GB | 6–8 GB |
| Almacenamiento libre | 8 GB | 16 GB+ |
| Termux | [F-Droid](https://f-droid.org/packages/com.termux/) | Última versión |
| Chip | Helio G99 / SD 665 | Snapdragon 8 Gen 1+ |

### APK adicional (mandos Bluetooth)

Para mandos BT instala **[Termux:X11-Extra](https://github.com/moio9/termux-x11-extra/releases)**:

1. Empareja el mando en Ajustes de Android
2. Abre Termux:X11-Extra
3. Input Type → `xinput` o `both`

> Los mandos **no** llegan al proot si solo usas noVNC desde otro PC. Para jugar con mando necesitas X11 en el móvil.

---

## Comandos

| Comando | Descripción |
|---------|-------------|
| `steam-headless start` | Inicia escritorio + VNC + noVNC |
| `steam-headless stop` | Detiene servicios |
| `steam-headless status` | Estado de procesos |
| `steam-headless url` | URL y contraseña VNC |
| `steam-headless logs` | Ver logs |
| `steam-headless set-password` | Cambiar contraseña VNC |
| `steam-headless shell` | Entrar al Ubuntu proot |
| `steam-headless reinstall` | Repetir configuración interna |

### Reinstalar desde cero

```bash
steam-headless stop
rm -f ~/.termux-steam-headless-installed
rm -rf ~/.termux-steam-headless
curl -fsSL https://raw.githubusercontent.com/re-3v0lv3d/termux-steam-headless/main/install.sh | bash
```

### Instalar sin arrancar al final

```bash
curl -fsSL https://raw.githubusercontent.com/re-3v0lv3d/termux-steam-headless/main/install.sh | AUTO_START=0 bash
```

### Desinstalar

```bash
bash ~/termux-steam-headless/uninstall.sh
```

---

## Solución de problemas

### Pantalla negra en noVNC

```bash
# Abre Termux:X11-Extra manualmente, luego:
steam-headless stop && steam-headless start
steam-headless logs
```

### Error `/dev/shm`

```bash
mkdir -p /dev/shm && chmod 755 /dev/shm
steam-headless start
```

### Steam no abre

```bash
steam-headless shell
wine ~/.steam-wine/drive_c/Program\ Files\ \(x86\)/Steam/steam.exe -oldbigpicture -bigpicture -windowed
```

### El one-liner no clona el repo

```bash
export TSH_REPO=re-3v0lv3d/termux-steam-headless
curl -fsSL https://raw.githubusercontent.com/re-3v0lv3d/termux-steam-headless/main/install.sh | bash
```

---

## Limitaciones

- No sustituye a docker-steam-headless en un servidor x86 con GPU dedicada
- Juegos AAA recientes no son realistas; prioriza indie, 2D y retro
- Sin Sunshine/Moonlight host
- Rendimiento muy dependiente del hardware

---

## Estructura del proyecto

```
termux-steam-headless/
├── install.sh                 # One-liner: clona, instala, arranca
├── bin/steam-headless         # CLI de gestión
├── scripts/
│   ├── proot-setup.sh         # Setup dentro de Ubuntu
│   ├── start-services.sh      # XFCE + VNC + noVNC
│   ├── stop-services.sh
│   ├── status-services.sh
│   ├── install-box.sh         # Box64/Box86
│   └── get-ip.sh
└── README.md
```

---

## Licencia

MIT — ver [LICENSE](LICENSE)

Documentación adicional: [docs/GUIA.md](docs/GUIA.md)
