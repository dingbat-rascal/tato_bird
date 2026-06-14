local M = {}

-- Path to the SQLite database
local DB_PATH = vim.fn.stdpath('data') .. '/tatoeba.db'
-- local DB_PATH = vim.fn.stdpath('config') .. '/tatoeba.db'

-- Check if database exists
function M.db_exists()
    local f = io.open(DB_PATH, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Execute a SQL query and return results
function M.query(sql, params)
    if not M.db_exists() then
        vim.notify("Database not found at: " .. DB_PATH, vim.log.levels.ERROR)
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
        local cmd = string.format('sqlite3 -json "%s" "%s"', DB_PATH, sql)
        local handle = io.popen(cmd)
        if not handle then
            vim.notify("Failed to execute sqlite3 command", vim.log.levels.ERROR)
            return nil
        end
        
        local result = handle:read("*a")
        handle:close()
        
        -- Parse JSON result
        local ok_json, parsed = pcall(vim.fn.json_decode, result)
        if ok_json then
            return parsed
        else
            vim.notify("Failed to parse database results", vim.log.levels.ERROR)
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

-- Get all unique tags
function M.get_tags()
    local sql = [[
        SELECT DISTINCT tag_name, COUNT(*) as count 
        FROM tags 
        GROUP BY tag_name 
        ORDER BY count DESC
    ]]
    return M.query(sql)
end

-- Get sentence pairs for a language pair
function M.get_sentence_pairs(source_lang, target_lang, limit)
    limit = limit or 100
    
    local sql = string.format([[
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
        LIMIT %d
    ]], source_lang, target_lang, limit)
    
    return M.query(sql)
end

-- Get sentences by tag
function M.get_sentences_by_tag(lang, tag_name, limit)
    limit = limit or 100
    
    local sql = string.format([[
        SELECT DISTINCT
            s.id,
            s.text,
            s.lang
        FROM sentences s
        INNER JOIN tags t ON s.id = t.sentence_id
        WHERE s.lang = '%s' AND t.tag_name = '%s'
        LIMIT %d
    ]], lang, tag_name, limit)
    
    return M.query(sql)
end

-- Get random sentence pairs with optional tag filter
function M.get_random_pairs(source_lang, target_lang, tag_filter, limit)
    limit = limit or 100
    
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

-- Get tags for a specific language
function M.get_tags_for_language(lang, limit)
    limit = limit or 1000  -- Default to showing many tags
    
    -- Escape single quotes in language code to prevent SQL injection
    lang = lang:gsub("'", "''")
    
    local sql = string.format([[
        SELECT DISTINCT t.tag_name, COUNT(*) as count
        FROM tags t
        INNER JOIN sentences s ON t.sentence_id = s.id
        WHERE s.lang = '%s'
        GROUP BY t.tag_name
        ORDER BY count DESC
        LIMIT %d
    ]], lang, limit)
    
    return M.query(sql)
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

-- Check if a language pair exists
function M.has_language_pair(source_lang, target_lang)
    local sql = string.format([[
        SELECT COUNT(*) as count
        FROM sentences s1
        INNER JOIN links l ON s1.id = l.sentence_id
        INNER JOIN sentences s2 ON l.translation_id = s2.id
        WHERE s1.lang = '%s' AND s2.lang = '%s'
        LIMIT 1
    ]], source_lang, target_lang)
    
    local result = M.query(sql)
    return result and result[1] and result[1].count > 0
end

-- Get database statistics
function M.get_stats()
    local stats = {}
    
    -- Total sentences
    local result = M.query("SELECT COUNT(*) as count FROM sentences")
    stats.total_sentences = result and result[1] and result[1].count or 0
    
    -- Total languages
    result = M.query("SELECT COUNT(DISTINCT lang) as count FROM sentences")
    stats.total_languages = result and result[1] and result[1].count or 0
    
    -- Total links
    result = M.query("SELECT COUNT(*) as count FROM links")
    stats.total_links = result and result[1] and result[1].count or 0
    
    -- Total tags
    result = M.query("SELECT COUNT(*) as count FROM tags")
    stats.total_tags = result and result[1] and result[1].count or 0
    
    return stats
end

return M
