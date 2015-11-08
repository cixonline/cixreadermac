#!/bin/bash

# Config
lprojDir="./CIXReader/Resources/CIXReader Help/Contents/Resources"
lprojList=$(\ls -1 "${lprojDir}" | sed -n 's:\.lproj$:&:p' | sed -e 's:\.lproj::')


# Index the help files.
for lang in ${lprojList}; do
	helpDir="${lprojDir}/${lang}.lproj"
	if [[ -d "${helpDir}" ]]; then
		echo "Setting up for ${lang} ..."
		case "${lang}" in
			ja|ko|zh_CN|zh_TW)
				MIN_TERM="1"
			;;
			*)
				MIN_TERM="3"
		esac
		case "${lang}" in
			en|de|es|fr|sv|hu|it)
				/usr/bin/hiutil -C -avv -m "${MIN_TERM}" -s "${lang}" -f "${helpDir}/CIXReader.helpindex" "${helpDir}"
			;;
			*)
				/usr/bin/hiutil -C -avv -m "${MIN_TERM}" -f "${helpDir}/CIXReader.helpindex" "${helpDir}"
		esac
	fi
done

exit 0
