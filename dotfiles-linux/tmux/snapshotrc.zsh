export CC="$(which clang)"
export CXX="$(which clang++)"
export CXXFLAGS="-Wall -fdiagnostics-color=always"
export CMAKE_EXPORT_COMPILE_COMMANDS="ON"
export CMAKE_COLOR_DIAGNOSTICS="ON"
export CMAKE_GENERATOR="Ninja"

alias unsetc='unset CC; unset CXX; unset CXXFLAGS; echo "CC, CXX, CXXFLAGS unset"'
alias init='cmake -G Ninja -S . -B ./build -Wdev -DPC_FFMPEG_LIBRARY_DIRS=./3rdparty/ffmpeg/lib -DPC_FFMPEG_INCLUDE_DIRS=./3rdparty/ffmpeg/include'
alias compile='cmake --build ./build --target package'
