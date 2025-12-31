function git-dir
    # ---------------- HELP ----------------
    function __git_dir_help
        echo "Usage:"
        echo "  git-dir [--dry-run] \"<includes !excludes>\" <repo-url>"
        echo ""
        echo "Options:"
        echo "  --dry-run     Show what would be done (no clone, no changes)"
        echo "  --help        Show this help and exit"
        echo ""
        echo "Pathspec rules:"
        echo "  include        directory to include in the working tree"
        echo "  !exclude       subdirectory to exclude"
        echo ""
        echo "Examples:"
        echo "  git-dir \"docs resources/logo !resources/logo/print\" https://github.com/USER/REPO.git"
        echo "  git-dir --dry-run \"docs !docs/assets\" https://github.com/USER/REPO.git"
        echo ""
        echo "Example directory name:"
        echo "  example-repo_docs_(no assets)_resources-logo_(no print)"
    end

    # ---------------- ARGUMENT PARSING ----------------
    set DRYRUN 0

    if test (count $argv) -eq 0
        __git_dir_help
        return 0
    end

    if contains -- --help $argv
        __git_dir_help
        return 0
    end

    if test "$argv[1]" = "--dry-run"
        set DRYRUN 1
        set SPEC $argv[2]
        set REPO $argv[3]
    else
        set SPEC $argv[1]
        set REPO $argv[2]
    end

    if test -z "$SPEC" -o -z "$REPO"
        __git_dir_help
        return 1
    end

    # ---------------- SPLIT PATHS, DROP EMPTY ----------------
    set PATHS
    for P in (string split " " -- $SPEC)
        if test -n "$P"
            set PATHS $PATHS "$P"
        end
    end

    set REPONAME (basename $REPO .git)

    # ---------------- INCLUDES / EXCLUDES ----------------
    set INCLUDES
    set EXCLUDES
    for P in $PATHS
        if string match -q "!*" "$P"
            set EXCLUDES $EXCLUDES (string sub -s 2 "$P")
        else
            set INCLUDES $INCLUDES "$P"
        end
    end

    # Deduplicate
    set INCLUDES (printf "%s\n" $INCLUDES | sort -u)
    set EXCLUDES (printf "%s\n" $EXCLUDES | sort -u)

    # ---------------- DIRECTORY NAME GENERATION ----------------
    set NAMEPARTS

    for I in $INCLUDES
        set I_SAFE (string replace -a "/" "-" $I)

        set E_NAMES
        for E in $EXCLUDES
            if string match -q "$I/*" "$E"
                set E_NAMES $E_NAMES (basename "$E")
            end
        end

        set E_NAMES (printf "%s\n" $E_NAMES | sort -u)

        if test (count $E_NAMES) -gt 0
            set NAMEPARTS $NAMEPARTS "$I_SAFE""_(no "(string join " " $E_NAMES)")"
        else
            set NAMEPARTS $NAMEPARTS "$I_SAFE"
        end
    end

    set NAMEJOIN (string join "_" $NAMEPARTS)
    set WORKDIR "$PWD/$REPONAME"_"$NAMEJOIN"

    # ---------------- DRY-RUN ----------------
    if test $DRYRUN -eq 1
        echo "[DRY-RUN]"
        echo "Repo:        $REPONAME"
        echo "Workdir:     $WORKDIR"
        echo "Includes:    $INCLUDES"
        echo "Excludes:    $EXCLUDES"
        echo "Sparse-set:  $PATHS"
        echo "Clone:       SKIP"
        echo "Checkout:    SKIP"
        return 0
    end

    # ---------------- CLONE OR UPDATE ----------------
    if not test -d "$WORKDIR/.git"
        mkdir -p "$WORKDIR"
        git clone --filter=blob:none --no-checkout "$REPO" "$WORKDIR"
    end

    cd "$WORKDIR" || return 1

    # ---------------- SPARSE CHECKOUT ----------------
    git sparse-checkout init --no-cone
    git sparse-checkout set $PATHS
    git checkout

    # ---------------- SYMLINKS ----------------
    for I in $INCLUDES
        if string match -q "*/*" "$I"
            set LINKNAME (basename "$I")
            if not test -e "$LINKNAME"
                ln -s "$I" "$LINKNAME"
            end
        end
    end
end
