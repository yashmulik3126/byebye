#!/bin/bash
# byebye - quit all open apps gracefully, then shut down the Mac

KEEP_APPS=("Finder" "Terminal" "iTerm2" "Code")
DRY_RUN=0
VERBOSE=0
ASSUME_YES=0

usage() {
  cat <<EOF
Usage: byebye [options]

Quit all open apps, then shut down the Mac.

Options:
  -h, --help       Show this help and exit
  -n, --dry-run    Show what would happen, change nothing
  -v, --verbose    More output
  -y, --yes        Skip the confirmation prompt
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)    usage; exit 0 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -v|--verbose) VERBOSE=1 ;;
    -y|--yes)     ASSUME_YES=1 ;;
    *) echo "byebye: unknown option '$arg'" >&2; usage >&2; exit 2 ;;
  esac
done

if [ "$(uname)" != "Darwin" ]; then
  echo "byebye: this tool only works on macOS" >&2
  exit 1
fi

# 1. Gather the visible apps
apps=$(osascript -e 'tell application "System Events" to get name of every application process whose background only is false' 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$apps" ]; then
  echo "byebye: could not list apps (check System Settings > Privacy & Security > Automation)" >&2
  exit 3
fi

# 2. Filter out the apps we keep alive
to_quit=()
while IFS= read -r name; do
  [ -z "$name" ] && continue
  skip=0
  for keep in "${KEEP_APPS[@]}"; do
    [ "$name" = "$keep" ] && skip=1
  done
  [ $skip -eq 0 ] && to_quit+=("$name")
done < <(echo "$apps" | tr ',' '\n' | sed 's/^ *//')

echo "Apps that will be quit:"
for a in "${to_quit[@]}"; do
  echo "  - $a"
done

# 3. Dry run stops here
if [ $DRY_RUN -eq 1 ]; then
  echo "[dry run] Would then shut down the Mac. Nothing was changed."
  exit 0
fi

# 4. Confirm
if [ $ASSUME_YES -eq 0 ]; then
  read -r -p "Quit these apps and shut down? (y/n) " answer
  if [ "$answer" != "y" ]; then
    echo "Cancelled."
    exit 0
  fi
fi

# 5. Quit apps, then shut down
for a in "${to_quit[@]}"; do
  [ $VERBOSE -eq 1 ] && echo "Quitting $a..."
  osascript -e "tell application \"$a\" to quit" >/dev/null 2>&1 || echo "byebye: could not quit $a" >&2
done

sleep 3
[ $VERBOSE -eq 1 ] && echo "Shutting down..."
osascript -e 'tell application "System Events" to shut down'
