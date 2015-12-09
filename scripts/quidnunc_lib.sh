#!/bin/bash


function cleanup_wrappers {
    for FILE in "$PIDDIR"/wrap_*pid; do
        echo PIDTOKILL="$(cat $FILE)"
        echo kill $PIDTOKILL
        echo rm -f "$FILE"
    done
}

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

function s3_archive_file {
    #Archives $1 file to $2 bucket
    if [[ -z "$QUIDNUNC_EXPIRE_DELTA" ]]; then
        EXPIRY=1m
    else
        EXPIRY=$QUIDNUNC_EXPIRE_DELTA
    fi
    log info "Archiving item $1 to s3://$2"
    aws s3 cp --storage-class=STANDARD_IA \
              --expires=$(date -v +${EXPIRY} -u +"%Y-%m-%dT%H:%M:%SZ") \
              "$1" "s3://${2}" \
    || log error "Could not archive $1 to s3://$2 ERR:$?"
    log info "Success."
    return 0
}

function s3_archive_path {
    # Archives everything matching $1 on path $2 to bucket $3
    # Delete the files, too, if the $4 is set to "true"
    log info "Searching in $2 for files matching $1 to upload to s3"
    find "$2" -iname "$1"  | while read FILE; do
        ACTFILE="$(get_abs_filename "$FILE")"
        log debug "Archiving $ACTFILE"
        s3_archive_file "$ACTFILE" "$3"
        RESULT=$?
        if [[ "$RESULT" == "0" ]]; then
            log debug "REMOVING $ACTFILE"
            rm -f "$ACTFILE"
        else
            log error "FAILED TO UPLOAD $ACTFILE : $RESULT"
        fi
    done
    log info "Done uploading to s3"
}


function archive {
    FILE="$1"
    if [[ -f "${FILE}" ]]; then
        if lsof -t -- "$FILE"; then
            log info "SKIPPING opened file '$FILE'"
        else
            log info "ARCHIVE '$FILE' to '$ARCHIVEDIR'"
            log info "PREP FOR UPLOAD: " "${UPLOADDIR}"/"$(basename "$FILE").tmp"
            cp "${FILE}" "${UPLOADDIR}"/"$(basename "$FILE").tmp"
            mv "${UPLOADDIR}"/"$(basename "$FILE").tmp" "${UPLOADDIR}"/"$(basename "$FILE")"
            log info mv "${FILE}" "${ARCHIVEDIR}"
            mv "${FILE}" "${ARCHIVEDIR}"
        fi
    fi
}


function watch_and_archive {
    log info "Watching $SOURCEDIR"
#    fswatch "$SOURCEDIR" | while read FILE; do
    while true; do
        unset FOUND
        find "$SOURCEDIR" | while read FILE; do
            set FOUND FOUND
            archive "$FILE"
            s3_archive_path "*.mpg" "$UPLOADDIR" "${BUCKET}"
        done
        if [[ -z "$FOUND" ]]; then
            log debug "SLEEPING"
            sleep 20
        fi
    done
}


function camera_get_candidates {
    CAMERACOUNT=0
    nmap  -sn $CAMERA_IP_RANGE -oG - 2>/dev/null |grep ^Host | awk '{print $2}' | while read IPADDR; do
        MACADDR="$(arp -n "$IPADDR" | awk '{print $4}' | sed "s/://g")"
        if [[ ! "$MACADDR" == "(incomplete)" ]]; then
            echo "${MACADDR},${IPADDR}"
        fi
    done
}
