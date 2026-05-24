# FlexLöve - Agent Guidelines

A focused brief for agents editing this codebase. Read `README.md` for the user-facing API.

## What this library is

CSS-style UI for LÖVE2D. **Retained mode only**. Public prop names, methods, and event types map to their CSS/DOM equivalents wherever practical, so an agent fluent in CSS can navigate without learning a parallel vocabulary.

## Running tests

- All tests: `lua testing/runAll.lua --no-coverage`
- Verbose: append `--verbose` to see per-file output
- Single file: `lua testing/__tests__/<name>_test.lua`
- New tests: extend `package.path`, install the `FlexLove.modules.*` custom searcher, `require("testing.loveStub")`, then `FlexLove.init()` in `setUp`. `testing/__tests__/flexlove_test.lua` is the template. Guard the bottom-of-file runner with `if not _G.RUNNING_ALL_TESTS then os.exit(luaunit.LuaUnit.run()) end`.
- Assertions use `luaunit` (bundled at `testing/luaunit.lua`).

## Lint and format

- Lint: `selene modules/ FlexLove.lua` (config: any `selene.toml` / `selene.yml` at the repo root)
- Format: `stylua modules/ FlexLove.lua` (config: `stylua.toml` - 120 cols, 2-space indent, double quotes)
- LSP: `.luarc.json` (LuaJIT runtime, love2d library)

## Public API contract

- **CSS naming wherever it transfers cleanly.** Visual props use `color`, `fontSize`, `borderRadius`, `border`, `borderColor`, `borderStyle`, `borderTop`/etc., `backgroundColor`, `backgroundImage`, `backgroundSize`, `backgroundPosition`, `backgroundRepeat`, `backgroundOpacity`. Layout uses `display`, `position`, `flexDirection = "row"|"column"`, etc.
- **DOM-style tree mutation:** `appendChild`, `removeChild`, `replaceChildren`, `setParent`. Find elements via `FlexLove.getElementById` and `FlexLove.elementFromPoint`.
- **DOM-style typed event handlers:** `onClick`, `onMouseDown`, `onMouseUp`, `onMouseEnter`, `onMouseLeave`, `onMouseMove`, `onDrag`, `onContextMenu`, `onAuxClick`. The catch-all `onEvent(self, event)` still exists for power users; both fire if both are set.
- **CSS shorthand strings:** `border = "2px solid #fff"` and `transition = "opacity 300ms ease-in-out"` are parsed at construction. Multi-property `transition = "opacity 0.3s, transform 0.5s ease-out 0.1s"` works.
- **`children` prop is construction-time only.** Read exactly once inside `Element.new()`, then discarded. Each entry is constructed (table) or reparented (Element instance) at that moment. After construction, `el.children` is the live array of attached child Element instances; **reassigning `el.children = {...}` does nothing** - the framework won't re-interpret a fresh prop table. Use `appendChild`/`removeChild`/`replaceChildren`/`setParent` for runtime mutation. There is no reconciliation - the tree is retained, not virtual.
- **No public `parent` prop.** Internal `self.parent` field remains for traversal; user code should not read it.
- **Direct field mutation** must work for: `backgroundColor`, `borderColor`, `borderRadius`, `opacity`, `themeComponent`, `onEvent`, every typed event handler, `onTouchEvent`, `onGesture`, `disabled`, `active`. These are picked up at draw time (`Renderer:draw` syncs from element) or at event time (`EventHandler:processMouseEvents` syncs). If you add a new "side-effect-on-write" field, wire it through one of those sync points - **don't** require users to call `setProperty`.

## Code conventions

