-- ============================================================
-- SECTION 1: OPTIONS
-- ============================================================
do
    vim.cmd('source ~/.vimrc')
    vim.loader.enable()
    vim.g.have_nerd_font = true
end

-- ============================================================
-- SECTION 2: KEYMAPS & AUTOCMDS
-- ============================================================
do
    vim.diagnostic.config({
        update_in_insert = false,
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = { min = vim.diagnostic.severity.WARN } },
        virtual_text = true,
        virtual_lines = false,
        jump = {
            on_jump = function(_, bufnr)
                vim.diagnostic.open_float({
                    bufnr = bufnr,
                    scope = 'cursor',
                    focus = false,
                })
            end,
        },
    })
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
    vim.api.nvim_create_autocmd('TextYankPost', {
        desc = 'Highlight when yanking text',
        group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
        callback = function()
            vim.hl.on_yank()
        end,
    })
end

-- ============================================================
-- SECTION 3: PLUGIN BUILDS
-- ============================================================
do
    local function run_build(name, cmd, cwd)
        local result = vim.system(cmd, { cwd = cwd }):wait()
        if result.code ~= 0 then
            local stderr = result.stderr or ''
            local stdout = result.stdout or ''
            local output = stderr ~= '' and stderr or stdout
            if output == '' then
                output = 'No output from build command.'
            end
            vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
        end
    end

    vim.api.nvim_create_autocmd('PackChanged', {
        callback = function(ev)
            local name = ev.data.spec.name
            local kind = ev.data.kind
            if kind ~= 'install' and kind ~= 'update' then
                return
            end

            if name == 'telescope-fzf-native.nvim' and vim.fn.executable('make') == 1 then
                run_build(name, { 'make' }, ev.data.path)
                return
            end

            if name == 'LuaSnip' then
                if vim.fn.has('win32') ~= 1 and vim.fn.executable('make') == 1 then
                    run_build(name, { 'make', 'install_jsregexp' }, ev.data.path)
                    return
                end
            end

            if name == 'nvim-treesitter' then
                if not ev.data.active then
                    vim.cmd.packadd('nvim-treesitter')
                end
                vim.cmd('TSUpdate')
                return
            end
        end,
    })
end

-- ============================================================
-- SECTION 4: UI / CORE UX Plugins
-- ============================================================
do
    vim.pack.add({ 'https://github.com/tpope/vim-fugitive' })
    vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })
    local gitsigns = require('gitsigns')
    gitsigns.setup({
        on_attach = function(bufnr)
            vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = '[s]tage hunk', buf = bufnr })
            vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = '[r]eset hunk', buf = bufnr })
            vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = '[S]tage buffer', buf = bufnr })
            vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = '[R]eset buffer', buf = bufnr })
            vim.keymap.set('n', ']c', function()
                if vim.wo.diff then
                    vim.cmd.normal({ ']c', bang = true })
                else
                    gitsigns.nav_hunk('next')
                end
            end, { desc = 'Next [c]hange', buf = bufnr })
            vim.keymap.set('n', '[c', function()
                if vim.wo.diff then
                    vim.cmd.normal({ '[c', bang = true })
                else
                    gitsigns.nav_hunk('prev')
                end
            end, { desc = 'Prev [c]hange', buf = bufnr })
            vim.keymap.set('v', '<leader>hs', function()
                gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end, { desc = '[s]tage hunk', buf = bufnr })
            vim.keymap.set('v', '<leader>hr', function()
                gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end, { desc = '[r]eset hunk', buf = bufnr })
        end,
    })

    vim.pack.add({ 'https://github.com/folke/which-key.nvim' })
    require('which-key').setup({
        delay = 0,
        icons = { mappings = vim.g.have_nerd_font },
        spec = {
            { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
            { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
            { 'gr', group = 'LSP Actions', mode = { 'n' } },
            { '<leader>t', group = '[T]oggle' },
        },
    })

    vim.pack.add({
        {
            src = 'https://github.com/catppuccin/nvim.git',
            name = 'catppuccin',
        },
    })
    require('catppuccin').setup({
        transparent_background = true,
    })

    vim.pack.add({ 'https://github.com/nvim-mini/mini.nvim' })
    if vim.g.have_nerd_font then
        require('mini.icons').setup()
        MiniIcons.mock_nvim_web_devicons()
    end
    local statusline = require('mini.statusline')
    statusline.setup({ use_icons = vim.g.have_nerd_font })
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
        return '%2l:%-2v'
    end

    vim.pack.add({ 'https://github.com/saghen/blink.indent' })
end

-- ============================================================
-- SECTION 5: SEARCH & NAVIGATION
-- ============================================================
do
    local telescope_plugins = {
        'https://github.com/nvim-lua/plenary.nvim',
        'https://github.com/nvim-telescope/telescope.nvim',
        'https://github.com/nvim-telescope/telescope-ui-select.nvim',
    }
    if vim.fn.executable('make') == 1 then
        table.insert(telescope_plugins, 'https://github.com/nvim-telescope/telescope-fzf-native.nvim')
    end
    vim.pack.add(telescope_plugins)
    require('telescope').setup({
        extensions = {
            ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
    })
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[F]iles' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[G]rep' })

    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
            local buf = event.buf
            vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[r]eferences' })
            vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[i]mplementations' })
            vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[d]efinitions' })
            vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[t]ype definition' })
        end,
    })

    vim.keymap.set('n', '<leader/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
            winblend = 10,
            previewer = false,
        }))
    end, { desc = '[/] Search current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep({
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
        })
    end, { desc = '[/] Search in Open Files' })
