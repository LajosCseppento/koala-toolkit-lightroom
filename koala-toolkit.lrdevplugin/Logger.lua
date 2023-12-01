--------------------------------------------------------------------------------
-- Set logging options here ----------------------------------------------------
--------------------------------------------------------------------------------

local Logger = {}
Logger.traceEnabled = false -- true or false (true is useful for troubleshooting, but it can slow down the plugin)
Logger.debugEnabled = true  -- true or false (true is useful for troubleshooting, but it can slow down the plugin)
Logger.infoEnabled = true   -- true or false
Logger.target = "print"     -- nil, "print" or "logfile"

--------------------------------------------------------------------------------
-- Do not change below ---------------------------------------------------------
--------------------------------------------------------------------------------

-- This is an LRC logger wrapper with quick access to log level settings.

if Logger.traceEnabled then
    Logger.debugEnabled = true
    Logger.infoEnabled = true
elseif Logger.debugEnabled then
    Logger.infoEnabled = true
end

local LrLogger = import "LrLogger"
Logger.delegate = LrLogger("KoalaToolkit")
if Logger.target then
    Logger.delegate:enable(Logger.target)
end

function Logger.trace(...)
    if Logger.traceEnabled then
        Logger.delegate:trace(...)
    end
end

function Logger.tracef(format, ...)
    if Logger.traceEnabled then
        Logger.delegate:tracef(format, ...)
    end
end

function Logger.debug(...)
    if Logger.debugEnabled then
        Logger.delegate:debug(...)
    end
end

function Logger.debugf(format, ...)
    if Logger.debugEnabled then
        Logger.delegate:debugf(format, ...)
    end
end

function Logger.info(...)
    if Logger.infoEnabled then
        Logger.delegate:info(...)
    end
end

function Logger.infof(format, ...)
    if Logger.infoEnabled then
        Logger.delegate:infof(format, ...)
    end
end

function Logger.warn(...)
    Logger.delegate:warn(...)
end

function Logger.warnf(format, ...)
    Logger.delegate:warnf(format, ...)
end

function Logger.error(...)
    Logger.delegate:error(...)
end

function Logger.errorf(format, ...)
    Logger.delegate:errorf(format, ...)
end

function Logger.fatal(...)
    Logger.delegate:fatal(...)
end

function Logger.fatalf(format, ...)
    Logger.delegate:fatal(format, ...)
end

return Logger
