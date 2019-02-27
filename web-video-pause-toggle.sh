#!/bin/bash
# global function to pause a running Youtube in Conkeror
# get current window

main () {
    # TODO: boilerplate
    local LOCKFILE=/tmp/web-video-only-lock.txt
    if [[ -e "$LOCKFILE" ]]; then
        local LOCKFILE_CONTENTS=$(cat "$LOCKFILE")
        if kill -0 "$LOCKFILE_CONTENTS" &>/dev/null; then
            echo "Found $LOCKFILE pid $LOCKFILE_CONTENTS"
            # TODO: fix up this grep so I check for something valid
            if ps -ef | grep "$LOCKFILE_CONTENTS.*"'[w]eb-video' &>/dev/null; then
                echo "A web-video script is already running!"
                exit 1
            else
                echo "Running because $LOCKFILE contents stale"
            fi
        fi
    fi
    echo $$ > "$LOCKFILE"

    local CURRENTWINDOW=$(xdotool getwindowfocus)

    xdotool search --class --onlyvisible --maxdepth 2 "dolphin-emu|Fceux|mGBA|mpv|PCSXR|PCSX2|PPSSPPSDL|vlc|zsnes" | while IFS= read -r WINID; do
        local THECLASS=$(xprop WM_CLASS -id "$WINID")
        echo "$WINID: $THECLASS"
        if [[ "$THECLASS" =~ "vlc" ]]; then
            # TODO: requires different from default config
            wmctrl -i -R "$WINID"
            sleep 0.25
            # TODO: only get window focus temporarily, why do I need --clearmodifiers here?
            xdotool getwindowfocus key --window "%1" --clearmodifiers "space"
            sleep 0.25
            # TODO: not yet
            # echo "$WINID" > /tmp/cic-web-video-last.txt
            # echo $(xprop WM_CLASS -id "$WINID") >> /tmp/cic-web-video-last.txt
            xdotool windowactivate --sync "$CURRENTWINDOW"
        fi
    done

    local CURRENTYOUTUBE=
    # filtering by name probably cuts out more windows more quickly than class
    xdotool search --name "twitch|youtube" | while IFS= read -r line; do
        if [[ -n "$line" ]] && xdotool search --class "chromium-browser|conkeror|firefox" | grep -- "$line" >/dev/null; then
            xdotool windowfocus --sync "$line"
            # TODO: very arbitrary delay, perhaps wait for something to return
            sleep 0.05
            "$HOME/bin/conkeror-batch" -f web-video-pause-toggle
            [[ "$line" == "$CURRENTWINDOW" ]] && CURRENTYOUTUBE=1
        fi
    done
    xdotool windowactivate --sync "$CURRENTWINDOW"
    # TODO: should have an if before xdotool, but couldn't get it working in 5 minutes
    # restore focus if not youtube window
    # if [[ -n "$CURRENTYOUTUBE" ]]; then
    # fi
}
main "$@"
