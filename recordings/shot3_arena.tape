# castus — shot 3: the arena crash, auto-decoded backtrace.
# Render from the castus root:   vhs recordings/shot3_arena.tape
# Needs: vhs (which pulls ttyd + ffmpeg).  Output -> recordings/shot3_arena.mp4

Output recordings/shot3_arena.mp4

Set Shell "bash"
Set FontSize 22
Set Width 1280
Set Height 720
Set Padding 24
Set Theme "Dracula"
Set TypingSpeed 55ms

# --- setup (hidden): clean prompt + stage the already-built bad commit ---
Hide
Type `export PS1="$ "` Enter
Type "clear" Enter
Type "make scene NAME=arena" Enter
Sleep 1s
Type "clear" Enter
Show

# --- on camera ---
Type "cat .castus-config.yaml" Enter
Sleep 3s
Type "./castus --verify ." Enter
Sleep 5s
