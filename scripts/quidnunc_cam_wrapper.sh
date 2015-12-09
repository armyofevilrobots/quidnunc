#!/bin/bash

MY_MAC=$(echo "$(basename $0)"| sed "s/^cam_//" | sed "s/_wrapper.*//")
if [[ $(uname) == "Darwin" ]]; then
    SELF=$(readlink  $0) # /me hates bsd utils
else
    SELF=$(readlink -f $0)
fi
FFMPEG_PID=

. "$(dirname $SELF)"/quidnunc.config
. "$(dirname $SELF)"/quidnunc_lib.sh



while true; do
    log info "Top of camera loop for ${MY_MAC}"
    if [[ ! -f "${CAMERA_DISCOVERY_FILE}" ]]; then
        log warn "Regenerating camera discovery file."
        camera_get_candidates > "${CAMERA_DISCOVERY_FILE}"
        continue;
    elif [[ $(grep "${MY_MAC}" "${CAMERA_DISCOVERY_FILE}") == "" ]]; then
        log info grep "${MY_MAC}" "${CAMERA_DISCOVERY_FILE}"
        log warn "CAMWRAP: Could not find cam IP for camera ${MY_MAC}. Sleeping..."
        sleep 30
        camera_get_candidates > "${CAMERA_DISCOVERY_FILE}"
        continue;
    fi

    MY_IP="$(cat "${CAMERA_DISCOVERY_FILE}" | grep "${MY_MAC}" | cut -f 2 -d,)"
    URINAME=CAM_${MY_MAC}_URI
    URI="$(eval "echo \$${URINAME}")"
    URI="$(echo "$URI"|sed "s/%IP%/${MY_IP}/")"

    ping -c 1 "${MY_IP}" &>/dev/null || ( \
        log error "Could not ping camera ${MY_MAC}"; \
        sleep 5; \
        continue )

    function die {
        kill $FFMPEG_PID
    }

    trap die EXIT

    log info "Connecting to camera at ${MY_MAC} with IP ${MY_IP} for ${SELF}"
    $FFMPEG -y -loglevel error -i "${URI}" \
           -f dshow -vcodec copy  -acodec copy \
           -tune zerolatency -vsync 1 -async 1 \
           -f segment  -segment_time 60 -segment_atclocktime 1 -map 0 \
           -strftime 1 "${SOURCEDIR}/${MY_MAC}-%Y-%m-%dT%H:%M:%S.mpg" || sleep 5
    FFMPEG_PID=$!
done
