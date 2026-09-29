#!/bin/bash -e 

# Usage:
# PROJ_DATA_DIR=/path/to/PROJ-data ./build_lv14_2020.sh

PROJ_DATA_DIR="${PROJ_DATA_DIR:=..}"
echo PROJ_DATA_DIR=$PROJ_DATA_DIR

# Setup build directory
mkdir -p build

# Copy input file into build directory
wget https://s3.storage.pub.lvdc.gov.lv/lgia-opendata/citi/LKS-2020_darba_faili/LV14_2020_02072025.zip -P ./build/
unzip -j ./build/LV14_2020_02072025.zip -d ./build
orig=LV14_2020.gri
input=LV14_2020.asc
input_tif=LV14_2020.tif
output=lv_lgia_LV14_2020.tif
awk 'NR==1{print "NCOLS "($4-$3)/$6+1 "\nNROWS "($2-$1)/$5+1 "\nXLLCENTER "$3 "\nYLLCENTER "$1  "\nCELLSIZE "$6} NR>1{print $0}' ./build/$orig > ./build/$input
# this assumes that $5 and $6 are the same. If not, DX and DY should be used instead of CELLSIZE. https://gdal.org/en/stable/drivers/raster/aaigrid.html
# produces this header
# NCOLS 297
# NROWS 101
# XLLCENTER 20.900000
# YLLCENTER 55.600000
# CELLSIZE 0.02500000

head ./build/$input

#####
# this is not needed for the conversion. It just creates a valid xyz as "lat lon z"
temp_xyz=./build/lv_2020.tmp.xyz
gdal_translate ./build/$input $temp_xyz -co DECIMAL_PRECISION=5 
awk '{printf("%s %s% 9.3f\n",$2, $1, $3)}' $temp_xyz | sort -n -k 1,1r -k 2,2 > ./build/lv_2020.xyz
#####

gdal_translate -of GTiff -a_nodata 9999 ./build/$input ./build/$input_tif

docker run --user $(id -u):$(id -g) --workdir $PWD \
            --rm -v /home:/home ghcr.io/osgeo/gdal:alpine-normal-latest \
            sh -c " \
            # Call vertoffset_grid_to_gtiff-script 
            python3 ${PROJ_DATA_DIR}/grid_tools/vertoffset_grid_to_gtiff.py \
            --type GEOGRAPHIC_TO_VERTICAL \
            --parameter-name geoid_undulation \
            --source-crs \"EPSG:10304\" \
            --target-crs \"EPSG:7700\" \
            --description \"ETRS89-LVA [LKS-2020] (EPSG:10304) to Latvia 2000 height (EPSG:7700). Converted from $orig\" \
            --area-of-use \"Latvia - onshore\" \
            --copyright \"Derived from work by Latvian Geospatial Information Agency. CC-BY-4.0 https://creativecommons.org/licenses/by/4.0/\" \
            ./build/$input_tif ./$output && \
            # Run check_gtiff_grid-script
            python3 ${PROJ_DATA_DIR}/grid_tools/check_gtiff_grid.py ./$output \ 
            # Show info
            gdalinfo ./$output "

# Remove build directory
rm -rf build
