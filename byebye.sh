#!/bin/bash
# byebye - quit all apps, then shut down the Mac

read -p "Quit all apps and shut down? (y/n) " answer
[ "$answer" != "y" ] && echo "Cancelled." && exit 0

osascript <<'EOF'
tell application "System Events"
  set appList to name of every application process whose background only is false
end tell
repeat with appName in appList
  if appName is not in {"Finder", "Terminal", "Code"} then
    try
      tell application appName to quit
    end try
  end if
end repeat
EOF

sleep 3
osascript -e 'tell app "System Events" to shut down'
