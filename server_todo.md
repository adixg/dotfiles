# Home Server TODO

Laptop (Lenovo IdeaPad Gaming 3 15IMH05, i5-10300H, 8 GB RAM) running Arch, lid
closed / external screen, used as an always-on home server.

Assessment done 2026-09-03. Verdict: **safe to run 24/7 once the "Must" items
below are done.** Nothing is currently failing; the fixes are about battery
safety, staying reachable, and not wearing out the disk faster than necessary.

Status snapshot at assessment time:
- HDD (`/dev/sda`, WD10SPZX, holds `/`): SMART PASSED, 0 reallocated / 0 pending
  sectors, 0 CRC errors, 7985 power-on hours. Only issue: `Load_Cycle_Count`
  294828 and climbing fast (~37/hr) due to aggressive head parking.
- NVMe (`/dev/nvme0`, SK Hynix, Windows/NTFS): SMART PASSED, 8% wear, 0 errors.
  Healthy. **129 unsafe shutdowns** recorded here.
- Battery (L19D3PF4): 1435 cycles, ~82% of design capacity, held at partial
  charge by TLP.
- No firewall, SSH allows passwords, on WiFi not Ethernet, no backups, no UPS.

---

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
(Current thresholds read START=80 / STOP=1, which looks misconfigured — fix
regardless of which path you choose.)

### 2. Add a UPS
- [ ] Buy a small UPS (~600 VA, ~$60-80). **129 unsafe shutdowns** on the NVMe
      means this box loses power / hard-locks regularly; the HDD has survived so
      far on luck. Mandatory if the battery comes out.
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
Currently: `PasswordAuthentication yes`, listening on `0.0.0.0:22`, no
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
      (firewall rule, or `ListenAddress` lines). Tailscale is already running —
      use it as the remote path, don't port-forward 22 on the router.

---

## Should do

### 5. Fix HDD head-parking (load cycle count)
`Load_Cycle_Count` is at ~49% of the ~600k rating after only 8000 hours.
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
No cron jobs, no timers, no backup tooling. If `/dev/sda` dies, everything is
gone.
- [ ] Set up `restic` or `borg`, weekly, to an external disk and/or a remote.
- [ ] Test a restore.

### 7. smartd self-tests + alerting
`smartd` is enabled but only watches attributes.
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

### 10. intel-ucode
Not installed — CPU shows "Old microcode" / "Vulnerable: No microcode" for
several items. Bootloader is GRUB; `mkinitcpio` HOOKS already has the
`microcode` hook, so no manual bootloader edits needed.
- [ ] `sudo pacman -S intel-ucode`
- [ ] `sudo mkinitcpio -P`
- [ ] `sudo grub-mkconfig -o /boot/grub/grub.cfg`
- [ ] Reboot, verify: `journalctl -k -b | grep -i microcode` → "microcode
      updated early to revision 0x...".

---

## Nice to have

### 11. Move root onto the NVMe (promoted from "nice to have" — plan finalized)
The SSD is healthy (8% wear) and would be far better for 24/7 than a 5400rpm
laptop HDD, which is also the drive with the climbing `Load_Cycle_Count`. The
HDD's `Load_Cycle_Count` fix (item 5) still matters regardless of this move,
since the HDD isn't going away — it becomes the cold-storage disk (see below).

**Current numbers** (checked 2026-09-11):
- Root (`sda4`, ext4) uses 149G of 232G.
- `/home/aditya` is 94G of that. Breakdown: `anaconda3` 44G, `.cache` 14G,
  `anime` 14G, `.ollama` 6.2G, everything else (`~/.config`, `~/.rustup`,
  `~/github`, `~/codes`, `~/Downloads`, browser profiles, `~/uni_memories`,
  etc.) ~22G combined.
- `/var/cache/pacman/pkg` is 12G — prunable.
- Non-home system footprint (`/etc`, `/var` minus pacman cache, etc.) ≈ 43G.
- Decision made: `anaconda3` and `anime` are cold/unused on this server — they
  stay behind on the HDD rather than moving to the SSD. `.ollama` is treated as
  hot (kept on SSD) since model-load speed benefits from NVMe — flag if that's
  wrong and it should move to cold storage instead.
