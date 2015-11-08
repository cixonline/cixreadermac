#!/bin/sh

# Config
xauto="${OBJROOT}/autorevision.h"
cauto="${OBJROOT}/autorevision.cache"
fauto="${SRCROOT}/CIXReader/src/autorevision.h"

# Ensure svn update
svn update

# Check our paths
if [ ! -d "${BUILT_PRODUCTS_DIR}" ]; then
	mkdir -p "${BUILT_PRODUCTS_DIR}"
fi
if [ ! -d "${OBJROOT}" ]; then
	mkdir -p "${OBJROOT}"
fi

if ! ./autorevision/autorevision.sh -o "${cauto}" -t sh; then
	exit ${?}
fi

# Source the initial autorevision output for filtering.
. "${cauto}"

# Trunk builds are always beta
case "${VCS_BRANCH}" in
    *trunk*)
        isbeta=1
        FULL_VCS_NUM="1.51.${VCS_NUM} Beta"
    ;;
    *)
        isbeta=0
        FULL_VCS_NUM="1.51.${VCS_NUM}"
    ;;
esac

# Output for (objroot)/autorevision.h.
echo "#define VCS_NUM	${VCS_NUM}">${xauto}
echo "#define FULL_VCS_NUM	${FULL_VCS_NUM}">>${xauto}
echo "#define VCS_BETA	${isbeta}">>${xauto}

echo "VCS_BETA=${isbeta}">>${cauto}

# Copy to src folder
cp ${xauto} ${fauto}

exit ${?}
