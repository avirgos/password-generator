#!/bin/bash

######################################################################
# Template
######################################################################
set -o errexit  # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset  # Exit if variable not set.
IFS=$'\n\t'     # Remove the initial space and instead use '\n'.

######################################################################
# Global variables
######################################################################
ARGUMENTS_PASSWORD_GENERATE=$(echo "${@}" | cut -d ' ' -f1)
ARGUMENTS_PASSWORD_NUMBER=$(echo "${@}" | cut -d ' ' -f2)
ARGUMENTS_NUMBER=$(echo "${#}")
ARGUMENTS_PASSWORD_MIN_LENGTH=8
ARGUMENTS_PASSWORD_MAX_LENGTH=100
ARGUMENTS_PASSWORD_MIN_NUMBER=2
ARGUMENTS_PASSWORD_MAX_NUMBER=150

ALL_CHARACTERS='A-Za-z0-9[]!"#$%&'\''()*+,-./:;<=>?@\^_`{|}~'
ALL_CHARACTERS_REGEX='[a-z][A-Z][0-9][][!"#$%&'\''()*+,-./:;<=>?@\^_`{|}~]'

NC='\033[0m'
GREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'

######################################################################
# Generates one password or multiple passwords.
#
# Globals:
#   ARGUMENTS_PASSWORD_GENERATE
#   ARGUMENTS_PASSWORD_NUMBER
#   ARGUMENTS_NUMBER
#   ARGUMENTS_PASSWORD_MIN_NUMBER
#   ARGUMENTS_PASSWORD_MAX_NUMBER
# Locals:
#   file_name
#   file_extension
#   file_name_and_extension
#   file_number
# Arguments:
#   -g
#   -g <numberPasswordsToGenerate>
# Outputs:
#   Prints, on the standard output, instructions about the 
#   mode selected.
######################################################################
function generate() {
    if test "${ARGUMENTS_PASSWORD_GENERATE}" = "-g" && test "${ARGUMENTS_NUMBER}" -eq 1
    then
        echo "
        -----------------------------------
        |                                 |
        |     ONE random password mode    |
        |                                 |
        -----------------------------------
        "

        one_password
    elif test "${ARGUMENTS_PASSWORD_NUMBER}" -ge "${ARGUMENTS_PASSWORD_MIN_NUMBER}" > /dev/null 2>&1 &&
        test "${ARGUMENTS_PASSWORD_NUMBER}" -le "${ARGUMENTS_PASSWORD_MAX_NUMBER}" > /dev/null 2>&1 
    then
        # file parameters
        local file_name=generated-"$(date +%F)"
        local file_extension="csv"
        local file_directory="passwords-generated"
        local file_name_and_extension="${file_name}"."${file_extension}"
        local file_number=1

        # create the directory to store random passwords files generated
        if ! test -e "${file_directory}"
        then
            mkdir "${file_directory}"
        fi

        # create random passwords file
        if test -e "${file_name_and_extension}" || test -s "${file_name_and_extension}" && test -f "${file_name_and_extension}"
        then
            file_name_and_extension="${file_name}"-"${file_number}"."${file_extension}" # generated-<date>-<number>

            while test -e "${file_name_and_extension}" && test -s "${file_name_and_extension}" && 
                test -f "${file_name_and_extension}"
            do
                let "file_number=file_number+1"
                file_name_and_extension="${file_name}"-"${file_number}"."${file_extension}"
            done
        fi

        echo "
        -----------------------------------------
        |                                       |
        |     MULTIPLE random passwords mode    |
        |                                       |
        -----------------------------------------
        "

        multiple_passwords
    else
        help_user
    fi
}

######################################################################
# Generates a random password with the length chose by the user.
#
# Globals:
#   BLUE
#   NC
#   GREEN
#
#   ALL_CHARACTERS
#   ARGUMENTS_PASSWORD_MIN_LENGTH
#   ARGUMENTS_PASSWORD_MAX_LENGTH
# Locals:
#   one_password
#   password_length
#   password
# Argument:
#   -g
# Outputs:
#   Prints, on the standard output, the password generated.
######################################################################
function one_password() {
    local one_password=1

    echo -e ""${BLUE}"[!] Password length must be in this range : [ "${ARGUMENTS_PASSWORD_MIN_LENGTH}" ; "${ARGUMENTS_PASSWORD_MAX_LENGTH}" ]"${NC}""

    local password_length=""

    while ! [[ "${password_length}" =~ ^[0-9]+$ ]] || 
        test "${password_length}" -lt "${ARGUMENTS_PASSWORD_MIN_LENGTH}" ||
        test "${password_length}" -gt "${ARGUMENTS_PASSWORD_MAX_LENGTH}"
    do
        read -p "Enter a length for your password : " password_length 
    done

    while test "${one_password}" -eq 1
    do
        local password=$(< /dev/urandom tr -dc "${ALL_CHARACTERS}" | head -c "${password_length}" | tr -d '\n')
        
        if test $(echo "${password}" | grep "${ALL_CHARACTERS_REGEX}")
        then
            echo -e ""${GREEN}"Password generated !"${NC}""
            echo -e "${password}"
            one_password=0
        fi 
    done
}

