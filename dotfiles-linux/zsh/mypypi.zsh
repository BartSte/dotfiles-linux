# The followig alias sends the content of the file `$1` to grep. Next,
# grep will search for the line that starts with `password = `. Finally, sed
# will remove the `password = ` part. The result is the password which is saved
# as the variable `pypi_token`. The same is done for the username. Finally,
# these variables are used to create an environment variable `MYPYPI` which is
# used by pip to install packages from a private repository. It can be used as
# an argument for the `--extra-index-url` option of `pip install`.
# I pypi_username or pypi_token is empty, then the variable MYPYPI is not set.
# This is done to avoid errors when installing packages from PyPI.
make_index_url() {
    pypi_username=$(grep "^username = " $1 | sed "s/^username = //")
    pypi_token=$(grep "^password = " $1 | sed "s/^password = //")
    MYPYPI="https://$pypi_username:$pypi_token@gitlab.com/api/v4/groups/2265086/-/packages/pypi/simple/"
    [[ -z $pypi_username || -z $pypi_token ]] || echo $MYPYPI
}
