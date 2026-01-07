#!/usr/bin/env bash
set -euo pipefail

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[34m"
reset="\033[0m"

failures=0

warn() { echo -e "${yellow}WARN${reset}: $1"; }
info() { echo -e "${blue}INFO${reset}: $1"; }
fail() { echo -e "${red}FAIL${reset}: $1"; failures=1; }
pass() { echo -e "${green}PASS${reset}: $1"; }

find_config() {
    local basename="$1"
    local dir="${2:-confs}"
    for ext in yml yaml; do
        [ -f "$dir/$basename.$ext" ] && echo "$dir/$basename.$ext" && return 0
    done
    return 1
}

expect() {
    if ! grep -Eq "$2" "$1"; then
        fail "$3"
    else
        pass "$3"
    fi
}

expect_in_configs() {
    local pattern="$1"
    local description="$2"
    local -a config_files=()
    for ext in yml yaml; do
        local -a matches=(confs/*.$ext)
        for file in "${matches[@]}"; do
            [ -e "$file" ] || continue
            config_files+=("$file")
        done
    done
    if [ ${#config_files[@]} -eq 0 ]; then
        fail "No config files found in confs/"
        return
    fi
    if ! grep -Eq "$pattern" "${config_files[@]}"; then
        fail "$description"
    else
        pass "$description"
    fi
}

echo -e "${blue}=== Configuration Tests ===${reset}"

# Config checks
expect_in_configs 'kind:[[:space:]]*Namespace' "Namespace definitions exist"
expect_in_configs 'name:[[:space:]]*argocd' "ArgoCD namespace named argocd"
expect_in_configs 'name:[[:space:]]*dev' "Dev namespace named dev"
expect_in_configs 'kind:[[:space:]]*Application' "ArgoCD Application exists"
expect_in_configs 'repoURL:' "Application has git repo URL"
expect_in_configs 'automated:' "Application has auto-sync"
expect_in_configs 'prune:[[:space:]]*true' "Application has prune enabled"
expect_in_configs 'selfHeal:[[:space:]]*true' "Application has selfHeal enabled"
expect_in_configs 'destination:' "Application has destination"
expect_in_configs 'namespace:[[:space:]]*dev' "Application deploys to dev namespace"

[ "$failures" -ne 0 ] && exit 1

echo -e "\n${blue}=== Runtime Tests ===${reset}"

if ! command -v kubectl >/dev/null 2>&1; then
    warn "kubectl not found, skipping runtime tests"
    exit 0
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
    warn "No cluster running, skipping runtime tests"
    exit 0
fi

# Check cluster
if k3d cluster list 2>/dev/null | grep -q "p3-cluster"; then
    pass "k3d cluster exists (p3-cluster)"
else
    fail "k3d cluster not found"
fi

# Check argocd namespace
if kubectl get ns argocd >/dev/null 2>&1; then
    pass "argocd namespace exists"
else
    fail "argocd namespace missing"
fi

# Check dev namespace
if kubectl get ns dev >/dev/null 2>&1; then
    pass "dev namespace exists"
else
    fail "dev namespace missing"
fi

# Check ArgoCD pods
info "Checking ArgoCD pods (timeout: 2min)..."
max_wait=120
elapsed=0
while [ $elapsed -lt $max_wait ]; do
    ready=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    [ "$ready" -ge 7 ] && break
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ "$ready" -ge 7 ]; then
    pass "ArgoCD pods running ($ready/7)"
else
    fail "ArgoCD pods not ready ($ready/7)"
fi

# Check ArgoCD server is ready
if kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q "Running"; then
    pass "ArgoCD server pod is running"
else
    fail "ArgoCD server pod not running"
fi

# Check ArgoCD Application (auto-detect name)
app_name=$(kubectl get application -n argocd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$app_name" ]; then
    pass "ArgoCD Application ($app_name) exists"

    # Check sync status
    sync_status=$(kubectl get application "$app_name" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    if [ "$sync_status" = "Synced" ]; then
        pass "Application is Synced"
    else
        fail "Application not Synced (status: $sync_status)"
    fi

    # Check health status
    health_status=$(kubectl get application "$app_name" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    if [ "$health_status" = "Healthy" ]; then
        pass "Application is Healthy"
    else
        fail "Application not Healthy (status: $health_status)"
    fi
else
    fail "ArgoCD Application missing"
fi

# Check app deployed in dev namespace
info "Checking app pods in dev namespace (timeout: 1min)..."
max_wait=60
elapsed=0
while [ $elapsed -lt $max_wait ]; do
    app_pods=$(kubectl get pods -n dev --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    [ "$app_pods" -ge 1 ] && break
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ "$app_pods" -ge 1 ]; then
    pass "App pods running in dev namespace ($app_pods)"
else
    fail "App pods not deployed in dev namespace"
fi

# Check Service exists
if kubectl get svc -n dev >/dev/null 2>&1; then
    svc_count=$(kubectl get svc -n dev --no-headers 2>/dev/null | wc -l)
    pass "Services exist in dev namespace ($svc_count)"
else
    fail "No services in dev namespace"
fi

# Check Ingress exists
if kubectl get ingress -n dev >/dev/null 2>&1; then
    ingress_count=$(kubectl get ingress -n dev --no-headers 2>/dev/null | wc -l)
    pass "Ingress exists in dev namespace ($ingress_count)"
else
    fail "No ingress in dev namespace"
fi

# Test app accessibility
if command -v curl >/dev/null 2>&1; then
    info "Testing app accessibility on localhost:8888..."
    if curl -sf http://localhost:8888 >/dev/null 2>&1; then
        response=$(curl -s http://localhost:8888)
        pass "App accessible at http://localhost:8888"
        if echo "$response" | grep -q "status"; then
            pass "App returns valid JSON response"
        fi
    else
        fail "App not accessible at http://localhost:8888"
    fi
else
    warn "curl not found, skipping app accessibility test"
fi

[ "$failures" -ne 0 ] && exit 1

echo -e "\n${green}✓ All tests passed!${reset}"
echo -e "${blue}Run \"make status\" for detailed cluster info${reset}"
exit 0
