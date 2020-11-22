#!/bin/bash

# This script allows the user to disable or delete accounts, and optionally archive them.

# Tells the user how to use this program:
usage () {
  echo
  echo "Description: suspend, delete, or archive an account."
  echo
  echo "Usage: $0 -s|-d|-a|-h" username
  echo "Options:"
  echo "  -s  Suspend account"
  echo "  -d  Delete account"
  echo "  -a  Archive home folder and delete account"
  echo "  -h  Display this help message"
  echo
}

# Check whether the argument passed is a valid account name:
validate_username () {
  id $OPTARG &>/dev/null
  if [[ "$?" -ne 0 ]]
  then
    echo "${OPTARG}'s account does not exist on this system." >&2
    echo "Use -h for help."
    exit 1
  fi
}

# Expire (lock/disable) the account:
suspend () {
  validate_username
  chage $OPTARG -E0
  if [[ "$?" -eq 0 ]]
  then
    echo "${OPTARG}'s account has been suspended."
    exit 0
  else
    echo "${OPTARG}'s account has NOT been suspended." >&2
    exit 1
  fi
  # The account can be re-enabled with this:
  # sudo chage USERNAME -E -1
}

delete () {
  validate_username
  userdel -r "$OPTARG"
  if [[ "$?" -eq 0 ]]
  then
    echo "${OPTARG}'s account has been deleted."
    exit 0
  else
    echo "${OPTARG}'s account has NOT been deleted." >&2
    exit 1
  fi
}

# Archiving the account's home folder and then calling the delete function:
archive () {
  validate_username
  
  # Getting the account's home directory:
  local HOME=$(grep -w ${OPTARG} /etc/passwd | cut -d: -f6)
  # I passed the -w option to grep because otherwise it will return anything that matches the string,
  # although the validate_username function now takes care of that.
  # I did not use the below because eval introduces security risks:
  # $(eval echo ~${OPTARG})
  # I did not use the below because it will also return accounts that are not local, such as LDAP accounts.
  # $(getent passwd ${OPTARG} | cut -d: -f6)

  tar -zcvf ${OPTARG}.tar.gz $HOME

  if [[ "$?" -eq 0 ]]
  then
    echo "${OPTARG}'s home folder has been archived."
    delete
  else
    echo "${OPTARG}'s home folder has NOT been archived." >&2
    exit 1
  fi
}

# check if run with superuser privileges
if [[ "${UID}" -ne 0 ]]
then
  echo "Please run with sudo or as root." >&2
  exit 1
fi

# Check whether no arguments have been given
if [[ "${#}" -eq 0 ]]
then
  usage
  exit 1
fi

while getopts s:d:a:h FLAG
do
  case "$FLAG" in
    s)
      suspend
      ;;
    d)
      delete
      ;;
    a)
      archive
      ;;
    h)
      usage
      exit 0
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

