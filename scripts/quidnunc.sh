#!/bin/bash

# Now we have basic settings, import functions...

. "$(dirname $0)"/quidnunc.config
. "$(dirname $0)"/quidnunc_lib.sh
. "$(dirname $0)"/quidnunc_s3_upload.sh #Plugin

check_paths_are_dirs "$SOURCEDIR" "$ARCHIVEDIR" "$UPLOADDIR" "$WRAPPERDIR" "$PIDDIR"|| exit 255

#function launch_wrappers {
#    log info "WRAPPER DIR IS $WRAPPERDIR"
#    for FILE in "$WRAPPERDIR"/cam*wrapper.sh; do
#        echo Launching "${FILE}"
#        "${FILE}" "$$" &
#        echo "$!" > "${WRAPPER_DIR}"/wrap_"$(basename ${FILE})".pid
#    done
#}
#
#trap cleanup_wrappers EXIT


#function background_arch_existing {
#    for FILE in "${1}"/*; do
#        archive "$(get_abs_filename $FILE)"
#    done
#
#}

# Make sure old files are gotten...
#background_arch_existing "${1}" #No longer needed.

#Launch the wrappers
#launch_wrappers

# Now watch and archive new ones.
watch_and_archive

