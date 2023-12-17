local LrHttp = import "LrHttp"

return {
    sectionsForTopOfDialog = function(f, _)
        return {
            {
                title = LOC "$$$/KoalaToolkit/PluginManager=About",
                f:row {
                    f:static_text {
                        title = LOC "$$$/KoalaToolkit/Title1=Lightroom Classic utilities to better manage (not only koala) photos.",
                        fill_horizontal = 1,
                    },
                },
                f:row {
                    spacing = f:control_spacing(),
                    f:push_button {
                        width = 100,
                        title = LOC "$$$/KoalaToolkit/ButtonTitle=More Info...",
                        enabled = true,
                        action = function()
                            LrHttp.openUrlInBrowser("https://github.com/LajosCseppento/koala-toolkit-lightroom")
                        end,
                    },
                    f:push_button {
                        width = 120,
                        title = LOC "$$$/KoalaToolkit/ButtonTitle=Report an Issue...",
                        enabled = true,
                        action = function()
                            LrHttp.openUrlInBrowser("https://github.com/LajosCseppento/koala-toolkit-lightroom/issues")
                        end,
                    },
                },
            },
        }
    end,
}
