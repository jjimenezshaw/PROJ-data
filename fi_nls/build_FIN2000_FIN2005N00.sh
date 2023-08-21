#!/bin/bash -e 

# Usage:
# PROJ_DATA_DIR=/path/to/PROJ-data ./build_FIN2000_FIN2005N00.sh

# Setup build directory
mkdir -p build
rm -f build/*

run_one () {
    vert_code=$1
    vert_name=$2
    orig=$3
    input=$3.xyz
    output=$4
    echo " lat lon z" > ./build/$input
    sed 's/ 0.000/ nan/g' $orig >> ./build/$input
    docker run --user $(id -u):$(id -g) --workdir $PWD \
            --rm -v /home:/home ghcr.io/osgeo/gdal:alpine-normal-latest \
            sh -c " \
            # Call vertoffset_grid_to_gtiff-script 
            python3 ${PROJ_DATA_DIR}/grid_tools/vertoffset_grid_to_gtiff.py \
            --type GEOGRAPHIC_TO_VERTICAL \
            --parameter-name geoid_undulation \
            --source-crs \"EPSG:4937\" \
            --target-crs \"$vert_code\" \
            --description \"ETRS89 (EPSG:4937) to $vert_name ($vert_code). Converted from $orig\" \
            --area-of-use \"Finland\" \
            --copyright \"Derived from work by NLS (MMT) Finland. CC-BY-4.0 https://creativecommons.org/licenses/by/4.0/\" \
            ./build/$input ./$output && \
            # Show info
            gdalinfo ./$output "
}

run_one "EPSG:3900" "N2000 height" "FIN2005N00.lst" "fi_nls_FIN2005N00.tif"
run_one "EPSG:5717" "N60 height" "FIN2000.lst" "fi_nls_FIN2000.tif"
# Remove build directory
rm -rf build
