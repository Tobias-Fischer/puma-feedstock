#!/bin/bash
set -e  # exit when any command fails

export CXXFLAGS="${CXXFLAGS-} -D_LIBCPP_ENABLE_CXX17_REMOVED_FEATURES"

echo -e "\n### INSTALLING PuMA GUI ###\n"
# The C++ library the GUI links against comes from the puma package in the host
# environment, so BUILD_PREFIX and INSTALL_PREFIX both point at the prefix.
# Replace the vendored QCustomPlot 2.0.0, which predates Qt 6, with the 2.1.1
# release the recipe fetches as a second source.
cp "$SRC_DIR"/qcustomplot-2.1.1/qcustomplot.h "$SRC_DIR"/qcustomplot-2.1.1/qcustomplot.cpp \
   "$SRC_DIR"/qcustomplot-2.1.1/GPL.txt "$SRC_DIR"/gui/src/Utilities/qcustomplot/
cd "$SRC_DIR"/gui/build
# workarounds for openGL and g++ on linux
if [ "$(uname)" != "Darwin" ]; then
      # libGL comes from the libgl-devel host package, which installs into the
      # prefix.
      echo "QMAKE_LIBS_OPENGL=${PREFIX}/lib/libGL.so" >> pumaGUI.pro
      # pumaGUI.pro builds with qmake's linux-g++ spec, which invokes a bare
      # "g++", so a link to the conda compiler goes ahead of it on PATH. GXX
      # holds a command name, so resolve it to a path before linking to it.
      ln -sf "$(command -v "${GXX}")" g++
      export PATH="${PWD}:${PATH}"
fi
if [ "${CONDA_BUILD_CROSS_COMPILATION:-0}" = "1" ]; then
      # The qmake6 in the host prefix is a target binary. Run the build
      # machine's qmake6 instead and hand it the host prefix's Qt paths, with
      # the Host* entries pointing at the build prefix so moc, uic and rcc are
      # runnable. HostData stays on the host prefix because that is where the
      # mkspecs describing the target Qt live.
      cp "${PREFIX}/bin/qt6.conf" cross_qt.conf
      cat >> cross_qt.conf <<EOF
HostPrefix = ${BUILD_PREFIX}
HostBinaries = ${BUILD_PREFIX}/lib/qt6/bin
HostLibraryExecutables = ${BUILD_PREFIX}/lib/qt6
HostLibraries = ${BUILD_PREFIX}/lib
HostData = ${PREFIX}/lib/qt6
EOF
      "${BUILD_PREFIX}/bin/qmake6" -qtconf "${PWD}/cross_qt.conf" \
            QMAKE_CC="${CC}" \
            QMAKE_CXX="${CXX}" \
            QMAKE_LINK="${CXX}" \
            BUILD_PREFIX=$PREFIX \
            INSTALL_PREFIX=$PREFIX
else
      qmake6 \
            BUILD_PREFIX=$PREFIX \
            INSTALL_PREFIX=$PREFIX
fi
make -j$CPU_COUNT
make install

echo -e "\n### END OF INSTALLATION ###\n"
