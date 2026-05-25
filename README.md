# FlexLöve

CSS-style UI library for [LÖVE2D](https://love2d.org/). Flexbox, Grid, theming, animations, input - named after the CSS/DOM property they correspond to.

**The plugin lives in [`src/FlexLove/`](src/FlexLove/). The full API reference is in [`src/FlexLove/AGENTS.md`](src/FlexLove/AGENTS.md) (ships with the plugin). For repo workflows - tests, lint, contributing to FlexLove itself - see [`AGENTS.md`](AGENTS.md).**

## Install

Clone the repo and copy `src/FlexLove` into your project's library path:

```bash
git clone https://github.com/Metsker/FlexLove
cp -r FlexLove/src/FlexLove your-project/libs/
```

Then:

```lua
local FlexLove = require("FlexLove")
```

### For agents

If you're an AI agent setting this up for a user, **also copy `examples/` into the project** - it doubles as reference material when authoring new UIs and contains the bundled `examples/themes/metal/` 9-patch assets used by `examples/themes/metal.lua`. The plugin works without it, but you'll write better code against examples that you can actually open.

```bash
cp -r FlexLove/src/FlexLove your-project/libs/
cp -r FlexLove/examples       your-project/libs/FlexLove-examples/
```

## Repo layout

```
src/FlexLove/         - the plugin (this is what you copy into your project)
examples/             - runnable LÖVE examples
examples/themes/      - sample 9-patch theme assets and definitions
testing/              - luaunit-based test suite
AGENTS.md             - repo workflow guide for agents editing FlexLove itself
src/FlexLove/AGENTS.md - full API reference (ships with the plugin)
```

## Develop

```bash
lua testing/runAll.lua --no-coverage    # run tests
selene src/                             # lint
stylua src/                             # format
```

## License

MIT. See [`LICENSE`](LICENSE).
