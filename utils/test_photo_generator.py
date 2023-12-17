"""Test photo generator"""
import os
import shutil

from PIL import Image, ImageColor


def generate_photo(target_dir: str, width: int, height: int, color: str):
    """Generates a test photo (both JPEG and display JPEG).

    Args:
        target_dir (str): Target directory
        width (int): Width
        height (int): Height
        color (str): Color (known to PIL, e.g. "red")
    """
    image = Image.new("RGB", (width, height), color)

    os.makedirs(target_dir, exist_ok=True)

    image.save(os.path.join(target_dir, f"{color}.jpg"), "JPEG")
    # Copy file to make sure it has the same metadata
    shutil.copy(
        os.path.join(target_dir, f"{color}.jpg"),
        os.path.join(target_dir, f"{color}_display.jpg"),
    )


def generate_test_photos():
    """Generates test photos."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    photos_dir = os.path.abspath(os.path.join(script_dir, "..", "TestPhotos"))

    print(f"Deleting contents of {photos_dir} ...")
    if os.path.exists(photos_dir):
        for file in os.listdir(photos_dir):
            os.remove(os.path.join(photos_dir, file))

    subdirs = [
        "01",
        os.path.join("01", "a"),
        os.path.join("01", "b"),
        os.path.join("01", "c"),
        "02",
        os.path.join("03", "a"),
        os.path.join("03", "b"),
        os.path.join("03", "c"),
        os.path.join("03", "c", "x"),
        os.path.join("03", "c", "y"),
    ]
    i = 1
    for color in sorted(ImageColor.colormap.keys()):
        target_dir = os.path.join(photos_dir, subdirs[i % len(subdirs)])
        print(f"Generating {target_dir} - {color} ...")
        generate_photo(target_dir, 800, 800, color)
        i += 1

    print("Done")


if __name__ == "__main__":
    generate_test_photos()
