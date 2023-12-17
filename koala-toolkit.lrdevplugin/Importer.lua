local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrFileUtils = import "LrFileUtils"
local LrTasks = import "LrTasks"

local ProgressReporter = require("ProgressReporter")
local Logger = require("Logger")
local Utils = require("Utils")

local Importer = {}
Importer.buildSmartPreviews = true

--- Truncates path to a maximum length, substitues the beginning with "..." if needed.
--
-- @tparam string path path to truncate
-- @tparam int maxLength maximum length of the path (including "..." when truncated)
-- @treturn string truncated path
local function truncatePath(path, maxLength)
    if #path > maxLength then
        local truncated = path.sub(path, -(maxLength - 3))
        local separatorPosition = truncated.find(truncated, "[/\\]")
        if separatorPosition ~= nil then
            truncated = truncated.sub(truncated, separatorPosition)
        end

        return "..." .. truncated
    else
        return path
    end
end

--------------------------------------------------------------------------------
-- Scan ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- Collects base file paths with all extensions in a folder.
--
-- Skips trivial files and display JPEGs.
--
-- @tparam string folderPath folder path
-- @tparam LrProgressScope lrProgressScope progress scope
-- @treturn table a table where keys are base file paths and values are sets of extensions
local function collectBaseFilePathsToExtensions(folderPath, lrProgressScope)
    if lrProgressScope:isCanceled() then
        return {}
    end

    local progressReporter = ProgressReporter:new(lrProgressScope, function(progress)
        return string.format("Located %d files in %s", progress, truncatePath(folderPath, 30))
    end)
    local baseFilePathsToExtensions = {}

    for filePath in LrFileUtils.recursiveFiles(folderPath) do
        if Utils.isDisplayJpeg(filePath) then
            Logger.tracef("[Importer/collectBaseFilePathsToExtensions] Skipping %s (display JPEG)", filePath)
        else
            local baseFilePath, extension = Utils.getBaseFilePathAndExtension(filePath)

            if extension == nil then
                Logger.tracef("[Importer/collectBaseFilePathsToExtensions] Skipping %s (no extension)", filePath)
            elseif Utils.shouldNeverImport(extension) then
                Logger.tracef("[Importer/collectBaseFilePathsToExtensions] Skipping %s (should never import)", filePath)
            else
                Logger.tracef("[Importer/collectBaseFilePathsToExtensions] Marking %s", filePath)
                if not baseFilePathsToExtensions[baseFilePath] then
                    baseFilePathsToExtensions[baseFilePath] = {}
                end
                baseFilePathsToExtensions[baseFilePath][extension] = true
            end
        end

        progressReporter:incrementProgress()
        if progressReporter:reportProgress() then
            return {}
        end
    end

    return baseFilePathsToExtensions
end

--- Collects importable file paths from base file paths with all extensions.
--
-- Skips JPEGs if there is a DNG or RAW file with the same base file path.
--
-- @tparam table baseFilePathsToExtensions a table where keys are base file paths and values are sets of extensions
-- @tparam string folderPath folder path
-- @tparam LrProgressScope lrProgressScope progress scope
-- @treturn table an array of importable paths
local function collectImportableFilePaths(baseFilePathsToExtensions, folderPath, lrProgressScope)
    if lrProgressScope:isCanceled() then
        return {}
    end

    local total = Utils.tableLength(baseFilePathsToExtensions)
    local progressReporter = ProgressReporter:new(lrProgressScope, function(progress)
        return string.format(
            "Checking files in %s ... (%d/%d)",
            truncatePath(folderPath, 30), progress, total
        )
    end)
    local importablePaths = {}

    for baseFilePath, extensions in pairs(baseFilePathsToExtensions) do
        -- Keep copy to avoid changing the original table
        local importableExtensionsSet = {}
        local hasRaw = false
        -- It can have .jpg and .jpeg too
        -- Plus, it is case sensitive, so simply removing .jpg and .jpeg would not work
        local jpegExtensionsArray = {}
        for extension, _ in pairs(extensions) do
            Logger.tracef("[Importer/collectImportablePaths] Checking %s.%s", baseFilePath, extension)
            importableExtensionsSet[extension] = true

            if Utils.isDngExtension(extension) or Utils.isRawExtension(extension) then
                hasRaw = true
            elseif Utils.isJpegExtension(extension) then
                table.insert(jpegExtensionsArray, extension)
            end
        end

        if hasRaw then
            for _, jpegExtension in ipairs(jpegExtensionsArray) do
                Logger.tracef("[Importer/collectImportablePaths] Skipping %s.%s (has DNG or RAW)", baseFilePath)
                importableExtensionsSet[jpegExtension] = nil
            end
        end

        for extension, _ in pairs(importableExtensionsSet) do
            local path = baseFilePath .. "." .. extension
            Logger.tracef("[Importer/collectImportablePaths] Marking %s", path)
            table.insert(importablePaths, path)
        end

        progressReporter:incrementProgress()
        if progressReporter:reportProgress() then
            return {}
        end
    end

    return importablePaths
