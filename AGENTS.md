# FlexLöve - Agent Guidelines

A focused brief for agents editing this codebase. Read `README.md` for the user-facing API.

## What this library is

CSS-style UI for LÖVE2D. **Retained mode only**: elements live across frames, you mutate them. There is no immediate mode anymore, no `beginFrame`/`endFrame`, no `StateManager`, no `ModuleLoader` build profiles.

## Running tests

- All tests: `lua testing/runAll.lua --no-coverage`
- Verbose: append `--verbose` to see per-file output
- Single file: `lua testing/__tests__/<name>_test.lua` (entry point is the file itself)
- 4 tests fail by default - `TestEasing.*` use `math.pow` / `math.atan2`, both deprecated in Lua 5.4. Pre-existing, unrelated to UI changes.
- New tests require: `package.path` extension, custom searcher for `FlexLove.modules.*`, `require("testing.loveStub")`, and `FlexLove.init()` in `setUp`. Use `testing/__tests__/flexlove_test.lua` as a template.
- Assertions use `luaunit` (bundled at `testing/luaunit.lua`).

## Lint and format

- Lint: `luacheck modules/ FlexLove.lua` (config: `.luacheckrc`)
- Format: `stylua modules/ FlexLove.lua` (config: `stylua.toml` - 120 cols, 2-space indent, double quotes)
- LSP: `.luarc.json` (LuaJIT runtime, love2d library)

## Public API contract

These are the conventions FlexLove makes to its users. Don't break them silently.

- **CSS naming**: `display: "block"|"flex"|"grid"|"none"`, `position: "static"|"relative"|"absolute"|"fixed"`. Internal `positioning` field still exists - it's derived from `display`/`position` in `Element.new()`.
- **`children` prop** accepts either a prop table OR a pre-built `Element` instance. Pre-built elements are reparented (detached from `topElements` first).
- **No public `parent` prop**. Internal `self.parent` field remains for traversal; user code shouldn't read it.
- **Direct field mutation** must work for: `backgroundColor`, `borderColor`, `cornerRadius`, `opacity`, `themeComponent`, `onEvent`, `onTouchEvent`, `onGesture`, `disabled`, `active`. These are picked up at draw time (`Renderer:draw` syncs from element) or at event time (`EventHandler:processMouseEvents` syncs). If you add a new "side-effect-on-write" field, wire it through one of those sync points - **don't** require users to call `setProperty`.

## Code conventions

- **Modules**: `local M = {}`, return table at bottom; constructors `M.new(props[, deps])` -> instance (never nil)
- **Methods**: instance methods with colon (`M:foo()`); module/static with dot (`M.foo()`)
- **Private fields**: prefix `_`
- **Dependencies**: passed via a `deps` table (`{ utils, ErrorHandler, Units, ... }`). Only `FlexLove.lua` calls `require()` for siblings; modules receive their dependencies through `init(deps)`.
- **LuaDoc**: `---@param`, `---@return`, `---@class`, `---@field` on public APIs.
- **Errors**: `ErrorHandler.error(module, code)` for unrecoverable; `ErrorHandler.warn(module, code, details)` otherwise. Error codes live in `modules/ErrorHandler.lua`.
- **Strings**: `string.format()` over concatenation in hot paths.
- **Auto-sizing**: omit `width` / `height`; don't pass `"auto"`.

## Layout flow

1. `Element.new(props)` resolves units, builds sub-modules (`_renderer`, `_eventHandler`, `_themeManager`, `_layoutEngine`, optional `_textEditor`, `_scrollManager`), attaches to parent (or `topElements`).
2. `addChild` and `setParent` re-run `layoutChildren()` on the parent.
3. `resize()` re-resolves viewport-relative units, then re-lays out top-level elements.
4. `FlexLove.update(dt)` drives `Element:update(dt)` on each top-level tree - that handles hover/press, animations, scroll momentum, text-editor blink, theme state.
5. `FlexLove.draw()` z-sorts top-level elements and renders.

## Common pitfalls

- Anything passed via `parent =` in props is still honoured internally (`addChild` requires a parent reference at construction). When refactoring children handling, keep that path working for the existing tests.
- The `display` field is now a **string** (`"block"`/`"flex"`/`"grid"`/`"none"`), not a boolean. Old comparisons like `child.display ~= false` were updated to `child.display ~= "none"` in `LayoutEngine.lua`, `Grid.lua`, and `Element.lua`. If you add a new check, use the string.
- The `Renderer` caches its own copies of visual props but `Renderer:draw` resyncs from the element each call. Don't reintroduce a "set once" cache - it breaks the direct-mutation contract.
- `EventHandler:processMouseEvents` syncs `onEvent`/`onTouchEvent`/`onGesture` from the element only when those fields are non-nil. Tests assign directly to the handler; keep that path working too.
- `TextEditor:_saveState` is a no-op stub kept only so existing internal call sites compile. Don't add new callers.

## Building features

- Adding a new prop:
  1. Type it in `modules/types.lua` (`ElementProps`)
  2. Read it in `Element.new()` and store on `self`
  3. If it affects layout, add the field to `_layoutEngine` setup and to `setProperty`'s `layoutProperties` table
  4. If it affects rendering, sync it into the Renderer at the top of `Renderer:draw`
  5. Add a test in the appropriate `*_test.lua`
- Adding a new event type: register it through `EventHandler` (mouse) or `GestureRecognizer` (touch). Don't bolt new handlers onto `Element:update` directly.

## What's intentionally out of scope right now

- Sticky/`position: fixed` is recognised as a synonym for `"absolute"`; full sticky behaviour isn't implemented.
- Inline display, baseline alignment beyond stretch/flex-start/center/end, and CSS-style `box-sizing: content-box` are not supported. Border-box is the only model.
- Per-element render caching: the Renderer reads from the element every draw; do not introduce caches that break the "edit a field, see it next frame" contract.
