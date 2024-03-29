#!/bin/bash

set -u

# Ask yes/no question, returning true or false in the global variable boolYNQuestionAnswer
boolAskYNQuestion()
{
  declare -g boolYNQuestionAnswer=false
  echo -n "$1" "Answer y/n [""$2""]: "
  read ans
  if [ -z "$ans" ]; then
    if [ "$2" = "y" ]; then
      boolYNQuestionAnswer="true"
    fi
  elif [ "$ans" = "y" ]; then
    boolYNQuestionAnswer=true
  else
    boolYNQuestionAnswer=false
  fi
}

# Ask user for version input
echo
read -p 'Enter release base version number on the form a.b.c  (tag without v): ' baseversion
if [[ -z $baseversion ]]; then
    echo Error: Must give a base version
    exit 1
fi

# Ask user for release date
echo
read -p 'Enter release date on the form YYYY-MM-DD: ' releasedate
if [[ -z $releasedate ]]; then
    echo Error: Must give a release date
    exit 1
fi

# Ask user for release "revision"
# TODO Get this information automatically from git
#$(./getGitInfo.sh date.time .)
echo
read -p 'Enter release revision: ' releaserevision
if [[ -z $releaserevision ]]; then
    echo Error: Must give a release revision
    exit 1
fi

# Ask user for git hash
# TODO Get this information automatically from git
echo
read -p 'Enter release commit hash: ' commithash
if [[ -z $commithash ]]; then
    echo Error: Must give a commit hash
    exit 1
fi


readonly fullversionname=${baseversion}.${releaserevision}

echo
boolAskYNQuestion "Do you want to build a development release?" "y"
doDevRelease="${boolYNQuestionAnswer}"

echo
echo ---------------------------------------
echo Build DEVELOPMENT release: $doDevRelease
echo Release base version number: $baseversion
echo Release commit hash: $commithash
echo Release date: $releasedate
echo Release revision number: $releaserevision
echo Release full version string: $fullversionname
echo ---------------------------------------
boolAskYNQuestion "Is this OK?" "n"
if [ "${boolYNQuestionAnswer}" = false ]; then
  echo Aborting!
  exit 1
fi


# Prepare flatpak files
manifest=com.github.hopsan.Hopsan.json
appdata=com.github.hopsan.Hopsan.appdata.xml

cp -f ${manifest}.in ${manifest}
sed "s|HOPSAN_FULL_RELEASE_VERSION|${fullversionname}|g" -i ${manifest}
sed "s|HOPSAN_BASE_VERSION|${baseversion}|g" -i ${manifest}
sed "s|HOPSAN_COMMIT_HASH|${commithash}|g" -i ${manifest}
sed "s|HOPSAN_RELEASE_REVISION|${releaserevision}|g" -i ${manifest}
sed "s|HOPSAN_DEVELOPMENT_RELEASE|${doDevRelease}|g" -i ${manifest}

grep -F ${baseversion} ${appdata} 2>&1 > /dev/null
if [[ $? -eq 1 ]]; then
    releasetag="\ \ \ \ <release version=\"${baseversion}\" date=\"$releasedate\">\n      <description>\n        <p>See Hopsan-release-notes.txt for the full changelog.</p>\n      </description>\n    </release>"
    sed "/<releases>/a ${releasetag}/" -i ${appdata}
else
  echo Info: ${baseversion} is already in ${appdata} not adding it again
fi

appstream-util upgrade ${appdata}
appstream-util validate ${appdata}

echo Done preparing ${manifest} and ${appdata}
echo
