# Shellperfmon

Because installing a 300MB agent just to watch your RAM shrivel is overrated.

## What’s the Point?
`main.sh` is a single script that spits out JSON with details about your CPU, memory, disk usage, process count, and other thrilling statistics. It works on macOS, the BSDs, and Linux—assuming you have the required utilities (This tool is designed to use the most common utils on each platform for maximum compatibility).

## Features
- Detects your OS and grabs system stats accordingly.
- Prints memory, CPU utilization, disk usage, logged-in users, and the top five memory hogs.
- Outputs plain JSON for piping into whatever tool you hold dearest.

Current JSON SCHEMA (from lines 60–70 of `main.sh`):

```
    60  # Generate JSON output
    61  echo "{
    62    \"hostname\":\"$(hostname)\",
    63    \"time\":\"$(date +%s)\",
    64    \"mem\":{\"avail\":\"$mem_avail\", \"total\":\"$mem_total\", \"used\":
\"$mem_used\"},
    65    \"cpuUtilization\":\"$cpu_utilization\",
    66    \"DiskUsage\":$disk_usage_fixed,
    67    \"Process Count\":\"$process_count\",
    68    \"Total Threads\":\"$total_threads\",
    69    \"Logged-in Users\":$logged_in_users_fixed,
    70    \"Top 5 Memory Consuming Processes\":$top_processes
    71  }" | sed 's/,]/]/g' | sed 's/,\s*}/}/g'
```
