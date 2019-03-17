# yamahaAvr
Controls AVR Yamaha RX-477
yamahaAvr.sh {host} {command} {subcommand} 
commands:
power: {on|off|status}
input: {$inputname|status} --> defined input name
mute: {on|off|status}
volume: {up|down|status|$value}

Thanks to https://blog.chmouel.com/2016/09/23/controlling-yamaha-av-rx-a830-from-command-line/ 

# yamahaBox
Controls Yamaha WX-010
yamahaBox.sh {host} {command} {subcommand} 
commands:
power: {on|off|status}
input: {$inputname|status} --> bluetooth,spotify,airplay
mute: {on|off|status}
volume: {up|down|status|$value}

# philipsTv
Controls Philips TV Remote Devices
philipsTv.sh {host} {command} {subcommand} 
commands:
power: {off|status}
input: {$inputname|status} --> tv,sat,hdmi1,hdmi2,...,hdmiside,ext1,ypbpr,vga
mute: {on|off|status}
volume: {up|down|status|$value}
