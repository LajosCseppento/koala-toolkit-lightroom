local LrTasks = import "LrTasks"

local ProgressReporter = {
    -- Do not yield or do anything, otherwise LRC will get really slow.
    minimumReportIntervalSeconds = 1,
    -- Do not check the elapsed time too often
    minimumReportProgressChange = 100,
    -- Will only report if both the interval and progress change are met.
}

--- Creates a new ProgressReporter.
--
-- Call reportProgress() to report progress if the minimum time and minimum progress elapsed.
-- Use ProgressReporter to avoid calling LrTasks.yield() and LrProgressScope methods too often.
--
-- @tparam LrProgressScope lrProgressScope
-- @tparam function buildCaptionFunction takes one argument, the progress, and returns a string
-- @treturn ProgressReporter
function ProgressReporter:new(lrProgressScope, buildCaptionFunction)
    local object = {
        _progress = 0,
        _lastReportTime = nil, -- Clock time, not epoch
        _lrProgressScope = lrProgressScope,
        _buildCaptionFunction = buildCaptionFunction,
    }
    setmetatable(object, self)
    self.__index = self
    object:reportProgress()
    return object
end

function ProgressReporter:getProgress()
    return self._progress
end

function ProgressReporter:incrementProgress()
    self._progress = self._progress + 1
end

function ProgressReporter:_doReportProgress()
    if self._buildCaptionFunction ~= nil then
        local caption = self._buildCaptionFunction(self._progress)
        self._lrProgressScope:setCaption(caption)
    end

    LrTasks.yield()
    return self._lrProgressScope:isCanceled()
end

--- Reports progress, regardless of the minimum time and minimum progress elapsed.
--
-- @treturn bool true if the task was cancelled, false otherwise
function ProgressReporter:forceReportProgress()
    self._lastReportTime = os.clock()
    return self:_doReportProgress()
end

--- Reports progress if the minimum time and minimum progress elapsed.
--
-- @tretrun bool true if the task was cancelled, false otherwise
function ProgressReporter:reportProgress()
    if self._lastReportTime == nil then
        return self:forceReportProgress()
    elseif self._progress % self.minimumReportProgressChange ~= 0 then
        return false
    end

    local now = os.clock()
    if now - self._lastReportTime < self.minimumReportIntervalSeconds then
        return false
    end

    self._lastReportTime = now
    return self:_doReportProgress()
end

return ProgressReporter
