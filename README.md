# Server Monitoring System

A lightweight **Bash-based Linux server monitoring script** that checks basic system health and service status from the terminal.

The project was built to practice Linux system administration, Bash scripting, command pipelines, text processing, and service monitoring.

## Features

The monitoring script currently checks:

* 🖥️ Hostname
* ⏱️ System uptime
* ⚙️ CPU usage
* 🧠 Memory usage
* 💾 Disk usage
* 🐳 Docker installation and container status
* 🔌 Listening TCP ports and associated processes
* 🚦 Configurable warning and critical thresholds

## Technologies Used

* Bash
* Linux
* `top`
* `awk`
* `grep`
* `sed`
* `ss`
* `systemctl`
* `bc`
* Docker

## Example Output

```text
===============================================
          SERVER MONITORING SYSTEM             
===============================================
Hostname              : pop-os
UP Time               : 2026-09-02 11:07:23
-----------------------------------------------
CPU Usage             : 8.5% [OK]
-----------------------------------------------
Memory Usage          : 39.478% [OK]
-----------------------------------------------
Disk Usage            : 10% [OK]
-----------------------------------------------
Checking Docker Status...
Docker Service Status: active
```

## CPU Monitoring

CPU usage is obtained from `top` in batch mode:

```bash
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
```

The `top` output contains several CPU statistics:

```text
%Cpu(s):  0.8 us,  0.8 sy,  1.6 ni, 96.9 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
```

The `id` value represents the percentage of CPU that is idle.

Therefore:

```text
CPU Usage = 100 - Idle CPU
           = 100 - 96.9
           = 3.1%
```

### `top` flags

| Flag   | Function                                                         |
| ------ | ---------------------------------------------------------------- |
| `-b`   | Batch mode; produces non-interactive output suitable for scripts |
| `-n 1` | Runs one iteration/snapshot and exits                            |

## Floating-Point Comparisons with `bc`

Bash arithmetic is primarily integer-based, but system monitoring often produces decimal values such as:

```text
82.5
```

For decimal comparisons, the script uses `bc`:

```bash
if (( $(echo "$MEMORY_USAGE > $MEMORY_LIMIT" | bc -l) )); then
```

For example:

```bash
echo "82.5 > 80" | bc -l
```

returns:

```text
1
```

while:

```bash
echo "75.5 > 80" | bc -l
```

returns:

```text
0
```

### `bc -l`

* `bc` = command-line calculator
* `-l` = loads the standard math library, providing useful floating-point/mathematical functionality

`bc` returns:

```text
1 = true
0 = false
```

This allows the result to be used in a Bash `if` condition.

## Docker Monitoring

The script checks whether Docker is available using:

```bash
if command -v docker >/dev/null 2>&1; then
```

Rather than:

```bash
which docker
```

### Why `command -v` instead of `which`?

`command -v` asks the shell how it would resolve a command and is a shell built-in, making it a better choice for Bash scripts.

`which` is generally an external utility that searches for executables in `$PATH`.

For example:

```bash
command -v docker
```

may return:

```text
/usr/bin/docker
```

The script redirects the output because it only needs the command's exit status:

```bash
>/dev/null 2>&1
```

* `>/dev/null` = discard standard output (`stdout`)
* `2>&1` = redirect standard error (`stderr`) to the same destination as standard output

The result is therefore used as a simple availability check:

```text
Docker found       → exit status 0 → continue
Docker not found   → non-zero      → show warning
```

## Docker Service Issue

One of the practical issues encountered during development was that the **Docker engine was not running when the monitoring script attempted to check Docker**.

The issue was resolved by configuring the Docker service to **start automatically when the system boots**.

The service can be enabled with:

```bash
sudo systemctl enable docker
```

The `systemctl` flag:

* `enable` = configures the service to start automatically during boot

The Docker service can also be checked with:

```bash
systemctl is-active docker
```

This is more appropriate for scripting than parsing the output of:

```bash
systemctl status docker
```

because `is-active` directly communicates whether the service is currently running through its exit status.

## Listening Port Monitoring

The project also uses `ss` to identify listening TCP ports:

```bash
ss -lntp
```

Flags used:

| Flag | Function                                                    |
| ---- | ----------------------------------------------------------- |
| `-l` | Show listening sockets                                      |
| `-n` | Show numeric addresses and ports instead of resolving names |
| `-t` | Show TCP sockets                                            |
| `-p` | Show the process associated with the socket                 |

The output is then processed using `awk` to extract relevant fields.

Example:

```bash
ss -lntp | awk 'NR>1 {print $4, $6}'
```

Here:

* `NR` = current input record/line number
* `NR>1` = skip the first/header line
* `$4` = fourth field
* `$6` = sixth field

## Key Bash Concepts Practiced

This project helped reinforce several Linux and Bash concepts:

* Variables and command substitution
* Environment variables
* Exit statuses
* `if/else` conditions
* Pipes (`|`)
* Output redirection
* `/dev/null`
* `awk` field and line processing
* `grep`
* `systemctl`
* Process and service monitoring
* TCP socket inspection with `ss`
* Floating-point calculations with `bc`
* Bash loops and `read`
* Linux command-line troubleshooting

## Lessons Learned

### 1. Bash variable assignment

Bash does not allow spaces around `=` when assigning variables.

Correct:

```bash
CPU_LIMIT=80
```

Incorrect:

```bash
CPU_LIMIT = 80
```

### 2. Environment variables are case-sensitive

For example:

```bash
echo "$HOSTNAME"
echo "$USER"
```

is different from:

```bash
echo "$hostname"
echo "$user"
```

Bash treats those as different variable names.

### 3. Command output vs variables

There is an important difference between:

```bash
echo pwd
```

and:

```bash
pwd
```

The first prints the text `pwd`, while the second actually executes the `pwd` command.

Similarly:

```bash
HOSTNAME=$(hostname)
```

executes the `hostname` command and stores its output in a variable.

### 4. Commands have exit statuses

Linux commands generally return an exit status:

```text
0     → success
non-0 → failure
```

This is heavily used in Bash scripting for conditions such as:

```bash
if command -v docker >/dev/null 2>&1; then
```

### 5. `top` is not the same as `systemctl`

The options:

```bash
-bn1
```

belong to `top`. They are not generic Linux options.

`top -bn1` means:

```text
-b  → batch mode
-n1 → one iteration
```

Commands such as `systemctl` have their own options and should be used according to their own interface.

## Future Improvements

Possible future additions include:

* CPU temperature monitoring
* Network bandwidth monitoring
* Load average alerts
* Process monitoring
* Automatic email/Telegram notifications
* Log file generation
* Cron/systemd timer integration
* Configurable thresholds through a `.conf` file
* Running the monitor periodically as a systemd service
* Exporting monitoring data for Prometheus/Grafana

## Purpose

This project is part of my Linux and DevOps learning journey, focusing on understanding how system information can be collected, processed, and evaluated using standard Linux utilities and Bash.

The goal was not just to build a monitoring script, but to understand **how Linux commands expose system information and how Bash can combine those commands into an automated monitoring workflow**.
