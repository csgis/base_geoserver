#!/bin/bash

# =============================================================================
# GeoServer Extensions Downloader
# Downloads and unpacks GeoServer extensions based on an extensions file
# =============================================================================

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_EXTS_FILE="extensions"
DEFAULT_TARGET_DIR="geoserver-exts"

usage="Usage: $0 -v <gs_version> [-f <exts_file>] [-t <target_dir>] [-h]
  -f  extensions file. Default is '${DEFAULT_EXTS_FILE}' in the current directory.
  -v  GeoServer version (e.g., 2.28.1).
  -t  target directory. Default is '${DEFAULT_TARGET_DIR}' in the current directory.
  -h  Show this help."

extsFile="${PWD}/${DEFAULT_EXTS_FILE}"
targetDir="${PWD}/${DEFAULT_TARGET_DIR}"

while getopts "hv:t:f:" option; do
  case $option in
    v)
      version=${OPTARG};;
    f)
      extsFile=${OPTARG};;
    t)
      targetDir=${OPTARG};;
    h)
      echo "$usage"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 2
      ;;
  esac
done

if [ -z "${version}" ]; then
  echo "Missing GeoServer version."
  echo "$usage"
  exit 3
fi

if [ -d "${targetDir}" ]; then
  echo "[WARN] Target directory already exists: $targetDir"
  echo "[WARN] Extensions will be added/overwritten."
fi

if [ ! -f "${extsFile}" ]; then
  echo "Cannot find '${extsFile}' file."
  exit 1
fi

# Extract major.minor version (e.g., 2.28 from 2.28.1)
majorVersion=$(echo ${version} | grep -Eo "[0-9]+\.[0-9]+")

# URLs for downloading extensions
baseSfUrl="http://sourceforge.net/projects/geoserver/files/GeoServer/${version}/extensions"
baseAresUrl="https://build.geoserver.org/geoserver/${majorVersion}.x/community-latest/"

# Parse extensions file (remove comments and empty lines)
exts=$(sed 's/#.*$//g;/^$/d' ${extsFile} 2>/dev/null)

mkdir -p ${targetDir}
pushd ${targetDir} > /dev/null
echo "[INFO] Downloading extensions to ${targetDir}..."
echo "[INFO] GeoServer version: ${version} (major: ${majorVersion})"
echo ""

for ext in ${exts}; do
  # Community extensions (geofence) come from build server
  if [ "${ext}" == "geofence" ]; then
    filename="geoserver-${majorVersion}-SNAPSHOT-geofence-plugin.zip"
    baseUrl=${baseAresUrl}
  elif [ "${ext}" == "geofence-server" ]; then
    filename="geoserver-${majorVersion}-SNAPSHOT-geofence-server-plugin.zip"
    baseUrl=${baseAresUrl}
  else
    # Official extensions from SourceForge
    filename="geoserver-${version}-${ext}-plugin.zip"
    baseUrl=${baseSfUrl}
  fi

  echo "[INFO] * Extension: $ext..."
  echo "[INFO]   URL: ${baseUrl}/${filename}"
  
  wget -q --show-progress "${baseUrl}/${filename}"

  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to download ${ext}. Skipping."
    continue
  fi

  # Unpack to extension-specific directory
  unzip -q -o -d ${ext} ${filename}
  rm ${filename}
  echo "[INFO]   Done."
done

popd > /dev/null
echo ""
echo "[INFO] All extensions downloaded to: ${targetDir}"
echo "[INFO] Mount this directory to /var/local/geoserver-exts/ in your container."
