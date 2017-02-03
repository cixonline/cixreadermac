#!/bin/bash

. "${OBJROOT}/autorevision.cache"

# Bump up GIT version number to base off the old SVN number
VCS_NUM=$(($VCS_NUM + 600))

# values set in project-all.xcconfig
VIENNA_UPLOADS_DIR="${BUILT_PRODUCTS_DIR}/Uploads"
DOWNLOAD_BASE_URL="https://cixreader.cixhosting.co.uk/cixreader/osx"

if [ ${VCS_BETA} -eq 0 ]; then
    DOWNLOAD_SUB_DIR="release";
else
    DOWNLOAD_SUB_DIR="beta";
fi

VERSION="1.64.${VCS_NUM}"

DMG_FILENAME="cr_osx${VERSION}.dmg"
dSYM_FILENAME="cr_osx${VERSION}-dSYM"

VIENNA_CHANGELOG="appcast.xml"

DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL}/${DOWNLOAD_SUB_DIR}"

# Zip up the app
if [ ! -d "${VIENNA_UPLOADS_DIR}" ]; then
	mkdir -p "${VIENNA_UPLOADS_DIR}"
fi
cd "${VIENNA_UPLOADS_DIR}"

# Copy down the latest changes file
cp "${BUILT_PRODUCTS_DIR}/Changes.html" .
cp "${BUILT_PRODUCTS_DIR}/ChangesShort.html" .

# Copy the app cleanly
rsync -clprt --del --exclude=".DS_Store" "${BUILT_PRODUCTS_DIR}/CIXReader.app" "${VIENNA_UPLOADS_DIR}"
if [ -f "${DMG_FILENAME}" ]; then
	rm "${DMG_FILENAME}"
fi
hdiutil create "${DMG_FILENAME}" -srcfolder "${VIENNA_UPLOADS_DIR}/CIXReader.app" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW 
rm -rf CIXReader.app

# Output the sparkle change log
cd "${VIENNA_UPLOADS_DIR}"

pubDate="$(LC_TIME=en_US date -jf '%FT%T%z' "${VCS_DATE}" '+%a, %d %b %G %T %z')"
DMGSIZE="$(stat -f %z "${DMG_FILENAME}")"

cat > "${VIENNA_CHANGELOG}" << EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
	<channel>
		<title>CIXReader Version ${VERSION}</title>
        <link>${DOWNLOAD_BASE_URL}/appcast.xml</link>
		<description>Most recent changes with links to updates.</description>
		<language>en-us</language>
		<copyright>Copyright 2014-2016, CIXOnline Ltd</copyright>
		<item>
			<title>Version ${VERSION}</title>
			<pubDate>${pubDate}</pubDate>
			<link>${DOWNLOAD_BASE_URL}/${DMG_FILENAME}</link>
			<sparkle:minimumSystemVersion>${MACOSX_DEPLOYMENT_TARGET}.0</sparkle:minimumSystemVersion>
			<enclosure url="${DOWNLOAD_BASE_URL}/${DMG_FILENAME}" sparkle:version="${VCS_NUM}" sparkle:shortVersionString="${VERSION}" length="${DMGSIZE}" type="application/octet-stream"/>
			<sparkle:releaseNotesLink>${DOWNLOAD_BASE_URL}/ChangesShort.html</sparkle:releaseNotesLink>
		</item>
	</channel>
</rss>

EOF

exit 0