- **New NVMe root only needs to hold**: ~43G system + ~22G home (misc) +
  `.ollama` 6.2G ≈ **~72G**, so size the new partition generously at
  **100-120G** for headroom (Docker images, package growth, logs).

**Key design decision: hot/cold split, not a full copy.**
`anaconda3` and `anime` (58G) get *left in place* on the old `sda4` — no need
to re-copy them anywhere. After migration, `sda4` stops being root and becomes
a plain data volume; those two folders are bind-mounted back into
`/home/aditya` on the new system so every path stays identical (nothing that
references `~/anaconda3` or `~/anime` needs to change).

**Steps:**
1. **Windows**: Settings → Power → disable Fast Startup. Fully shut down (not
   sleep/hibernate — a hibernated NTFS volume can make Linux tools refuse to
   touch it). Boot into Windows, Disk Management → shrink `C:` (`nvme0n1p3`)
   by ~110-130G.
2. **Backup irreplaceable data** to an external drive before any partitioning
   — SSH keys, `~/github`, `~/codes`, `~/uni_memories`, `~/org`, anything not
   already in a git remote. (This doubles as finally doing item 6.)
3. Boot a live/rescue environment, create a new ext4 partition in the freed
   NVMe space (e.g. `nvme0n1p5`).
4. `rsync -aHAXS` from `sda4` (mounted, not live-booted-from) to the new
   partition, **excluding**:
   `/proc /sys /dev /run /tmp /mnt /media /lost+found`,
   `home/aditya/.cache`, `home/aditya/anaconda3`, `home/aditya/anime`,
   and prune `/var/cache/pacman/pkg` first (`paccache -rk1`) or exclude it too.
5. Chroot into the new root:
   - Update `/etc/fstab`: new root UUID; keep swap on `sda3` as-is; add an
     entry mounting the old `sda4` (now a data volume) at e.g. `/mnt/hdd`;
     add bind mounts —
     `/mnt/hdd/home/aditya/anaconda3 -> /home/aditya/anaconda3` and
     `/mnt/hdd/home/aditya/anime -> /home/aditya/anime` (create the empty
     mountpoint dirs first).
   - `mkinitcpio -P` to rebuild the initramfs with the new root UUID baked in.
   - `grub-mkconfig -o /boot/grub/grub.cfg` to regenerate the config.
   - `grub-install` (re-run, targeting the ESP — currently unmounted anywhere,
     likely `nvme0n1p1` shared with Windows) — needed because GRUB's core
     image embeds where to find `/boot/grub` at install time, and that
     pointer needs to move with root. Confirm the exact ESP/target before
     running this.
6. Boot from the new root, verify the bind-mounted folders show up correctly
   and everything works.
7. **Don't touch `sda4` immediately** — keep it bootable as a fallback for a
   few days. Once confident, repurpose the rest of it as: home for the
   `anaconda3`/`anime` bind mounts, plus a good target for the restic/borg
   backup repo from item 6.
8. On the new NVMe-backed root, add `noatime` (or `relatime`) and enable
   `fstrim.timer` — the HDD never needed TRIM, the SSD does.

### 12. ProtonVPN daemon
`proton.VPN.service` is enabled but fails to start on every boot. If unused:
- [ ] `sudo systemctl disable --now proton.VPN.service`
(A full-tunnel VPN on a server also breaks inbound LAN/Tailscale reachability —
leave it off unless you have a specific need.)

### 13. Tailscale hardening
- [ ] Disable key expiry for this node (so it doesn't drop off the tailnet).
- [ ] Tighten ACLs to only what needs to reach it.
- [ ] Consider Tailscale SSH.

---

## Reference: re-run the health check later

```
sudo smartctl -H -A -f brief /dev/sda      # watch Reallocated / Pending / Load_Cycle_Count
sudo smartctl -H -A /dev/nvme0             # watch Percentage Used / Available Spare / Unsafe Shutdowns
sudo tlp-stat -b                           # battery charge thresholds + health
sensors                                    # temperatures
systemctl --failed                         # anything broken
journalctl -p 3 -b                         # errors since boot
ss -tulpn                                   # what's listening
```

Idle power draw ≈ 10-20 W ≈ $1-3/month.
