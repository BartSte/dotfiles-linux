export CC="$(which clang)"
export CXX="$(which clang++)"
export CXXFLAGS="-Wall -fdiagnostics-color=always"
export CMAKE_EXPORT_COMPILE_COMMANDS="ON"
export CMAKE_COLOR_DIAGNOSTICS="ON"
export CMAKE_GENERATOR="Ninja"

alias unsetc='unset CC; unset CXX; unset CXXFLAGS; echo "CC, CXX, CXXFLAGS unset"'
alias init='cmake -G Ninja -S . -B ./build -Wdev'
alias compile='cmake --build ./build --target package'
