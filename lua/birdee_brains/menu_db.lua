local M = {}
local db = require('birdee_brains.db')

-- Menu state
local state = {
    step = 1,  -- 1: select source language, 2: select target language, 3: select filter (topic/skill), 4: select specific topic/skill
    source_lang = nil,
    target_lang = nil,
    filter_type = nil,  -- 'topic' or 'skill' or 'none'
    filter_value = nil,
    available_languages = nil,
    available_pairs = nil,
    available_topics = nil,
}

-- Language code to name mapping (ISO 639-2/639-3 based on Library of Congress)
local LANG_NAMES = {
    -- Major languages
    eng = "English",
    spa = "Spanish",
    fra = "French",
    deu = "German",
    ita = "Italian",
    jpn = "Japanese",
    rus = "Russian",
    por = "Portuguese",
    cmn = "Mandarin Chinese",
    zho = "Chinese",
    ara = "Arabic",
    hin = "Hindi",
    ben = "Bengali",
    nld = "Dutch",
    pol = "Polish",
    tur = "Turkish",
    kor = "Korean",
    vie = "Vietnamese",
    swe = "Swedish",
    fin = "Finnish",
    hun = "Hungarian",
    ces = "Czech",
    ell = "Greek",
    tha = "Thai",
    ind = "Indonesian",
    ukr = "Ukrainian",
    ron = "Romanian",
    cat = "Catalan",
    dan = "Danish",
    nor = "Norwegian",
    nob = "Norwegian Bokmål",
    nno = "Norwegian Nynorsk",
    bul = "Bulgarian",
    hrv = "Croatian",
    slk = "Slovak",
    lit = "Lithuanian",
    slv = "Slovenian",
    est = "Estonian",
    lav = "Latvian",
    isl = "Icelandic",
    afr = "Afrikaans",
    sqi = "Albanian",
    eus = "Basque",
    bel = "Belarusian",
    bos = "Bosnian",
    glg = "Galician",
    kat = "Georgian",
    hye = "Armenian",
    aze = "Azerbaijani",
    kaz = "Kazakh",
    uzb = "Uzbek",
    mon = "Mongolian",
    
    -- South Asian languages
    nep = "Nepali",
    sin = "Sinhala",
    tam = "Tamil",
    tel = "Telugu",
    mar = "Marathi",
    urd = "Urdu",
    pan = "Punjabi",
    guj = "Gujarati",
    kan = "Kannada",
    mal = "Malayalam",
    ori = "Oriya",
    asm = "Assamese",
    
    -- Middle Eastern languages
    fas = "Persian",
    pus = "Pashto",
    kur = "Kurdish",
    heb = "Hebrew",
    
    -- African languages
    amh = "Amharic",
    swa = "Swahili",
    hau = "Hausa",
    yor = "Yoruba",
    zul = "Zulu",
    xho = "Xhosa",
    mlg = "Malagasy",
    som = "Somali",
    
    -- Constructed languages
    epo = "Esperanto",
    ido = "Ido",
    ina = "Interlingua",
    vol = "Volapük",
    jbo = "Lojban",
    tlh = "Klingon",
    
    -- Classical/Historical languages
    lat = "Latin",
    san = "Sanskrit",
    grc = "Ancient Greek",
    chu = "Church Slavonic",
    ang = "Old English",
    
    -- Celtic languages
    gle = "Irish",
    gla = "Scottish Gaelic",
    cym = "Welsh",
    glv = "Manx",
    
    -- Regional European languages
    oci = "Occitan",
    ast = "Asturian",
    arg = "Aragonese",
    lad = "Ladino",
    yid = "Yiddish",
    mlt = "Maltese",
    mkd = "Macedonian",
    srp = "Serbian",
    cnr = "Montenegrin",
    
    -- Turkic languages
    tat = "Tatar",
    chv = "Chuvash",
    tgk = "Tajik",
    tuk = "Turkmen",
    kir = "Kyrgyz",
    uig = "Uyghur",
    
    -- East Asian languages
    bod = "Tibetan",
    mya = "Burmese",
    khm = "Khmer",
    lao = "Lao",
    wuu = "Wu Chinese",
    yue = "Cantonese",
    nan = "Min Nan Chinese",
    hak = "Hakka Chinese",
    
    -- Southeast Asian languages
    tgl = "Tagalog",
    ceb = "Cebuano",
    war = "Waray",
    jav = "Javanese",
    sun = "Sundanese",
    msa = "Malay",
    zsm = "Standard Malay",
    
    -- Additional languages from Tatoeba
    acm = "Mesopotamian Arabic",
    ady = "Adyghe",
    ain = "Ainu",
    akl = "Aklanon",
    aln = "Gheg Albanian",
    apc = "Levantine Arabic",
    arq = "Algerian Arabic",
    ary = "Moroccan Arabic",
    arz = "Egyptian Arabic",
    avk = "Kotava",
    awa = "Awadhi",
    bak = "Bashkir",
    bam = "Bambara",
    bar = "Bavarian",
    ber = "Berber",
    bho = "Bhojpuri",
    brx = "Bodo",
    bua = "Buriat",
    cbk = "Chavacano",
    cha = "Chamorro",
    che = "Chechen",
    chr = "Cherokee",
    ckt = "Chukchi",
    cor = "Cornish",
    cos = "Corsican",
    crh = "Crimean Tatar",
    csb = "Kashubian",
    cycl = "CycL",
    dak = "Dakota",
    dsb = "Lower Sorbian",
    dtp = "Central Dusun",
    dws = "Dutton World Speedwords",
    egl = "Emilian",
    enm = "Middle English",
    ext = "Extremaduran",
    fij = "Fijian",
    fkv = "Kven Finnish",
    fry = "Western Frisian",
    fur = "Friulian",
    gos = "Gronings",
    got = "Gothic",
    grn = "Guarani",
    gsw = "Swiss German",
    hat = "Haitian Creole",
    haw = "Hawaiian",
    hif = "Fiji Hindi",
    hil = "Hiligaynon",
    hmn = "Hmong",
    hoc = "Ho",
    hsb = "Upper Sorbian",
    ido = "Ido",
    ile = "Interlingue",
    ilo = "Iloko",
    ina = "Interlingua",
    izh = "Ingrian",
    jbo = "Lojban",
    kab = "Kabyle",
    kal = "Kalaallisut",
    kha = "Khasi",
    kjh = "Khakas",
    krl = "Karelian",
    ksh = "Colognian",
    kum = "Kumyk",
    kzj = "Coastal Kadazan",
    lad = "Ladino",
    ldn = "Láadan",
    lfn = "Lingua Franca Nova",
    lij = "Ligurian",
    lin = "Lingala",
    liv = "Livonian",
    lkt = "Lakota",
    lld = "Ladin",
    lmo = "Lombard",
    ltg = "Latgalian",
    ltz = "Luxembourgish",
    lzh = "Literary Chinese",
    lzz = "Laz",
    mah = "Marshallese",
    mai = "Maithili",
    mfe = "Morisyen",
    mhr = "Eastern Mari",
    mic = "Mi'kmaq",
    min = "Minangkabau",
    moh = "Mohawk",
    mrj = "Western Mari",
    mwl = "Mirandese",
    mww = "Hmong Daw",
    myv = "Erzya",
    nah = "Nahuatl",
    nap = "Neapolitan",
    nau = "Nauru",
    nav = "Navajo",
    niu = "Niuean",
    nog = "Nogai",
    non = "Old Norse",
    nov = "Novial",
    npi = "Nepali",
    orv = "Old Russian",
    oss = "Ossetian",
    ota = "Ottoman Turkish",
    pag = "Pangasinan",
    pam = "Pampanga",
    pap = "Papiamento",
    pau = "Palauan",
    pcd = "Picard",
    pdc = "Pennsylvania German",
    pes = "Iranian Persian",
    pms = "Piedmontese",
    pnb = "Western Punjabi",
    prg = "Prussian",
    quc = "K'iche'",
    qya = "Quenya",
    rap = "Rapanui",
    rif = "Tarifit",
    roh = "Romansh",
    rom = "Romany",
    rue = "Rusyn",
    rup = "Aromanian",
    sah = "Yakut",
    scn = "Sicilian",
    sco = "Scots",
    sgs = "Samogitian",
    shs = "Shuswap",
    shy = "Tachawit",
    sjn = "Sindarin",
    sma = "Southern Sami",
    sme = "Northern Sami",
    sna = "Shona",
    snd = "Sindhi",
    sot = "Southern Sotho",
    stq = "Saterland Frisian",
    swg = "Swabian",
    swh = "Swahili",
    tah = "Tahitian",
    tet = "Tetum",
    tir = "Tigrinya",
    tlh = "Klingon",
    tly = "Talysh",
    tmr = "Jewish Babylonian Aramaic",
    toi = "Tonga",
    tok = "Toki Pona",
    tpi = "Tok Pisin",
    tpw = "Old Tupi",
    tso = "Tsonga",
    tvl = "Tuvalu",
    tyv = "Tuvinian",
    tzl = "Talossan",
    udm = "Udmurt",
    vec = "Venetian",
    vep = "Veps",
    vro = "Võro",
    war = "Waray",
    wln = "Walloon",
    wol = "Wolof",
    wuu = "Wu Chinese",
    xal = "Kalmyk",
    xmf = "Mingrelian",
    yue = "Cantonese",
    zea = "Zeelandic",
    zza = "Zaza",
}

