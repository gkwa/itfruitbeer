import pathlib

import md_toc

from . import main2

__project_name__ = "itfruitbeer"


def main() -> int:
    out = main2.render_template("readme/readme.md.j2")
    readme = pathlib.Path("README.md")
    readme.write_text(out)
    toc = md_toc.build_toc(readme)
    md_toc.write_string_on_file_between_markers(readme, toc, "<!--TOC-->")

    return 0