- **Modules**: `local M = {}`, return table at bottom; constructors `M.new(props[, deps])` -> instance (never nil).
- **Methods**: instance methods with colon (`M:foo()`); module/static with dot (`M.foo()`).
- **Private fields**: prefix `_`.
- **Dependencies**: passed via a `deps` table (`{ utils, ErrorHandler, Units, ... }`). Only `FlexLove.lua` calls `require()` for siblings; modules receive their dependencies through `init(deps)`.
- **LuaDoc**: `---@param`, `---@return`, `---@class`, `---@field` on public APIs.
- **Errors**: `ErrorHandler.error(module, code)` for unrecoverable; `ErrorHandler.warn(module, code, details)` otherwise. Codes live in `modules/ErrorHandler.lua`.
- **Strings**: `string.format()` over concatenation in hot paths.
- **Auto-sizing**: omit `width` / `height`; don't pass `"auto"`.

## Layout flow

1. `Element.new(props)` resolves units, builds sub-modules (`_renderer`, `_eventHandler`, `_themeManager`, `_layoutEngine`, optional `_textEditor`, `_scrollManager`), attaches to parent (or `topElements`).
2. `appendChild` and `setParent` re-run `layoutChildren()` on the parent.
3. `resize()` re-resolves viewport-relative units, then re-lays out top-level elements.
4. `FlexLove.update(dt)` drives `Element:update(dt)` on each top-level tree - hover/press, animations, scroll momentum, text-editor blink, theme state.
5. `FlexLove.draw()` z-sorts top-level elements and renders.

## Event dispatch internals

`EventHandler:_invokeCallback(element, event)` is the single dispatch site. It always fires `self.onEvent`, then looks up `event.type` in the `TYPED_PROPS` table at the top of `modules/EventHandler.lua` and fires every matching `element[propName]`. To add a new event type or typed prop:

1. Add an entry to `TYPED_PROPS`.
2. Store the prop on the element in `Element.new()` and its `*Deferred` flag.
3. Add the prop name to the `hasAnyHandler` check in `EventHandler:processMouseEvents` so a user setting only the typed prop still gets dispatch.
4. Add the prop name to the `isInteractive` check in `FlexLove.elementFromPoint` so it counts for hit-testing.

## Common pitfalls

- Anything passed via `parent =` in props is still honoured internally (`appendChild` requires a parent reference during construction). When refactoring children handling, keep that path working for the existing tests.
- `display` is a **string** (`"block"`/`"flex"`/`"grid"`/`"none"`), not a boolean. Comparisons in `LayoutEngine.lua`, `Grid.lua`, `Element.lua`, and `FlexLove.lua` use the string.
- `flexDirection` is `"row"` or `"column"` only; the old `"horizontal"`/`"vertical"` aliases are gone.
- The `Renderer` caches visual props but `Renderer:draw` resyncs from the element each call. Don't reintroduce a "set once" cache - it breaks direct mutation.
- `EventHandler:processMouseEvents` syncs `onEvent`/`onTouchEvent`/`onGesture` from the element only when those fields are non-nil. Tests assign directly to the handler; keep that path working.
- `TextEditor:_saveState` is a no-op stub kept only so existing internal call sites compile. Don't add new callers.
- Lua 5.4: `for` loop variables are `const`. Don't reassign `for x in ... do x = ... end`; use `for raw in ... do local x = raw end` instead.

## Adding a new prop

1. Type it in `modules/types.lua` (`ElementProps`).
2. Read it in `Element.new()` and store on `self`.
3. If it affects layout, add the field to `_layoutEngine` setup and to `setProperty`'s `layoutProperties` table.
4. If it affects rendering, sync it into the Renderer at the top of `Renderer:draw`.
5. Add a test in the appropriate `*_test.lua`.

## Intentionally out of scope right now

- Sticky / `position: fixed` is recognised as a synonym for `"absolute"`; full sticky behaviour isn't implemented.
- Reverse flex directions (`row-reverse`, `column-reverse`) are implemented via a final mirror pass at the end of `LayoutEngine:layoutChildren()` that walks each flex child's subtree by a single delta.
- `borderStyle` values other than `"solid"` (passed through but not rendered).
- Inline display, baseline alignment beyond stretch/flex-start/center/end, and CSS `box-sizing: content-box`. Border-box is the only model.
- Per-element render caching: don't introduce caches that break the "edit a field, see it next frame" contract.
