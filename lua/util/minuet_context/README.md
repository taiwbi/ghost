# Minuet completion contexts

`init.lua` captures syntax before a completion request and selects the first
matching rule. Each response is filtered using that request's copied state and
filter function, without reading the current buffer again. Missing parsers,
queries, unsupported forms, and rule errors leave suggestions unrestricted.

The built-in `strings.lua` rule uses `@string` / `@string.*` highlight captures
and small delimiter adapters. Its table includes Python, JavaScript,
TypeScript/TSX, Lua, Rust, C/C++, Go, JSON/JSONC, CSS/SCSS, PHP, Bash, SQL, and
HTML/XML attributes. A matching parser and highlight query must be installed.
Multiline literals retain multiline completions, stopping at their delimiter;
interpolated expressions retain code completions. Unclosed literals are skipped.

## Add another context

Create a module with `name`, `detect(info)`, and `filter(text, state)`, then call
`require("util.minuet_context").register(require("your.module"))` during setup.
Reusing a name replaces its rule in place; `unregister(name)` removes it.

`info` supplies `bufnr`, zero-based `row`/byte `col`, byte `offset`, the active
parser `language` (including injections), innermost named `node`, and `request`.
Helpers `info.text(node)`, `info.contains(node)`, and `info.captures()` read syntax.
Captures contain `{ name, node }` and do not require highlighting to be active.

`detect` returns nil when inapplicable or a **plain table** of immutable filter
settings. Do not store Tree-sitter nodes, buffers, or live parser objects in it.
`filter` receives only suggestion text and that captured state; return text or
nil to discard the suggestion. It must not read editor state.

For example, a future HTML-text module could use the shared boundary filter:

```lua
return {
  name = "html_text",
  detect = function(info)
    if info.language == "html" and info.node:type() == "text" then
      return { closing = "<", multiline = true }
    end
  end,
  filter = require("util.minuet_context.boundary").filter,
}
```

This example is not registered by default. A complete HTML-text rule should
also define behavior at empty text nodes, tag edges, and embedded languages.

`boundary.lua` supports a closing delimiter, optional `escape` character,
`doubled` delimiters (SQL), and a `multiline` flag. Contexts with different
requirements can provide their own pure filter instead.

Run checks from the config root:

```sh
nvim --headless -n -u NONE -i NONE -l tests/minuet_context.lua
nvim --headless -n -u NONE -i NONE -l tests/minuet_completion.lua
```