end

-- ============================================================
-- SECTION 6: LSP
-- ============================================================
do
    vim.pack.add({ 'https://github.com/j-hui/fidget.nvim' })
    require('fidget').setup({})

    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
            local map = function(keys, func, desc, mode)
                mode = mode or 'n'
                vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
            end

            map('grn', vim.lsp.buf.rename, 'rename')
            map('gra', vim.lsp.buf.code_action, 'code action', { 'n', 'x' })
            map('grD', vim.lsp.buf.declaration, 'declaration')
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client and client:supports_method('textDocument/documentHighlight', event.buf) then
                local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
                vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                    buffer = event.buf,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.document_highlight,
                })

                vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                    buffer = event.buf,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.clear_references,
                })

                vim.api.nvim_create_autocmd('LspDetach', {
                    group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
                    callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds({ group = 'lsp-highlight', buffer = event2.buf })
                    end,
                })
            end
        end,
    })

    local servers = {
        clangd = {},
        gopls = {},
        pyright = {},
        stylua = {},
        lua_ls = {
            on_init = function(client)
                client.server_capabilities.documentFormattingProvider = false
                if client.workspace_folders then
                    local path = client.workspace_folders[1].name
                    if
                        path ~= vim.fn.stdpath('config')
                        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                    then
                        return
                    end
                end

                local current_settings = client.config.settings
                client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
                    runtime = {
                        version = 'LuaJIT',
                        path = { 'lua/?.lua', 'lua/?/init.lua' },
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = vim.api.nvim_get_runtime_file('', true),
                    },
                })
            end,
            settings = {
                Lua = {
                    format = { enable = false },
                },
            },
        },
    }

    vim.pack.add({
        'https://github.com/neovim/nvim-lspconfig',
        'https://github.com/mason-org/mason.nvim',
        'https://github.com/mason-org/mason-lspconfig.nvim',
        'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
    })

    require('mason').setup({})

    require('mason-lspconfig').setup({
        automatic_enable = false,
    })
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {})
    require('mason-tool-installer').setup({ ensure_installed = ensure_installed })
    for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
    end
end

