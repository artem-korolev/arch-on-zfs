#!/bin/bash

# Binance
export BTC_WALLET=3NTy34RgFxDnDQCkxgjXprpQveNCcnyDVJ
export WORKERPWD=x
export WORKERNAME=rtx3090

cd /home/ethminer/

# ETHMINER
#~/src/ethminer-git/build/ethminer/ethminer --pool stratum+tcp://prorokxp.001:123456@ethash.poolbinance.com:443

# Binance + NBMiner / ethhash [WORKING]
#~/NBMiner_Linux/nbminer -i 99 -a ethash -o stratum+tcp://ethash.poolbinance.com:443 -u prorokxp.001 -p 123456

# NiceHash + NBMiner / kawpow [WORKING]
#./NBMiner_Linux/nbminer --lhr 0 -i 90 -a kawpow -o stratum+tcp://kawpow.eu-west.nicehash.com:3385 -u 3NTy34RgFxDnDQCkxgjXprpQveNCcnyDVJ.rtx3090 --mt 6
#./gminer/miner -i 96 --algo equihash --server kawpow.eu-west.nicehash.com:3385 -u 3NTy34RgFxDnDQCkxgjXprpQveNCcnyDVJ.rtx3090

# Binance + GMiner (96% intensity allows to use X11 programs on desktop Linux machine, when mining)
#./gminer/miner -i 98 --algo ethash --server ethash.poolbinance.com:8888 --user prorokxp
./gminer/miner -i 98 --algo ethash --server ethash.poolbinance.com:8888 --user prorokxp.001 --dag_mode 2 --safe_dag 1 --lhr 1 --lhr_tune 1 --lock_cclock 940

#./ethminer --pool stratum+tcp://3NTy34RgFxDnDQCkxgjXprpQveNCcnyDVJ.RTX3090:x@octopus.eu-north.nicehash.com:3389
#./ethminer --pool stratum+tcp://3NTy34RgFxDnDQCkxgjXprpQveNCcnyDVJ.RTX3090:x@octopus.eu-west.nicehash.com:3389
#./ethminer -U -F http://ethereum.eu.nicehash.com:3500/n1c3-3NTy34RgFxDnDQCkxgjXprpQveNCcnyDVJ.RTX3090/100
#./ethminer -U -P daggerhashimoto.eu.nicehash.com:3353 -O 3NTy34RgFxDnDQCkxgjXprpQveNCcnyDVJ --stratum-protocol 2
