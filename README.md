# Kali Apple Silicon Image
This repository contains scripts for compiling native Kali image for Apple silicon hardware such as Apple M1 and M2.

### Hosted Installer
To install a prebuilt image run:
```
curl -sL https:// > install.sh	# Download
less install.sh						# Review
sh install.sh						# Run

```


#### Can I dual-boot macOS and Linux?
Yes! The installer can automatically resize your macos partition according to your liking and install Kali  in the freed up space. Removing macos is not even supported at the moment since it is required to update the system firmware.


### Related Projects
- [Asahi Linux](https://asahilinux.org/)
- [Pop_OS! arm64](https://github.com/pop-os/pop-arm64/)
- [m1-debian](https://git.zerfleddert.de/cgi-bin/gitweb.cgi/m1-debian)
- [asahi-fedora-builder](https://github.com/leifliddy/asahi-fedora-builder)
- [ubuntu-asahi](https://github.com/UbuntuAsahi/ubuntu-asahi)




