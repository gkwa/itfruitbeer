import dataclasses
import pathlib

import md_toc

from . import main2

__project_name__ = "itfruitbeer"


@dataclasses.dataclass
class Script:
    outfile: str
    tmpl: str


def main() -> int:
    rendered = main2.render_template("readme/readme.md.j2")
    outfile = pathlib.Path("README.md")
    outfile.write_text(rendered)
    toc = md_toc.build_toc(outfile)
    md_toc.write_string_on_file_between_markers(outfile, toc, "<!--TOC-->")

    scripts = [
        Script(outfile="incus.sh", tmpl="install-incus/script.sh.j2"),
        Script(outfile="script01.sh", tmpl="script01/script.sh.j2"),
        Script(outfile="script02.sh", tmpl="script02/script.sh.j2"),
        Script(outfile="script03.sh", tmpl="script03/script.sh.j2"),
    ]

    for script in scripts:
        rendered = main2.render_template(script.tmpl)
        outfile = pathlib.Path(script.outfile)
        outfile.write_text(rendered)
        if outfile.suffix == ".sh":
            outfile.chmod(0o755)

    return 0
