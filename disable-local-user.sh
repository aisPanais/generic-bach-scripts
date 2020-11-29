#!/bin/bash

# This script allows the user to disable or delete accounts, and optionally archive them.

#################################
#########   FUNCTIONS   #########
#################################

# Tells the user how to use this program:
usage () {
  echo
  echo "Description: suspend, delete, and optionally archive user accounts."
  echo
  echo "Usage: $0 -s|-d|-a|-h username"
  echo
  echo "Options:"
  echo
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
    echo -e "${RED_TEXT}${OPTARG}'s account does not exist on this system.${RESET_TEXT_COLOR}" >&2
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
    echo -e "${GREEN_TEXT}${OPTARG}'s account has been suspended.${RESET_TEXT_COLOR}"
    exit 0
  else
    echo -e "${RED_TEXT}${OPTARG}'s account has NOT been suspended.${RESET_TEXT_COLOR}" >&2
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
    echo -e "${GREEN_TEXT}${OPTARG}'s account has been deleted.${RESET_TEXT_COLOR}"
    exit 0
  else
    echo -e "${RED_TEXT}${OPTARG}'s account has NOT been deleted.${RESET_TEXT_COLOR}" >&2
    exit 1
  fi
}

# Archiving the account's home folder and then calling the delete function:
archive () {
  validate_username
  
  # Getting the account's home directory:
  local HOME=$(grep -w ${OPTARG} /etc/passwd | cut -d: -f6)
  # I passed the -w option to grep because otherwise it will return anything that matches the string
  # (for example, the string could be a single letter, and it would match all files and folders that contain that letter),
  # although the validate_username function now takes care of that.
  # I did not use the below, because eval introduces security risks:
  # $(eval echo ~${OPTARG})
  # I did not use the below, because it will also return accounts that are not local, such as LDAP accounts.
  # $(getent passwd ${OPTARG} | cut -d: -f6)

  tar -zcvf ${OPTARG}.tar.gz $HOME

  if [[ "$?" -eq 0 ]]
  then
    echo -e "${GREEN_TEXT}${OPTARG}'s home folder has been archived.${RESET_TEXT_COLOR}"
    delete
  else
    echo -e "${RED_TEXT}${OPTARG}'s home folder has NOT been archived.${RESET_TEXT_COLOR}" >&2
    exit 1
  fi
}

########################################
#########   END OF FUNCTIONS   #########
########################################

RED_TEXT='\033[0;31m'
GREEN_TEXT='\033[0;32m'
RESET_TEXT_COLOR='\033[0m'
# TODO:
# The above assumes that the text color was originally white
# so "resetting" the text color actually makes it white.
# This would be a problem if the user's terminal text color was not originally white
# because we would be changing it to white instead of their original text color.
# I could first check what color the text setting is before making it red,
# and then "resetting" would actually return it to what it was before.
# All this could be done in a function.

# check if ran with superuser privileges
if [[ "${UID}" -ne 0 ]]
then
  echo -e "${RED_TEXT}Please run with sudo or as root.${RESET_TEXT_COLOR}" >&2
  exit 1
fi

# Check whether no arguments have been given
if [[ "${#}" -eq 0 ]]
then
  echo -e "${RED_TEXT}No arguments have been provided.${RESET_TEXT_COLOR}" >&2
  usage
  exit 1
fi

while getopts s:d:a:h FLAG
# TODO: I could find a way to color STDERR of the getopts command.
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

# Check that an option has been specified.
if [[ $OPTIND -eq 1 ]]
then
  echo -e "${RED_TEXT}No option was specified.${RESET_TEXT_COLOR}" >&2
  usage
  exit 1
fi

