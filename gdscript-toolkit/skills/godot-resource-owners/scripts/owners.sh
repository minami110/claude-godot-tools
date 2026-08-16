#!/bin/bash
# List the owners (reverse dependencies) of Godot resources — the script-side
# equivalent of the editor's FileSystem dock "View Owners...".
#
# Usage:
#   owners.sh <project_root> <path>...
#
#   <project_root>  directory containing project.godot
#   <path>          target resource, given as res://..., an absolute path, or a
#                   path relative to <project_root>. Several targets may be given.
#
# For each target the script resolves its UID (from the .uid sidecar, the
# .import file, or the .tscn/.tres header) and greps the project's text
# resources for both the res:// path and the uid:// reference.
#
# Output (one block per target):
#   [OWNERS] res://path/to/target   (uid://abc123 | uid: none)
#   [OWNERS]   res://path/to/owner   (path+uid | path | uid)
#   [OWNERS]   (none)
#
# The tag tells how the owner refers to the target: `uid` references survive a
# move/rename (Godot re-resolves them), `path` references do not.
#
# Exit code: 0 = done, 2 = bad arguments (no target, missing project.godot,
# target does not exist).
set -euo pipefail

usage() {
  echo "Usage: owners.sh <project_root> <path>..." >&2
  exit 2
}

[ $# -ge 2 ] || usage

ROOT="$1"
shift
[ -f "$ROOT/project.godot" ] || {
  echo "[OWNERS] error: project.godot not found in: $ROOT" >&2
  exit 2
}
ROOT="$(cd "$ROOT" && pwd -P)"

# Candidate owner files: text formats that reference other resources by
# res:// path or uid://. Mirrors the editor's scan rules — directories whose
# name starts with "." (.godot, .git, ...) and directories containing a
# .gdignore file are skipped entirely. *.import / *.uid only describe the
# target itself and are not candidates.
FILE_LIST="$(mktemp)"
trap 'rm -f "$FILE_LIST"' EXIT
(cd "$ROOT" && find . -mindepth 1 \
  \( -type d \( -name '.*' -o -exec test -e '{}/.gdignore' \; \) \) -prune -o \
  -type f \( -name '*.gd' -o -name '*.cs' -o -name '*.tscn' -o -name '*.tres' \
             -o -name '*.gdshader' -o -name '*.gdshaderinc' -o -name '*.gdextension' \
             -o -name 'project.godot' \) -print0) > "$FILE_LIST"

# res:// / absolute / root-relative  ->  root-relative (no leading slash)
normalize() {
  local p="$1"
  case "$p" in
    res://*) p="${p#res://}" ;;
    /*)
      local abs
      abs="$(cd "$(dirname "$p")" 2>/dev/null && pwd -P)/$(basename "$p")" || abs="$p"
      case "$abs" in
        "$ROOT"/*) p="${abs#"$ROOT"/}" ;;
        *)
          echo "[OWNERS] error: path is outside the project root: $1" >&2
          exit 2
          ;;
      esac
      ;;
  esac
  printf '%s\n' "$p"
}

# Where Godot stores the UID of a resource:
#   scripts / shaders  -> <file>.uid sidecar
#   imported assets    -> <file>.import  (uid="uid://...")
#   .tscn / .tres      -> the resource header line
resolve_uid() {
  local rel="$1" uid=""
  if [ -f "$ROOT/$rel.uid" ]; then
    uid="$(grep -o 'uid://[0-9a-z]*' "$ROOT/$rel.uid" | head -n1 || true)"
  elif [ -f "$ROOT/$rel.import" ]; then
    uid="$(grep -o '^uid="uid://[0-9a-z]*"' "$ROOT/$rel.import" | grep -o 'uid://[0-9a-z]*' | head -n1 || true)"
  else
    case "$rel" in
      *.tscn|*.tres)
        uid="$(head -n1 "$ROOT/$rel" | grep -o 'uid="uid://[0-9a-z]*"' | grep -o 'uid://[0-9a-z]*' | head -n1 || true)"
        ;;
    esac
  fi
  printf '%s\n' "$uid"
}

# Escape a literal for use inside an ERE.
ere_escape() {
  printf '%s' "$1" | sed -e 's/[][\.|$(){}?+*^\\]/\\&/g'
}

# grep -l for `<literal>` followed by a non-path character (avoids matching
# `res://a.gd` inside `res://a.gdshader`, or `uid://abc` inside `uid://abcd`).
grep_owners() {
  local literal="$1" boundary="$2"
  (cd "$ROOT" && xargs -0 -r grep -IlE -e "$(ere_escape "$literal")(${boundary}|\$)" -- < "$FILE_LIST" 2>/dev/null || true) \
    | sed -e 's#^\./##' | sort
}

for target in "$@"; do
  rel="$(normalize "$target")"
  if [ ! -f "$ROOT/$rel" ]; then
    echo "[OWNERS] error: target does not exist: res://$rel" >&2
    exit 2
  fi
  uid="$(resolve_uid "$rel")"

  by_path="$(grep_owners "res://$rel" '[^A-Za-z0-9_./-]')"
  by_uid=""
  if [ -n "$uid" ]; then
    by_uid="$(grep_owners "$uid" '[^0-9a-z]')"
  fi

  echo "[OWNERS] res://$rel   (${uid:-uid: none})"
  found=0
  # union of both lists, excluding the target itself (a .tscn/.tres header
  # contains its own uid)
  while IFS= read -r owner; do
    [ -n "$owner" ] || continue
    [ "$owner" = "$rel" ] && continue
    in_path=0; in_uid=0
    grep -qxF "$owner" <<<"$by_path" && in_path=1
    grep -qxF "$owner" <<<"$by_uid" && in_uid=1
    if [ $in_path -eq 1 ] && [ $in_uid -eq 1 ]; then tag="path+uid"
    elif [ $in_path -eq 1 ]; then tag="path"
    else tag="uid"; fi
    echo "[OWNERS]   res://$owner   ($tag)"
    found=1
  done < <(printf '%s\n%s\n' "$by_path" "$by_uid" | sort -u)
  [ $found -eq 1 ] || echo "[OWNERS]   (none)"
done
