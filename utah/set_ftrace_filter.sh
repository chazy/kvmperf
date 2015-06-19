#!/bin/bash

TDIR=/sys/kernel/debug/tracing


cat >> $TDIR/set_ftrace_filter <<EOF
arch_cpu_idle
handle_IPI
irqfd_inject
io_mem_abort
kvm_handle_wfx
kvm_vgic_inject_irq
kvm_set_irq
handle_mmio_sgi_reg
mlx4_eq_int
mlx4_en_xmit
net_tx_action
net_rx_action
handle_rx_net
handle_tx_kick
sock_sendmsg
sock_recvmsg
arch_timer_handler_virt
arch_timer_handler_phys
EOF

echo 1 > $TDIR/events/kvm/kvm_entry/enable
echo 1 > $TDIR/events/kvm/kvm_exit/enable
echo 1 > $TDIR/events/sched/sched_switch/enable

echo function > $TDIR/current_tracer
