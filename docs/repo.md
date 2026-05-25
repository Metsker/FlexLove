# FlexLöve - Repo Guidelines

A brief for agents editing FlexLove itself. For the public API and authoring guidance, see [`usage.md`](usage.md).

## Repo layout

```
init.lua              - the plugin entry point
modules/              - everything init.lua wires together
docs/                 - usage.md (API) + repo.md (this file)
examples/             - runnable LÖVE examples
themes/               - reference theme definitions (palette-only + 9-patch schema)
testing/              - luaunit-based test suite
```

`init.lua` is the only file that calls `require()` for siblings; modules receive their dependencies through `init(deps)`.

## Running tests

- All tests: `lua testing/runAll.lua --no-coverage`
- Verbose: append `--verbose` to see per-file output
- Single file: `lua testing/__tests__/<name>_test.lua`
- New tests: extend `package.path` with `";./?.lua"`, install the test bootstrap (a custom searcher that resolves `require("FlexLove")` to `./init.lua` and aliases `FlexLove.modules.*` to `modules.*` for cache sharing), `require("testing.loveStub")`, then `FlexLove.init()` in `setUp`. `testing/__tests__/flexlove_test.lua` is the template. Guard the bottom-of-file runner with `if not _G.RUNNING_ALL_TESTS then os.exit(luaunit.LuaUnit.run()) end`.
- Assertions use `luaunit` (bundled at `testing/luaunit.lua`).

## Lint and format

- Lint: `selene init.lua modules/` (config: any `selene.toml` / `selene.yml` at the repo root)
- Format: `stylua init.lua modules/` (config: `stylua.toml` - 120 cols, 2-space indent, double quotes)
- LSP: `.luarc.json` (LuaJIT runtime, love2d library)

## Code conventions

- **Modules**: `local M = {}`, return table at bottom; constructors `M.new(props[, deps])` -> instance (never nil).
- **Methods**: instance methods with colon (`M:foo()`); module/static with dot (`M.foo()`).
- **Private fields**: prefix `_`.
- **Dependencies**: passed via a `deps` table (`{ utils, ErrorHandler, Units, ... }`). Only `init.lua` calls `require()` for siblings; modules receive their dependencies through `init(deps)`.
- **LuaDoc**: `---@param`, `---@return`, `---@class`, `---@field` on public APIs.
- **Errors**: `ErrorHandler.error(module, code)` for unrecoverable; `ErrorHandler.warn(module, code, details)` otherwise. Codes live in `modules/ErrorHandler.lua`.
- **Strings**: `string.format()` over concatenation in hot paths.
- **Auto-sizing**: omit `width` / `height`; don't pass `"auto"`.

## Layout flow

1. `Element.new(props)` resolves units, builds sub-modules (`_renderer`, `_eventHandler`, `_themeManager`, `_layoutEngine`, optional `_textEditor`, `_scrollManager`), attaches to parent (or `topElements`).
2. `appendChild` and `setParent` re-run `layoutChildren()` on the parent.
3. `resize()` re-resolves viewport-relative units, then re-lays out top-level elements.
4. `FlexLove.update(dt)` drives `Element:update(dt)` on each top-level tree (hover/press, animations, scroll momentum, text-editor blink, theme state), then walks `topElements` again and calls `:layoutChildren()` on each so direct layout-prop mutations and animated layout-affecting props land that frame. `_canSkipLayout` short-circuits on unchanged trees so the per-frame cost is roughly one hash compute per element.
5. `FlexLove.draw()` z-sorts top-level elements and renders.

## Event dispatch internals

`EventHandler:_invokeCallback(element, event)` is the single dispatch site. It always fires `self.onEvent`, then looks up `event.type` in the `TYPED_PROPS` table at the top of `modules/EventHandler.lua` and fires every matching `element[propName]`. To add a new event type or typed prop:

1. Add an entry to `TYPED_PROPS`.
2. Store the prop on the element in `Element.new()` and its `*Deferred` flag.
3. Add the prop name to the `hasAnyHandler` check in `EventHandler:processMouseEvents` so a user setting only the typed prop still gets dispatch.
4. Add the prop name to the `isInteractive` check in `FlexLove.elementFromPoint` so it counts for hit-testing.

## Editor-side pitfalls

