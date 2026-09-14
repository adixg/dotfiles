# Arch on the SSD — primary install

Lenovo IdeaPad Gaming 3 15IMH05 (i5-10300H, 8 GB RAM, GTX 1650 Mobile).

This is the **second** Arch install on this laptop, living on the NVMe SSD
(`nvme0n1p5`, labelled `Arch`). It is now the one in daily use. The original
Arch install on the HDD (`sda4`) is still intact and still bootable from the
GRUB menu, but it is no longer the system being maintained.

The home-server plan that this file originally documented is **deferred** — see
[Home server plan (deferred)](#home-server-plan-deferred) at the bottom. Nothing
there is being acted on right now, but it is kept because the hardware and most
of the reasoning still apply if this box ever does become an always-on server.

---

## Current layout

| Device | Contents |
| --- | --- |
| `nvme0n1p1` | EFI system partition (`SYSTEM_DRV`), mounted at `/efi` |
| `nvme0n1p2` | Microsoft reserved (MSR) |
| `nvme0n1p3` | Windows (`Windows-SSD`) |
| `nvme0n1p4` | Windows Recovery (WinRE) |
| `nvme0n1p5` | **Arch — current root**, ext4, ~157 G |
| `sda1` | Microsoft reserved, leftover |
| `sda2` | NTFS `Data` |
| `sda3` | swap (not currently used by this install) |
| `sda4` | **Old Arch install**, ext4, intact and bootable |

Boot: UEFI, Secure Boot off, GRUB installed to `/efi/EFI/GRUB` with its config
at `/boot/grub/grub.cfg`. Firmware boot order puts GRUB first; the GRUB menu
lists this Arch install, Windows, and the old Arch on `sda4`.

## Done on this install

- Root migrated to the NVMe (this was item 11 of the old plan).
- GRUB reinstalled properly from this system: `grub` + `os-prober` are real
  pacman packages now, `/efi` is mounted via `fstab`, `GRUB_DISABLE_OS_PROBER=false`
  is set, and the stale 2024 `grub.cfg` that lived on the ESP has been removed.
- `fuse3` installed — without it `grub-mount` cannot run, and `os-prober`
  silently fails to detect *any* unmounted partition (this is what hid the old
  Arch install from the boot menu).
- Dead `ubuntu` UEFI boot entry removed.
- NVIDIA GTX 1650 switched from `nouveau` to the proprietary driver. Under
  `nouveau`, EGL failed to initialise on that GPU and the HDMI output — which is
  wired to the dGPU — displayed nothing at all.
- `intel-ucode` installed (was item 10).
- **Audio**: there was no audio stack at all. `pipewire`, `pipewire-pulse`,
  `pipewire-alsa`, `wireplumber` and `rtkit` installed. Note the sockets only
  activate at session start, so the first time they need starting by hand.
  Firefox had also grabbed the ALSA device directly (it launched when no sound
  server existed and fell back to raw ALSA), which blocked PipeWire from
  claiming the internal card until Firefox was closed.
- **Swap**: `zram-generator` configured with `zram-size = ram / 2`, zstd, giving
  3.8 G of compressed swap at priority 100 — roughly 8-11 G of effective
  capacity at typical zstd ratios, with zero SSD writes. Paired with
  `vm.swappiness = 180` and `vm.page-cluster = 0` in
  `/etc/sysctl.d/99-zram.conf`: high swappiness is correct *because* the swap
  is in RAM, where swapping costs microseconds of CPU rather than a disk
  round-trip. If disk swap is ever added, lower swappiness back toward 60.
  `sda3` (7.7 G swap, from the old install) is deliberately left off — using it
  would keep the HDD spinning and work against the `Load_Cycle_Count` problem
  in item 5.
- Tailscale joined to the tailnet as `arch-ssd` (`100.115.174.125`), with
  `tailscaled` enabled so it survives reboots.
- `smartmontools`, `nvme-cli`, `openssh`, `bluez`, `ntfs-3g`, `acpi`, `paru`
  and the desktop pieces that were missing (`dunst`, `btop`, `grim`, `slurp`,
  `brightnessctl`, `neovim`, `xdg-desktop-portal-hyprland`, `hyprpolkitagent`,
  `hypridle`, fonts) installed.
- Dotfiles now actually in use: `~/.config/{hypr,kitty,waybar,wofi,btop,cava}`
  and `~/.zshrc` are symlinks into this repo. Several were plain directories or
  missing entirely, so those configs had never been loading.

## Outstanding on this install

These apply to normal daily use, not to server duty.

### Remote access — done
- [x] Tailscale SSH enabled (`tailscale up --ssh`). `sshd` stays `disabled`/
      `inactive` on purpose — no open port, no keys to manage, access is
      governed by tailnet ACLs instead.
- [x] MagicDNS confirmed working tailnet-wide (`arch-ssd.tail38f762.ts.net`),
      so `ssh aditya@arch-ssd` works as-is from any device on the tailnet —
      no local alias needed anywhere.

### SSD housekeeping — mostly done
- [x] TRIM enabled (`fstrim.timer`).
- [ ] Consider `noatime` for `/` in `fstab` (currently `relatime`, which is
      already fine — this is a marginal gain).

### Backups
Still nothing. `sda4` and `sda2` are large and idle and make a reasonable local
target, but a local-only backup on the same machine is not a backup. **This is
the single biggest gap left on this install.**
- [ ] Set up `restic` or `borg`, then **test a restore**.

### Git / SSH credentials — done
- [x] Dotfiles `origin` is on HTTPS with a PAT cached via
      `credential.helper store`, so pushes work. No SSH key exists
      (`~/.ssh` is absent); generate one if key-based auth is ever wanted.
- [x] `iit`/`iitjump` aliases removed from `zshrc` — no longer needed, so
      `sshpass` is not required either.
- [x] Dead `ubuntu` alias (pointed at `100.125.129.5`, offline 400+ days)
      removed from `zshrc`.

### Old install cleanup (not urgent)
- [ ] `sda4` is being kept as a fallback. Once confident in this install,
      decide whether to repurpose it (the old plan wanted `anaconda3` and
      `anime` bind-mounted from it — that was never set up, so nothing on this
      install depends on it today).

## Health check

```
sudo smartctl -H -A /dev/nvme0             # Percentage Used / Available Spare / Unsafe Shutdowns
sudo smartctl -H -A -f brief /dev/sda      # Reallocated / Pending / Load_Cycle_Count
sensors                                    # temperatures
systemctl --failed                         # anything broken
journalctl -p 3 -b                         # errors since boot
ss -tulpn                                  # what's listening
```

### NVMe reading, 2026-09-13 (after the migration)

```
Percentage Used              8%          unchanged since the 2026-09-03 check
Available Spare              100%        threshold 10% — no reserve consumed
Media/Data Integrity Errors  0
Error Log Entries            0
Data Units Written           35.0 TB
Power On Hours               3,746
Power Cycles                 5,321
Unsafe Shutdowns             129         also unchanged since 2026-09-03
Temperature                  37 C
```

What this means: 35 TB written for 8 % consumed implies an effective endurance
around 435 TB, well above the ~150 TBW typically quoted for this class of
drive, leaving roughly 400 TB of writes. A light server writing 10-20 GB/day
would take decades to reach that, so **endurance is not the constraint** and
running 24/7 costs it almost nothing — what wears an SSD is bytes written, not
hours powered on.

The real hazard is **sudden power loss**, and 129 unsafe shutdowns is ~2.4 % of
all power-offs. That matters more now than it did in September: back then this
drive held only Windows, and it now holds the OS. This is why the UPS (item 2)
is the one deferred item worth promoting. Reassuringly, none of the damage
indicators have moved — spare still 100 %, zero media errors — so the 129 are
history rather than an ongoing pattern. Every shutdown since this install was
created has been clean.

---

# Home server plan (deferred)

Everything below was written for using this laptop as an always-on home server
(lid closed, external screen). **It is not being done right now.** Kept for
reference in case that changes.

Assessment was done **2026-09-03, before the SSD migration**, so where it talks
about `/` living on the HDD, or about Tailscale already running, that describes
the old `sda4` install. The hardware facts and the reasoning still hold.

Verdict at the time: safe to run 24/7 once the "Must" items were done. Nothing
was failing; the fixes were about battery safety, staying reachable, and not
wearing out the disk faster than necessary.

Status snapshot at assessment time:
- HDD (`/dev/sda`, WD10SPZX, held `/` then): SMART PASSED, 0 reallocated / 0
  pending sectors, 0 CRC errors, 7985 power-on hours. Only issue:
  `Load_Cycle_Count` 294828 and climbing fast (~37/hr) due to aggressive head
  parking.
- NVMe (`/dev/nvme0`, SK Hynix, Windows/NTFS then): SMART PASSED, 8% wear, 0
  errors. Healthy. **129 unsafe shutdowns** recorded here.
- Battery (L19D3PF4): 1435 cycles, ~82% of design capacity, held at partial
  charge by TLP. (TLP is *not* installed on the current SSD install.)
- No firewall, SSH allows passwords, on WiFi not Ethernet, no backups, no UPS.

## Must do before leaving it on 24/7

### 1. Battery: inspect, then remove or cap hard
- [ ] Physically check the battery for **swelling** (bulging bottom cover,
      lifting trackpad, laptop won't sit flat). A swollen Li-po in an always-on
      unattended machine is the one real fire risk here.
- [ ] Decide: **remove the battery and run AC-only** (preferred), OR keep it in
      with a low charge cap.

**To remove it (internal battery, means opening the bottom cover):**
1. Full shutdown, unplug charger.
2. Check BIOS/UEFI for a "Disable built-in battery" option (common on Lenovo) —
   use it if present, then power off.
3. Flip laptop over, remove the ~10 bottom-cover Phillips screws (a couple near
   the hinge are captive and only loosen). Note any different screw lengths.
4. Pry the cover off with a plastic spudger/guitar pick, starting at the hinge
   edge. Plastic clips — go slow.
5. Battery is the big flat pack near the front, 3-4 screws + one ribbon
   connector. **Disconnect the connector first** (lift the plug straight up, not
   by the wires), then remove screws, then lift the pack out.
6. Reinstall the bottom cover. Plug in AC, power on.

Notes:
- Lenovo laptops boot and run fine on AC with no battery. Some models cap
  CPU/GPU power without a battery — irrelevant for an idle headless server.
- Removing the battery means **no built-in UPS** → get a UPS (see item 2).
- Store the removed pack at ~40-60% charge, cool, in a metal tin, away from
  anything flammable. Recycle as battery e-waste, don't bin it.

**If keeping the battery instead**, in `/etc/tlp.conf`:
```
STOP_CHARGE_THRESH_BAT0=60
START_CHARGE_THRESH_BAT0=55
```
then `sudo systemctl restart tlp`. Verify with `sudo tlp-stat -b`. Still
eyeball it for swelling every few months.
(Thresholds read START=80 / STOP=1 at assessment time, which looked
misconfigured — fix regardless of which path you choose.)

### 2. Add a UPS
- [ ] Buy a small UPS (~600 VA, ~$60-80). **129 unsafe shutdowns** on the NVMe
      means this box loses power / hard-locks regularly. Now that the OS lives
      on that NVMe, this matters more than it did. Mandatory if the battery
      comes out.
- [ ] Configure `nut` for automatic clean shutdown on battery.

### 3. Stop lid-close from suspending the server
It only stays awake now because logind sees it as "docked" via the external
display. Replug the monitor or a config hiccup → suspend → server offline.
- [ ] Create `/etc/systemd/logind.conf.d/server.conf`:
```
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```
- [ ] `sudo systemctl restart systemd-logind`

### 4. Lock down SSH
At assessment: `PasswordAuthentication yes`, listening on `0.0.0.0:22`, no
brute-force protection.
- [ ] Put keys in `~/.ssh/authorized_keys`, confirm key login works.
- [ ] In `/etc/ssh/sshd_config.d/10-hardening.conf`:
```
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
```
- [ ] `sudo systemctl restart sshd`
- [ ] Install `sshguard` or `fail2ban` and enable it.
- [ ] Preferred: restrict port 22 to the Tailscale interface + LAN subnet only
      (firewall rule, or `ListenAddress` lines) — use Tailscale as the remote
      path, don't port-forward 22 on the router. Tailscale SSH avoids running
      `sshd` for inbound entirely.

## Should do

### 5. Fix HDD head-parking (load cycle count)
Only relevant if the HDD stays in active use; it is not mounted by the current
install. `Load_Cycle_Count` was at ~49% of the ~600k rating after only 8000
hours.
- [ ] Add to `/etc/tlp.conf` (TLP will override manual `hdparm` otherwise):
```
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="254 254"
DISK_IDLE_SECS_ON_AC=0
```
- [ ] `sudo systemctl restart tlp`
- [ ] Verify: `sudo hdparm -B /dev/sda` → should show 254 / "APM_level = off".
- [ ] Re-check in ~1 week: `sudo smartctl -A /dev/sda | grep Load_Cycle`. If
      still climbing fast, install `idle3-tools` (AUR), run
      `sudo idle3ctl -d /dev/sda`, then fully power-cycle the machine.

### 6. Backups
(Also listed above as outstanding for daily use — it matters either way.)
- [ ] Set up `restic` or `borg`, weekly, to an external disk and/or a remote.
- [ ] Test a restore.

### 7. smartd self-tests + alerting
- [ ] In `/etc/smartd.conf`, replace the `DEVICESCAN` line with:
```
/dev/sda    -a -o on -S on -s (S/../.././02|L/../../6/03) -W 4,45,55 -m root -M exec /usr/share/smartmontools/smartd_warning.sh
/dev/nvme0  -a -W 4,45,60 -m root -M exec /usr/share/smartmontools/smartd_warning.sh
```
      (short test nightly 02:00, long test Sat 03:00, temp tracking)
- [ ] `sudo systemctl restart smartd`
- [ ] Edit `smartd_warning.sh` to push a notification you'll actually see on a
      headless box (ntfy / Slack webhook / Tailscale), since `-m root` mail goes
      nowhere without an MTA.

### 8. Firewall
No firewall at all (nftables empty, iptables empty, ufw/firewalld not
installed).
- [ ] Install `ufw`. Default deny incoming, allow outgoing.
- [ ] Allow SSH from the LAN subnet and/or `tailscale0` only.
- [ ] Allow whatever services you actually expose.
- [ ] Note: Docker writes its own iptables rules and bypasses ufw when you
      publish container ports — account for that.

### 9. Wire Ethernet
Currently on WiFi (`wlp0s20f3`); iwlwifi logged association hiccups. Use a cable
for a server — WiFi drops cause intermittent unreachability.

### 10. intel-ucode — done
Installed on the current SSD install.

## Nice to have

### 11. Move root onto the NVMe — done
Completed. Root now lives on `nvme0n1p5`. Note the hot/cold split described in
the original plan was **not** carried out: `anaconda3` and `anime` were left on
`sda4`, but no bind mounts were configured, so the current install simply does
not reference them.

### 12. ProtonVPN daemon
`proton.VPN.service` was enabled but failed to start on every boot on the old
install. If unused:
- [ ] `sudo systemctl disable --now proton.VPN.service`
(A full-tunnel VPN on a server also breaks inbound LAN/Tailscale reachability —
leave it off unless you have a specific need.)

### 13. Tailscale hardening
- [x] `tailscaled` enabled and the node is on the tailnet as `arch-ssd`
      (`100.115.174.125`).
- [ ] **Disable key expiry** for this node in the admin console, or an
      unattended box silently drops off the tailnet after ~6 months and takes
      your remote access with it. This is the single most common way people
      lock themselves out of a Tailscale home server.
- [ ] Tighten ACLs to only what needs to reach it.
- [ ] Consider Tailscale SSH (`tailscale up --ssh`).

---

Idle power draw ≈ 10-20 W ≈ $1-3/month.
