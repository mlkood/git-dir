# git-dir

`git-dir` is a small helper that clones a Git repository **partially** using
Git’s **sparse-checkout**, while generating a **descriptive working directory name**
based on included and excluded paths.

It supports:

- multiple include paths
- per-include excludes (`!path`)
- deterministic, human-readable directory names
- symlinks for deep subdirectories
- safe re-runs (no nested clones)
- `--dry-run` and `--help`
- Fish **and** Bash

This is **not** a Git wrapper.  
It uses standard Git features (`sparse-checkout`, `blob:none`) correctly.

---

## What problem this solves

Normally:

bash
git clone https://github.com/user/repo.git

You get everything.

With git-dir, you can do:

git-dir "docs !docs/assets resources/logo !resources/logo/print" \
  https://github.com/user/repo.git

And get only what you want, with a directory name that tells you exactly
what was included and excluded.
Resulting directory structure

Command:

git-dir "docs !docs/assets resources/logo !resources/logo/print" REPO_URL

Creates:

repo_docs_(no assets)_resources-logo_(no print)/
├── docs/
│   └── (assets excluded)
├── resources/
│   └── logo/
│       └── (print excluded)
└── logo -> resources/logo

Notes:

    docs/assets is not present

    resources/logo/print is not present

    logo is a symlink for convenience

    .git is normal and fully functional

    git pull works as expected

Installation
Fish

Copy the Fish version into:

~/.config/fish/functions/git-dir.fish

Reload:

functions -e git-dir
source ~/.config/fish/functions/git-dir.fish

Bash

Save the Bash version as:

~/bin/git-dir

Make executable:

chmod +x ~/bin/git-dir

Ensure ~/bin is in your $PATH.
Usage

git-dir [--dry-run] "<includes !excludes>" <repo-url>

Includes

Paths to include in the working tree.
Excludes

Paths prefixed with ! are excluded only under their matching include.
Examples
Simple include

git-dir "docs" https://github.com/user/repo.git

Directory:

repo_docs/

Include + exclude

git-dir "docs !docs/assets" REPO_URL

Directory:

repo_docs_(no assets)/

Multiple includes and excludes

git-dir "docs !docs/assets resources/logo !resources/logo/print" REPO_URL

Directory:

repo_docs_(no assets)_resources-logo_(no print)/

Dry run

Preview without cloning or writing anything:

git-dir --dry-run "docs !docs/assets resources/logo !resources/logo/print" REPO_URL

Output example:

[DRY-RUN]
Repo:        repo
Workdir:     /path/repo_docs_(no assets)_resources-logo_(no print)
Includes:    docs resources/logo
Excludes:    docs/assets resources/logo/print
Sparse-set:  docs !docs/assets resources/logo !resources/logo/print
Clone:       SKIP
Checkout:    SKIP

Help

git-dir --help

Shows usage, rules, and naming examples.
Naming rules (important)

    Each include becomes one name segment

    Excludes are grouped under the include they belong to

    (no …) is added only if excludes exist

    Order is stable and deterministic

    Trailing spaces and duplicate paths are handled safely

Example:

example-repo_docs_(no assets)_resources-logo_(no print)

Notes and limitations

    This uses git sparse-checkout --no-cone (required for exclusions)

    Excluded paths are not downloaded at all

    Do not commit through symlinks — edit the real paths

    Directory names may contain spaces and parentheses
