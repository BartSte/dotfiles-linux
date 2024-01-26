export CC="$(which clang)"
export CXX="$(which clang++)"
export CXXFLAGS="-Wall -Wextra -Wno-unused-parameter -fdiagnostics-color=always"
export CMAKE_EXPORT_COMPILE_COMMANDS="ON"
export CMAKE_COLOR_DIAGNOSTICS="ON"
export CMAKE_GENERATOR="Ninja"

alias unsetc='unset CC; unset CXX; unset CXXFLAGS; echo "CC, CXX, CXXFLAGS unset"'
alias bb='cmake --build "~/code/snapshot/build"'
alias bp='cmake --build "~/code/snapshot/build" --target package'
alias tt='ctest --test-dir "~/code/snapshot/build" --verbose'
