#!/bin/bash

# Monitor System Health

HOSTNAME=$(hostname)
UPTIME=$(uptime -s)

# Setting Limit/ Threshold for the system
CPU_LIMIT=80
MEMORY_LIMIT=80
DISK_WARNING=75
DISK_CRITICAL=90


echo "==============================================="
echo "          SERVER MONITORING SYSTEM             "
echo "==============================================="

echo "Hostname              : $HOSTNAME"
echo "UP Time               : $UPTIME"

echo "-----------------------------------------------"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}') #us-> user proces , sy-> kernal processes , id -> cpu idle
                                                                #100-idle cpu usage = active cpu usage
echo -n "CPU Usage             : $CPU_USAGE%"

if (( $(echo "$CPU_USAGE > $CPU_LIMIT" | bc -l) )); then
    echo " [WARNING: CPU usage exceeds $CPU_LIMIT%]"
else
    echo " [OK]"
fi



echo "-----------------------------------------------"

MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100}')
echo -n "Memory Usage          : $MEMORY_USAGE%"

if (( $(echo "$MEMORY_USAGE > $MEMORY_LIMIT" | bc -l) )); then
    echo " [WARNING: Memory usage exceeds $MEMORY_LIMIT%]"
else
    echo " [OK]"
fi


echo "-----------------------------------------------"

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

echo -n "Disk Usage            : $DISK_USAGE%"

if (( DISK_USAGE >= DISK_CRITICAL )); then
    echo " [CRITICAL: Disk usage exceeds $DISK_CRITICAL%]"
elif (( DISK_USAGE >= DISK_WARNING )); then
    echo " [WARNING: Disk usage exceeds $DISK_WARNING%]"
else
    echo " [OK]"
fi


echo "-----------------------------------------------"

echo "Checking Docker Status..."


if command -v docker 2&> /dev/null; then
    DOCKER_STATUS=$(systemctl is-active docker)
    echo "Docker Service Status: $DOCKER_STATUS"
    echo " "
    if [ "$DOCKER_STATUS" == "active" ]; then
        echo -e "Running Docker Containers:"
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    else
        echo "Docker service is not running."
    fi
else
    echo "Docker is not installed on this system."
fi

# ---------- Systemd Services ----------
echo "-----------------------------------------------"
echo "Services:"

SERVICES=("nginx" "docker" "ssh")

for SERVICE in "${SERVICES[@]}"; do

    if systemctl is-active --quiet "$SERVICE"; then
        echo "  $SERVICE:        ACTIVE"
    else
        echo "  $SERVICE:        INACTIVE"
    fi

done
echo "-----------------------------------------------"
# ---------- Listening Ports ----------
echo "Listening Ports:"

ss -lntp | awk 'NR>1 {print $4, $6}' | while read -r line; do

    PORT=$(echo "$line" | awk '{print $1}')

    PROCESS=$(echo "$line" | awk '{print $2}')

    echo "  Port: $PORT, Process: $PROCESS"

done

