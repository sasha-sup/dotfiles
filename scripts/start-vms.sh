#!/bin/bash
# Toggle libvirt VMs, each on its own i3 workspace.
# VM names and per-VM workspaces come from ~/.config/dotfiles.env (VMS, VM_WORKSPACES).
# VMS[i] opens on VM_WORKSPACES[i]; falls back to VM_WORKSPACE if unset.

# shellcheck source=/dev/null
. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true

if [ -z "${VMS+x}" ] || [ "${#VMS[@]}" -eq 0 ]; then
    echo "VMS array not set (see ~/.config/dotfiles.env)" >&2
    exit 1
fi

if virsh -c qemu:///system list --all | grep -q "shut off"; then
    for i in "${!VMS[@]}"; do
        vm="${VMS[$i]}"
        ws="${VM_WORKSPACES[$i]:-${VM_WORKSPACE:-}}"
        virsh -c qemu:///system start "$vm"
        if [ -n "$ws" ]; then
            i3-msg "workspace number $ws; exec virt-viewer --wait -c qemu:///system $vm"
        fi
    done
else
    for vm in $(virsh -c qemu:///system list --name); do
        virsh -c qemu:///system shutdown "$vm"
    done
fi
