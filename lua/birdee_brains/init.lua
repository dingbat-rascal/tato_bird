local M = {}

-- ============================================================================
-- Requires
-- ============================================================================

local settings_module = require("birdee_brains.settings")
local dictionary_module = require("birdee_brains.dictionary")
local game_engine_module = require("birdee_brains.game_engine")
local ui_module = require("birdee_brains.ui")
local keymaps_module = require("birdee_brains.keymaps")

-- ============================================================================
-- Local State
-- ============================================================================

M.SETTINGS = {}

-- ============================================================================
-- Public API
-- ============================================================================

--- Show the navigation menu
function M.show_menu()
    local menu = require('birdee_brains.menu_db')
    local db = require('birdee_brains.db')
    
    -- Check if database exists
    if not db.db_exists() then
        vim.notify("Database not found! Please copy tatoeba.db to: " .. vim.fn.stdpath('config'), vim.log.levels.ERROR)
        return
    end
    
    -- Reset menu state
    menu.reset()
    
    -- Create a new buffer for the menu
    local buf = vim.api.nvim_create_buf(false, true)
    
    -- Make window larger and scrollable
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(40, vim.o.lines - 4)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = 'minimal',
        border = 'rounded'
    })
    
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('scrolloff', 5, { win = win })
    vim.api.nvim_set_option_value('wrap', false, { win = win })
    vim.api.nvim_set_option_value('cursorline', true, { win = win })
    
    -- Display initial menu
    menu.display_menu(buf)
    
    -- Handle Enter key to select current line
    vim.keymap.set('n', '<CR>', function()
        if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
            return
        end
        
        local state = menu.get_state()
        
        -- Check if ready to start
        if menu.is_ready() then
            vim.api.nvim_win_close(win, true)
            -- Start game with selected configuration
            M.start_game_from_db(state)
            return
        end
        
        -- Get current line and extract selection
        local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
        local line_text = vim.api.nvim_buf_get_lines(buf, cursor_line - 1, cursor_line, false)[1]
        
        -- Extract code/value from line based on current step
        local input = nil
        
        if state.step == 1 or state.step == 2 then
            -- Extract language code from line like "  [eng] English (12345 sentences)"
            input = line_text:match("%[([^%]]+)%]")
        elseif state.step == 3 then
            -- Extract filter type from line like "  [topic] Filter by Topic/Tag"
            input = line_text:match("%[([^%]]+)%]")
        elseif state.step == 4 then
            if state.filter_type == 'topic' then
                -- Extract tag name from line like "  [maths] (123 sentences)"
                input = line_text:match("%[([^%]]+)%]")
            else
                -- Extract skill level from line like "  [beginner] Beginner (Simple sentences)"
                input = line_text:match("%[([^%]]+)%]")
            end
        end
        
        if not input then
            return
        end
        
        -- Process the selection
        if state.step == 1 then
            menu.select_source_language(input)
        elseif state.step == 2 then
            menu.select_target_language(input)
        elseif state.step == 3 then
            menu.select_filter_type(input)
        elseif state.step == 4 then
            menu.select_filter_value(input)
        end
        
        -- Redisplay menu
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
                menu.display_menu(buf)
            end
        end)
    end, { buffer = buf })
    
    -- Escape to go back
    vim.keymap.set('n', '<Esc>', function()
        local state = menu.get_state()
        if state.step == 1 then
            vim.api.nvim_win_close(win, true)
        else
            -- Go back one step
            if state.step == 2 then
                state.step = 1
                state.source_lang = nil
                state.available_pairs = nil
            elseif state.step == 3 then
                state.step = 2
                state.target_lang = nil
            elseif state.step == 4 then
                state.step = 3
                state.filter_type = nil
                state.available_topics = nil
                state.available_skills = nil
            elseif state.step == 5 then
                state.step = state.filter_type == 'none' and 3 or 4
                state.filter_value = nil
            end
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(buf) then
                    menu.display_menu(buf)
                end
            end)
        end
    end, { buffer = buf })
    
    -- Quit
    vim.keymap.set('n', 'q', function()
        menu.reset()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })
    
    -- Scrolling in normal mode
    vim.keymap.set('n', 'j', '<Down>', { buffer = buf })
    vim.keymap.set('n', 'k', '<Up>', { buffer = buf })
    vim.keymap.set('n', '<C-d>', '<C-d>', { buffer = buf })
    vim.keymap.set('n', '<C-u>', '<C-u>', { buffer = buf })
    vim.keymap.set('n', 'G', 'G', { buffer = buf })
    vim.keymap.set('n', 'gg', 'gg', { buffer = buf })
    
    -- Start in insert mode for prompt
    vim.cmd('startinsert')
end