-- Get display name for language code
local function get_lang_name(code)
    return LANG_NAMES[code] or code
end

-- Reset menu state
function M.reset()
    state = {
        step = 1,
        source_lang = nil,
        target_lang = nil,
        filter_type = nil,
        filter_value = nil,
        available_languages = nil,
        available_pairs = nil,
        available_topics = nil,
    }
end

-- Get current navigation path for display
function M.get_navigation_path()
    local path = {}
    
    if state.source_lang then
        table.insert(path, "Learning: " .. get_lang_name(state.source_lang))
    end
    
    if state.target_lang then
        table.insert(path, "From: " .. get_lang_name(state.target_lang))
    end
    
    if state.filter_type then
        if state.filter_type == 'topic' then
            table.insert(path, "Filter: Topic")
        end
    end
    
    if state.filter_value then
        table.insert(path, state.filter_value)
    end
    
    return table.concat(path, " → ")
end

-- Select source language (language to learn)
function M.select_source_language(lang_code)
    state.source_lang = lang_code
    state.step = 2
end

-- Select target language (language you know)
function M.select_target_language(lang_code)
    state.target_lang = lang_code
    state.step = 3
end

-- Select filter type
function M.select_filter_type(filter_type)
    state.filter_type = filter_type
    if filter_type == 'none' then
        state.step = 5  -- Ready to start
    else
        state.step = 4
    end
