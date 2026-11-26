@echo on

:: The C++ library the GUI links against comes from the libpuma package in the
:: host environment, so BUILD_PREFIX and INSTALL_PREFIX both point at the
:: prefix. qmake wants forward slashes.
set "PUMA_PREFIX=%LIBRARY_PREFIX:\=/%"

cd gui\build
if errorlevel 1 exit 1

:: Without debug_and_release the executable lands next to the Makefile and
:: "nmake install" picks it up from there.
qmake6 "CONFIG+=release" "CONFIG-=debug_and_release" ^
      BUILD_PREFIX=%PUMA_PREFIX% ^
      INSTALL_PREFIX=%PUMA_PREFIX%
if errorlevel 1 exit 1

nmake
if errorlevel 1 exit 1

nmake install
if errorlevel 1 exit 1
