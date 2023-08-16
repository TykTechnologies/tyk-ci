# Tyk's CI testing environment

The tarball implements a docker compose based testing environment that is used in the automation. It will untar into a directory called `auto`.

If you want to run this locally, you will need,
- docker compose plugin or above (not the python based docker-compose)
- AWS integration account credentials
- dashboard license (`export TYK_DB_LICENSEKEY=`)

The README in the tarball has further information.
