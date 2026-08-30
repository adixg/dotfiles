-- Migrated from the user's legacy hyprland.conf to Hyprland 0.55+ Lua syntax.
-- Current config location: ~/.config/hypr/hyprland.lua

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = "#000000",
    },
})

hl.device({
    name = "at-translated-set-2-keyboard",
    enabled = false,
})


------------------
---- MONITORS ----
------------------

-- External Lenovo monitor: left
hl.monitor({
    output = "HDMI-A-1",
    mode = "1280x1024@60.02",
    position = "0x0",
    scale = 1,
})

-- Laptop display: right
hl.monitor({
    output = "eDP-1",
    position = "1280x0",
    scale = 1,
})

-- For screensharing, replace the eDP-1 rule above with:
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "1920x0", scale = 1, bitdepth = 8 })

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpaper.service")
    hl.exec_cmd("waybar -c ~/.config/waybar/retro.jsonc -s ~/.config/waybar/retro.css")
--    hl.exec_cmd("swww-daemon && swww img ~/Downloads/wallpaper.png --transition-type wipe --transition-duration 2")
--    hl.exec_cmd("dunst")

    -- Preserve your old silent workspace launches.
    hl.exec_cmd("kitty", { workspace = "1 silent" })
    hl.exec_cmd("firefox", { workspace = "2 silent" })
    hl.exec_cmd("kitty", { workspace = "3 silent" })
    hl.exec_cmd("kitty btop", { workspace = "9 silent" })

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "36")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Force QtWebEngine (qutebrowser) to use GBM for hardware-accelerated
-- rendering on Wayland; avoids the software-fallback / black-screen issues.
hl.env("QTWEBENGINE_FORCE_USE_GBM", "1")

----------------
---- INPUT -----
----------------

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Your old config sourced Catppuccin Macchiato and used only $blue + $rosewater
-- for the active border. Those colors are inlined here so this file is standalone.
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgb(8aadf4)", "rgb(f4dbd6)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },
})

-- Preserve your custom animation timings.
hl.curve("myBezier", {
    type = "bezier",
    points = {
        { 0.05, 0.9 },
        { 0.1, 1.05 },
    },
})

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })

--------------------
---- WINDOW RULES --
--------------------

-- Make qutebrowser slightly transparent (active and inactive opacity).
-- qutebrowser's real window class is "org.qutebrowser.qutebrowser".
hl.window_rule({
    match   = { class = "org.qutebrowser.qutebrowser" },
    opacity = "0.92 0.92",
})

----------------
---- GESTURE ----
----------------

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

----------------------
---- PER-DEVICE -------
----------------------

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Q",      hl.dsp.exec_cmd("qutebrowser"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + G",      hl.dsp.exec_cmd("godot"))
hl.bind(mainMod .. " + P",      hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("emacs"))
hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd("retroarch"))
hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("kitty -e ani-cli"))
hl.bind(mainMod .. " + U",      hl.dsp.exec_cmd("alacritty"))
hl.bind(mainMod .. " + Z",      hl.dsp.exec_cmd("librewolf"))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("discord"))
hl.bind(mainMod .. " + Y",      hl.dsp.exec_cmd("anki"))

-- Window / compositor actions
hl.bind(mainMod .. " + C", hl.dsp.window.close({}))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.group.toggle({}))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- NOTE: your old config also assigned SUPER+P to pseudotiling, which conflicts
-- with SUPER+P = Spotify above. Uncomment this and change the key if desired.
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo({ action = "toggle" }))

-- Launchers / lock / logout
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("wofi --show drun --conf ~/github/wofi/config/config --style ~/github/wofi/src/macchiato/style.css"))

hl.bind(
    "SUPER + I",
    hl.dsp.exec_cmd("/home/aditya/.config/hypr/scripts/next-wallpaper.sh"),
    { description = "Next wallpaper" }
)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("wlogout"))

-- Screenshot selected region
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%F_%T).png]]))

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume 0 +10%"))
hl.bind("F3",                    hl.dsp.exec_cmd("pactl set-sink-volume 0 +10%"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume 0 -10%"))
hl.bind("F2",                    hl.dsp.exec_cmd("pactl set-sink-volume 0 -10%"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-volume 0 0"))
hl.bind("F1",                    hl.dsp.exec_cmd("pactl set-sink-volume 0 0"))

-- Brightness
hl.bind("F6", hl.dsp.exec_cmd("brightnessctl set +1%"))
hl.bind("F5", hl.dsp.exec_cmd("brightnessctl set 1%-"))

-- Focus movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- Group cycling
hl.bind("SUPER + ALT + J", hl.dsp.group.next({}))
hl.bind("SUPER + ALT + K", hl.dsp.group.prev({}))

-- Workspace switching and moving windows.
local workspaceKeys = {
    { key = "1", workspace = 1 },
    { key = "2", workspace = 2 },
    { key = "3", workspace = 3 },
    { key = "4", workspace = 4 },
    { key = "5", workspace = 5 },
    { key = "6", workspace = 6 },
    { key = "7", workspace = 7 },
    { key = "8", workspace = 8 },
    { key = "9", workspace = 9 },
    { key = "0", workspace = 10 },
}

for _, item in ipairs(workspaceKeys) do
    hl.bind(mainMod .. " + " .. item.key,
        hl.dsp.focus({ workspace = item.workspace }))

    hl.bind(mainMod .. " + SHIFT + " .. item.key,
        hl.dsp.window.move({ workspace = item.workspace, follow = true }))
end

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move / resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Keyboard resize
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -10, y = 0,   relative = true }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -10, relative = true }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }))
