# Guía rápida — termux-steam-headless

## Usuario final

```bash
curl -fsSL https://raw.githubusercontent.com/re-3v0lv3d/termux-steam-headless/main/install.sh | bash
```

Espera a que termine. Abre la URL que muestra al final.

## Mantenedor del repositorio

### Antes de publicar

1. En `install.sh`, línea 12:

```bash
TSH_REPO_DEFAULT="re-3v0lv3d/termux-steam-headless"
```

2. En `README.md`, reemplaza todas las apariciones de `re-3v0lv3d`.

### Subir a GitHub

```bash
git add .
git commit -m "Initial release: one-liner install for Termux Steam headless"
git branch -M main
git remote add origin https://github.com/re-3v0lv3d/termux-steam-headless.git
git push -u origin main
```

### Probar el one-liner

En Termux del móvil:

```bash
curl -fsSL https://raw.githubusercontent.com/re-3v0lv3d/termux-steam-headless/main/install.sh | bash
```

## Variables de entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `TSH_REPO` | `re-3v0lv3d/termux-steam-headless` | Repo GitHub |
| `TSH_BRANCH` | `main` | Rama |
| `AUTO_START` | `1` | Arrancar al terminar install |
| `PROOT_DISTRO` | `ubuntu` | Distro proot-distro |

## Flujo interno del instalador

```
curl | bash
    │
    ├─► ¿Existe scripts/proot-setup.sh local?
    │       No → git clone → re-ejecutar install.sh --local
    │
    ├─► pkg install (Termux)
    ├─► proot-distro install ubuntu
    ├─► proot-setup.sh (XFCE, Wine, Steam, VNC)
    ├─► steam-headless start
    └─► muestra URL noVNC
```