--- Start game from database menu configuration
function M.start_game_from_db(menu_state)
    local db = require('birdee_brains.db')
    
    -- Fetch sentence pairs from database
    local limit = M.SETTINGS.lesson_size or 100
    local pairs
    
    if menu_state.filter_type == 'topic' and menu_state.filter_value then
        pairs = db.get_random_pairs(menu_state.source_lang, menu_state.target_lang, menu_state.filter_value, limit)
    else
        pairs = db.get_random_pairs(menu_state.source_lang, menu_state.target_lang, nil, limit)
    end
    
    if not pairs or #pairs == 0 then
        vim.notify("No sentence pairs found for this configuration!", vim.log.levels.ERROR)
        return
    end
    
    -- Convert database pairs to dictionary format
    local questions = {}
    local answers = {}
    local metadata = {}
    
    for i, pair in ipairs(pairs) do
        questions[i] = pair.target_text  -- What you know (native language)
        answers[i] = pair.source_text    -- What you're learning
        metadata[i] = {
            source_id = pair.source_id,
            target_id = pair.target_id,
            source_lang = pair.source_lang,
            target_lang = pair.target_lang,
        }
    end
    
    vim.notify(string.format("Loaded %d sentence pairs: %s → %s", 
        #pairs, menu_state.target_lang, menu_state.source_lang), vim.log.levels.INFO)
    
    -- Start the game with loaded data
    M.start_game_with_data(M.SETTINGS, questions, answers, metadata)
end


--- Start the game with provided data
--- @param SETTINGS table Game settings
--- @param questions table Question data
--- @param answers table Answer data
--- @param metadata table Metadata
function M.start_game_with_data(SETTINGS, questions, answers, metadata)
    -- Guard clause: validate settings
    if not SETTINGS then
        vim.notify("Invalid settings", vim.log.levels.ERROR)
        return
    end

    -- Guard clause: validate loaded data
    if not questions or #questions == 0 then
        vim.notify("Failed to load questions", vim.log.levels.ERROR)
        return
    end
    if not answers or #answers == 0 then
        vim.notify("Failed to load answers", vim.log.levels.ERROR)
        return
    end

    -- Create game engine
    local engine = game_engine_module.create_engine(SETTINGS)
    engine.metadata = metadata

    -- Create buffer and window
    local buf = vim.api.nvim_create_buf(false, true)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        vim.notify("Failed to create game buffer", vim.log.levels.ERROR)
        return
    end
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = 80,
        height = 24,
        col = (vim.o.columns - 80) / 2,
        row = (vim.o.lines - 24) / 2,
        style = 'minimal',
        border = 'rounded'
    })

    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.notify("Failed to create game window", vim.log.levels.ERROR)
        return
    end

    local ns_id = vim.api.nvim_create_namespace("game_feedback")

    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

    vim.api.nvim_buf_call(buf, function()
        -- Disable autocomplete
        vim.cmd("setlocal completeopt=")
        vim.cmd("setlocal completefunc=")
        vim.cmd("setlocal omnifunc=")

        if SETTINGS.game_mode == "speedrun" and SETTINGS.input_keymap ~= "" then
            vim.cmd("setlocal keymap=" .. SETTINGS.input_keymap)
            vim.cmd("setlocal iminsert=1")
        else
            vim.cmd("setlocal keymap=")
            vim.cmd("setlocal iminsert=0")
        end
    end)

    -- Setup UI
    ui_module.setup_highlights()

    -- Next round function
    local function next_round()
        if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
            return
        end

        engine:select_target(questions)

        local choices = nil
        if SETTINGS.game_mode == "multiple_choice" then
            -- Guard clause: validate target index before generating choices
            if not engine.target_idx or not answers[engine.target_idx] then
                vim.notify("Invalid target index", vim.log.levels.ERROR)
                return
            end

            choices = engine:generate_choices(answers, answers[engine.target_idx])
            
            -- Guard clause: ensure choices were generated
            if not choices or type(choices) ~= "table" then
                vim.notify("Failed to generate choices", vim.log.levels.ERROR)
                return
            end
            
            -- Debug: Check what generate_choices returned
            if SETTINGS.debug then
                vim.notify(string.format("generate_choices returned %d choices", #choices), vim.log.levels.INFO)
            end
            
            -- Force exactly 4 choices - create new table to avoid reference issues
            local safe_choices = {}
            for i = 1, 4 do
                safe_choices[i] = choices[i] or ""
            end
            
            -- Debug: Verify safe_choices has 4 elements
            if SETTINGS.debug then
                vim.notify(string.format("safe_choices has %d elements", #safe_choices), vim.log.levels.INFO)
                for i = 1, 4 do
                    vim.notify(string.format("  [%d] = '%s'", i, safe_choices[i]), vim.log.levels.INFO)
                end
            end

            -- Store choices in engine state for keymap access
            engine.current_choices = safe_choices
            choices = safe_choices
        end

        local layout = ui_module.build_layout(engine, questions, choices, SETTINGS.game_mode)
        ui_module.render(buf, win, layout, SETTINGS.game_mode)
    end

    -- Setup keymaps
    keymaps_module.setup_keymaps(buf, win, engine, questions, answers, SETTINGS, next_round)

    -- Setup game-specific input handlers
    if SETTINGS.game_mode == "speedrun" then
        keymaps_module.setup_speedrun_input(buf, engine, questions, answers, SETTINGS, ns_id, next_round)
    else
        keymaps_module.setup_multiple_choice_input(buf, engine, answers, SETTINGS, ns_id, next_round)
    end

    -- Start the game
    next_round()
end


-- ============================================================================
-- Setup
-- ============================================================================

--- Setup the plugin with user configuration
--- @param opts table|nil User configuration options
function M.setup(opts)
    -- Merge user config with defaults
    M.SETTINGS = vim.tbl_deep_extend("force", settings_module.DEFAULTS, opts or {})
    
    -- Create user commands
    vim.api.nvim_create_user_command('BirdeeBrainsMenu', function()
        M.show_menu()
    end, { desc = "Open Birdee Brains menu" })
    
    
    -- Setup global keymap to launch menu
    vim.keymap.set('n', '<C-g>', M.show_menu, { silent = true, desc = "Open Birdee Brains Menu" })
end

return M
