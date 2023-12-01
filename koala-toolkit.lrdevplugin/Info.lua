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
        }
    },

    LrPluginInfoProvider = "PluginInfoProvider.lua",

    VERSION = { major = 0, minor = 1, revision = 0, build = 0, },

}
