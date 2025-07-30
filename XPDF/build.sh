#!/bin/bash -eu
# Copyright 2020 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITION S OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

DIR=$(dirname "$(readlink -f "$0")")
TUNER_COMPILER_BIN=${TUNER_COMPILER_BIN:-/usr/bin}
TUNER_FLAGS="${TUNER_FLAGS:--O0} -I"$DIR/xpdf-4.05/xpdf""
TUNER_OUTPUT=${TUNER_OUTPUT:-"$DIR/out"}

if [[ "$TUNER_OUTPUT" == /* ]]; then
	TUNER_OUTPUT="$TUNER_OUTPUT"
else
	TUNER_OUTPUT="$DIR/$TUNER_OUTPUT"
fi

TUNER_OUTPUT=$(realpath "$TUNER_OUTPUT")
TUNER_CORE_COUNT=${TUNER_CORE_COUNT:-$(nproc)}

export CXX="$TUNER_COMPILER_BIN/g++"

cd $DIR

mkdir -p $TUNER_OUTPUT/src
tar -zxf xpdf-4.05.tar.gz -C "$TUNER_OUTPUT/src"
dir_name=`tar -tzf xpdf-4.05.tar.gz | head -1 | cut -f1 -d"/"`
#cd $dir_name

cd $DIR

SRC_DIR="$TUNER_OUTPUT/src/$dir_name"

sed -i '/#--- object files needed by XpdfWidget/, /#--- pdftops/d' "$SRC_DIR/xpdf/CMakeLists.txt"
sed -i '/if (NOT QT4_FOUND AND NOT Qt5Widgets_FOUND AND NOT Qt6Widgets_FOUND)/, /endif ()/d' "$SRC_DIR/CMakeLists.txt"

BUILD_DIR="$TUNER_OUTPUT/build"
mkdir -p "$BUILD_DIR"
cd "$TUNER_OUTPUT/build"

export LD="$CXX"
cmake "$SRC_DIR" -DCMAKE_C_FLAGS="$TUNER_FLAGS" -DCMAKE_CXX_FLAGS="$TUNER_FLAGS" \
  -DOPI_SUPPORT=ON -DSPLASH_CMYK=ON -DMULTITHREADED=ON \
  -DUSE_EXCEPTIONS=ON -DXPDFWIDGET_PRINTING=ON
make

cd $DIR

"$TUNER_COMPILER_BIN/g++" -std=c++17 $TUNER_FLAGS \
    -I"$SRC_DIR/goo" -I"$BUILD_DIR" -I"$SRC_DIR/xpdf" \
    "$SRC_DIR/xpdf/Zoox.cc" \
    "./fuzz_zxdoc.cc" \
    -L"$BUILD_DIR/goo" -L"$BUILD_DIR/fofi" -L"$BUILD_DIR/splash" \
    -lgoo -lfofi -lsplash \
    -o "$TUNER_OUTPUT/tune_me"
