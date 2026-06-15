local M = {}

-- Path to the SQLite database
-- Find the plugin root by searching for the tato_bird plugin in runtimepath
local function find_plugin_root()
    local rtp = vim.api.nvim_list_runtime_paths()
    for _, path in ipairs(rtp) do
        -- Normalize path for comparison
        local normalized = vim.fs.normalize(path)
        if normalized:match("tato_bird$") or normalized:match("tato_bird[\\/]") then
            return normalized
        end
    end
    -- Fallback to calculating from current file location
    local source_file = debug.getinfo(1, "S").source:sub(2)
    return vim.fn.fnamemodify(source_file, ":h:h:h")
end

local plugin_root = find_plugin_root()
-- Use proper path joining for cross-platform compatibility
local DB_PATH = vim.fs.normalize(plugin_root .. '/tatoeba.db')

-- Cache backend availability to avoid repeated require attempts
local BACKEND_TYPE = nil  -- 'sqlite', 'plenary', or 'shell'
local BACKEND_MODULE = nil

local function get_db_backend()
    if BACKEND_TYPE == nil then
        -- Try sqlite.lua first
        local ok_sqlite, sqlite = pcall(require, 'sqlite')
        if ok_sqlite then
            BACKEND_TYPE = 'sqlite'
            BACKEND_MODULE = sqlite
            return BACKEND_TYPE, BACKEND_MODULE
        end
        
        -- Try plenary.sqlite
        local ok_plenary, plenary_sqlite = pcall(require, 'plenary.sqlite')
        if ok_plenary then
            BACKEND_TYPE = 'plenary'
            BACKEND_MODULE = plenary_sqlite
            return BACKEND_TYPE, BACKEND_MODULE
        end
        
        -- Fall back to shell command
        BACKEND_TYPE = 'shell'
        return BACKEND_TYPE, nil
    end
    return BACKEND_TYPE, BACKEND_MODULE
end

