#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
echo $SCRIPT_DIR

# FIXME: ディレクトリ移動しなくてもいいような書き方にしてほしい
cd $SCRIPT_DIR
cd certificate && ./setup.sh
cd $SCRIPT_DIR
cd configuration && ./setup.sh
cd $SCRIPT_DIR
cd secrets && ./setup.sh
cd $SCRIPT_DIR
cd etcd && ./setup.sh
cd $SCRIPT_DIR
cd control && ./setup.sh
cd $SCRIPT_DIR
cd worker && ./setup.sh
