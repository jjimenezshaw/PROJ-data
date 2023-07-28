#!/bin/bash -e 

# https://geoportal.cuzk.cz/(S(s1ba0icqjtrcrgflitle1fit))/Default.aspx?mode=TextMeta&side=bodpole&metadataID=CZ-CUZK-QGZU&head_tab=sekce-02-gp&menu=275
# Download https://geoportal.cuzk.cz/opendata/QGZU/KVAZIGEOID.zip

# Usage:
# PROJ_DATA_DIR=/path/to/PROJ-data ./build_QGZU-2013.sh /path/to/KVAZIGEOID/folder

if [[ -d "$1" ]]; then
    echo "Content of used directory (*.txt)"
    ls -lh $1/*.txt
else
    echo "First parameter must be a directory"
    exit 1
fi

# Setup build directory
mkdir -p build

orig=KVAZIGEOID.zip
output=cz_cuzk_QGZU-2013.tif
tmp=./build/tmp.xyz
input_xyz=./build/xyz.xyz
input=./build/xyz.tif
echo "lat lon z" > $tmp
cat $1/*.txt >> $tmp
sort -s -k1,1r -k2,2 $tmp -o $input_xyz
gdalwarp -dstnodata -9999 $input_xyz $input


docker run --user $(id -u):$(id -g) --workdir $PWD \
            --rm -v /home:/home ghcr.io/osgeo/gdal:alpine-normal-latest \
            sh -c " \
            # Call vertoffset_grid_to_gtiff-script 
            python3 ${PROJ_DATA_DIR}/grid_tools/vertoffset_grid_to_gtiff.py \
            --type GEOGRAPHIC_TO_VERTICAL \
            --parameter-name geoid_undulation \
            --source-crs \"EPSG:4937\" \
            --target-crs \"EPSG:8357\" \
            --description \"ETRS89 (EPSG:4937) to Baltic 1957 height (EPSG:8357). Converted from $orig\" \
            --area-of-use \"Czechia\" \
            --copyright \"Derived from work by ČÚZK Czechia. CC-BY-4.0 https://creativecommons.org/licenses/by/4.0/\" \
            ./$input ./$output && \
            # Show info
            gdalinfo ./$output "

# Remove build directory
rm -rf build
