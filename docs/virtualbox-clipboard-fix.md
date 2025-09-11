# VirtualBox Shared Clipboard Fix

## Problem
Shared clipboard not working between VirtualBox host and VM even when enabled.

## Root Cause
Version mismatch between VirtualBox host and Guest Additions in the VM:
- VirtualBox Host: 7.0.26
- Guest Additions: 6.0.0 (too old)

## Solution Steps

### 1. Check Current Status
```bash
# Check VirtualBox version
VBoxManage --version

# Check VM Guest Additions version
VBoxManage showvminfo "VM-NAME" --machinereadable | grep GuestAdditionsVersion

# Check clipboard setting
VBoxManage showvminfo "VM-NAME" | grep "Clipboard Mode"
```

### 2. Enable Shared Clipboard
```bash
# For powered off VM
VBoxManage modifyvm "VM-NAME" --clipboard-mode bidirectional

# For running VM
VBoxManage controlvm "VM-NAME" clipboard mode bidirectional
```

### 3. Update Guest Additions (Critical!)
1. **Inside the running VM**: 
   - Go to VirtualBox menu: **Devices** → **Insert Guest Additions CD Image**
   - Navigate to mounted CD and run installer
   - Restart VM after installation

2. **Alternative - Manual method**:
   - Download Guest Additions ISO from Oracle
   - Mount and install manually

### 4. Verify Fix
- Restart VM after Guest Additions update
- Test copy/paste between host and VM
- Guest Additions version should match VirtualBox version

## Key Takeaway
Always keep Guest Additions version synchronized with VirtualBox host version for optimal functionality.

## Commands Used for fokin-iot VM
```bash
VBoxManage modifyvm "fokin-iot" --clipboard-mode bidirectional
VBoxManage controlvm "fokin-iot" clipboard mode bidirectional
VBoxManage controlvm "fokin-iot" acpipowerbutton  # Graceful shutdown
```
