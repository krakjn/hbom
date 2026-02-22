```
 █████      █████                             
▒▒███      ▒▒███                              
 ▒███████   ▒███████   ██████  █████████████  
 ▒███▒▒███  ▒███▒▒███ ███▒▒███▒▒███▒▒███▒▒███ 
 ▒███ ▒███  ▒███ ▒███▒███ ▒███ ▒███ ▒███ ▒███ 
 ▒███ ▒███  ▒███ ▒███▒███ ▒███ ▒███ ▒███ ▒███ 
 ████ █████ ████████ ▒▒██████  █████▒███ █████
▒▒▒▒ ▒▒▒▒▒ ▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒  ▒▒▒▒▒ ▒▒▒ ▒▒▒▒▒ 
```
                                              
# Hardware Bill of Materials

A Linux tool that outputs a hardware bill of materials in JSON (default), TOML, INI, or CSV. It describes host, board, BIOS, chassis, chipset, PCI/USB/block/input devices, network, CPU, memory, sound, GPU, thermal, power, platform, ACPI, virtio, I2C, and TPM. Data is discovered at runtime from sysfs and devicetree (no hardcoded device lists). Targets desktops, servers, and embedded devices (e.g. NVIDIA Orin).

**Zig 0.15.2**

## Build
zig has __native cross compile__ **out of the box!**
```bash
zig build
```

This produces musl-only binaries (fully static, no host libc). All are installed under `zig-out/bin/` with explicit names per target:

- `hbom-x86_64-linux-musl`
- `hbom-i386-linux-musl`
- `hbom-aarch64-linux-musl`
- `hbom-arm-linux-musl`

## Usage

- **No arguments** — write JSON to `hbom.json` in the current directory.
- **`-o FILE`** / **`--output FILE`** — write output to `FILE`.
- **`--stdout`** — print output to stdout.
- **`-f FORMAT`** / **`--format=FORMAT`** — output format: `json` (default), `toml`, `ini`, `csv`. With no `-o`/`--output`, the default filename is `hbom.{format}` (e.g. `hbom.toml`).
- **`-p`** / **`--pretty`** — pretty-print JSON; no effect for toml/ini/csv.
- **`-h`** / **`--help`** — show help.

## Output

Supported formats: **JSON** (default), **TOML**, **INI**, **CSV**. All include: `host`, `board`, `bios`, `chassis`, `chipset`, `pci[]`, `usb[]`, `block[]`, `input[]`, `net[]`, `cpu`, `memory`, `sound[]`, `gpu[]`, `thermal[]`, `power[]`, `platform[]`, `acpi[]`, `virtio[]`, `i2c[]`, `tpm`. Empty sections are omitted. Serial numbers and identifiers are included where the kernel exposes them (DMI, devicetree, sysfs).

Values are reported as the firmware/kernel provides them. When a value is a known DMI placeholder (e.g. `x.x`, `Default string`, `To be filled by O.E.M.`), hbom emits the literal `"placeholder"` instead so the field remains present but indicates the firmware did not set a real value.
