#!/bin/bash
# start_fpga.sh - FPGA services launcher with fixed library paths

# Set environment variables for non-interactive shells
export HOME=/home/admin
export USER=admin
export CORE_LOCAL_IP=192.168.0.106
export CORE_MASTER_ADDR=192.168.0.106:10010

# Include both lib and lib64 for yaml-cpp and other dependencies
export PATH=$HOME/.local/bin:$HOME/corgi_ws/install/bin:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=$HOME/.local/lib:$HOME/.local/lib64:$HOME/corgi_ws/install/lib:$HOME/corgi_ws/install/lib64:/usr/lib:/lib

GRPC_BIN="grpccore"
DRIVER_BIN="/home/admin/corgi_ws/fpga_driver/build/fpga_driver"

cd /home/admin
# Kill the entire process group on exit to clean up children
trap "kill -- -$$ 2>/dev/null" INT TERM EXIT

# 1. Start grpccore
$GRPC_BIN > /dev/null 2>&1 &
sleep 5

# 2. Start fpga_driver with explicit library path
if [ -f "$DRIVER_BIN" ]; then
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH "$DRIVER_BIN" > /dev/null 2>&1 &
    DRIVER_PID=$!
    # Wait for the driver process to exit
    wait $DRIVER_PID
else
    exit 1
fi
