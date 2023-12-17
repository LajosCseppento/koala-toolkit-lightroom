-- This file should be LRC API free, so it can be easily tested without Lightroom.

local Utils = {}

local function toSet(array)
    local set = {}
    for _, value in ipairs(array) do
        set[value] = true
    end

    return set
end

function Utils.tableLength(table)
    local length = 0
    for _ in pairs(table) do length = length + 1 end
    return length
end

Utils.dngExtension = "dng"

Utils.jpegExtensionsArray = { "jpg", "jpeg" }
Utils.jpegExtensionsSet = toSet(Utils.jpegExtensionsArray)

-- https://en.wikipedia.org/wiki/Raw_image_format
Utils.rawExtensionsArray = {
    "3fr", "ari", "arw", "bay", "braw", "crw", "cr2", "cr3", "cap", "data", "dcs", "dcr", "dng", "drf", "eip", "erf",
    "fff", "gpr", "iiq", "k25", "kdc", "mdc", "mef", "mos", "mrw", "nef", "nrw", "obm", "orf", "pef", "ptx", "pxn", "r3d",
    "raf", "raw", "rwl", "rw2", "rwz", "sr2", "srf", "srw", "tif", "x3f"
}
Utils.rawExtensionsSet = toSet(Utils.rawExtensionsArray)

-- https://helpx.adobe.com/lightroom-classic/kb/video-support-lightroom.html
Utils.videoExtensionsArray = { "3gp", "3gpp", "avi", "m2t", "m2ts", "m4v", "mov", "mp4", "mpe", "mpg", "mts" }
Utils.videoExtensionsSet = toSet(Utils.videoExtensionsArray)


function Utils.isDisplayJpeg(filePath)
    return filePath:lower():match("_display%.jpg$") ~= nil or filePath:lower():match("_display%.jpeg$") ~= nil
end

function Utils.isDngExtension(extension)
    return extension:lower() == Utils.dngExtension
end

function Utils.isJpegExtension(extension)
    return Utils.jpegExtensionsSet[extension:lower()] ~= nil
end

function Utils.isRawExtension(extension)
    return Utils.rawExtensionsSet[extension:lower()] ~= nil
end

function Utils.isVideoExtension(extension)
    return Utils.videoExtensionsSet[extension:lower()] ~= nil
end

--- Returns base path and extension of the a path.
--
-- Assumes that the path is a file path, not a directory path.
--
-- @tparam string filePath file path
-- @tretrun string base path
-- @tretrun string|nil extension
function Utils.getBaseFilePathAndExtension(filePath)
    local pos = filePath:find("%.[^/\\.]+$")
    if pos == nil then
        return filePath, nil
    else
        local baseFilePath = filePath:sub(1, pos - 1)
        local extension = filePath:sub(pos + 1)

        if #baseFilePath == 0 then
            return filePath, nil
        else
            local beforeDot = baseFilePath:sub(-1)
            if beforeDot == "/" or beforeDot == "\\" then
                -- Special files, e.g., .MYLock
                return filePath, nil
            end
        end

        return baseFilePath, extension
    end
end

--- Tells whether a file should never be imported.
--
-- @tparam string filePath file path
-- @treturn bool true if the file should never be imported
function Utils.shouldNeverImport(extension)
    local ext = extension:lower()
    if ext == "gif" or ext == "xml" or ext == "xmp" or ext == "webp" then
        return true
    elseif ext:sub(1, 5) == "mylio" then
        return true
    end

    return false
end

return Utils
