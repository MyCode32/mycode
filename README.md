![Fuxion logo](https://github.com/MyCode32/mycode/blob/master/logos/logo.jpg)

# mycode is the future of MITM WPA attacks
MyCode3 is a security auditing and social-engineering research tool. It is a remake of linset by vk496 with (hopefully) fewer bugs and more functionality. The script attempts to retrieve the WPA/WPA2 key from a target access point by means of a social engineering (phishing) attack. It's compatible with the latest release of Kali (rolling). MyCode3's attacks' setup is mostly manual, but experimental auto-mode handles some of the attacks' setup parameters.

## Installation
please download the latest version.
<br>
**Download the latest revision**
```
git clone https://www.github.com/MyCode32/mycode.git
```
**Switch to tool's directory**
```
cd mycode 
```
**Run mycode (missing dependencies will be auto-installed)**
```
./mycode.sh
```

**mycode is also available in arch** 
```
cd bin/arch
makepkg
```

or using the blackarch repo
```
pacman -S mycode
```

## :book: How it works
* Scan for a target wireless network.
* Launch the `Handshake Snooper` attack.
* Capture a handshake (necessary for password verification).
* Launch `Captive Portal` attack.
* Spawns a rogue (fake) AP, imitating the original access point.
* Spawns a DNS server, redirecting all requests to the attacker's host running the captive portal.
* Spawns a web server, serving the captive portal which prompts users for their WPA/WPA2 key.
* Spawns a jammer, deauthenticating all clients from original AP and luring them to the rogue AP.
* All authentication attempts at the captive portal are checked against the handshake file captured earlier.
* The attack will automatically terminate once a correct key has been submitted.
* The key will be logged and clients will be allowed to reconnect to the target access point.

## :heavy_exclamation_mark: Requirements

A Linux-based operating system. Basically, Kali Linux is recommended.

Mycode need compatible WiFi Adapter.

Read the [Kali Linux WiFi Adapter](https://hackersgrid.com/2020/02/wifi-adapter-for-kali-linux.html)

## Note
* MyCode3 **DOES NOT WORK** on Linux Subsystem For Windows 10, because the subsystem doesn't allow access to network interfaces. Any Issue regarding the same would be **Closed Immediately**
