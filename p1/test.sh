#!/usr/bin/env bash
set -euo pipefail

# Minimal static checks that the Vagrantfile meets the mandatory subject constraints.

vagrantfile="$(dirname "${BASH_SOURCE[0]}")/Vagrantfile"
scriptsdir="$(dirname "${BASH_SOURCE[0]}")/scripts"

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[34m"
reset="\033[0m"

failures=0

warn() {
	echo -e "${yellow}WARN${reset}: $1"
}

info() {
	echo -e "${blue}INFO${reset}: $1"
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

expect_in_scripts() {
	local description="$1"
	local pattern="$2"
	if ! grep -Eq "$pattern" "$scriptsdir"/*.sh; then
		fail "$description"
	else
		pass "$description"
	fi
}

printf '%s=== Configuration Tests ===%s\n' "$blue" "$reset"

expect "box uses bento/debian-13" 'config.vm.box[[:space:]]*=[[:space:]]*"bento/debian-13"'
expect "server machine defined with suffix S" 'config.vm.define[[:space:]]+"[^"]*S"'
expect "worker machine defined with suffix SW" 'config.vm.define[[:space:]]+"[^"]*SW"'
expect "server private IP 192.168.56.110" '"private_network"[^\n]*ip:[[:space:]]*"192\.168\.56\.110"'
expect "worker private IP 192.168.56.111" '"private_network"[^\n]*ip:[[:space:]]*"192\.168\.56\.111"'
expect "server k3s install script present" 'install_k3s\.sh'
expect_in_scripts "server installs k3s server" 'curl -sfL https://get.k3s.io.*sh -'
expect_in_scripts "server writes token to shared folder" '/vagrant/token'
expect_in_scripts "worker reads token from shared folder" '/vagrant/token'
expect_in_scripts "worker joins server URL" 'https://192\.168\.56\.110:6443'

if [ "$failures" -ne 0 ]; then
	exit 1
fi

echo -e "${blue}=== Runtime Tests ===${reset}"

if ! command -v vagrant >/dev/null 2>&1; then
	warn "vagrant command not found, skipping runtime tests"
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
	fi
}

# Auto-detect server/worker machines from vagrant status
server_machine=$(vagrant status --machine-readable 2>/dev/null | awk -F, '$3=="state" && $2 !~ /SW$/ && $2 ~ /S$/ {print $2; exit}')
worker_machine=$(vagrant status --machine-readable 2>/dev/null | awk -F, '$3=="state" && $2 ~ /SW$/ {print $2; exit}')

for machine in "$server_machine" "$worker_machine"; do
	[ -z "$machine" ] && continue
	state=$(machine_state "$machine")
	if [ "$state" = "running" ]; then
		pass "$machine is running"
	else
		fail "$machine is not running (state: ${state:-unknown})"
		continue
	fi

	ssh_check "$machine" "${machine}: passwordless SSH works" 'hostname'
	if [[ "$machine" =~ SW$ ]]; then
		expected_ip="192.168.56.111"
	else
		expected_ip="192.168.56.110"
	fi
	ssh_check "$machine" "${machine}: eth1 has IP ${expected_ip}" "ip a show eth1 | grep -F '${expected_ip}'"
done

# Guard if we cannot detect machines
if [ -z "$server_machine" ]; then
	warn "No server VM detected (name ending with S)"
	exit 0
fi

# Check k3s is installed on server
state_server=$(machine_state "$server_machine")
if [ "$state_server" = "running" ]; then
	if vagrant ssh "$server_machine" -c "command -v kubectl >/dev/null 2>&1" >/dev/null 2>&1; then
		pass "kubectl installed on $server_machine"
	else
		fail "kubectl not installed on $server_machine"
	fi

	if vagrant ssh "$server_machine" -c "sudo systemctl is-active k3s >/dev/null 2>&1" >/dev/null 2>&1; then
		pass "k3s service is active on $server_machine"
	else
		fail "k3s service not active on $server_machine"
	fi
fi

# Check k3s agent on worker
state_worker=""
if [ -n "$worker_machine" ]; then
	state_worker=$(machine_state "$worker_machine")
	if [ "$state_worker" = "running" ]; then
		if vagrant ssh "$worker_machine" -c "sudo systemctl is-active k3s-agent >/dev/null 2>&1" >/dev/null 2>&1; then
			pass "k3s-agent service is active on $worker_machine"
		else
			fail "k3s-agent service not active on $worker_machine"
		fi
	fi
else
	warn "No worker VM detected (name ending with SW)"
fi

# Check kubectl shows both nodes
if [ "$state_server" = "running" ]; then
	info "Checking k3s cluster nodes (timeout: 60s)..."
	# Give the worker time to join (wait up to 60 seconds)
	max_wait=60
	elapsed=0
	while [ $elapsed -lt $max_wait ]; do
		node_count=$(vagrant ssh "$server_machine" -c "sudo kubectl get nodes --no-headers 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r')
		if [ "$node_count" = "2" ]; then
			break
		fi
		sleep 5
		elapsed=$((elapsed + 5))
	done

	nodes_output=$(vagrant ssh "$server_machine" -c "sudo kubectl get nodes --no-headers" 2>/dev/null)
	server_lc=$(echo "$server_machine" | tr '[:upper:]' '[:lower:]')
	worker_lc=$(echo "$worker_machine" | tr '[:upper:]' '[:lower:]')
	if echo "$nodes_output" | grep -q "$server_lc" && echo "$nodes_output" | grep -q "$worker_lc"; then
		pass "kubectl shows both $server_machine and $worker_machine nodes"

		# Check node status
		ready_count=$(echo "$nodes_output" | grep -c "Ready" || echo "0")
		if [ "$ready_count" = "2" ]; then
			pass "Both nodes are Ready"
		else
			fail "Not all nodes are Ready ($ready_count/2)"
			vagrant ssh "$server_machine" -c "sudo kubectl get nodes -o wide" 2>/dev/null || true
		fi
	else
		fail "kubectl does not show both nodes (found: $(echo "$nodes_output" | awk '{print $1}' | tr '\n' ' '))"
		vagrant ssh "$server_machine" -c "sudo kubectl get nodes -o wide" 2>/dev/null || true
	fi

	# Check kube-system pods
	info "Checking kube-system pods..."
	pods_running=$(vagrant ssh "$server_machine" -c "sudo kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c 'Running'" 2>/dev/null | tr -d '\r' | awk 'NF{print $1}' || echo "0")
	pods_running=${pods_running:-0}
	if [ "$pods_running" -ge 5 ]; then
		pass "kube-system pods running ($pods_running)"
	else
		fail "Not enough kube-system pods running ($pods_running)"
	fi
else
	warn "$server_machine is not running, skipping kubectl checks"
fi
[ "$failures" -ne 0 ] && exit 1

echo -e "\n${green}✓ All tests passed!${reset}"
echo -e "${blue}Run \"make status\" for detailed cluster info${reset}"
exit 0