- The `Renderer` caches visual props but `Renderer:draw` resyncs from the element each call. Don't reintroduce a "set once" cache - it breaks direct mutation.
- The `LayoutEngine` does the same for layout props: at the top of `LayoutEngine:layoutChildren()` it pulls `display`, `flexDirection`, `flexWrap`, `justifyContent`, `alignItems`, `alignContent`, `gap`, `gridRows`, `gridColumns`, `columnGap`, `rowGap` from the element. `_canSkipLayout`'s `layoutInputsHash` includes the same fields so direct mutation also invalidates the memoization cache. Don't snapshot these at construction and skip the resync - direct assignment is the documented contract (see `docs/usage.md` "Runtime mutation").
- When `_canSkipLayout` returns true, `layoutChildren` still descends into children before returning. Without that descent, a parent's "nothing changed at my level" cache hit would prevent a deep grandchild's own cache from ever being consulted, and a directly-mutated grandchild would silently fail to re-layout. Skip means "skip self-work," not "skip everything." If you optimize this path, keep the descent.
- Flex/grid props are stored on the element regardless of its current `display` so `display` flips at runtime pick them up. The `display == "flex"` / `display == "grid"` gating happens at *use* time inside the engine, not at *storage* time in the constructor.
- `setProperty` is **not** redundant with the pull-at-use-time reactivity. It exists for two cases that direct assignment cannot express, and folding either into a reactive `__newindex`-style hook will break invariants the rest of the codebase relies on:
  - **Animation triggers.** A raw `el.opacity = 0` snaps the value. To animate via a configured `transition`, `setProperty` captures the current value, creates an interpolation animation, and the Animation module then writes the interpolated value to `el.opacity` every frame *via raw assignment*. That last detail is load-bearing: if you ever wire assignment to "start a new animation toward this value if a transition is configured," the animation engine's own per-frame writes will spawn nested animations on top of each other and the system implodes. Keep raw assignment as "snap" and `setProperty` as "animate" - they have to remain distinct operations.
  - **Unit string resolution.** A raw `el.width = "50%"` would leave a string in `el.width` that downstream numeric code chokes on (NaN math, comparison errors). `setProperty("width", "50%")` parses the string, resolves it against the parent's content box, and stores two pieces of state: the resolved pixel number on `el.width` (what layout reads) and the unit spec on `el.units.width` (what `FlexLove.resize()` uses to re-resolve on viewport changes). A single field write can only carry one of those, hence the helper. If you want a more specific entry point than `setProperty`, add `Element:setWidth("50%")` / `Element:setUnit(prop, value)` rather than trying to teach `=` to do dual storage.
- `EventHandler:processMouseEvents` syncs `onEvent`/`onTouchEvent`/`onGesture` from the element only when those fields are non-nil. Tests assign directly to the handler; keep that path working.
- `TextEditor:_saveState` is a no-op stub kept only so existing internal call sites compile. Don't add new callers.
- Lua 5.4: `for` loop variables are `const`. Don't reassign `for x in ... do x = ... end`; use `for raw in ... do local x = raw end` instead.
- Reverse flex directions (`row-reverse`, `column-reverse`) are implemented via a final mirror pass at the end of `LayoutEngine:layoutChildren()` that walks each flex child's subtree by a single delta - don't fold this into the main layout walk without rethinking how `justifyContent` interacts with reversal.
- Per-element render caching is intentionally absent: don't introduce caches that break the "edit a field, see it next frame" contract.

## Adding a new prop

1. Type it in `modules/types.lua` (`ElementProps`).
2. Read it in `Element.new()` and store on `self`. For layout-related props, store the value regardless of current `display` so `display` flips pick it up.
3. If it affects layout: (a) initialize the field in `LayoutEngine.new` defaults, (b) sync it from the element at the top of `LayoutEngine:layoutChildren()` (the "pull at use time" block), (c) include it in `_canSkipLayout`'s `layoutInputsHash`, and (d) add it to `setProperty`'s `layoutProperties` table so animated changes via `transition` still invalidate.
4. If it affects rendering, sync it into the Renderer at the top of `Renderer:draw`.
5. Add a test in the appropriate `*_test.lua`.
6. Document it in `docs/usage.md` under the relevant API section.
