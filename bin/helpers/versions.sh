##############
# Version number helpers
##############

# Is version $1 less than or equal to version $2?
version_lte() {
  [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

# Is version $1 less than version $2?
version_lt() {
  [ "$1" = "$2" ] && return 1 || version_lte "$1" "$2"
}

# Is version $1 greater than or equal to version $2?
version_gte() {
  ! version_lt "${@}"
}

# Is version $1 greater than version $2?
version_gt() {
  ! version_lte "${@}"
}
