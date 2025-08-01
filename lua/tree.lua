function Setup()
  return {

    {
      -- Highlight, edit, and navigate code
      'nvim-treesitter/nvim-treesitter',
      dependencies = {
        'nvim-treesitter/nvim-treesitter-textobjects',
      },
      build = ':TSUpdate',
    },
    {
      'nvim-neo-tree/neo-tree.nvim',
      branch = 'main',
      dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
        'MunifTanjim/nui.nvim',
      },
      init = function()
        vim.g.neo_tree_remove_legacy_commands = true
      end,
      opts = function()
        return {
          auto_clean_after_session_restore = true,
          close_if_last_window = true,
          sources = { 'filesystem', 'buffers', 'git_status' },
          default_component_configs = {
            git_status = {
              symbols = {
                added = 'GitAdd',
                deleted = 'GitDelete',
                modified = 'GitChange',
                renamed = 'GitRenamed',
                untracked = 'GitUntracked',
                ignored = 'GitIgnored',
                unstaged = 'GitUnstaged',
                staged = 'GitStaged',
                conflict = 'GitConflict',
              },
            },
          },
          commands = {
            system_open = function(state)
              (vim.ui.open or vim.ui.open)(state.tree:get_node():get_id())
            end,
            child_or_open = function(state)
              local node = state.tree:get_node()
              if node.type == 'directory' or node:has_children() then
                if not node:is_expanded() then -- if unexpanded, expand
                  state.commands.toggle_node(state)
                else -- if expanded and has children, seleect the next child
                  require('neo-tree.ui.renderer').focus_node(state, node:get_child_ids()[1])
                end
              else -- if not a directory just open it
                state.commands.open(state)
              end
            end,
            close = function(state)
              local node = state.tree:get_node()
              if node.type == 'directory' or node:has_children() then
                if node:is_expanded() then -- if unexpanded, expand
                  state.commands.toggle_node(state)
                end
              end
            end,
          },
          window = {
            width = 30,
            mappings = {
              ['<space>'] = false,
              ['H'] = 'toggle_hidden',
              ['l'] = 'child_or_open',
              ['h'] = 'close',
              ['S'] = 'open_split',
            },
          },
          filesystem = {
            follow_current_file = { enabled = true },
            hijack_netrw_behavior = 'open_current',
            use_libuv_file_watcher = true,
          },
          event_handlers = {
            {
              event = 'neo_tree_buffer_enter',
              handler = function(_)
                vim.opt_local.signcolumn = 'auto'
              end,
            },
          },
        }
      end,
    },
  }
end

function Startup()
  require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript' },

    -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
    auto_install = true,

    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    },
  }
  local autocmd = vim.api.nvim_create_autocmd
  autocmd('BufEnter', {
    desc = 'Open Neo-Tree on startup with directory',
    group = vim.api.nvim_create_augroup('neotree_start', { clear = true }),
    callback = function()
      if package.loaded['neo-tree'] then
        vim.api.nvim_del_augroup_by_name 'neotree_start'
      else
        local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(0))
        if stats and stats.type == 'directory' then
          vim.api.nvim_del_augroup_by_name 'neotree_start'
          require 'neo-tree'
        end
      end
    end,
  })
  autocmd('TermClose', {
    pattern = '*lazygit',
    desc = 'Refresh Neo-Tree git when closing lazygit',
    group = vim.api.nvim_create_augroup('neotree_git_refresh', { clear = true }),
    callback = function()
      if package.loaded['neo-tree.sources.git_status'] then
        require('neo-tree.sources.git_status').refresh()
      end
    end,
  })
end

return { ['setup'] = Setup, ['startup'] = Startup }
