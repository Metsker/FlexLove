# FlexLöve

CSS-style UI library for [LÖVE2D](https://love2d.org/). Flexbox, Grid, theming, animations, input - written so that an agent (or a human who already knows CSS) can start composing UI in minutes.

> Retained mode only. v0.14 and earlier shipped an immediate-mode runtime; v0.15 removed it.

## Quick start

```lua
local FlexLove = require("FlexLove")
local Color    = FlexLove.Color

function love.load()
  FlexLove.init()                           -- once at startup
  FlexLove.new({                            -- one root tree
    id        = "root",
    display   = "flex",
    flexDirection = "vertical",
    justifyContent = "center",
    alignItems     = "center",
    width = "100vw", height = "100vh",
    backgroundColor = Color.fromHex("#101418"),
    children = {
      { text = "Hello, FlexLove", textColor = Color.new(1,1,1,1), textSize = "3vh" },
    },
  })
end

function love.update(dt) FlexLove.update(dt) end
function love.draw()     FlexLove.draw()     end
function love.resize()   FlexLove.resize()   end
function love.mousepressed(x, y, b)  FlexLove.mousepressed and FlexLove.mousepressed(x, y, b) end
function love.keypressed(k, sc, rep)  FlexLove.keypressed(k, sc, rep) end
function love.textinput(t)            FlexLove.textinput(t) end
function love.wheelmoved(dx, dy)      FlexLove.wheelmoved(dx, dy) end
```

See `examples/basic_ui.lua` for a worked example.

## API surface (the parts you build with)

### Layout - CSS naming, CSS behaviour

| Prop | Values | Meaning |
| --- | --- | --- |
| `display` | `"block"` (default), `"flex"`, `"grid"`, `"none"` | `flex`/`grid` make the element a container that lays out its children; `none` removes it from layout, render, and hit-testing |
| `position` | `"static"`/`"relative"` (default), `"absolute"`, `"fixed"` | `absolute`/`fixed` detach the element so `top`/`right`/`bottom`/`left` apply |
| `flexDirection` | `"horizontal"`/`"row"`, `"vertical"`/`"column"` | Main-axis direction for `display: flex` |
| `justifyContent` | `"flex-start"`, `"center"`, `"flex-end"`, `"space-between"`, `"space-around"`, `"space-evenly"` | Main-axis alignment |
| `alignItems` | `"stretch"`, `"flex-start"`, `"center"`, `"flex-end"`, `"baseline"` | Cross-axis alignment |
| `flexWrap` | `"nowrap"`, `"wrap"`, `"wrap-reverse"` | Multi-line wrapping |
| `flex`, `flexGrow`, `flexShrink`, `flexBasis` | numbers / `"1 0 auto"` style strings | Flex item sizing |
| `gridRows`, `gridColumns` | number or array `{ "1fr", "auto", "100px" }` | Grid track sizes |
| `columnGap`, `rowGap`, `gap` | number, `"10px"`, `"5%"`, `"2vw"` | Track gaps |
| `top`/`right`/`bottom`/`left` | number, `"50%"`, `"10vh"`, `FlexLove.calc("50% - 10px")` | Only respected for `position: absolute` / `fixed` |

Auto-sizing: omit `width` or `height` to size to content. **Don't** pass `"auto"` - just leave the prop off.

### Visuals

`backgroundColor`, `borderColor`, `border`, `cornerRadius`, `opacity`, `visibility`, `transform`, `textColor`, `textSize`, `textAlign`, `fontFamily`, `imagePath`, `objectFit`, `objectPosition`, `imageOpacity`, `imageRepeat`, `imageTint`, `contentBlur`, `backdropBlur`, `themeComponent`.

**Direct mutation works:** assigning `el.backgroundColor`, `el.borderColor`, `el.opacity`, `el.cornerRadius`, `el.themeComponent`, or `el.onEvent` on an existing element takes effect on the next frame. No `setProperty` call required.

### Tree composition - children, not parent

There is no public `parent` prop. Build trees through `children`, which accepts a mix of:

- **Prop tables** - constructed in place under this element
- **Pre-built `Element` instances** - reparented under this element

```lua
local saveBtn = FlexLove.new({ text = "Save", width = 80, height = 30,
  onEvent = function(self, e) if e.type == "release" then save() end end })

local row = FlexLove.new({
  display = "flex", flexDirection = "horizontal", gap = 8,
  children = {
    { text = "Filename:" },          -- prop table -> new child
    { width = 200, height = 30, editable = true, id = "filename-input" },
    saveBtn,                         -- pre-built Element -> reparented
  },
})
```

For mutations after construction use `addChild`, `removeChild`, `setParent`, `clearChildren`, or just edit fields directly.

### Events

```lua
FlexLove.new({
  text = "Click me",
  onEvent = function(self, event)
    -- event.type: "click" | "press" | "release" | "rightclick" | "middleclick"
    --            | "drag" | "hover" | "unhover" | "touchpress" | "touchmove" | "touchrelease"
    -- event.button:     1 = left, 2 = right, 3 = middle
    -- event.x, event.y: mouse position
    -- event.modifiers:  { shift, ctrl, alt, gui }
    -- event.clickCount: 2 for double-click, etc.
  end,
})
```

`onEvent` can be reassigned at any time: `el.onEvent = newHandler` is enough.

### Units

Everywhere a dimension is accepted, you can pass:

- A **number** (pixels)
- A **string** with units: `"100px"`, `"50%"`, `"10vw"`, `"5vh"`, or one of the named text-size presets (`"xxs"`, `"xs"`, ..., `"4xl"`)
- A **`FlexLove.calc(expr)`** result, e.g. `FlexLove.calc("50% - 10vw")` (operators `+ - * /`, parentheses, units `px % vw vh`)

### Text input

```lua
FlexLove.new({
  width = 200, height = 30,
  editable    = true,                 -- mandatory
  multiline   = false,                -- single-line by default
  placeholder = "Type here...",
  text        = "",
  onTextChange = function(el, newText, oldText) ... end,
  onEnter      = function(el) ... end,
})
```

Other text-input flags: `maxLength`, `passwordMode`, `selectOnFocus`, `cursorColor`, `selectionColor`, `cursorBlinkRate`. In `love.load` call `love.keyboard.setKeyRepeat(true)` if you want arrow-key/backspace repeat.

### Keyboard navigation (opt-in)

```lua
FlexLove.init({
  keyboardNavigation = true,
  -- or a table for fine control:
  -- keyboardNavigation = { directionalNavigation = true, wrapAround = false,
  --                        focusIndicator = { color = {0.3, 0.6, 1, 0.8} } }
})
```

Tab / Shift+Tab move sequentially through focusables (anything with `editable = true`, `onEvent`, or a `themeComponent`). Arrow keys do spatial navigation when `directionalNavigation = true`. Enter / Space activate, Escape dismisses.

### Theming and 9-patch

```lua
FlexLove.init({ theme = "metal" })

FlexLove.new({
  themeComponent = "button",          -- pulls 9-patch atlas + insets from theme
  text = "Save",
})
```

9-patch files (`*.9.png`) are auto-detected: the 1px guide border is stripped during load, top/left guides drive stretch regions, and bottom/right guides become content padding applied to children. See `themes/metal.lua` and `themes/space.lua` for full theme definitions.

### Calc, Color, Animation, Theme - exposed off `FlexLove`

```lua
FlexLove.calc("50% - 10vw")          -- responsive math
FlexLove.Color.new(1, 0, 0, 1)        -- 0..1 RGBA
FlexLove.Color.fromHex("#FF8800")
FlexLove.Animation.fade(0.5, 0, 1):apply(el)
FlexLove.Animation.scale(0.3, { width = 50 }, { width = 100 }):apply(el)
FlexLove.Theme.load("space")
FlexLove.Theme.setActive("space")
```

### Hit-testing, focus, debug

```lua
local el = FlexLove.getElementAtPosition(mouseX, mouseY)
local byId = FlexLove.getById("save-button")

FlexLove.setFocusedElement(byId)
FlexLove.clearFocus()
local focused = FlexLove.getFocusedElement()

FlexLove.setDebugDraw(true)           -- overlay element bounds in colour
```

### Deferred callbacks

LÖVE crashes if you call `love.window.setMode` while a `Canvas` is active. For any callback that needs to do that, set the matching `*Deferred` flag and call `FlexLove.executeDeferredCallbacks()` at the very end of `love.draw()` once all canvases are released:

```lua
FlexLove.new({
  text = "Fullscreen",
  onEvent = function() love.window.setMode(1920, 1080, { fullscreen = true }) end,
  onEventDeferred = true,
})

function love.draw()
  FlexLove.draw()
  FlexLove.executeDeferredCallbacks()
end
```

Same pattern with `onCreateDeferred`, `onFocusDeferred`, `onBlurDeferred`, `onTextInputDeferred`, `onTextChangeDeferred`, `onEnterDeferred`.

## Migrating from v0.14 or earlier

| Old | New |
| --- | --- |
| `positioning = "flex"` | `display = "flex"` |
| `positioning = "grid"` | `display = "grid"` |
| `positioning = "absolute"` | `position = "absolute"` |
| `positioning = "relative"` | `position = "relative"` |
| `display = true / false` | `display = "block"` / `display = "none"` |
| `FlexLove.setMode("immediate")` and `beginFrame`/`endFrame` | Removed - retained mode only |
| `parent = somePanel` | Use `children = { ... }` on the parent, or `panel:addChild(child)` |
| `el:setProperty("backgroundColor", c)` | `el.backgroundColor = c` |

## Repo layout

```
FlexLove.lua          - main module (the only `require()` entry point)
modules/              - everything FlexLove.lua wires together
examples/             - runnable LÖVE examples
themes/               - sample theme definitions
testing/              - luaunit-based test suite, run with: lua testing/runAll.lua --no-coverage
resources/            - sample images used by the README's demos
```

## Compatibility

- **Lua**: 5.1+ / LuaJIT
- **LÖVE**: 11.x

## License

MIT. See `LICENSE`.
