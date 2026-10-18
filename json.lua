local Json = {}

local escapeCharacters = {
  ['"'] = '\\"',
  ['\\'] = '\\\\',
  ['\b'] = '\\b',
  ['\f'] = '\\f',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
}

local function encodeString(value)
  return '"' .. value:gsub('[%z\1-\31\\"]', function(character)
    return escapeCharacters[character] or string.format('\\u%04x', character:byte())
  end) .. '"'
end

local function isArray(value)
  local count = 0
  for key in pairs(value) do
    if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 then
      return false
    end
    count = count + 1
  end
  return count == #value
end

local function encodeValue(value, seen)
  local valueType = type(value)
  if valueType == 'nil' then
    return 'null'
  elseif valueType == 'boolean' then
    return value and 'true' or 'false'
  elseif valueType == 'number' then
    assert(value == value and value ~= math.huge and value ~= -math.huge, 'JSON cannot encode a non-finite number')
    return string.format('%.17g', value)
  elseif valueType == 'string' then
    return encodeString(value)
  elseif valueType ~= 'table' then
    error('JSON cannot encode value of type ' .. valueType)
  end

  assert(not seen[value], 'JSON cannot encode cyclic tables')
  seen[value] = true
  local encoded = {}
  if isArray(value) then
    for index = 1, #value do
      encoded[index] = encodeValue(value[index], seen)
    end
    seen[value] = nil
    return '[' .. table.concat(encoded, ',') .. ']'
  end

  for key, entry in pairs(value) do
    assert(type(key) == 'string', 'JSON object keys must be strings')
    encoded[#encoded + 1] = encodeString(key) .. ':' .. encodeValue(entry, seen)
  end
  seen[value] = nil
  return '{' .. table.concat(encoded, ',') .. '}'
end

function Json.encode(value)
  return encodeValue(value, {})
end

local function utf8FromCodepoint(codepoint)
  if codepoint < 0x80 then
    return string.char(codepoint)
  elseif codepoint < 0x800 then
    return string.char(0xC0 + math.floor(codepoint / 0x40), 0x80 + codepoint % 0x40)
  elseif codepoint < 0x10000 then
    return string.char(
      0xE0 + math.floor(codepoint / 0x1000),
      0x80 + math.floor(codepoint / 0x40) % 0x40,
      0x80 + codepoint % 0x40
    )
  end
  return string.char(
    0xF0 + math.floor(codepoint / 0x40000),
    0x80 + math.floor(codepoint / 0x1000) % 0x40,
    0x80 + math.floor(codepoint / 0x40) % 0x40,
    0x80 + codepoint % 0x40
  )
end

function Json.decode(source)
  local position = 1
  local length = #source

  local function skipWhitespace()
    while position <= length and source:sub(position, position):match('%s') do
      position = position + 1
    end
  end

  local parseValue
  local function parseString()
    position = position + 1
    local chunks = {}
    local chunkStart = position
    while position <= length do
      local character = source:sub(position, position)
      if character == '"' then
        chunks[#chunks + 1] = source:sub(chunkStart, position - 1)
        position = position + 1
        return table.concat(chunks)
      elseif character == '\\' then
        chunks[#chunks + 1] = source:sub(chunkStart, position - 1)
        position = position + 1
        local escape = source:sub(position, position)
        local simpleEscapes = {
          ['"'] = '"',
          ['\\'] = '\\',
          ['/'] = '/',
          b = '\b',
          f = '\f',
          n = '\n',
          r = '\r',
          t = '\t',
        }
        if simpleEscapes[escape] then
          chunks[#chunks + 1] = simpleEscapes[escape]
          position = position + 1
        elseif escape == 'u' then
          local code = tonumber(source:sub(position + 1, position + 4), 16)
          assert(code, 'Invalid Unicode escape in JSON')
          position = position + 5
          if code >= 0xD800 and code <= 0xDBFF
              and source:sub(position, position + 1) == '\\u' then
            local low = tonumber(source:sub(position + 2, position + 5), 16)
            if low and low >= 0xDC00 and low <= 0xDFFF then
              code = 0x10000 + (code - 0xD800) * 0x400 + low - 0xDC00
              position = position + 6
            end
          end
          chunks[#chunks + 1] = utf8FromCodepoint(code)
        else
          error('Invalid escape sequence in JSON at byte ' .. position)
        end
        chunkStart = position
      else
        position = position + 1
      end
    end
    error('Unterminated string in JSON')
  end

  local function parseArray()
    position = position + 1
    skipWhitespace()
    local values = {}
    if source:sub(position, position) == ']' then
      position = position + 1
      return values
    end
    while true do
      values[#values + 1] = parseValue()
      skipWhitespace()
      local delimiter = source:sub(position, position)
      position = position + 1
      if delimiter == ']' then
        return values
      end
      assert(delimiter == ',', 'Expected comma in JSON array')
      skipWhitespace()
    end
  end

  local function parseObject()
    position = position + 1
    skipWhitespace()
    local values = {}
    if source:sub(position, position) == '}' then
      position = position + 1
      return values
    end
    while true do
      assert(source:sub(position, position) == '"', 'Expected object key in JSON')
      local key = parseString()
      skipWhitespace()
      assert(source:sub(position, position) == ':', 'Expected colon in JSON object')
      position = position + 1
      skipWhitespace()
      values[key] = parseValue()
      skipWhitespace()
      local delimiter = source:sub(position, position)
      position = position + 1
      if delimiter == '}' then
        return values
      end
      assert(delimiter == ',', 'Expected comma in JSON object')
      skipWhitespace()
    end
  end

  parseValue = function()
    skipWhitespace()
    local character = source:sub(position, position)
    if character == '"' then
      return parseString()
    elseif character == '{' then
      return parseObject()
    elseif character == '[' then
      return parseArray()
    elseif source:sub(position, position + 3) == 'true' then
      position = position + 4
      return true
    elseif source:sub(position, position + 4) == 'false' then
      position = position + 5
      return false
    elseif source:sub(position, position + 3) == 'null' then
      position = position + 4
      return nil
    end

    local number = source:sub(position):match('^-?%d+%.?%d*[eE]?[+-]?%d*')
    assert(number and number ~= '', 'Invalid JSON value at byte ' .. position)
    position = position + #number
    return assert(tonumber(number), 'Invalid JSON number')
  end

  local result = parseValue()
  skipWhitespace()
  assert(position > length, 'Unexpected trailing data in JSON')
  return result
end

return Json
