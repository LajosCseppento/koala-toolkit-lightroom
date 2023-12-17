local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrTasks = import "LrTasks"

local ProgressReporter = require("ProgressReporter")
local Logger = require("Logger")

LrTasks.startAsyncTask(function()
    local lrCatalog = LrApplication.activeCatalog()

    -- Ask for access early when the user triggers the action in case file system scanning takes a long time
    Logger.info("Requesting prolonged write access")
    lrCatalog:withProlongedWriteAccessDo({
        title = "Build All Smart Previews",
        caption = "Building smart previews...",
        pluginName = "Koala Toolkit",
        optionalMessage = "If you proceed, the plugin build smart previews for all photos.",
        func = function(_, lrProgressScope)
            lrProgressScope:setIndeterminate()
            LrTasks.yield() -- Allow the progress dialog to show up

            Logger.info("Building all smart previews")

            local allPhotos = lrCatalog:getAllPhotos()
            local total = #allPhotos
            local progressReporter = ProgressReporter:new(lrProgressScope, function(progress)
                return string.format(
                    "Building smart previews... (%d/%d)",
                    progress, total
                )
            end)

            for _, lrPhoto in ipairs(allPhotos) do
                if not lrPhoto:getRawMetadata("smartPreviewInfo") then
                    lrPhoto:buildSmartPreview()
                end

                progressReporter:incrementProgress()
                if progressReporter:reportProgress() then
                    return {}
                end
            end

            local msg = "Built all smart previews"
            Logger.info(msg)
            LrDialogs.message("Koala Toolkit", msg, "info")
        end,
    })
end)
