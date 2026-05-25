# FlexLöve

CSS-style UI library for [LÖVE2D](https://love2d.org/). Flexbox, Grid, theming, animations, input - named after the CSS/DOM property they correspond to, so an agent fluent in CSS can compose UI without learning a parallel vocabulary.

**Retained mode only.** No reconciliation, no virtual DOM - build trees declaratively at construction; mutate them imperatively after.

This file is the implementation reference for agents using FlexLove. For repo workflows (tests, lint, contributing changes to FlexLove itself), see [`repo.md`](repo.md).

## Quick start

```lua
local FlexLove = require("FlexLove")
local Color    = FlexLove.Color

function love.load()
  FlexLove.init()
  FlexLove.new({
    id        = "root",
    display   = "flex",
    flexDirection  = "column",
    justifyContent = "center",
    alignItems     = "center",
    width = "100vw", height = "100vh",
    backgroundColor = Color.fromHex("#101418"),
    children = {
      {
        text = "Hello, FlexLove",
        color = Color.new(1, 1, 1, 1),
        fontSize = "3vh",
      },
    },
  })
end

function love.update(dt) FlexLove.update(dt) end
function love.draw()     FlexLove.draw()     end
function love.resize()   FlexLove.resize()   end
function love.keypressed(k, sc, rep) FlexLove.keypressed(k, sc, rep) end
function love.textinput(t)           FlexLove.textinput(t) end
function love.wheelmoved(dx, dy)     FlexLove.wheelmoved(dx, dy) end
```

See the repo's `examples/basic_ui.lua` for a complete worked example.

## API surface

### Layout

| Prop | Values | Notes |
| --- | --- | --- |
| `display` | `"flex"` (default), `"block"`, `"grid"`, `"none"` | `flex`/`grid` make this a container that lays out its children; `block` leaves children at their explicit `x`/`y` (no automatic flow); `none` removes it from layout, render, and hit-testing. `flexDirection` / `justifyContent` / `alignItems` / `flexWrap` only take effect under `display = "flex"`; `gridRows` / `gridColumns` only under `display = "grid"`. |
| `position` | `"relative"` (default), `"static"`, `"absolute"`, `"fixed"` | `absolute`/`fixed` detach the child from its parent's flow so `top`/`right`/`bottom`/`left` apply. `display` and `position` are independent: a `display = "flex"` element can also be `position = "absolute"`. |
| `flexDirection` | `"row"`, `"row-reverse"`, `"column"`, `"column-reverse"` | CSS values. `row-reverse` / `column-reverse` mirror the main-axis position of each child (and its subtree); `justifyContent` semantics flip accordingly. |
| `justifyContent` | `"flex-start"`, `"center"`, `"flex-end"`, `"space-between"`, `"space-around"`, `"space-evenly"` | |
| `alignItems` | `"stretch"`, `"flex-start"`, `"center"`, `"flex-end"`, `"baseline"` | |
| `flexWrap` | `"nowrap"`, `"wrap"`, `"wrap-reverse"` | |
| `flex`, `flexGrow`, `flexShrink`, `flexBasis` | numbers / `"1 0 auto"` style strings | |
| `gridRows`, `gridColumns` | number or array `{ "1fr", "auto", "100px" }` | |
| `columnGap`, `rowGap`, `gap` | number, `"10px"`, `"5%"`, `"2vw"` | |
| `top`/`right`/`bottom`/`left` | number, `"50%"`, `"10vh"`, `FlexLove.calc("50% - 10px")` | Only used for `position: absolute` / `fixed` |

Auto-sizing: omit `width` or `height` to size to content. **Don't** pass `"auto"` - just leave the prop off.

> **Defaults diverge from CSS on purpose.** CSS defaults `display: inline` (spec) / `block` (UA stylesheet for `<div>` etc.) and `position: static`. FlexLove defaults `display: flex` and `position: relative`. There's no `inline` mode here, so the spec default isn't applicable; `flex` matches what game UI authors want almost every time; `relative` over `static` is naming-only (they behave identically today) and matches what CSS authors actually write.

### Visual props - all CSS-named

`backgroundColor`, `backgroundImage`, `backgroundSize`, `backgroundPosition`, `backgroundRepeat`, `backgroundOpacity`, `imageTint`, `color`, `fontSize`, `fontFamily`, `textAlign`, `verticalAlign`, `borderRadius`, `border`, `borderStyle`, `borderColor`, `borderTop`/`borderRight`/`borderBottom`/`borderLeft`, `opacity`, `visibility`, `transform`, `transition`, `contentBlur`, `backdropBlur`, `themeComponent`.

**Direct mutation works.** Assigning `el.backgroundColor`, `el.color`, `el.borderRadius`, `el.opacity`, `el.themeComponent`, or any of the event handlers on an existing element takes effect on the next frame. No `setProperty` call required.

### `border` shorthand

```lua
FlexLove.new({ border = "2px solid #ff0000" })           -- all four sides
FlexLove.new({ borderTop = "1px solid #888", borderLeft = "1px solid #888" })
FlexLove.new({ border = 2, borderColor = Color.fromHex("#fff") })  -- legacy table+color form
```

The shorthand parses `<width> <style> <color>` in any order. `borderStyle` is currently a passthrough field - only `"solid"` is rendered.

### `transition` shorthand

```lua
FlexLove.new({
  transition = "opacity 300ms ease-in-out, width 0.5s linear 0.1s",
})
```

`transition` accepts the CSS shorthand: `<property> <duration> <timing-function> <delay>`. Multiple property transitions are comma-separated. Durations accept `300ms`, `0.5s`, or a bare number (seconds). Timing functions: `linear`, `ease`, `ease-in`, `ease-out`, `ease-in-out`, or any FlexLove easing name (e.g. `easeOutCubic`).

### Tree composition

Build trees through `children`, which accepts either:

- **Prop tables** - constructed in place under this element
- **Pre-built `Element` instances** - reparented under this element

```lua
local saveBtn = FlexLove.new({ text = "Save", width = 80, height = 30,
  onClick = function() save() end })

local row = FlexLove.new({
  display = "flex", flexDirection = "row", gap = 8,
  children = {
    { text = "Filename:" },
    { width = 200, height = 30, editable = true, id = "filename-input" },
    saveBtn,
  },
})
```

> **`children` is construction-time only.** The prop is read exactly once, inside `FlexLove.new(...)`. Each entry is constructed (table) or reparented (Element instance) at that moment, then the prop is discarded. After construction, **assigning to `el.children = { ... }` does nothing**: the field still holds the live array of attached child Element instances, but the framework will not interpret a fresh prop table you write into it.
>
> Mutate trees at runtime with the DOM-named methods below.

```lua
-- Construction-time (the only time `children` is interpreted):
local panel = FlexLove.new({ children = { childA, childB } })

-- Construct-and-attach in one step. Resolves percentage units, auto-sizing,
-- and other parent-dependent layout against `panel` at construction time -
-- prefer this when building procedurally:
local childC = panel:appendNew({ width = "50%", height = "100%" })

-- Reparent an existing element:
panel:appendChild(strayElement)

-- Other runtime mutation:
panel:removeChild(childA)
panel:replaceChildren()         -- clear all
childA:setParent(otherParent)   -- move

-- `panel.children` is a read-mostly array of currently-attached Element
-- instances. Iterate it freely; don't reassign it.
for _, child in ipairs(panel.children) do print(child.id) end
```

Tree-mutation methods: `appendNew`, `appendChild`, `removeChild`, `replaceChildren`, `setParent`, `getChildCount`. Find elements via `FlexLove.getElementById(id)` and `FlexLove.elementFromPoint(x, y)`.

#### Conditional and looped children

Lua doesn't have JSX's `{cond && <Foo/>}` shorthand. Build the children array first, then pass it:

```lua
local kids = {}
if showHeader then
  table.insert(kids, { id = "header", text = "Title" })
end
for _, item in ipairs(items) do
  table.insert(kids, { text = item.label, onClick = function() select(item) end })
end

FlexLove.new({ display = "flex", flexDirection = "column", children = kids })
```

### Events - typed handlers + catch-all

DOM-style typed handlers (preferred):

```lua
FlexLove.new({
  text = "Click me",
  onClick       = function(self, event) ... end,
  onMouseDown   = function(self, event) ... end,
  onMouseUp     = function(self, event) ... end,
  onMouseEnter  = function(self, event) ... end,
  onMouseLeave  = function(self, event) ... end,
  onMouseMove   = function(self, event) ... end,   -- fires during drag too
  onDrag        = function(self, event) ... end,   -- fires only during drag
  onContextMenu = function(self, event) ... end,   -- right click
  onAuxClick    = function(self, event) ... end,   -- middle click
})
```

The catch-all `onEvent` still works, sees every type, and fires alongside typed handlers when both are set:

```lua
onEvent = function(self, event)
  -- event.type: "click" | "press" | "release" | "rightclick" | "middleclick"
  --            | "drag" | "hover" | "unhover"
  --            | "touchpress" | "touchmove" | "touchrelease"
  -- event.button: 1 left, 2 right, 3 middle
  -- event.x, event.y, event.modifiers, event.clickCount
end
```

Any handler can be deferred (run after canvas release) by setting its `*Deferred` flag, e.g. `onClickDeferred = true`. Same for `onEvent`, `onMouseDown`, `onTouchEvent`, `onGesture`, `onFocus`, `onBlur`, `onTextInput`, `onTextChange`, `onEnter`, `onCreate`.

### Units

Everywhere a dimension is accepted, you can pass:

- A **number** (pixels)
- A **string** with units: `"100px"`, `"50%"`, `"10vw"`, `"5vh"`, or a named font-size preset (`"xxs"`, ..., `"4xl"`)
- A **`FlexLove.calc(expr)`** result: `FlexLove.calc("50% - 10vw")` (operators `+ - * /`, parentheses, units `px % vw vh`)

### Text input

```lua
FlexLove.new({
  width = 200, height = 30,
  editable    = true,                 -- mandatory
  multiline   = false,
  placeholder = "Type here...",
  text        = "",
  onTextChange = function(el, newText, oldText) ... end,
  onEnter      = function(el) ... end,
})
```

Other input flags: `maxLength`, `passwordMode`, `selectOnFocus`, `cursorColor`, `selectionColor`, `cursorBlinkRate`. Add `love.keyboard.setKeyRepeat(true)` in `love.load` if you want arrow/backspace repeat.

### Keyboard navigation

```lua
FlexLove.init({
  keyboardNavigation = true,
  -- or fine control:
  -- keyboardNavigation = { directionalNavigation = true, wrapAround = false,
  --                        focusIndicator = { color = {0.3, 0.6, 1, 0.8} } }
})
```

Tab/Shift+Tab cycle focus through focusables (anything with `editable = true`, an event handler, or a `themeComponent`). Arrow keys navigate spatially when `directionalNavigation = true`. Enter/Space activate, Escape dismisses.

### Theming and 9-patch

```lua
FlexLove.init({ theme = "catppuccin" })

FlexLove.new({
  themeComponent = "button",          -- pulls 9-patch atlas + insets from theme
  text = "Save",
})
```

Files ending in `.9.png` are auto-detected: the 1px guide border is stripped on load, top/left guides drive stretch regions, and bottom/right guides become content padding applied to children.

Two reference themes live under `themes/` in the repo:

- **`themes/catppuccin.lua`** - Catppuccin Mocha palette. Colors only, no 9-patch atlases or fonts. Elements with `themeComponent = "..."` fall back to their own `backgroundColor` / `borderRadius` props for visuals. Drop this in if you want a coherent palette without sprite work.
- **`themes/example_theme.lua`** - full schema reference (components, states, atlases, insets). Atlas PNGs aren't shipped; copy the structure and supply your own art.

### Color, Animation, Theme, Calc - exposed off `FlexLove`

```lua
FlexLove.calc("50% - 10vw")
FlexLove.Color.new(1, 0, 0, 1)
FlexLove.Color.fromHex("#FF8800")
FlexLove.Animation.fade(0.5, 0, 1):apply(el)
FlexLove.Animation.scale(0.3, { width = 50 }, { width = 100 }):apply(el)
FlexLove.Theme.load("space")
FlexLove.Theme.setActive("space")
```

### Hit-testing, focus, debug

```lua
local el = FlexLove.elementFromPoint(mouseX, mouseY)
local byId = FlexLove.getElementById("save-button")

FlexLove.setFocusedElement(byId)
FlexLove.clearFocus()
local focused = FlexLove.getFocusedElement()

FlexLove.setDebugDraw(true)
```

### Deferred callbacks

LÖVE crashes if you call `love.window.setMode` while a `Canvas` is active. For any callback that needs to, set its `*Deferred` flag and call `FlexLove.executeDeferredCallbacks()` at the very end of `love.draw()` once all canvases are released:

```lua
FlexLove.new({
  text = "Fullscreen",
  onClick = function() love.window.setMode(1920, 1080, { fullscreen = true }) end,
  onClickDeferred = true,
})

function love.draw()
  FlexLove.draw()
  FlexLove.executeDeferredCallbacks()
end
```

## Guarantees you can rely on

These behaviours are part of the public contract - tests pin them down, and they won't silently change:

- **CSS naming wherever it transfers cleanly.** Visual props use `color`, `fontSize`, `borderRadius`, `border`, `borderColor`, `borderStyle`, `borderTop`/etc., `backgroundColor`, `backgroundImage`, `backgroundSize`, `backgroundPosition`, `backgroundRepeat`, `backgroundOpacity`. Layout uses `display`, `position`, `flexDirection = "row"|"column"`, etc.
- **DOM-style tree mutation:** `appendChild`, `removeChild`, `replaceChildren`, `setParent`. Find elements via `FlexLove.getElementById` and `FlexLove.elementFromPoint`.
- **DOM-style typed event handlers:** `onClick`, `onMouseDown`, `onMouseUp`, `onMouseEnter`, `onMouseLeave`, `onMouseMove`, `onDrag`, `onContextMenu`, `onAuxClick`. The catch-all `onEvent(self, event)` still exists for power users; both fire if both are set.
- **CSS shorthand strings:** `border = "2px solid #fff"` and `transition = "opacity 300ms ease-in-out"` are parsed at construction. Multi-property `transition = "opacity 0.3s, transform 0.5s ease-out 0.1s"` works.
- **Direct field mutation** works for: `backgroundColor`, `borderColor`, `borderRadius`, `opacity`, `themeComponent`, `onEvent`, every typed event handler, `onTouchEvent`, `onGesture`, `disabled`, `active`. Set the field and the change is picked up next frame.

## Intentionally out of scope

- Sticky / `position: fixed` is recognised as a synonym for `"absolute"`; full sticky behaviour isn't implemented. Offsets resolve against the immediate parent, not the viewport.
- `position: relative` (the default) and `position: static` behave identically today: `top`/`right`/`bottom`/`left` are ignored on both (a `LAY_011` warning fires) and neither establishes a new containing block for `absolute` descendants — absolute children always position against their immediate parent. Planned future addition: have `relative` honor `top`/`right`/`bottom`/`left` as visual offsets that don't affect flow (the CSS-faithful behavior).
- `display: block` parents do not normal-flow-stack their children. Block just means "I don't lay out my children"; each child sits at the `x`/`y` resolved at construction time. Use `display = "flex"` with `flexDirection = "column"` if you want vertical stacking.
- `borderStyle` values other than `"solid"` (passed through but not rendered).
- Inline display, baseline alignment beyond `stretch`/`flex-start`/`center`/`end`, and CSS `box-sizing: content-box`. Border-box is the only model.
