#!/bin/sh
################################################################################
# MIT License
#
# Copyright (c) 2022 Wynand Marais
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################
# Description:
#
# This script is used to prepare the host for installation. It disables swap,
# shuts down all LVM services and remove all existing volumes. This is a
# destructive script and if you change your mind after running it, you may not
# be able to recover.
# Disable all swap.
################################################################################
swapoff --all

# Unmount anything on /mnt.
umount -A --recursive /mnt >/dev/null 2>&1

# Get a list of all the volume groups.
VGS=(`vgdisplay | grep "VG Name" | awk '{print $3}'`)

# Delete all the logical volumes associated with each volume group.
for vg in ${VGS[@]}; do
  lvremove -q -f ${vg} >/dev/null 2>&1
  vgremove -q -f ${vg} >/dev/null 2>&1
done

# Get a list of all the physical volumes.
PVS=(`pvdisplay | grep "PV Name" | awk '{print $3}'`)

# Delete all the physical volumes.
for pv in ${PVS[@]}; do 
  pvremove -q -f ${pv} >/dev/null 2>&1
done

# Get a list of all the open encrypted volumes.
EVS=(`dmsetup ls --target crypt | awk '{print $1}'`)
for ev in ${EVS[@]}; do
  cryptsetup luksClose ${ev}
done

# No errors occurred (That we care about).
exit 0

