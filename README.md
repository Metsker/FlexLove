# FlexLöve

CSS-style UI library for [LÖVE2D](https://love2d.org/). Flexbox, Grid, theming, animations, input - named after the CSS/DOM property they correspond to, so a CSS-fluent developer (or agent) can compose UI without learning a parallel vocabulary.

> Retained mode only. v0.14 and earlier shipped an immediate-mode runtime; v0.15 removed it.

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

See `examples/basic_ui.lua` for a complete worked example.

## API surface

### Layout

| Prop | Values | Notes |
| --- | --- | --- |
| `display` | `"block"` (default), `"flex"`, `"grid"`, `"none"` | `flex`/`grid` make this a container that lays out its children; `none` removes it from layout, render, and hit-testing |
| `position` | `"static"`/`"relative"` (default), `"absolute"`, `"fixed"` | `absolute`/`fixed` detach from flow so `top`/`right`/`bottom`/`left` apply |
| `flexDirection` | `"row"`, `"column"` | CSS values only. `row-reverse` / `column-reverse` not yet implemented. |
| `justifyContent` | `"flex-start"`, `"center"`, `"flex-end"`, `"space-between"`, `"space-around"`, `"space-evenly"` | |
| `alignItems` | `"stretch"`, `"flex-start"`, `"center"`, `"flex-end"`, `"baseline"` | |
| `flexWrap` | `"nowrap"`, `"wrap"`, `"wrap-reverse"` | |
| `flex`, `flexGrow`, `flexShrink`, `flexBasis` | numbers / `"1 0 auto"` style strings | |
| `gridRows`, `gridColumns` | number or array `{ "1fr", "auto", "100px" }` | |
| `columnGap`, `rowGap`, `gap` | number, `"10px"`, `"5%"`, `"2vw"` | |
| `top`/`right`/`bottom`/`left` | number, `"50%"`, `"10vh"`, `FlexLove.calc("50% - 10px")` | Only used for `position: absolute` / `fixed` |

Auto-sizing: omit `width` or `height` to size to content. **Don't** pass `"auto"` - just leave the prop off.

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

### Tree composition - children, not parent

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

-- Runtime mutation:
panel:appendChild(childC)      -- add
panel:removeChild(childA)      -- remove a specific child
panel:replaceChildren()        -- clear all
childA:setParent(otherParent)  -- move

-- `panel.children` is a read-mostly array of currently-attached Element
-- instances. Iterate it freely; don't reassign it.
for _, child in ipairs(panel.children) do print(child.id) end
```

There is no diff/reconciliation step - this is a retained-mode UI tree, not a React-style virtual DOM. Build trees declaratively at construction; mutate them imperatively after.

DOM-named tree-mutation methods: `appendChild`, `removeChild`, `replaceChildren`, `setParent`, `getChildCount`. Find elements via `FlexLove.getElementById(id)` and `FlexLove.elementFromPoint(x, y)`.

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
FlexLove.init({ theme = "metal" })

FlexLove.new({
  themeComponent = "button",          -- pulls 9-patch atlas + insets from theme
  text = "Save",
})
```

Files ending in `.9.png` are auto-detected: the 1px guide border is stripped on load, top/left guides drive stretch regions, and bottom/right guides become content padding applied to children. See `themes/metal.lua` and `themes/space.lua`.

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

## Migrating from v0.15.0

| Old | New |
| --- | --- |
| `textSize`, `minTextSize`, `maxTextSize`, `autoScaleText` | `fontSize`, `minFontSize`, `maxFontSize`, `autoScaleFont` |
| `textColor` | `color` |
| `cornerRadius` | `borderRadius` |
| `imagePath`, `objectFit`, `objectPosition`, `imageRepeat`, `imageOpacity` | `backgroundImage`, `backgroundSize`, `backgroundPosition`, `backgroundRepeat`, `backgroundOpacity` |
| `flexDirection = "horizontal" \| "vertical"` | `flexDirection = "row" \| "column"` |
| `addChild`, `clearChildren`, `getById`, `getElementAtPosition` | `appendChild`, `replaceChildren`, `getElementById`, `elementFromPoint` |
| `textAlign = "top-left"` etc. (compound strings) | `textAlign = "start"\|"center"\|"end"\|"justify"` + `verticalAlign = "start"\|"center"\|"end"` |
| `border = 2, borderColor = c` | `border = "2px solid #ff0000"` (or keep the table form) |
| `el:setTransition("opacity", { duration = 0.3 })` | `transition = "opacity 0.3s"` on the prop table |
| `onEvent + if event.type == "click"` | `onClick = function ...` |

## Repo layout

```
FlexLove.lua          - main module (the only require() entry point)
modules/              - everything FlexLove.lua wires together
examples/             - runnable LÖVE examples
themes/               - sample theme definitions
testing/              - luaunit-based test suite: lua testing/runAll.lua --no-coverage
resources/            - sample images for the README's demos
```

## Compatibility

- **Lua**: 5.1+ / LuaJIT / 5.4
- **LÖVE**: 11.x

## License

MIT. See `LICENSE`.
