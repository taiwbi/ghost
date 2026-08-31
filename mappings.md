# ⌨️ Mappings

Leader key is `<Space>`, local leader is `,`. [`which-key.nvim`](https://github.com/folke/which-key.nvim) shows the menu when you start a chord.

## General

| Action               | Mapping              |
| -------------------- | -------------------- |
| Leader               | `Space`              |
| Local leader         | `,`                  |
| Start / end of line  | `H` / `L`            |
| Window left/down/up/right | `Ctrl + h/j/k/l` |
| Resize up/down/left/right | `Ctrl + ↑/↓/←/→` |
| Force write          | `Ctrl + s`           |
| Force quit           | `Ctrl + q`           |
| New file             | `Leader + n`         |
| Save without formatting | `Leader + W`      |
| Close buffer         | `Leader + c`         |
| Force close buffer   | `Leader + C`         |
| Rename current file  | `Leader + R`         |
| Next / previous tab  | `]t` / `[t`          |
| Horizontal split     | `\`                  |
| Vertical split       | `\|`                 |

## Buffers

| Action                                  | Mapping       |
| --------------------------------------- | ------------- |
| Next / previous buffer                  | `Tab` / `Shift+Tab`, `]b` / `[b` |
| Move buffer right / left                | `>b` / `<b`   |
| Navigate via picker                     | `Leader + bb` |
| Close all except current                | `Leader + bc` |
| Close all                               | `Leader + bC` |
| Delete via picker                       | `Leader + bd` |
| Close buffers to the left               | `Leader + bl` |
| Go to last-used buffer                  | `Leader + bp` |
| Close buffers to the right              | `Leader + br` |
| Sort by extension / id / modified / full path / relative path | `Leader + bse` / `bsi` / `bsm` / `bsp` / `bsr` |
| Open buffer in horizontal split (picker)  | `Leader + b\` |
| Open buffer in vertical split (picker)    | `Leader + b\|` |

## Commenting

| Action                            | Mapping       |
| --------------------------------- | ------------- |
| Toggle comment of current line    | `Leader + /`  |
| Insert comment below              | `gco`         |
| Insert comment above              | `gcO`         |

## Lists (quickfix / location)

| Action                  | Mapping       |
| ----------------------- | ------------- |
| Open quickfix list      | `Leader + xq` |
| Next / previous / last / first quickfix entry | `]q` / `[q` / `]Q` / `[Q` |
| Open location list      | `Leader + xl` |
| Next / previous / last / first location entry | `]l` / `[l` / `]L` / `[L` |

## Completion (blink.cmp)

| Action                       | Mapping                              |
| ---------------------------- | ------------------------------------ |
| Open completion menu         | `Ctrl + Space`                       |
| Select completion            | `Enter`                              |
| Next / previous snippet stop | `Tab` / `Shift + Tab`                |
| Next completion              | `↓`, `Ctrl + n`, `Ctrl + j`, `Tab`   |
| Previous completion          | `↑`, `Ctrl + p`, `Ctrl + k`, `Shift + Tab` |
| Cancel completion            | `Ctrl + e`                           |
| Scroll docs up / down        | `Ctrl + u` / `Ctrl + d`              |

## File Explorer (oil.nvim)

| Action                            | Mapping      |
| --------------------------------- | ------------ |
| Open Oil in the current directory | `Leader + e` |

## Dashboard

| Action          | Mapping       |
| --------------- | ------------- |
| Home screen     | `Leader + h`  |

## Session (resession.nvim)

| Action                          | Mapping        |
| ------------------------------- | -------------- |
| Save session                    | `Leader + Ss`  |
| Load last session               | `Leader + Sl`  |
| Delete session                  | `Leader + Sd`  |
| Delete directory session        | `Leader + SD`  |
| Find session                    | `Leader + Sf`  |
| Find directory session          | `Leader + SF`  |
| Load current directory session  | `Leader + S.`  |

## Packages

| Action                    | Mapping       |
| ------------------------- | ------------- |
| Update Lazy and Mason     | `Leader + pa` |
| Plugins install           | `Leader + pi` |
| Mason installer           | `Leader + pm` |
| Mason updater             | `Leader + pM` |
| Plugins status            | `Leader + ps` |
| Plugins sync              | `Leader + pS` |
| Plugins check for updates | `Leader + pu` |
| Plugins update            | `Leader + pU` |

## LSP

| Action                      | Mapping                            |
| --------------------------- | ---------------------------------- |
| LSP info                    | `Leader + li`                      |
| None-ls info                | `Leader + lI`                      |
| Hover                       | `K` (built-in)                     |
| Format document             | `Leader + lf`                      |
| Symbols outline (Aerial)    | `Leader + lS`                      |
| Line diagnostics            | `gl`, `Leader + ld`                |
| Buffer diagnostics (picker) | `Leader + lb`                      |
| All diagnostics (picker)    | `Leader + lD`                      |
| Workspace diagnostics       | `Leader + lw` (Neovim 0.12+)       |
| Code actions                | `gra`, `Leader + la`               |
| Source code actions         | `Leader + lA`                      |
| Signature help              | `Leader + lh`                      |
| Rename                      | `grn`, `Leader + lr`               |
| Document symbols (picker)   | `Leader + ls`                      |
| Workspace symbols (picker)  | `Leader + lG`                      |
| References (picker)         | `grr`, `Leader + lR`               |
| Diagnostic next / previous  | `]d` / `[d`                        |
| Error next / previous       | `]e` / `[e`                        |
| Warning next / previous     | `]w` / `[w`                        |
| Document symbol next / previous (Aerial) | `]y` / `[y`           |
| Document symbol             | `gO` (built-in)                    |
| Declaration                 | `gD` (built-in)                    |
| Type definition             | `gy`                               |
| Definition                  | `gd`                               |
| Implementation              | `gri` (built-in)                   |

## Debugger (nvim-dap)

| Action                  | Mapping                    |
| ----------------------- | -------------------------- |
| Start / continue        | `Leader + dc` or `<F5>`    |
| Pause                   | `Leader + dp` or `<F6>`    |
| Restart                 | `Leader + dr` or `<C-F5>`  |
| Run to cursor           | `Leader + ds`              |
| Close session           | `Leader + dq`              |
| Terminate               | `Leader + dQ` or `<S-F5>`  |
| Toggle breakpoint       | `Leader + db` or `<F9>`    |
| Conditional breakpoint  | `Leader + dC`              |
| Clear breakpoints       | `Leader + dB`              |
| Step over               | `Leader + do` or `<F10>`   |
| Step into               | `Leader + di` or `<F11>`   |
| Step out                | `Leader + dO` or `<S-F11>` |
| Evaluate expression     | `Leader + dE`              |
| Toggle REPL             | `Leader + dR`              |
| Toggle UI               | `Leader + du`              |
| Debugger hover          | `Leader + dh`              |

## Pickers (snacks.picker)

| Action                            | Mapping              |
| --------------------------------- | -------------------- |
| Resume previous search            | `Leader + f + Enter` |
| Find marks                        | `Leader + f'`        |
| Find config files                 | `Leader + fa`        |
| Find buffers                      | `Leader + fb`        |
| Find word under cursor            | `Leader + fc`        |
| Find commands                     | `Leader + fC`        |
| Find files                        | `Leader + ff`        |
| Find files (include hidden)       | `Leader + fF`        |
| Find git-tracked files            | `Leader + fg`        |
| Find help tags                    | `Leader + fh`        |
| Find keymaps                      | `Leader + fk`        |
| Find lines                        | `Leader + fl`        |
| Find man pages                    | `Leader + fm`        |
| Find notifications                | `Leader + fn`        |
| Find old files                    | `Leader + fo`        |
| Find old files (cwd)              | `Leader + fO`        |
| Find projects                     | `Leader + fp`        |
| Find registers                    | `Leader + fr`        |
| Smart picker (buffers/recent/files)| `Leader + fs`       |
| Find colorschemes                 | `Leader + ft`        |
| Find undo history                 | `Leader + fu`        |
| Live grep                         | `Leader + fw`        |
| Live grep (include hidden)        | `Leader + fW`        |
| Git branches                      | `Leader + gb`        |
| Git commits (repo)                | `Leader + gc`        |
| Git commits (current file)        | `Leader + gC`        |
| Git browse                        | `Leader + go`        |
| Git status                        | `Leader + gt`        |
| Git stash                         | `Leader + gT`        |

## Git

| Action                    | Mapping                |
| ------------------------- | ---------------------- |
| Blame line                | `Leader + gl`          |
| Blame line (full)         | `Leader + gL`          |
| Preview hunk              | `Leader + gp`          |
| Reset hunk                | `Leader + gr` (n / v)  |
| Reset buffer              | `Leader + gR`          |
| Stage hunk                | `Leader + gs` (n / v)  |
| Stage buffer (including untracked files) | `Leader + gS`          |
| Unstage buffer             | `Leader + gU`          |
| Toggle inline diff (unstaged) | `Leader + gd`     |
| View diff side by side    | `Leader + gD`          |
| Next / previous Git hunk  | `]g` / `[g`            |
| First / last Git hunk     | `[G` / `]G`            |
| Hunk text object          | `ig` (in `o`, `x`)     |

## Terminal

| Action                     | Mapping        |
| -------------------------- | -------------- |
| Open ptyxis in current dir | `Leader + tg`  |

## UI / UX toggles

| Action                              | Mapping        |
| ----------------------------------- | -------------- |
| Toggle autopairs                    | `Leader + ua`  |
| Toggle background                   | `Leader + ub`  |
| Toggle autocompletion (buffer)      | `Leader + uc`  |
| Toggle autocompletion (global)      | `Leader + uC`  |
| Toggle diagnostics                  | `Leader + ud`  |
| Dismiss notifications               | `Leader + uD`  |
| Toggle autoformat (buffer)          | `Leader + uf`  |
| Toggle autoformat (global)          | `Leader + uF`  |
| Toggle signcolumn                   | `Leader + ug`  |
| Toggle foldcolumn                   | `Leader + u>`  |
| Toggle inlay hints (buffer)         | `Leader + uh`  |
| Toggle inlay hints (global)         | `Leader + uH`  |
| Toggle indent setting               | `Leader + ui`  |
| Toggle indent guides                | `Leader + u\|` |
| Toggle statusline                   | `Leader + ul`  |
| Toggle codelens                     | `Leader + uL`  |
| Change line numbering               | `Leader + un`  |
| Toggle notifications                | `Leader + uN`  |
| Toggle paste mode                   | `Leader + up`  |
| Toggle reference highlighting       | `Leader + ur`  |
| Toggle spellcheck                   | `Leader + us`  |
| Toggle conceal                      | `Leader + uS`  |
| Toggle tabline                      | `Leader + ut`  |
| Toggle URL highlighting             | `Leader + uu`  |
| Toggle diagnostics virtual text     | `Leader + uv`  |
| Toggle diagnostics virtual lines    | `Leader + uV`  |
| Toggle wrap                         | `Leader + uw`  |
| Toggle syntax highlighting (buffer) | `Leader + uy`  |
| Toggle LSP semantic tokens (buffer) | `Leader + uY`  |
| Toggle color highlighting           | `Leader + uz`  |
| Toggle zen mode                     | `Leader + uZ`  |

## Helpers

| Action                          | Mapping        |
| ------------------------------- | -------------- |
| Copy file's absolute path       | `Leader + ra`  |
| Copy file's relative path       | `Leader + rr`  |

## Database

| Action      | Mapping       |
| ----------- | ------------- |
| Toggle DBee | `Leader + Db` |

## Clipboard

| Action                                       | Mapping       |
| -------------------------------------------- | ------------- |
| Paste from clipboard (n / v / i / c / t)     | `Ctrl + Shift + v` |
| Paste without overwriting clipboard (v)      | `Leader + p`  |
| Delete without overwriting clipboard (v)     | `Leader + x`  |
| Yank entire file (preserve position)         | `yag`         |

## Visual mode

| Action          | Mapping  |
| --------------- | -------- |
| Stay-indent     | `<` / `>`|

## Neovide

| Action                       | Mapping     |
| ---------------------------- | ----------- |
| Reset scale factor           | `Ctrl + 0`  |
| Increase scale factor        | `Ctrl + +`  |
| Decrease scale factor        | `Ctrl + _`  |
