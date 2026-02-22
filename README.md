# hbom

Hardware Bill of Materials — a Linux tool that outputs condensed JSON describing host, board, BIOS, chassis, chipset, PCI and USB devices, block devices, and input devices. Data is discovered at runtime from sysfs and devicetree (no hardcoded device lists). Targets desktops, servers, and embedded devices (e.g. NVIDIA Orin).

**Zig 0.15.2**

## Build

```bash
zig build
```

Binary: `zig-out/bin/hbom`

## Usage

- **No arguments** — write JSON to `hbom.json` in the current directory.
- **`-o FILE`** / **`--output FILE`** — write JSON to `FILE`.
- **`--stdout`** — print JSON to stdout.
- **`-h`** / **`--help`** — show help.

## Output

Condensed JSON with: `host`, `board`, `bios`, `chassis`, `chipset`, `pci[]`, `usb[]`, `block[]`, `input[]`. Empty sections are omitted. Serial numbers and identifiers are included where the kernel exposes them (DMI, devicetree, sysfs).

Values are reported as the firmware/kernel provides them. When a value is a known DMI placeholder (e.g. `x.x`, `Default string`, `To be filled by O.E.M.`), hbom emits the literal `"placeholder"` instead so the field remains present but indicates the firmware did not set a real value.
