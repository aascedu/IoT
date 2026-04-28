#!/usr/bin/env bash
set -euo pipefail

# Minimal static checks that the Vagrantfile meets the mandatory subject constraints.

vagrantfile="$(dirname "${BASH_SOURCE[0]}")/Vagrantfile"
k8sdir="$(dirname "${BASH_SOURCE[0]}")/confs"

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

failures=0
runtime_failures=0

warn() {
    echo -e "${yellow}WARN${reset}: $1"
}

fail() { echo -e "${red}FAIL${reset}: $1"; failures=1; }
pass() { echo -e "${green}PASS${reset}: $1"; }

expect() {
    local description="$1"
    local pattern="$2"
    if ! grep -Eq "$pattern" "$vagrantfile"; then
        fail "$description"
    else
        pass "$description"
    fi
}

expect_in_k8s() {
	local description="$1"
	local pattern="$2"
	local -a k8s_files=()
	for ext in yml yaml; do
		local -a matches=("$k8sdir"/*."$ext")
		for file in "${matches[@]}"; do
			[ -e "$file" ] || continue
			k8s_files+=("$file")
		done
	done
	if [ ${#k8s_files[@]} -eq 0 ]; then
		fail "No Kubernetes manifest files (*.yml/*.yaml) found in $k8sdir"
		return
	fi
	if ! grep -Eq "$pattern" "${k8s_files[@]}"; then
		fail "$description"
	else
		pass "$description"
	fi
}

expect_in_k8s "app1 deployment exists" 'name:[[:space:]]*app1'
expect_in_k8s "app2 deployment exists with 3 replicas" 'replicas:[[:space:]]*3'
expect_in_k8s "app3 deployment exists" 'name:[[:space:]]*app3'
expect_in_k8s "app1 ingress configured for app1.com" 'host:[[:space:]]*app1\.com'
expect_in_k8s "app2 ingress configured for app2.com" 'host:[[:space:]]*app2\.com'
expect_in_k8s "app3 ingress configured as default backend" 'defaultBackend:'

if [ "$failures" -ne 0 ]; then
	exit 1
fi

echo -e "\n${green}=== Runtime checks ===${reset}"

if ! command -v vagrant >/dev/null 2>&1; then
	warn "vagrant command not found, skipping SSH and networking checks"
	exit 0
fi

machine_state() {
	local machine="$1"
	vagrant status "$machine" --machine-readable 2>/dev/null | awk -F, '$3=="state" {print $4; exit}'
}

ssh_check() {
    local machine="$1"
    local description="$2"
    if vagrant ssh "$machine" -c "$3" >/dev/null 2>&1; then
        pass "$description"
    else
        fail "$description"
        runtime_failures=1
    fi
}

# Auto-detect the machine name (should end with S)
server_machine=$(vagrant status --machine-readable 2>/dev/null | awk -F, '$3=="state" && $2 ~ /S$/ {print $2; exit}')
if [ -z "$server_machine" ]; then
	warn "No VM ending with 'S' found, skipping runtime checks"
	exit 0
fi

state_server=$(machine_state "$server_machine")
if [ "$state_server" != "running" ]; then
	warn "$server_machine is not running (state: ${state_server:-unknown}), skipping runtime checks"
	exit 0
fi

# Check VM hostname
hostname_check=$(vagrant ssh "$server_machine" -c "hostname" 2>/dev/null | tr -d '\r' || echo "FAILED")
if [[ "$hostname_check" =~ S$ ]]; then
    pass "VM hostname ends with S (found: $hostname_check)"
else
    fail "VM hostname does not end with S (found: $hostname_check)"
    runtime_failures=1
fi

# Check VM IP on eth1
if vagrant ssh "$server_machine" -c "ip a show eth1 | grep -F '192.168.56.110'" >/dev/null 2>&1; then
    pass "VM has IP 192.168.56.110 on eth1"
else
    fail "VM does not have IP 192.168.56.110 on eth1"
    runtime_failures=1
fi

# Wait for k3s to be ready
max_wait=60
elapsed=0
while [ $elapsed -lt $max_wait ]; do
	if vagrant ssh "$server_machine" -c "sudo kubectl get nodes --no-headers 2>/dev/null | grep -q Ready" 2>/dev/null; then
		break
	fi
	sleep 5
	elapsed=$((elapsed + 5))
done

# Check kubectl shows the node
nodes_output=$(vagrant ssh "$server_machine" -c "sudo kubectl get nodes --no-headers" 2>/dev/null || echo "")
node_name=$(echo "$nodes_output" | awk '{print $1}' | tr -d '\r')
if echo "$nodes_output" | grep -iq "ready"; then
    pass "k3s node is Ready (node: $node_name)"
else
    fail "k3s node is not Ready"
    runtime_failures=1
fi

# Check all pods are running
max_wait=120
elapsed=0
while [ $elapsed -lt $max_wait ]; do
	running_pods=$(vagrant ssh "$server_machine" -c "sudo kubectl get pods --no-headers 2>/dev/null | grep -c Running" 2>/dev/null | tr -d '\r' || echo "0")
	# Clean up the value to ensure it's a valid integer
	running_pods=$(echo "$running_pods" | grep -o '[0-9]*' | head -1)
	running_pods=${running_pods:-0}
	if [ "$running_pods" -ge 5 ]; then
		break
	fi
	sleep 5
	elapsed=$((elapsed + 5))
done

pass "Found $running_pods running pods"

# Test app routing with curl
server_ip="192.168.56.110"

curl_test() {
	local host="$1"
	local expected_app="$2"
	local description="$3"

	result=$(curl -sS -H "Host: $host" "$server_ip" 2>/dev/null | grep -o "Hello from App [0-9]" || echo "FAILED")

	if [ "$result" = "Hello from App $expected_app" ]; then
		pass "$description"
	else
		fail "$description (got: $result, expected: Hello from App $expected_app)"
		runtime_failures=1
	fi
}

# Test app1.com -> App 1
curl_test "app1.com" "1" "app1.com routes to App 1"

# Test app2.com -> App 2
curl_test "app2.com" "2" "app2.com routes to App 2"

# Test app3.com -> App 3
curl_test "app3.com" "3" "app3.com routes to App 3"

# Test unknown host -> App 3 (default)
curl_test "unknown.com" "3" "unknown host routes to App 3 (default)"

# Test another unknown host -> App 3 (default)
curl_test "random.example.com" "3" "random host routes to App 3 (default)"

if [ "$runtime_failures" -ne 0 ]; then
	exit 1
fi
