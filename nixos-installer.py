import os
import re
from glob import glob
import curses

rootdir_pattern = re.compile('^.*?/devices')
internal_devices = []

def device_state(name):
    with open('/sys/block/%s/device/block/%s/removable' % (name, name)) as f:
        if f.read(1) == '1':
            return

    path = rootdir_pattern.sub('', os.readlink('/sys/block/%s' % name))
    hotplug_buses = ("usb", "ieee1394", "mmc", "pcmcia", "firewire")
    for bus in hotplug_buses:
        if os.path.exists('/sys/bus/%s' % bus):
            for device_bus in os.listdir('/sys/bus/%s/devices' % bus):
                device_link = rootdir_pattern.sub('', os.readlink(
                    '/sys/bus/%s/devices/%s' % (bus, device_bus)))
                if re.search(device_link, path):
                    return

    internal_devices.append(name)


for path in glob('/sys/block/*/device'):
    name = re.sub('.*/(.*?)/device', '\g<1>', path)
    device_state(name)
print(' '.join(internal_devices))

