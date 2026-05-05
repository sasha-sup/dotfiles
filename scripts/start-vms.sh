#!/bin/bash
# Toggle libvirt VMs on one i3 workspace in tabbed layout.
# VM names and target workspace come from ~/.config/dotfiles.env (VMS, VM_WORKSPACE).

# shellcheck source=/dev/null
. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true

if [ -z "${VMS+x}" ] || [ "${#VMS[@]}" -eq 0 ]; then
    echo "VMS array not set (see ~/.config/dotfiles.env)" >&2
    exit 1
fi

target_ws="${VM_WORKSPACE:-${VM_WORKSPACES[0]:-}}"

if virsh -c qemu:///system list --all | grep -q "shut off"; then
    if [ -n "$target_ws" ]; then
        i3-msg "workspace number $target_ws; layout tabbed"
    fi

    for i in "${!VMS[@]}"; do
        vm="${VMS[$i]}"
        virsh -c qemu:///system start "$vm"
        if [ -n "$target_ws" ]; then
            i3-msg "workspace number $target_ws; exec virt-viewer --wait -c qemu:///system $vm"
        fi
    done
else
    for vm in $(virsh -c qemu:///system list --name); do
        virsh -c qemu:///system shutdown "$vm"
    done
fi
