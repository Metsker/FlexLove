# FlexLöve

CSS-style UI library for [LÖVE2D](https://love2d.org/). Flexbox, Grid, theming, animations, input - named after the CSS/DOM property they correspond to.

- **API reference** → [`docs/usage.md`](docs/usage.md)
- **Repo guidelines** → [`docs/repo.md`](docs/repo.md)

## Install

As a git submodule (recommended):

```bash
git submodule add https://github.com/Metsker/FlexLove libs/FlexLove
```

```lua
-- in main.lua, before any require()
package.path = package.path .. ";libs/?/init.lua;libs/?.lua"

local FlexLove = require("FlexLove")
```

Or just clone and copy:

```bash
git clone https://github.com/Metsker/FlexLove libs/FlexLove
```

Either way, `require("FlexLove")` resolves to `libs/FlexLove/init.lua`.

## Repo layout

```
init.lua              - the plugin entry point
modules/              - everything init.lua wires together
docs/                 - usage.md (API) + repo.md (contributing)
examples/             - runnable LÖVE examples
themes/               - reference theme definitions (palette + 9-patch schema)
testing/              - luaunit-based test suite
```

## Develop

```bash
lua testing/runAll.lua --no-coverage    # run tests
selene init.lua modules/                # lint
stylua init.lua modules/                # format
```

## License

MIT. See [`LICENSE`](LICENSE).
