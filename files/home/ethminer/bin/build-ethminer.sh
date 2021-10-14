#!/bin/bash

BRANCH=master

cd /home/ethminer/src
if [ ! -d /home/ethminer/src/ethminer ]; then
   git clone https://github.com/ethereum-mining/ethminer.git ethminer-git
fi

cd ethminer-git
git checkout ${BRANCH}
git submodule update --init --recursive
git fetch origin 47348022be371df97ed1d8535bcb3969a085f60a
git cherry-pick 47348022be371df97ed1d8535bcb3969a085f60a
rm -Rf build
mkdir build
cd build
cmake .. -DETHDBUS=OFF -DETHASHCL=OFF -DETHASHCUDA=ON
cmake --build .
