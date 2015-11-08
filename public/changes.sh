#!/bin/bash

. "${OBJROOT}/autorevision.cache"

SRC_CHANGES_HTML="${SRCROOT}/public/Changes.html"
OBJ_CHANGES_HTML="${BUILT_PRODUCTS_DIR}/Changes.html"

sed -e s/\$\(VCS_NUM\)/${VCS_NUM}/g -e s/\$\(VCS_BETA\)/${VCS_BETA}/g ${SRC_CHANGES_HTML} > ${OBJ_CHANGES_HTML}

SRC_CHANGES_HTML="${SRCROOT}/public/ChangesShort.html"
OBJ_CHANGES_HTML="${BUILT_PRODUCTS_DIR}/ChangesShort.html"

sed -e s/\$\(VCS_NUM\)/${VCS_NUM}/g -e s/\$\(VCS_BETA\)/${VCS_BETA}/g ${SRC_CHANGES_HTML} > ${OBJ_CHANGES_HTML}
