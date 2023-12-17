return {

    LrSdkVersion = 13.0,
    LrSdkMinimumVersion = 13.0,

    LrToolkitIdentifier = "dev.lajoscseppento.koala-toolkit-lightroom",

    LrPluginName = LOC "$$$/SmartImport/PluginName=Koala Toolkit",
    LrPluginInfoUrl = "https://github.com/LajosCseppento/koala-toolkit-lightroom",

    LrLibraryMenuItems = {
        {
            title = "Run Smart Import",
            file = "RunSmartImportMenuItem.lua",
        },
        {
            title = "Run Smart Import (do not build smart previews)",
            file = "RunSmartImportNoSmartPreviewsMenuItem.lua",
        },
        {
            title = "Build All Smart Previews",
            file = "BuildAllSmartPreviewsImportMenuItem.lua",
        },
    },

    LrPluginInfoProvider = "PluginInfoProvider.lua",

    VERSION = { major = 1, minor = 0, revision = 0, build = 0, },

}
