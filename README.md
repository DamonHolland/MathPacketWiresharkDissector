# Math Packet Wireshark Dissector Plugin

## Installation
1. Drag the math_packet_dissector.lua into your Wireshark plugins folder. (Ex: User/.local/lib/wireshark/plugins/3.4/)
2. Reload your plugins in wireshark with Ctrl + Shift + L

## Examples
### Wireshark packet window with plugin
![Packet Window](images/packetwindow.png?raw=true "Wireshark packet window with plugin") </br>
MATHRQ are math request packets. </br>
MATHRS are math response packets.

### Parsed Math Request
![Math Request](images/mathrequest.png?raw=true "Parsed Math Request")

### Parsed Math Response
![Math Response](images/mathresponse.png?raw=true "Parsed Math Response") </br>
You can see the reassembly of TCP packets to create the single math response listing.

### Parsed Math Response w/Error
![Math Error Response](images/matherror.png?raw=true "Parsed Math Response w/Error")

## Update
### Added 1.1 Support and X-String Parsing

### Parsed 1.1 Math Response with X-Strings 
![Parsed 1.1 Math Response with X-Strings](images/mathresponse1.1.png?raw=true "Parsed 1.1 Math Response with X-Strings")

### 1.1 Math Continue Request
![1.1 Math Continue Request](images/mathresponsekeepalive.png?raw=true "1.1 Math Continue Request")


## How it works
The plugin is written in Lua.

A Single dissector acts as a wrapper for any TCP packet on a given port. </br>
The wrapper will call the corresponding response / request dissector depending on the src / dest port. </br>
The wrapper will reassemble response packets before calling the response dissector. </br>
Finally, the response / request dissectors parse out information about the math packet and add them to the wireshark data tree.
