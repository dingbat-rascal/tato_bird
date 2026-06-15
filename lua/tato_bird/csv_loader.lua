local M = {}

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Parse a CSV line, handling quoted fields
--- @param line string The CSV line to parse
--- @return table fields Array of field values
local function parse_csv_line(line)
    local fields = {}
    local field = ""
    local in_quotes = false
    local i = 1

    while i <= #line do
        local char = line:sub(i, i)

        if char == '"' then
            if in_quotes and i < #line and line:sub(i + 1, i + 1) == '"' then
                -- Escaped quote
                field = field .. '"'
                i = i + 1
            else
                -- Toggle quote state
                in_quotes = not in_quotes
            end
        elseif char == ',' and not in_quotes then
            -- End of field
            table.insert(fields, field)
            field = ""
        else
            field = field .. char
        end

        i = i + 1
    end

    -- Add the last field
    table.insert(fields, field)

    return fields
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Load CSV file and return data as array of row objects + headers
--- @param filepath string Path to the CSV file
--- @return table data Array of row objects
--- @return table headers Array of header names
--- @return string|nil error Error message if any
function M.load_csv(filepath)
    if not filepath or filepath == "" then
        return {}, {}, "No filepath provided"
    end
    
    -- Normalize path for the current platform
    local normalized_path = vim.fs.normalize(filepath)
    
    local file = io.open(normalized_path, "r")
    if not file then
        return {}, {}, "Could not open CSV file: " .. normalized_path
    end

    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    if #lines == 0 then
        return {}, {}, "CSV file is empty: " .. filepath
    end

    -- Parse header (first line)
    local headers = parse_csv_line(lines[1])

    if #headers == 0 then
        return {}, {}, "CSV file has no headers: " .. normalized_path
    end

    -- Parse data rows
    local data = {}
    for i = 2, #lines do
        local line = lines[i]
        -- Skip empty lines
        if line and line:match("%S") then
            local fields = parse_csv_line(line)

            -- Only process rows that have at least one non-empty field
            local has_content = false
            for _, field in ipairs(fields) do
                if field and field:match("%S") then
                    has_content = true
                    break
                end
            end

            if has_content then
                local row = {}
                -- Populate row with CSV data
                for j, header in ipairs(headers) do
                    row[header] = fields[j] or ""
                end
                table.insert(data, row)
            end
        end
    end

    return data, headers, nil
end

--- Extract a single column from the data as an array
--- @param data table Array of row objects
--- @param column_name string Name of the column to extract
--- @return table result Array of column values
function M.extract_column(data, column_name)
    if not data or #data == 0 then
        return {}
    end
    if not column_name or column_name == "" then
        return {}
    end
    local result = {}
    for _, row in ipairs(data) do
        table.insert(result, row[column_name] or "")
    end
    return result
end

return M