end

--- Scans a folder and returns paths to import.
--
-- @tparam string folderPath folder path
-- @tparam LrProgressScope lrProgressScope progress scope
-- @treturn table an array of paths to import
local function scanFolder(folderPath, lrProgressScope)
    if lrProgressScope:isCanceled() then
        return {}
    end

    Logger.debugf("[Importer/scanFolder] Collecting base paths with all extensions in %s ...", folderPath)
    local baseFilePathsToExtensions = collectBaseFilePathsToExtensions(folderPath, lrProgressScope)

    Logger.debugf("[Importer/scanFolder] Determining importable files in %s ...", folderPath)
    local importableFilePaths = collectImportableFilePaths(baseFilePathsToExtensions, folderPath, lrProgressScope)
    Logger.debugf("[Importer/scanFolder] Found %d importable files in %s", #importableFilePaths, folderPath)

    return importableFilePaths
end

--- Collects paths to import from importable paths (filters out what is already in catalog).
--
-- Note: I found two options to match file system files against the LRC catalog. One is to loop through each path and
-- ask the catalog for the corresponding object (LrCatalog:findPhotoByPath). Other is to get all objects from the
-- catalog and loop through them, asking for their path (LrPhoto:getRawMetadata("path")).
--
-- The performance was quite different, but none of them are fast (fast NVMe SSD):
-- - LrCatalog:findPhotoByPath for 48370 paths: 52.844 seconds
-- - LrPhoto:getRawMetadata("path") for 42124 photos: 27.28 seconds
--
-- @tparam table importablePaths an array of importable paths
-- @tparam LrCatalog lrCatalog catalog
-- @tparam LrProgressScope lrProgressScope progress scope
-- @treturn table an array of paths to import
local function collectPathsToImport(importablePaths, lrCatalog, lrProgressScope)
    if lrProgressScope:isCanceled() then
        return {}
    end

    -- Fetch photos with paths
    Logger.infof("Analyising catalog ...")
    lrProgressScope:setCaption("Analysing catalog ...")
    LrTasks.yield()

    local allPhotos = lrCatalog:getAllPhotos() -- This is relatively fast
    local total = #allPhotos
    local progressReporter = ProgressReporter:new(lrProgressScope, function(progress)
        return string.format(
            "Analysing catalog... (%d/%d)",
            progress, total
        )
    end)
    local allPaths = {}

    for _, lrPhoto in ipairs(allPhotos) do
        allPaths[lrPhoto:getRawMetadata("path")] = true

        progressReporter:incrementProgress()
        if progressReporter:reportProgress() then
            return {}
        end
    end

    -- Match against importable paths
    local pathsToImport = {}

    for _, path in ipairs(importablePaths) do
        if allPaths[path] == nil then
            Logger.tracef("[Importer/collectPathsToImport] Marking %s", path)
            table.insert(pathsToImport, path)
        else
            Logger.tracef("[Importer/collectPathsToImport] Skipping %s (already in catalog)", path)
        end
    end

    return pathsToImport
end


--- Scans all folders in a catalog and returns paths to import.
--
-- @tparam LrCatalog lrCatalog catalog
-- @tparam LrProgressScope lrProgressScope progress scope
-- @treturn table an array of paths to import
local function scanFolders(lrCatalog, lrProgressScope)
    if lrProgressScope:isCanceled() then
        return {}
    end

    local allImportableFilePaths = {}

    for _, lrFolder in ipairs(lrCatalog:getFolders()) do
        local folderPath = lrFolder:getPath()

        Logger.infof("Scanning %s ...", folderPath)
        lrProgressScope:setCaption("Scanning " .. truncatePath(folderPath, 40))
        LrTasks.yield()

        local importableFilePaths = scanFolder(folderPath, lrProgressScope)
        for _, path in ipairs(importableFilePaths) do
            table.insert(allImportableFilePaths, path)
        end

        LrTasks.yield()
        if lrProgressScope:isCanceled() then
            return {}
        end
    end

    table.sort(allImportableFilePaths)

    Logger.debugf("[Importer/scanFolders] Selecting files to import ... (ignore what is already in catalog)")
    local allPathsToImport = collectPathsToImport(allImportableFilePaths, lrCatalog, lrProgressScope)
    Logger.debugf("[Importer/scanFolders] Selected %d files to import", allPathsToImport)

    return allPathsToImport
end

--------------------------------------------------------------------------------
-- Import ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--- Imports files from all folders in a catalog.
--
-- @tparam LrCatalog lrCatalog catalog
-- @tparam LrProgressScope lrProgressScope progress scope
local function smartImport(lrCatalog, lrProgressScope)
    -- Determine what to import
    Logger.info("Running Smart Import...")
    local pathsToImport = scanFolders(lrCatalog, lrProgressScope)

    if lrProgressScope:isCanceled() then
        local msg = "Operation cancelled, no files were imported"
        Logger.info(msg)
        LrDialogs.message("Koala Toolkit", msg, "info");
        return
    end

    local pathsToImportCount = #pathsToImport

    if pathsToImportCount == 0 then
        local msg = "No files to import"
        Logger.info(msg)
        LrDialogs.message("Koala Toolkit", msg, "info");
        return
    end

    Logger.infof("Importing %d files", pathsToImport)
    lrProgressScope:setCaption("Importing...")
    LrTasks.yield()

    local lrImportCollection = lrCatalog:createCollection("Previous Smart Import", nil, true)
    lrImportCollection:removeAllPhotos()

    lrProgressScope:setPortionComplete(0, pathsToImportCount)
    LrTasks.yield()
    local successCount = 0
    local failedCount = 0

    for i, path in ipairs(pathsToImport) do
        Logger.infof("Importing %s (%d/%d)", path, i, pathsToImportCount)
        lrProgressScope:setCaption("Importing " .. truncatePath(path, 40))

        -- This is slow and did not find a way to parallelize it
        -- Even if wrapped as async task, LRC imports one by one
        local success, lrPhoto = LrTasks.pcall(function()
            return lrCatalog:addPhoto(path)
        end)

        if success then
            successCount = successCount + 1

            -- Always add immediately in case the user cancels later
            lrImportCollection:addPhotos({ lrPhoto })

            if Importer.buildSmartPreviews then
                -- This can already go in parallel
                LrTasks.startAsyncTask(function()
                    Logger.infof("Triggering smart preview build for %s", path)
                    lrCatalog:buildSmartPreviews({ lrPhoto })
                end)
            end
        else
            failedCount = failedCount + 1
            Logger.warnf("Failed to import %s: %s", path, lrPhoto)
        end

        lrProgressScope:setPortionComplete(i, pathsToImportCount)
        LrTasks.yield()
        if lrProgressScope:isCanceled() then
            local msg = string.format("Operation canceled (%d/%d)", i, pathsToImportCount)
            Logger.infof(msg)
            LrDialogs.message("Koala Toolkit", msg, "info");
            return
        end
    end

    if not lrProgressScope:isCanceled() then
        local msg = string.format("Imported %d files", successCount)
        if failedCount > 0 then
            -- Reason might be unsupported format, deleted in the meantime, etc.
            msg = msg .. string.format("  (could not import %d files)", failedCount)
        end

        Logger.info(msg)
        LrDialogs.message("Koala Toolkit", msg, "info");
    end

    lrCatalog:setActiveSources({ lrImportCollection })
    LrTasks.yield()
end

function Importer.run()
    LrTasks.startAsyncTask(function()
        local lrCatalog = LrApplication.activeCatalog()

        -- Ask for access early when the user triggers the action in case file system scanning takes a long time
        Logger.info("Requesting prolonged write access")
        lrCatalog:withProlongedWriteAccessDo({
            title = "Smart Import",
            caption = "Scanning...",
            pluginName = "Koala Toolkit",
            optionalMessage = "If you proceed, the plugin will re-import all photos from all folders in your catalog.",
            func = function(_, lrProgressScope)
                lrProgressScope:setIndeterminate()
                LrTasks.yield() -- Allow the progress dialog to show up
                smartImport(lrCatalog, lrProgressScope)
            end,
        })
    end)
end

return Importer
