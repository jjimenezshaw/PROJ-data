#!/bin/bash -e

# https://www.lgia.gov.lv/en/latvijas-kvazigeoida-modelis
# Download https://s3.storage.pub.lvdc.gov.lv/lgia-opendata/citi/geodezija/kvazigeoida_modelis.zip

# Usage:
# PROJ_DATA_DIR=/path/to/PROJ-data ./build_LV14.sh

orig=./LV\'14.dat

# Setup build directory
mkdir -p build

output=lv_lgia_LV14.tif
tmp=./build/tmp.xyz
input=./build/xyz.tif
echo "lat lon z" > $tmp
sort -s -k1,1r -k2,2 "$orig" >> $tmp
gdal_translate -if XYZ -of GTIFF $tmp $input -a_nodata 9999
orig=`basename $orig`


docker run --user $(id -u):$(id -g) --workdir $PWD \
            --rm -v /home:/home ghcr.io/osgeo/gdal:alpine-normal-latest \
            sh -c " \
            # Call vertoffset_grid_to_gtiff-script
            python3 ${PROJ_DATA_DIR}/grid_tools/vertoffset_grid_to_gtiff.py \
            --type GEOGRAPHIC_TO_VERTICAL \
            --parameter-name geoid_undulation \
            --source-crs \"EPSG:4949\" \
            --target-crs \"EPSG:7700\" \
            --description \"LKS-92 (EPSG:4949) to Latvia 2000 height (EPSG:7700). Converted from $orig\" \
            --area-of-use \"Latvia\" \
            --copyright \"Derived from work by LGIA Latvia. CC-BY-4.0 https://creativecommons.org/licenses/by/4.0/\" \
            ./$input ./$output && \
            # Show info
            gdalinfo ./$output "

# Remove build directory
rm -rf build
