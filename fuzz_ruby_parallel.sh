#!/bin/bash

set -e

. ~/.bashrc

cd ~/ym/afl-yjit

chruby ruby-yjit-afl

set -x

# Use simple core dumps so AFL can get and parse them (mandatory)
sudo bash -c "echo core >/proc/sys/kernel/core_pattern"

# Turn off CPU scaling - some hosts don't have this file
sudo bash -c "cd /sys/devices/system/cpu && echo performance | tee cpu*/cpufreq/scaling_governor"

# Turn off Transparent Huge Pages (THP)
sudo bash -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"

# Tune the Linux scheduler
sudo bash -c "echo 1 >/proc/sys/kernel/sched_child_runs_first"
sudo bash -c "echo 1 >/proc/sys/kernel/sched_autogroup_enabled"

# General-purpose small-script tuning -- we don't seem to often hit this time limit
export AFL_TUNING="-m 400 -t 2000 -x afl-ruby.dict"
export YJIT_CMD="ruby --disable-gems --yjit-call-threshold=1"

# Command to resume a run from the output directory
#afl-fuzz -i- -o output $AFL_TUNING -- $YJIT_CMD

for i in 0{1..9} {10..95}
do
    #export FAKE_BUG=true
    afl-fuzz -i afl-input -o output -S bg_fuzzer_${i} $AFL_TUNING -- $YJIT_CMD >nd${i}.log &
done

# Command to start a new "quick and dirty" run from dictionary and/or input example
afl-fuzz -i afl-input -o output -M lead_fuzzer $AFL_TUNING -- $YJIT_CMD

