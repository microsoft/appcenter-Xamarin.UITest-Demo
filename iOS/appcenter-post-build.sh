#!/usr/bin/env bash

echo "Start Test upload script (ac-test-run.sh)"
sh ac-test-run.sh
echo "Finish Test upload script (ac-test-run.sh)"

echo "Start Distribute script (ac-distribute.sh)"
sh ac-distribute.sh
echo "Finish Distribute script (ac-distribute.sh)"

echo "end post-build script"