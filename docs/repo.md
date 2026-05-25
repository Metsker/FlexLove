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
4. `FlexLove.update(dt)` drives `Element:update(dt)` on each top-level tree - hover/press, animations, scroll momentum, text-editor blink, theme state.
5. `FlexLove.draw()` z-sorts top-level elements and renders.

## Event dispatch internals

`EventHandler:_invokeCallback(element, event)` is the single dispatch site. It always fires `self.onEvent`, then looks up `event.type` in the `TYPED_PROPS` table at the top of `modules/EventHandler.lua` and fires every matching `element[propName]`. To add a new event type or typed prop:

1. Add an entry to `TYPED_PROPS`.
2. Store the prop on the element in `Element.new()` and its `*Deferred` flag.
3. Add the prop name to the `hasAnyHandler` check in `EventHandler:processMouseEvents` so a user setting only the typed prop still gets dispatch.
4. Add the prop name to the `isInteractive` check in `FlexLove.elementFromPoint` so it counts for hit-testing.

## Editor-side pitfalls

- The `Renderer` caches visual props but `Renderer:draw` resyncs from the element each call. Don't reintroduce a "set once" cache - it breaks direct mutation.
- `EventHandler:processMouseEvents` syncs `onEvent`/`onTouchEvent`/`onGesture` from the element only when those fields are non-nil. Tests assign directly to the handler; keep that path working.
- `TextEditor:_saveState` is a no-op stub kept only so existing internal call sites compile. Don't add new callers.
- Lua 5.4: `for` loop variables are `const`. Don't reassign `for x in ... do x = ... end`; use `for raw in ... do local x = raw end` instead.
- Reverse flex directions (`row-reverse`, `column-reverse`) are implemented via a final mirror pass at the end of `LayoutEngine:layoutChildren()` that walks each flex child's subtree by a single delta - don't fold this into the main layout walk without rethinking how `justifyContent` interacts with reversal.
- Per-element render caching is intentionally absent: don't introduce caches that break the "edit a field, see it next frame" contract.

## Adding a new prop

1. Type it in `modules/types.lua` (`ElementProps`).
2. Read it in `Element.new()` and store on `self`.
3. If it affects layout, add the field to `_layoutEngine` setup and to `setProperty`'s `layoutProperties` table.
4. If it affects rendering, sync it into the Renderer at the top of `Renderer:draw`.
5. Add a test in the appropriate `*_test.lua`.
6. Document it in `docs/usage.md` under the relevant API section.
