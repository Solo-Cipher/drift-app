#!/bin/sh
# Roamy web server startup script
# Place in /opt/data/roamy_clone/start_server.sh

cd /opt/data/roamy_clone

# Kill any existing server
pkill -f "python3 server.py" 2>/dev/null
sleep 1

# Start server on port 80
nohup python3 server.py > /opt/data/roamy_clone/server.log 2>&1 &

echo "Roamy server started on port 80 (PID: $!)"
echo "Access at: http://156.67.221.166/"
