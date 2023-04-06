local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
    error('telescope-ctags-outline.nvim requires nvim-telescope/telescope.nvim')
end

local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local action_set = require "telescope.actions.set"
local entry_display = require('telescope.pickers.entry_display')
local utils = require('telescope.utils')
local make_entry = require "telescope.make_entry"
local previewers = require "telescope.previewers"

local function tags(opts) 
    local tagfiles = opts.ctags_file and { opts.ctags_file } or vim.fn.tagfiles()
    for i, ctags_file in ipairs(tagfiles) do
        tagfiles[i] = vim.fn.expand(ctags_file, true)
    end
    if vim.tbl_isempty(tagfiles) then
        utils.notify("builtin.tags", {
                msg = "No tags file found. Create one with ctags -R",
                level = "ERROR",
            })
        return
    end
    opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_ctags(opts))

    pickers.new(opts, {
        prompt_title = "Tags",
        finder = finders.new_oneshot_job(flatten { "C:\\bin\\cat.bat", tagfiles }, opts),
        previewer = previewers.ctags.new(opts),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function()
            action_set.select:enhance {
                post = function()
                    local selection = action_state.get_selected_entry()
                    if not selection then
                        return
                    end

                    if selection.scode then
                        -- un-escape / then escape required
                        -- special chars for vim.fn.search()
                        -- ] ~ *
                        local scode = selection.scode:gsub([[\/]], "/"):gsub("[%]~*]", function(x)
                            return "\\" .. x
                        end)

                        vim.cmd "norm! gg"
                        vim.fn.search(scode)
                        vim.cmd "norm! zz"
                    else
                        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
                    end
                end,
            }
            return true
        end,
    })
    :find()
end

return telescope.register_extension({
    setup = ctags_setup,
    exports = { tags = tags },
})
