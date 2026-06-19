# castus — shot 4: silent quantization drift, caught while everything else is green.
# Render from the castus root:   vhs recordings/shot4_drift.tape
# Needs: vhs (which pulls ttyd + ffmpeg).  Output -> recordings/shot4_drift.mp4

Output recordings/shot4_drift.mp4

Set Shell "bash"
Set FontSize 22
Set Width 1280
Set Height 720
Set Padding 24
Set Theme "Dracula"
Set TypingSpeed 55ms

# --- setup (hidden): clean prompt + stage the drift commit ---
Hide
Type `export PS1="$ "` Enter
Type "clear" Enter
Type "make scene NAME=drift" Enter
Sleep 1s
Type "clear" Enter
Show

# --- on camera ---
Type "cat scenarios/drift/NOTE.md" Enter
Sleep 4s
Type "make test-host" Enter
Sleep 2s
Type "./castus --verify ." Enter
Sleep 5s
