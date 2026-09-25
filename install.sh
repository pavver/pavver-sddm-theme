#!/usr/bin/env bash
# ==============================================================================
# Pavver SDDM Theme Installation Script
# ==============================================================================

set -e

THEME_NAME="pavver-sddm-theme"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/usr/share/sddm/themes/${THEME_NAME}"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_KDE_CONF="${SDDM_CONF_DIR}/kde_settings.conf"
SDDM_MAIN_CONF="/etc/sddm.conf"

echo "======================================================="
echo "   Встановлення теми SDDM: ${THEME_NAME}"
echo "======================================================="

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    echo "(!) Цей скрипт потребує прав адміністратора (root)."
    echo "    Будь ласка, запустіть його через sudo:"
    echo "    sudo $0"
    exit 1
fi

echo "[1/4] Копіювання файлів теми у ${TARGET_DIR}..."
mkdir -p "${TARGET_DIR}"
cp -rf "${SCRIPT_DIR}"/Main.qml "${TARGET_DIR}/"
cp -rf "${SCRIPT_DIR}"/metadata.desktop "${TARGET_DIR}/"
cp -rf "${SCRIPT_DIR}"/theme.conf "${TARGET_DIR}/"
cp -rf "${SCRIPT_DIR}"/preview.png "${TARGET_DIR}/"
cp -rf "${SCRIPT_DIR}"/assets "${TARGET_DIR}/"
cp -rf "${SCRIPT_DIR}"/components "${TARGET_DIR}/"
cp -rf "${SCRIPT_DIR}"/fonts "${TARGET_DIR}/"

echo "[2/4] Встановлення прав доступу..."
chmod -R 755 "${TARGET_DIR}"

echo "[3/4] Налаштування конфігурації SDDM..."
if [ -d "${SDDM_CONF_DIR}" ]; then
    mkdir -p "${SDDM_CONF_DIR}"
    if [ -f "${SDDM_KDE_CONF}" ]; then
        if grep -q "^\[Theme\]" "${SDDM_KDE_CONF}"; then
            sed -i '/^\[Theme\]/,/^\[/ s|^Current=.*|Current='"${THEME_NAME}"'|' "${SDDM_KDE_CONF}"
            if ! grep -q "^Current=${THEME_NAME}" "${SDDM_KDE_CONF}"; then
                sed -i '/^\[Theme\]/a Current='"${THEME_NAME}" "${SDDM_KDE_CONF}"
            fi
        else
            printf "\n[Theme]\nCurrent=%s\n" "${THEME_NAME}" >> "${SDDM_KDE_CONF}"
        fi
    else
        cat <<EOF > "${SDDM_KDE_CONF}"
[Theme]
Current=${THEME_NAME}
EOF
    fi
    echo "      Оновлено ${SDDM_KDE_CONF} -> Current=${THEME_NAME}"
else
    if [ -f "${SDDM_MAIN_CONF}" ]; then
        if grep -q "^\[Theme\]" "${SDDM_MAIN_CONF}"; then
            sed -i '/^\[Theme\]/,/^\[/ s|^Current=.*|Current='"${THEME_NAME}"'|' "${SDDM_MAIN_CONF}"
        else
            printf "\n[Theme]\nCurrent=%s\n" "${THEME_NAME}" >> "${SDDM_MAIN_CONF}"
        fi
    else
        cat <<EOF > "${SDDM_MAIN_CONF}"
[Theme]
Current=${THEME_NAME}
EOF
    fi
    echo "      Оновлено ${SDDM_MAIN_CONF} -> Current=${THEME_NAME}"
fi

echo "[4/4] Тема успішно встановлена та активована!"
echo "======================================================="
echo "Для перевірки роботи теми запустіть:"
echo "sddm-greeter-qt6 --test-mode --theme ${TARGET_DIR}"
echo "======================================================="
