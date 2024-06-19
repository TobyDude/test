# Set up necessary directories and variables
BASE_DIR="/NVIDIA"
TMP_DIR="/tmp/${PLUGIN_NAME}_$(echo $RANDOM)"
VERSION="$(date +'%Y.%m.%d')"

# Download the Nvidia driver package if it does not exist
cd "${DATA_DIR}"
if [ ! -f "${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run" ]; then
  wget -q --show-progress --progress=bar:force:noscroll -O "${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run" \
  "http://us.download.nvidia.com/XFree86/Linux-x86_64/${NV_DRV_V}/NVIDIA-Linux-x86_64-${NV_DRV_V}.run"
fi

# Make the Nvidia driver executable and install it in a temporary directory
chmod +x "${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run"
mkdir -p $BASE_DIR/usr/lib64/xorg/modules/{drivers,extensions} $BASE_DIR/usr/bin $BASE_DIR/etc \
          $BASE_DIR/lib/modules/${UNAME}/kernel/drivers/video $BASE_DIR/lib/firmware
"${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run" --kernel-name="$UNAME" \
  --no-precompiled-interface --disable-nouveau \
  --x-prefix=$BASE_DIR/usr --x-library-path=$BASE_DIR/usr/lib64 --x-module-path=$BASE_DIR/usr/lib64/xorg/modules \
  --opengl-prefix=$BASE_DIR/usr --installer-prefix=$BASE_DIR/usr --utility-prefix=$BASE_DIR/usr \
  --documentation-prefix=$BASE_DIR/usr --application-profile-path=$BASE_DIR/usr/share/nvidia \
  --proc-mount-point=$BASE_DIR/proc --kernel-install-path=$BASE_DIR/lib/modules/${UNAME}/kernel/drivers/video \
  --compat32-prefix=$BASE_DIR/usr --compat32-libdir=/lib --install-compat32-libs \
  --no-x-check --no-nouveau-check --skip-depmod --j"${CPU_COUNT}" --silent

# Copy files for OpenCL and Vulkan to temporary installation directory
[ -d /lib/firmware/nvidia ] && cp -R /lib/firmware/nvidia $BASE_DIR/lib/firmware/
cp /usr/bin/nvidia-modprobe $BASE_DIR/usr/bin/
cp -R /etc/OpenCL /etc/vulkan $BASE_DIR/etc/

# Download and extract libnvidia-container and nvidia-container-toolkit
download_and_extract() {
  local url=$1
  local file=$2
  if [ ! -f "${DATA_DIR}/${file}" ]; then
    wget -q --show-progress --progress=bar:force:noscroll -O "${DATA_DIR}/${file}" "${url}"
  fi
  tar -C $BASE_DIR -xf "${DATA_DIR}/${file}"
}

download_and_extract "https://github.com/ich777/libnvidia-container/releases/download/${LIBNVIDIA_CONTAINER_V}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz" "libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz"
download_and_extract "https://github.com/ich777/nvidia-container-toolkit/releases/download/${CONTAINER_TOOLKIT_V}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz" "nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz"

# Create Slackware package
mkdir -p "$TMP_DIR/$VERSION/install"
cd "$TMP_DIR/$VERSION"
cp -R $BASE_DIR/* .
tee install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Nvidia-Driver v${NV_DRV_V}
$PLUGIN_NAME: libnvidia-container v${LIBNVIDIA_CONTAINER_V}
$PLUGIN_NAME: nvidia-container-runtime v${NVIDIA_CONTAINER_RUNTIME_V}
$PLUGIN_NAME: nvidia-container-toolkit v${CONTAINER_TOOLKIT_V}
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF

${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n "${TMP_DIR}/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz"
md5sum "${TMP_DIR}/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz" | awk '{print $1}' > "${TMP_DIR}/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz.md5"
