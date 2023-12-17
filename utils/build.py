"""Builds the plugin package."""
import os
import re
import shutil
import subprocess


def extract_version(plugin_dir: str) -> str:
    """Extracts plugin version.

    Args:
        plugin_dir (str): Path to plugin directory
    """

    lua_code = """
    -- Placeholder for a Lightroom SDK function.
    function LOC(param)
      return param
    end

    local info = require("Info")
    print(
        info.VERSION.major .. "." ..
        info.VERSION.minor .. "." ..
        info.VERSION.revision .. "." ..
        info.VERSION.build
    )
    """

    extractor_script = os.path.join(plugin_dir, "_ExtractVersion.tmp.lua")
    with open(
        os.path.join(plugin_dir, extractor_script), "w", encoding="utf-8"
    ) as file:
        file.write(lua_code)

    try:
        version = subprocess.check_output(
            [
                "lua",
                extractor_script,
            ],
            cwd=plugin_dir,
        ).decode("utf-8")
        os.remove(extractor_script)
        return version.strip()
    except Exception as e:
        print("Failed to extract plugin version")
        raise e


def finalise_logger_configuration(logger_lua: str):
    """Finalise logger configuration.

    Args:
        logger_lua (str): Path to Logger.lua
    """
    print("Finalising logger configuration...")
    with open(logger_lua, "r", encoding="utf-8") as file:
        content = file.read()

    replacement_dict = {
        r"^Logger.traceEnabled\s*=.*$": "Logger.traceEnabled = false",
        r"^Logger.debugEnabled\s*=.*$": "Logger.debugEnabled = false",
        r"^Logger.infoEnabled\s*=.*$": "Logger.infoEnabled = true",
        r"^Logger.target\s*=.+$": "Logger.target = nil",
    }

    for pattern, replacement in replacement_dict.items():
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

    with open(logger_lua, "w", encoding="utf-8") as file:
        file.write(content)


def build():
    """Builds the plugin package."""

    print("Building plugin package...")

    script_dir = os.path.dirname(os.path.abspath(__file__))
    plugin_dir = os.path.abspath(
        os.path.join(script_dir, "..", "koala-toolkit.lrdevplugin")
    )
    build_dir = os.path.abspath(os.path.join(script_dir, "..", "build"))

    print(f"Extracting version from {plugin_dir} ...")
    version = extract_version(plugin_dir)
    print(f"Version: {version}")

    os.makedirs(build_dir, exist_ok=True)
    build_tmp_dir = os.path.join(build_dir, "tmp")
    build_tmp_plugin_dir = os.path.join(build_tmp_dir, "koala-toolkit.lrplugin")

    if os.path.exists(build_tmp_dir):
        print(f"Deleting contents of {build_tmp_dir} ...")
        shutil.rmtree(build_tmp_dir)

    print(f"Copying plugin to {build_tmp_plugin_dir} ...")
    shutil.copytree(plugin_dir, build_tmp_plugin_dir)

    logger_lua = os.path.join(build_tmp_plugin_dir, "Logger.lua")
    finalise_logger_configuration(logger_lua)

    # Zip directory
    print(f"Zipping plugin to {build_dir} ...")
    target_base_name = os.path.join(build_dir, f"koala-toolkit-{version}")
    target = shutil.make_archive(target_base_name, "zip", build_tmp_dir)

    print(f"Cleaning up {build_tmp_dir} ...")
    shutil.rmtree(build_tmp_dir)

    print(f"Done: {target}")


if __name__ == "__main__":
    build()
