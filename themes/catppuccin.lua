-- catppuccin.lua — FlexLöve theme based on the Catppuccin Mocha palette.
-- https://catppuccin.com/palette
--
-- Colors only — no 9-patch component atlases.  Elements that set
-- `themeComponent = "..."` resolve to nil here and fall back to their own
-- `backgroundColor` / `borderRadius` props for visuals.  Add a `components`
-- block alongside `colors` if you later drop atlas PNGs into the project.

local Color = require("libs.FlexLove").Color

-- ── Catppuccin Mocha palette ──────────────────────────────────────────────
local palette = {
  rosewater = Color.fromHex("#f5e0dc"),
  flamingo = Color.fromHex("#f2cdcd"),
  pink = Color.fromHex("#f5c2e7"),
  mauve = Color.fromHex("#cba6f7"),
  red = Color.fromHex("#f38ba8"),
  maroon = Color.fromHex("#eba0ac"),
  peach = Color.fromHex("#fab387"),
  yellow = Color.fromHex("#f9e2af"),
  green = Color.fromHex("#a6e3a1"),
  teal = Color.fromHex("#94e2d5"),
  sky = Color.fromHex("#89dceb"),
  sapphire = Color.fromHex("#74c7ec"),
  blue = Color.fromHex("#89b4fa"),
  lavender = Color.fromHex("#b4befe"),

  text = Color.fromHex("#cdd6f4"),
  subtext1 = Color.fromHex("#bac2de"),
  subtext0 = Color.fromHex("#a6adc8"),
  overlay2 = Color.fromHex("#9399b2"),
  overlay1 = Color.fromHex("#7f849c"),
  overlay0 = Color.fromHex("#6c7086"),
  surface2 = Color.fromHex("#585b70"),
  surface1 = Color.fromHex("#45475a"),
  surface0 = Color.fromHex("#313244"),
  base = Color.fromHex("#1e1e2e"),
  mantle = Color.fromHex("#181825"),
  crust = Color.fromHex("#11111b"),
}

return {
  name = "Catppuccin Mocha",

  -- Semantic aliases mapped to palette entries.  Code should prefer the
  -- semantic name (primary/text/border) so swapping flavours later is a
  -- one-file change.  The full palette is also exposed under its native
  -- Catppuccin names for ad-hoc highlights.
  colors = {
    -- semantic
    primary = palette.mauve,
    secondary = palette.surface0,
    accent = palette.peach,
    text = palette.text,
    textDark = palette.overlay1,
    background = palette.base,
    surface = palette.mantle,
    border = palette.surface1,
    success = palette.green,
    warning = palette.yellow,
    danger = palette.red,
    info = palette.sapphire,

    -- full Catppuccin palette
    rosewater = palette.rosewater,
    flamingo = palette.flamingo,
    pink = palette.pink,
    mauve = palette.mauve,
    red = palette.red,
    maroon = palette.maroon,
    peach = palette.peach,
    yellow = palette.yellow,
    green = palette.green,
    teal = palette.teal,
    sky = palette.sky,
    sapphire = palette.sapphire,
    blue = palette.blue,
    lavender = palette.lavender,
    subtext1 = palette.subtext1,
    subtext0 = palette.subtext0,
    overlay2 = palette.overlay2,
    overlay1 = palette.overlay1,
    overlay0 = palette.overlay0,
    surface2 = palette.surface2,
    surface1 = palette.surface1,
    surface0 = palette.surface0,
    base = palette.base,
    mantle = palette.mantle,
    crust = palette.crust,
  },
}
