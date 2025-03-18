#!/bin/bash

set -e

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Building Ballistic Pendulum AppImage ===${NC}"

# Create required directories
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
mkdir -p AppDir/usr/share/metainfo

# Check for required tools
if ! command -v meson &> /dev/null; then
    echo -e "${RED}Meson build system is required but not installed.${NC}"
    echo "Please install with: sudo apt-get install meson"
    exit 1
fi

if ! command -v ninja &> /dev/null; then
    echo -e "${RED}Ninja build tool is required but not installed.${NC}"
    echo "Please install with: sudo apt-get install ninja-build"
    exit 1
fi

# Clean up previous builds
echo -e "${BLUE}Cleaning up previous builds...${NC}"
rm -rf builddir AppDir/*.AppImage

# Build the application
echo -e "${BLUE}Building application...${NC}"
meson setup builddir
ninja -C builddir

# Copy binary to AppDir
echo -e "${BLUE}Creating AppDir structure...${NC}"
cp builddir/ballistic-pendulum AppDir/usr/bin/

# Create desktop file
echo -e "${BLUE}Creating desktop entry...${NC}"
cat > AppDir/usr/share/applications/org.example.ballisticpendulum.desktop << EOF
[Desktop Entry]
Name=Ballistic Pendulum
Name[ru]=Баллистический маятник
Comment=Physical simulation of a ballistic pendulum
Comment[ru]=Физическое моделирование баллистического маятника
Exec=ballistic-pendulum
Icon=org.example.ballisticpendulum
Terminal=false
Type=Application
Categories=Education;Science;Physics;GTK;
Keywords=physics;pendulum;simulation;
EOF

# Create application icon
echo -e "${BLUE}Creating application icon...${NC}"
cat > AppDir/usr/share/icons/hicolor/256x256/apps/org.example.ballisticpendulum.svg << EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <circle cx="128" cy="60" r="20" fill="#333333" stroke="#000000" stroke-width="2" />
  <line x1="128" y1="60" x2="128" y2="150" stroke="#666666" stroke-width="6" />
  <circle cx="128" cy="150" r="40" fill="#cc3333" stroke="#000000" stroke-width="2" />
  <circle cx="90" cy="150" r="10" fill="#3333cc" stroke="#000000" stroke-width="2" />
  <path d="M 40,150 L 60,150" stroke="#555555" stroke-width="3" />
  <path d="M 30,160 L 70,140" stroke="#555555" stroke-width="3" />
  <path d="M 30,140 L 70,160" stroke="#555555" stroke-width="3" />
</svg>
EOF

# Create AppStream metadata
echo -e "${BLUE}Creating AppStream metadata...${NC}"
cat > AppDir/usr/share/metainfo/org.example.ballisticpendulum.appdata.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>org.example.ballisticpendulum</id>
  <name>Ballistic Pendulum</name>
  <name xml:lang="ru">Баллистический маятник</name>
  <summary>Simulate a ballistic pendulum experiment</summary>
  <summary xml:lang="ru">Моделирование эксперимента с баллистическим маятником</summary>
  <description>
    <p>
      A virtual model of a physical experiment involving a ballistic pendulum,
      which is used to measure the velocity of a projectile by observing the 
      pendulum's maximum deflection angle.
    </p>
  </description>
  <url type="homepage">https://example.org</url>
  <launchable type="desktop-id">org.example.ballisticpendulum.desktop</launchable>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>MIT</project_license>
  <developer_name>Educational Physics Tools Team</developer_name>
  <categories>
    <category>Education</category>
    <category>Science</category>
  </categories>
  <content_rating type="oars-1.1" />
  <releases>
    <release version="1.0.0" date="$(date +%Y-%m-%d)"/>
  </releases>
</component>
EOF

# Create AppRun file (entry point for the AppImage)
echo -e "${BLUE}Creating AppRun script...${NC}"
cat > AppDir/AppRun << EOF
#!/bin/sh
SELF=\$(readlink -f "\$0")
HERE=\${SELF%/*}
export PATH="\${HERE}/usr/bin/:\${PATH}"
export LD_LIBRARY_PATH="\${HERE}/usr/lib/:\${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="\${HERE}/usr/share/:\${XDG_DATA_DIRS}"
export GSETTINGS_SCHEMA_DIR="\${HERE}/usr/share/glib-2.0/schemas/:\${GSETTINGS_SCHEMA_DIR}"
export GI_TYPELIB_PATH="\${HERE}/usr/lib/girepository-1.0/:\${GI_TYPELIB_PATH}"

exec "\${HERE}/usr/bin/ballistic-pendulum" "\$@"
EOF
chmod +x AppDir/AppRun

# Download linuxdeploy tools if not already present
echo -e "${BLUE}Downloading AppImage packaging tools...${NC}"
if [ ! -f linuxdeploy-x86_64.AppImage ]; then
    wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x linuxdeploy-x86_64.AppImage
fi
if [ ! -f linuxdeploy-plugin-gtk.sh ]; then
    wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
    chmod +x linuxdeploy-plugin-gtk.sh
fi

# Create the AppImage
echo -e "${BLUE}Creating AppImage package...${NC}"
./linuxdeploy-x86_64.AppImage --appdir=AppDir --plugin gtk --output appimage --desktop-file=AppDir/usr/share/applications/org.example.ballisticpendulum.desktop --icon-file=AppDir/usr/share/icons/hicolor/256x256/apps/org.example.ballisticpendulum.svg

# Move AppImage to current directory
mv *.AppImage ballistic-pendulum.AppImage

echo -e "${GREEN}AppImage created: ballistic-pendulum.AppImage${NC}"
echo -e "${GREEN}Now you can run your application by executing: ./ballistic-pendulum.AppImage${NC}"