-- Check if database exists
function M.db_exists()
    local f = io.open(DB_PATH, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Escape SQL for shell command (collapse whitespace, escape quotes)
local function escape_sql_for_shell(sql)
    -- Collapse whitespace (multiple spaces, tabs, newlines become single space)
    local collapsed = sql:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    
    -- On Windows, handle both cmd.exe and PowerShell escaping
    if vim.fn.has('win32') == 1 then
        -- For Windows, escape double quotes by doubling them for cmd.exe
        -- and also handle special characters
        collapsed = collapsed:gsub('"', '""')
        -- Escape special cmd.exe characters
        collapsed = collapsed:gsub('([&|<>^])', '^%1')
    else
        -- Unix-like: escape double quotes with backslash
        collapsed = collapsed:gsub('"', '\\"')
    end
    
    return collapsed
end

-- Execute a SQL query and return results
function M.query(sql, params)
    if not M.db_exists() then
        vim.notify("Database not found at: " .. DB_PATH .. "\nPlugin root: " .. plugin_root, vim.log.levels.ERROR)
        return nil
    end
    
    local backend_type, backend_module = get_db_backend()
    
    if backend_type == 'sqlite' then
        -- Using sqlite.lua plugin
        local db = backend_module.open(DB_PATH)
        local results = db:eval(sql, params or {})
        db:close()
        return results
    elseif backend_type == 'plenary' then
        -- Using plenary.sqlite
        local db = backend_module.new(DB_PATH)
        local results = db:execute(sql, params or {})
        return results
    else
        -- Fall back to system sqlite3 command
        local temp_sql = nil
        local cmd
        
        if vim.fn.has('win32') == 1 then
            -- Windows: Always use temp file to avoid escaping issues
            -- and command line length limits
            temp_sql = vim.fn.tempname() .. '.sql'
            local f = io.open(temp_sql, 'w')
            if not f then
                vim.notify("Failed to create temp SQL file", vim.log.levels.ERROR)
                return nil
            end
            f:write(sql)
            f:close()
            
            -- Normalize paths for Windows
            local db_path_win = vim.fn.shellescape(DB_PATH)
            local temp_sql_win = vim.fn.shellescape(temp_sql)
            
            -- Use cmd.exe with proper redirection
            cmd = string.format('cmd.exe /c "sqlite3 -json %s < %s"', db_path_win, temp_sql_win)
        else
            -- Unix-like systems: Use temp file for consistency and to avoid escaping issues
            temp_sql = vim.fn.tempname() .. '.sql'
            local f = io.open(temp_sql, 'w')
            if not f then
                vim.notify("Failed to create temp SQL file", vim.log.levels.ERROR)
                return nil
            end
            f:write(sql)
            f:close()
            
            -- Use shell redirection
            cmd = string.format('sqlite3 -json %s < %s', vim.fn.shellescape(DB_PATH), vim.fn.shellescape(temp_sql))
        end
        
        local handle = io.popen(cmd)
        if not handle then
            -- Clean up temp file
            if temp_sql then
                os.remove(temp_sql)
            end
            vim.notify("Failed to execute sqlite3 command:\n" .. cmd, vim.log.levels.ERROR)
            return nil
        end
        
        local result = handle:read("*a")
        local success = handle:close()
        
        -- Clean up temp file
        if temp_sql then
            os.remove(temp_sql)
        end
        
        if not success then
            vim.notify("sqlite3 command failed. Is sqlite3 installed and in PATH?", vim.log.levels.ERROR)
            return nil
        end
        
        if not result or result == "" then
            vim.notify("No results from database query", vim.log.levels.WARN)
            return nil
        end
        
        -- Parse JSON result
        local ok_json, parsed = pcall(vim.fn.json_decode, result)
        if ok_json then
            return parsed
        else
            vim.notify("Failed to parse database results:\n" .. (result:sub(1, 200) or "empty"), vim.log.levels.ERROR)
            return nil
        end
    end
end

-- Get all available languages
function M.get_languages()
    local sql = [[
        SELECT DISTINCT lang, COUNT(*) as count 
        FROM sentences 
        GROUP BY lang 
        ORDER BY count DESC
    ]]
    return M.query(sql)
end


-- Get random sentence pairs with optional tag filter
function M.get_random_pairs(source_lang, target_lang, tag_filter, limit)
    limit = limit or 100
    
    -- Escape single quotes in parameters to prevent SQL injection
    source_lang = source_lang:gsub("'", "''")
    target_lang = target_lang:gsub("'", "''")
    if tag_filter then
        tag_filter = tag_filter:gsub("'", "''")
    end
    
    local sql
    if tag_filter then
        sql = string.format([[
            SELECT 
                s1.id as source_id,
                s1.text as source_text,
                s1.lang as source_lang,
                s2.id as target_id,
                s2.text as target_text,
                s2.lang as target_lang
            FROM sentences s1
            INNER JOIN links l ON s1.id = l.sentence_id
            INNER JOIN sentences s2 ON l.translation_id = s2.id
            INNER JOIN tags t ON s1.id = t.sentence_id
            WHERE s1.lang = '%s' AND s2.lang = '%s' AND t.tag_name = '%s'
            ORDER BY RANDOM()
            LIMIT %d
        ]], source_lang, target_lang, tag_filter, limit)
    else
        sql = string.format([[
            SELECT 
                s1.id as source_id,
                s1.text as source_text,
                s1.lang as source_lang,
                s2.id as target_id,
                s2.text as target_text,
                s2.lang as target_lang
            FROM sentences s1
            INNER JOIN links l ON s1.id = l.sentence_id
            INNER JOIN sentences s2 ON l.translation_id = s2.id
            WHERE s1.lang = '%s' AND s2.lang = '%s'
            ORDER BY RANDOM()
            LIMIT %d
        ]], source_lang, target_lang, limit)
    end
    
    return M.query(sql)
end

-- Get tags for sentence pairs between two languages
function M.get_tags_for_language_pair(source_lang, target_lang, limit)
    limit = limit or 1000  -- Default to showing many tags
    
    -- Escape single quotes in language codes to prevent SQL injection
    source_lang = source_lang:gsub("'", "''")
    target_lang = target_lang:gsub("'", "''")
    
    -- Query for tags on sentences that have translations to the target language
    -- This ensures we only show tags for sentence pairs that actually exist
    local sql = string.format([[
        SELECT t.tag_name as tag, COUNT(DISTINCT t.sentence_id) as count
        FROM tags t
        INNER JOIN sentences s1 ON t.sentence_id = s1.id
        INNER JOIN links l ON s1.id = l.sentence_id
        INNER JOIN sentences s2 ON l.translation_id = s2.id
        WHERE s1.lang = '%s' AND s2.lang = '%s'
        GROUP BY t.tag_name
        HAVING count > 0
        ORDER BY count DESC
        LIMIT %d
    ]], source_lang, target_lang, limit)
    
    local results = M.query(sql)
    
    -- Filter out any invalid results (like column headers)
    if results and #results > 0 then
        local filtered = {}
        for _, row in ipairs(results) do
            -- Only include rows that have actual data (not column names)
            if row.tag and row.count and type(row.count) == "number" then
                table.insert(filtered, row)
            end
        end
        return filtered
    end
    
    return results or {}
end

-- Get available language pairs (languages that have translations to target_lang)
function M.get_language_pairs(target_lang)
    local sql = string.format([[
        SELECT DISTINCT s1.lang, COUNT(*) as pair_count
        FROM sentences s1
        INNER JOIN links l ON s1.id = l.sentence_id
        INNER JOIN sentences s2 ON l.translation_id = s2.id
        WHERE s2.lang = '%s' AND s1.lang != '%s'
        GROUP BY s1.lang
        ORDER BY pair_count DESC
    ]], target_lang, target_lang)
    
    return M.query(sql)
end


return M
