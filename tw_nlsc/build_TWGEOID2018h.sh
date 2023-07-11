#!/bin/bash -e 

# Usage:
# PROJ_DATA_DIR=/path/to/PROJ-data ./build_TWGEOID2018h.sh 

# Setup build directory
mkdir -p build

# Copy input file into build directory
wget https://www.isgeoid.polimi.it/Geoid/Asia/Taiwan/public/2018_hybrid_twgeoid.txt --no-check-certificate -P ./build/
orig=2018_hybrid_twgeoid.txt
input=$orig
output=tw_nlsc_TWGEOID2018h.tif

docker run --user $(id -u):$(id -g) --workdir $PWD \
            --rm -v /home:/home ghcr.io/osgeo/gdal:alpine-normal-latest \
            sh -c " \
            # Call vertoffset_grid_to_gtiff-script 
            python3 ${PROJ_DATA_DIR}/grid_tools/vertoffset_grid_to_gtiff.py \
            --type GEOGRAPHIC_TO_VERTICAL \
            --parameter-name geoid_undulation \
            --source-crs \"EPSG:3823\" \
            --target-crs \"EPSG:8904\" \
            --description \"TWD97 (EPSG:3823) to TWVD 2001 height (EPSG:8904). Converted from $orig\" \
            --area-of-use \"Taiwan\" \
            --copyright \"Derived from work by NLSC Taiwan. CC-BY-4.0 https://creativecommons.org/licenses/by/4.0/\" \
            ./build/$input ./$output && \
            # Show info
            gdalinfo ./$output "

# Remove build directory
rm -rf build
