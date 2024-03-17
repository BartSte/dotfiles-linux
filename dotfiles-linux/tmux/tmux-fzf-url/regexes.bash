# This script is used to grep the follow text from stdin:

# |--------------+----------------------------+-----------------------------------+----------------------|
# | type         | pattern                    | example                           | windows path support |
# | ----         | -------                    | -------                           | -------------------- |
# | python error | File "{file}", line {line} | File "/home/user/foo.py", line 17 | yes                  |
# | pytest error | {file}:{line}:             | test/test.py:123:                 | yes                  |
# | clang error  | {file}:{line}:{column}:    | test/test.cpp:123:4:              | no                   |
# |--------------+----------------------------+-----------------------------------+----------------------|

# The types are detected base on their patterns. After the detection, they are
# converted to the following convetion:

# - {file}:{line}:{column}

RE_PYTEST_ERROR="^[a-zA-Z0-9\\\/\_\.\-]*\.py:[0-9]+:"
RE_PYTHON_ERROR="\"([a-zA-Z0-9\\\/\_\.]*\.py)\",\sline\s([0-9]+)"
RE_CLANG_ERROR=""
