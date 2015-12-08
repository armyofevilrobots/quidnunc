#!/bin/bash
FSWATCH=/usr/local/bin/fswatch
LSOF=/usr/sbin/lsof
FACILITY=local3

. "$(dirname $0)"/quidnunc_lib.sh


function showhelp {
    log error "ready_to_archive_iterator.sh <SOURCEPATH> <TARGETPATH> <UPLOADPATH>"
}

function log {
    PRI="$FACILITY.$1"
    shift 1
    logger -s -t quidnunc -p $PRI $@
}

function get_abs_filename() {
    # $1 : relative filename
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

if [[ -z "$3" ]]; then
    showhelp
    log error "MUST SET TARGET PATHS"
    exit 0
fi

SOURCEDIR="$(get_abs_filename $1)"
ARCHIVEDIR="$(get_abs_filename $2)"
UPLOADDIR="$(get_abs_filename $3)"



function check_paths_are_dirs {
   #Make sure all args are actually dirs.
   log info "CHECKING PATH $1"
   if [[ -d "$1" ]]; then
       shift 1
       check_paths_are_dirs $@
   elif [[ -z $1 ]]; then
       log info "DONE CHECKING PATHS"
   else
       log error "PATH '$1' is not a dir."
       return 1
   fi
   return 0
}


function archive {
    FILE="$1"
    if [[ -f "${FILE}" ]]; then
        if lsof -t -- "$FILE"; then
            log info "SKIPPING opened file '$FILE'"
        else
            log info "ARCHIVE '$FILE' to '$ARCHIVEDIR'"
            #cp "${FILE}" "${UPLOADDIR}"
            #mv "${FILE}" "${ARCHIVEDIR}"
        fi
    fi
}

function watch_and_archive {
    log info "Watching $SOURCEDIR"
    fswatch "$SOURCEDIR" | while read FILE; do
        archive "$FILE"
    done
}


check_paths_are_dirs "$SOURCEDIR" "$ARCHIVEDIR" "$UPLOADDIR" || exit 255

for FILE in "${1}"/*; do
    archive "$(get_abs_filename $FILE)"
done
watch_and_archive

