import pathlib

import md_toc

from . import main2

__project_name__ = "itfruitbeer"


def main() -> int:
    out = main2.render_template("readme/readme.md.j2")
    outfile = pathlib.Path("README.md")
    outfile.write_text(out)
    toc = md_toc.build_toc(outfile)
    md_toc.write_string_on_file_between_markers(outfile, toc, "<!--TOC-->")

    scripts = {
        "readme/script01.sh.j2": {
            "outfile": "script01.sh",
        },
        "readme/script02.sh.j2": {
            "outfile": "script02.sh",
        },
        "readme/script03.sh.j2": {
            "outfile": "script03.sh",
        },
    }

    for script, config in scripts.items():
        out = main2.render_template(script)
        outfile = pathlib.Path(config["outfile"])
        outfile.write_text(out)
        outfile.chmod(0o775)

    return 0
