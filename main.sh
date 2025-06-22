#!/bin/which bash
# Detect OS type
os_type=$(uname)

# System info adjustments for macOS, BSD, and Linux
if [[ "$os_type" == "Darwin" ]]; then
    # macOS memory stats
    mem_total=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 "Gi"}')
    mem_used=$(vm_stat | awk '/Pages active/ {active=$3} /Pages wired down/ {wired=$3} END {print (active + wired) * 4096 / 1024 / 1024 / 1024 "Gi"}')
    mem_avail=$(vm_stat | awk '/Pages free/ {free=$3} /Pages speculative/ {spec=$3} END {print (free + spec) * 4096 / 1024 / 1024 / 1024 "Gi"}')
    cpu_utilization=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    disk_usage=$(df -h | grep '/dev/' | awk '{printf "\"%s\":\"%s\",", $NF, $(NF-1)}')

elif [[ "$os_type" == "FreeBSD" || "$os_type" == "OpenBSD" ]]; then
    # BSD memory stats
    mem_total=$(sysctl -n hw.physmem | awk '{print $1/1024/1024/1024 "Gi"}')
    mem_used=$(sysctl -n vm.stats.vm.v_active_count | awk '{print $1*4096 / 1024 / 1024 / 1024 "Gi"}')
    mem_avail=$(sysctl -n vm.stats.vm.v_inactive_count | awk '{print $1*4096 / 1024 / 1024 / 1024 "Gi"}')
    cpu_utilization=$(top -d1 | grep "CPU:" | awk '{print $2}' | sed 's/%//')
    disk_usage=$(df -h | grep '/dev/' | awk '{printf "\"%s\":\"%s\",", $NF, $(NF-1)}')

elif [[ "$os_type" == "Linux" ]]; then
    # Linux memory stats
    mem_avail=$(free -h | awk '/^Mem:/{print $7}')
    mem_total=$(free -h | awk '/^Mem:/{print $2}')
    mem_used=$(free -h | awk '/^Mem:/{print $3}')
    cpu_utilization=$(awk '/^cpu /{print 100*($2+$4)/($2+$4+$5)}' /proc/stat)
    disk_usage=$(df -h | grep '^/' | awk '{printf "\"%s\":\"%s\",", $6, $5}')
fi

# Process Count
process_count=$(ps -e | wc -l)

# Logged-in Users
logged_in_users=$(users | tr ' ' '\n' | sort | uniq | awk '{printf "\"%s\",", $0}')
logged_in_users_fixed=$(echo "[$logged_in_users]" | sed 's/,$/]/')

# Top 5 memory-consuming processes
top_processes=""
IFS=$'\n' # Set IFS to handle newlines in Bash
for proc in $(ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 6 | tail -n +2); do
    pid=$(echo "$proc" | awk '{print $1}')
    user=$(echo "$proc" | awk '{print $2}')
    cpu=$(echo "$proc" | awk '{print $3}')
    mem=$(echo "$proc" | awk '{print $4}')
    cmd=$(echo "$proc" | awk '{print $5}') # Only the base command without arguments

    # Add process info to the JSON array
    top_processes+="{\"PID\":\"$pid\",\"User\":\"$user\",\"%CPU\":\"$cpu\",\"%MEM\":\"$mem\",\"Command\":\"$cmd\"},"
done
top_processes="[${top_processes%,}]" # Trim trailing comma and wrap in brackets

# Use parameter expansion instead of sed for DiskUsage
disk_usage_fixed="{${disk_usage%,}}"

# Process stats
total_threads=$(ps -eLf | wc -l)

# Generate JSON output
echo "{
  \"hostname\":\"$(hostname)\",
  \"time\":\"$(date +%s)\",
  \"mem\":{\"avail\":\"$mem_avail\", \"total\":\"$mem_total\", \"used\":\"$mem_used\"},
  \"cpuUtilization\":\"$cpu_utilization\",
  \"DiskUsage\":$disk_usage_fixed,
  \"Process Count\":\"$process_count\",
  \"Total Threads\":\"$total_threads\",
  \"Logged-in Users\":$logged_in_users_fixed,
  \"Top 5 Memory Consuming Processes\":$top_processes
}" | sed 's/,]/]/g' | sed 's/,\s*}/}/g'