-- ============================================================
-- SECTION 7: FORMATTING
-- ============================================================
do
    vim.pack.add({ 'https://github.com/stevearc/conform.nvim' })
    require('conform').setup({
        notify_on_error = false,
        format_on_save = function(bufnr)
            local enabled_filetypes = {
                lua = true,
            }
            if enabled_filetypes[vim.bo[bufnr].filetype] then
                return { timeout_ms = 500 }
            else
                return nil
            end
        end,
        default_format_opts = {
            lsp_format = 'fallback',
        },
        formatters_by_ft = {
            lua = { 'stylua' },
        },
        formatters = {
            stylua = {
                prepend_args = {
                    '--indent-type',
                    'Spaces',
                    '--indent-width',
                    '4',
                    '--quote-style',
                    'AutoPreferSingle',
                },
            },
        },
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
        require('conform').format({ async = true })
    end, { desc = 'format buffer' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS
-- ============================================================
do
    vim.pack.add({
        {
            src = 'https://github.com/L3MON4D3/LuaSnip',
            version = vim.version.range('2.*'),
        },
        {
            src = 'https://github.com/saghen/blink.cmp',
            version = vim.version.range('1.*'),
        },
    })
    require('luasnip').setup({})
    require('blink.cmp').setup({
        keymap = {
            preset = 'default',
        },
        appearance = {
            nerd_font_variant = 'normal',
        },
        completion = {
            documentation = { auto_show = false, auto_show_delay_ms = 500 },
        },
        sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer' },
        },
        snippets = {
            preset = 'luasnip',
        },
        fuzzy = {
            implementation = 'prefer_rust',
        },
        signature = {
            enabled = true,
        },
    })
end

-- ============================================================
-- SECTION 9: TREESITTER
-- ============================================================
do
    vim.pack.add({
        {
            src = 'https://github.com/nvim-treesitter/nvim-treesitter',
            version = 'main',
        },
    })

    local parsers = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
    }
    require('nvim-treesitter').install(parsers)

    local function treesitter_try_attach(buf, language)
        if not vim.treesitter.language.add(language) then
            return
        end
        if not vim.api.nvim_buf_is_valid(buf) then
            return
        end
        vim.treesitter.start(buf, language)
        local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
        if has_indent_query then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end

    local available_parsers = require('nvim-treesitter').get_available()
    vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
            local buf, filetype = args.buf, args.match
            local language = vim.treesitter.language.get_lang(filetype)
            if not language then
                return
            end
            local installed_parsers = require('nvim-treesitter').get_installed('parsers')
            if vim.tbl_contains(installed_parsers, language) then
                treesitter_try_attach(buf, language)
            elseif vim.tbl_contains(available_parsers, language) then
                require('nvim-treesitter').install(language):await(function()
                    treesitter_try_attach(buf, language)
                end)
            else
                treesitter_try_attach(buf, language)
            end
        end,
    })
end

-- ============================================================
-- SECTION 10: DEBUGGING
-- ============================================================
do
    vim.pack.add({
        'https://github.com/mfussenegger/nvim-dap',
        'https://github.com/mfussenegger/nvim-dap-python',
        {
            src = 'https://github.com/igorlfs/nvim-dap-view',
            version = vim.version.range('1.*'),
        },
    })

    local dap = require('dap')
    local dap_python = require('dap-python')
    local dap_view = require('dap-view')
    local debugpy_adapter = vim.fn.exepath('debugpy-adapter')

    if debugpy_adapter == '' then
        error('debugpy-adapter not found. Run pipx install debugpy.')
    end

    dap_python.setup(debugpy_adapter)
    dap_python.test_runner = 'pytest'

    dap_python.resolve_python = function()
        local project_python = vim.fn.getcwd() .. '/.venv/bin/python'
        if vim.fn.executable(project_python) == 1 then
            return project_python
        end
        return vim.fn.expand('python3')
    end

    dap_view.setup({
        auto_toggle = true,
    })

    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP: Toggle breakpoint' })
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'DAP: Start or Continue' })
    vim.keymap.set('n', '<F4>', dap.step_over, { desc = 'DAP: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_into, { desc = 'DAP: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_out, { desc = 'DAP: Step Out' })
    vim.keymap.set('n', '<F1>', dap.terminate, { desc = 'DAP: Stop' })
    vim.keymap.set('n', '<leader><F5>', dap.run_last, { desc = 'DAP: Run Last' })
    vim.keymap.set('n', '<leader>dv', dap_view.toggle, { desc = 'DAP: Toggle View' })
    vim.keymap.set('n', '<leader>dh', dap_view.hover, { desc = 'DAP: Inspect value' })

    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Run current file',
        program = '${file}',
        cwd = '${workspaceFolder}',
        console = 'integratedTerminal',
        justMyCode = false,
    })

    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Run pytest',
        module = 'pytest',
        args = { '-vv', '-s' },
        cwd = '${workspaceFolder}',
        console = 'integratedTerminal',
        justMyCode = false,
    })
end

vim.cmd.colorscheme('catppuccin')

-- vim: set foldmethod=indent foldlevel=0:
