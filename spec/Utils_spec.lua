---@diagnostic disable: undefined-field, undefined-global
package.path = "koala-toolkit.lrdevplugin/?.lua;" .. package.path
Utils = require("Utils")

--- Declares parameterised test cases for describe(...).
--
-- @tparam table testCases test cases (table of arrays)
-- @tparam function callback callback function, argument is a test case array
-- @treturn function function that can be passed to describe(...)
local function declareTestCases(testCases, callback)
    -- describe(...) should receive a function, not immediately running the tests
    -- (Otherwise it works, but the last level of the hierarchy is missing.)
    return function()
        for _, args in ipairs(testCases) do
            local name = type(args) == "table" and args[1] or args

            -- Declare test case
            it(
                name,
                function() callback(args) end
            )
        end
    end
end

local function checkGetBaseFilePathAndExtension(filePath, expectedBaseFilePath, expectedExtension)
    local baseFilePath, extension = Utils.getBaseFilePathAndExtension(filePath)
    assert.are.equal(expectedBaseFilePath, baseFilePath)
    assert.are.equal(expectedExtension, extension)
end

describe("Utils", function()
    describe("isDisplayJpeg", function()
        describe("Not *_display.jpg", declareTestCases(
            {
                "IMG_1234.jpg",
                "E:\\IMG_1234.jpg",
                "E:\\Photos\\IMG_1234.arw",
                "/IMG_1234.jpg",
                "/Photos/IMG_1234.arw",
            },
            function(path)
                assert.False(Utils.isDisplayJpeg(path))
            end
        ))

        describe("Is *_display.jpg", declareTestCases(
            {
                "IMG_1234_display.jpg",
                "E:\\IMG_1234_display.jpg",
                "E:\\Photos\\IMG_1234_display.jpeg",
                "/IMG_1234_display.jpg",
                "/Photos/IMG_1234_display.jpeg",
            },
            function(path)
                assert.True(Utils.isDisplayJpeg(path))
            end
        ))
    end)

    describe("isJpegExtension", function()
        describe("Not JPEG", declareTestCases(
            { "dng", "ARW", "OrF" },
            function(path)
                assert.False(Utils.isJpegExtension(path))
            end
        ))

        describe("Is JPEG", declareTestCases(
            { "jpg", "JPEG", "jPeG" },
            function(path)
                assert.True(Utils.isJpegExtension(path))
            end
        ))
    end)

    describe("isDngExtension", function()
        describe("Not DNG", declareTestCases(
            { "jpg", "ARW", "OrF" },
            function(path)
                assert.False(Utils.isDngExtension(path))
            end
        ))

        describe("Is DNG", declareTestCases(
            { "dng", "DNG", "DnG" },
            function(path)
                assert.True(Utils.isDngExtension(path))
            end
        ))
    end)

    describe("isRawExtension", function()
        describe("Not raw", declareTestCases(
            { "jpg", "MOV", "Mp4" },
            function(path)
                assert.False(Utils.isRawExtension(path))
            end
        ))

        describe("Is raw", declareTestCases(
            { "arw", "ARW", "OrF" },
            function(path)
                assert.True(Utils.isRawExtension(path))
            end
        ))
    end)

    describe("isVideoExtension", function()
        describe("Not video", declareTestCases(
            { "jpg", "ARW", "OrF" },
            function(path)
                assert.False(Utils.isVideoExtension(path))
            end
        ))

        describe("Is video", declareTestCases(
            { "avi", "MOV", "Mp4" },
            function(path)
                assert.True(Utils.isVideoExtension(path))
            end
        ))
    end)

    describe("getBaseFilePathAndExtension", function()
        describe("No extension", declareTestCases(
            {
                "",
                ".",
                ".tricky",
                ".tricky.",
                "tricky.",
                "IMG_1234",
                "IMG_1234.",
                "E:\\Photos\\IMG_1234",
                "E:\\Photos\\IMG_1234.",
                "E:\\Photos\\IMG_1234.tricky.",
                "E:\\Photos\\.tricky",
                "/Photos/IMG_1234",
                "/Photos/IMG_1234.",
                "/Photos/IMG_1234.tricky.",
                "/Photos/.tricky",
            },
            function(path)
                checkGetBaseFilePathAndExtension(path, path, nil)
            end
        ))


        describe("Has extension", declareTestCases(
            {
                { "IMG_1234.jpg",                     "IMG_1234",                     "jpg" },
                { "E:\\Photos\\IMG_1234.jpg",         "E:\\Photos\\IMG_1234",         "jpg" },
                { "E:\\Photos\\IMG_1234.tricky.arw",  "E:\\Photos\\IMG_1234.tricky",  "arw" },
                { "E:\\Photos\\.IMG_1234.jpg",        "E:\\Photos\\.IMG_1234",        "jpg" },
                { "E:\\Photos\\.IMG_1234.tricky.arw", "E:\\Photos\\.IMG_1234.tricky", "arw" },
                { "/IMG_1234.jpg",                    "/IMG_1234",                    "jpg" },
                { "/Photos/IMG_1234.jpg",             "/Photos/IMG_1234",             "jpg" },
                { "/Photos/IMG_1234.tricky.arw",      "/Photos/IMG_1234.tricky",      "arw" },
                { "/Photos/.IMG_1234.jpg",            "/Photos/.IMG_1234",            "jpg" },
                { "/Photos/.IMG_1234.tricky.arw",     "/Photos/.IMG_1234.tricky",     "arw" },
            },
            function(args)
                checkGetBaseFilePathAndExtension(args[1], args[2], args[3])
            end
        ))
    end)

    describe("shouldNeverImport", function()
        describe("Never import", declareTestCases(
            { "gif", "XmL", "XMP", "MyLiObAk" },
            function(extension)
                assert.True(Utils.shouldNeverImport(extension))
            end
        ))

        describe("Might import", declareTestCases(
            { "jpg", "jPeG", "arW", "OrF", "Mp4" },
            function(extension)
                assert.False(Utils.shouldNeverImport(extension))
            end
        ))
    end)
end)
