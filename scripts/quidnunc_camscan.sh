#!/bin/bash

. "$(dirname $0)"/quidnunc.config
. "$(dirname $0)"/quidnunc_lib.sh

camera_get_candidates > "${CAMERA_DISCOVERY_FILE}"