######################################################################
# Grants permissions on the random passwords file generated.
#
# Globals:
#   GREEN
#   NC
# Locals:
#   file
# Arguments:
#   None
# Outputs:
#   Prints, on the standard output, a message that the permissions 
#   are granted to the file.
######################################################################
function grant_permissions() {
    chmod 700 "${file}"

    echo -e "\n"${GREEN}""${file}" is now readable and editable only by you."${NC}""
}

######################################################################
# Generates multiple random passwords with the length chose by the
# user and store them into .csv file.
#
# Globals:
#   BLUE
#   NC
#   GREEN
#
#   ALL_CHARACTERS
#   ARGUMENTS_PASSWORD_MIN_LENGTH
#   ARGUMENTS_PASSWORD_MAX_LENGTH
# Locals:
#   one_password
#   password_length
#   password
# Argument:
#   -g
# Outputs:
#   Prints, on the standard output, the name of the file 
#   containing the passwords.
######################################################################
function multiple_passwords() {
    echo -e ""${BLUE}"[!] Password length must be in this range : [ "${ARGUMENTS_PASSWORD_MIN_LENGTH}" ; "${ARGUMENTS_PASSWORD_MAX_LENGTH}" ]"${NC}""

    local password_length=""

    while ! [[ "${password_length}" =~ ^[0-9]+$ ]] || 
        test "${password_length}" -lt "${ARGUMENTS_PASSWORD_MIN_LENGTH}" ||
        test "${password_length}" -gt "${ARGUMENTS_PASSWORD_MAX_LENGTH}"
    do
        read -p "Enter a length for your passwords : " password_length 
    done

    local file="${file_directory}"/"${file_name_and_extension}"

    local number_passwords_generated=0
    local passwords_generated=()

    while test "${number_passwords_generated}" -lt "${ARGUMENTS_PASSWORD_NUMBER}"
    do
        local password=$(< /dev/urandom tr -dc "${ALL_CHARACTERS}" | head -c "${password_length}" | tr -d '\n')

        # check if the password doesn't have the minimal requirements or if the password is a duplicate
        while ! test $(echo "${password}" | grep "${ALL_CHARACTERS_REGEX}") || [[ "${passwords_generated[@]}" =~ "${password}" ]]
        do
            local password=$(< /dev/urandom tr -dc "${ALL_CHARACTERS}" | head -c "${password_length}" | tr -d '\n')
        done

        passwords_generated+=($password)
        echo -e "${password}" | tr " " " " >> "${file}"
        let "number_passwords_generated=number_passwords_generated+1"
    done
    
    echo -e ""${GREEN}""${file}" file has been generated successfully !"

    grant_permissions
}

######################################################################
# Displays instructions on using the script.
#
# Globals:
#   None
# Locals:
#   None
# Argument:
#   -h
# Outputs:
#   Prints, on the standard output, usage instructions for the script.
######################################################################
function help_user() {
    echo "password-generator {
    -g
        • generate a random password with the length ∈ [ 8 ; 100 ] chose by the user
    -g <number_passwords_to_generate>
        • generate multiple random passwords with the desired number ∈ [ 2 ; 150 ] and the length ∈ [ 8 ; 100 ] chose by the user
    -h
        • help 
    }"
}

######################################################################
# Main program
######################################################################
if test "${#}" -eq 0 
then 
    help_user
else 
    case "${1}" in
        -g)
            echo -e ""${BLUE}"[!] For multiple random passwords mode, the desired number must be in this range : [ "${ARGUMENTS_PASSWORD_MIN_NUMBER}" ; "${ARGUMENTS_PASSWORD_MAX_NUMBER}" ]"${NC}""
            generate ;;
        -h)
            help_user ;;
        *)
            help_user ;;
    esac
fi