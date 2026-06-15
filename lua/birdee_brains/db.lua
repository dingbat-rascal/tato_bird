local M = {}

-- Path to the SQLite database
-- Find the plugin root by searching for the tato_bird plugin in runtimepath
local function find_plugin_root()
    local rtp = vim.api.nvim_list_runtime_paths()
    for _, path in ipairs(rtp) do
        if path:match("tato_bird$") or path:match("tato_bird[\\/]") then
            return path
        end
    end
    -- Fallback to calculating from current file location
    return vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
end

local plugin_root = find_plugin_root()
-- Use vim.fs.normalize to handle path separators cross-platform
local DB_PATH = vim.fs.normalize(plugin_root .. '/tatoeba.db')

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
    -- Escape double quotes
    collapsed = collapsed:gsub('"', '\\"')
    return collapsed
end

-- Execute a SQL query and return results
function M.query(sql, params)
    if not M.db_exists() then
        vim.notify("Database not found at: " .. DB_PATH .. "\nPlugin root: " .. plugin_root, vim.log.levels.ERROR)
        return nil
    end
    
    -- Use sqlite.lua if available, otherwise fall back to system sqlite3
    local ok, sqlite = pcall(require, 'sqlite')
    
    if ok then
        -- Using sqlite.lua plugin
        local db = sqlite.open(DB_PATH)
        local results = db:eval(sql, params or {})
        db:close()
        return results
    else
        -- Fall back to system sqlite3 command
        local escaped_sql = escape_sql_for_shell(sql)
        
        local cmd
        if vim.fn.has('win32') == 1 then
            -- Windows: database path first, then -json flag
            cmd = string.format('sqlite3 "%s" -json "%s"', DB_PATH, escaped_sql)
        else
            -- Unix-like systems: -json flag first
            cmd = string.format('sqlite3 -json "%s" "%s"', DB_PATH, escaped_sql)
        end
        
        local handle = io.popen(cmd)
        if not handle then
            vim.notify("Failed to execute sqlite3 command:\n" .. cmd, vim.log.levels.ERROR)
            return nil
        end
        
        local result = handle:read("*a")
        handle:close()
        
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
            WHERE s1.lang = '%s' AND s2.lang = '%s' AND t.tag = '%s'
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

-- Get tags for a specific language
function M.get_tags_for_language(lang, limit)
    limit = limit or 1000  -- Default to showing many tags
    
    -- Escape single quotes in language code to prevent SQL injection
    lang = lang:gsub("'", "''")
    
    local sql = string.format([[
        SELECT t.tag, COUNT(*) as count
        FROM tags t
        INNER JOIN sentences s ON t.sentence_id = s.id
        WHERE s.lang = '%s'
        GROUP BY t.tag
        ORDER BY count DESC
        LIMIT %d
    ]], lang, limit)
    
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
    
    return results
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
