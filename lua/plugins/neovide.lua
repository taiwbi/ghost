if not vim.g.neovide then return {} end

vim.opt.linespace = 8
vim.opt.guicursor =
  "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"
vim.opt.winblend = 0
vim.opt.pumblend = 0

vim.g.neovide_padding_top = 0
vim.g.neovide_padding_bottom = 0
vim.g.neovide_padding_right = 0
vim.g.neovide_padding_left = 0
vim.g.neovide_opacity = 1
vim.g.neovide_floating_blur_amount_x = 8
vim.g.neovide_floating_blur_amount_y = 8
vim.g.neovide_floating_shadow = false
vim.g.neovide_floating_z_height = 0
vim.g.neovide_light_angle_degrees = 45
vim.g.neovide_light_radius = 0
vim.g.neovide_floating_corner_radius = 0
vim.g.neovide_scroll_animation_length = 0.15
vim.g.neovide_cursor_animation_length = 0.15
vim.g.neovide_cursor_trail_size = 0.02
vim.g.neovide_hide_mouse_when_typing = true
vim.g.neovide_cursor_smooth_blink = true
vim.g.neovide_cursor_vfx_mode = "pixiedust"
vim.g.neovide_cursor_vfx_particle_lifetime = 2
vim.g.neovide_cursor_vfx_particle_density = 3

return {}