end

-- Select specific topic or skill level
function M.select_filter_value(value)
    state.filter_value = value
    state.step = 5  -- Ready to start
end

-- Get current menu options based on state
function M.get_current_options()
    if state.step == 1 then
        -- Select source language
        if not state.available_languages then
            state.available_languages = db.get_languages()
        end
        
        local options = { "Select Language to Learn (press Enter on a line):" }
        if state.available_languages then
            -- Show ALL languages with better formatting
            for i, lang in ipairs(state.available_languages) do
                table.insert(options, string.format("  [%s] %s (%s sentences)", 
                    lang.lang,
                    get_lang_name(lang.lang),
                    lang.count))
            end
        else
            table.insert(options, "  Error: Could not load languages from database")
        end
        return options
        
    elseif state.step == 2 then
        -- Select target language
        if not state.available_pairs then
            state.available_pairs = db.get_language_pairs(state.source_lang)
        end
        
        local options = { "Select Your Native Language (press Enter on a line):" }
        if state.available_pairs then
            -- Show ALL language pairs with better formatting
            for i, pair in ipairs(state.available_pairs) do
                table.insert(options, string.format("  [%s] %s (%s pairs)", 
                    pair.lang,
                    get_lang_name(pair.lang),
                    pair.pair_count))
            end
        else
            table.insert(options, "  Error: Could not load language pairs")
        end
        return options
        
    elseif state.step == 3 then
        -- Select filter type
        return {
            "Choose Lesson Filter:",
            "  [topic] Filter by Topic/Tag",
            "  [none] No Filter (Random sentences)",
        }
        
    elseif state.step == 4 then
        if state.filter_type == 'topic' then
            -- Select topic
            if not state.available_topics then
                -- Get ALL topics (no limit)
                state.available_topics = db.get_tags_for_language(state.source_lang, 1000)
            end
            
            local options = { "Select Topic (press Enter on a line):" }
            if state.available_topics and #state.available_topics > 0 then
                -- Show ALL topics with sentence counts
                for i, tag in ipairs(state.available_topics) do
                    table.insert(options, string.format("  [%s] %s sentences",
                        tag.tag,
                        tag.count))
                end
            else
                table.insert(options, "  No topics available for this language")
            end
            return options
        end
        
    elseif state.step == 5 then
        -- Ready to start
        return {
            "Ready to Start!",
            "",
            "Configuration:",
            "  Learning: " .. get_lang_name(state.source_lang),
            "  From: " .. get_lang_name(state.target_lang),
            "  Filter: " .. (state.filter_type or "none"),
            "  Value: " .. (state.filter_value or "none"),
            "",
            "Press <CR> to start the lesson",
            "Press <Esc> to go back",
        }
    end
    
    return { "Error: Invalid menu state" }
end

-- Get current state
function M.get_state()
    return state
end

-- Check if ready to start game
function M.is_ready()
    return state.step == 5
end

-- Display menu in buffer
function M.display_menu(buf)
    local options = M.get_current_options()
    local path = M.get_navigation_path()
    
    local lines = {}
    
    -- Header
    table.insert(lines, "╔═══════════════════════════════════════════════════════════╗")
    table.insert(lines, "║          Birdee Brains - Language Learning Menu           ║")
    table.insert(lines, "╚═══════════════════════════════════════════════════════════╝")
    table.insert(lines, "")
    
    -- Navigation path
    if path ~= "" then
        table.insert(lines, "Current: " .. path)
        table.insert(lines, "")
    end
    
    local header_lines = #lines
    
    -- Options
    for _, line in ipairs(options) do
        table.insert(lines, line)
    end
    
    -- Footer
    table.insert(lines, "")
    table.insert(lines, "───────────────────────────────────────────────────────────")
    
    -- Show instructions (different for ready screen)
    if state.step == 5 then
        table.insert(lines, "Press <Esc> to go back | q to quit")
    else
        table.insert(lines, "<Esc> to go back | q to quit")
    end
    
    -- Make buffer modifiable, set lines, then make it non-modifiable again
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
end

return M
