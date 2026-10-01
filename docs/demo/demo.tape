# Rendered by docs/demo/record.sh, which provides $DEMO_ENV.
Output docs/demo.gif

Require herdr
Require fzf

Set Shell "bash"
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 1400
Set Height 820
Set Padding 10
Set Theme "Rose Pine"
Set TypingSpeed 90ms
Set CursorBlink false

Hide
Type `source "$DEMO_ENV" && clear && herdr`
Enter
Sleep 4s
Show

Sleep 1.5s

# Open the picker: workspaces first, with agent state and previews.
Ctrl+A
Type "o"
Sleep 2.5s
Up
Sleep 1.5s
Up
Sleep 1.5s

# Agents across all workspaces.
Ctrl+E
Sleep 2s
Up
Sleep 1.5s

# sesh configs, then zoxide.
Ctrl+G
Sleep 2s
Ctrl+X
Sleep 1.5s

# Fuzzy-find a directory and open it as a new workspace.
Type "blog"
Sleep 1.5s
Enter
Sleep 2.5s

# Toggle back and forth with the last-workspace action.
Ctrl+A
Type "L"
Sleep 2s
Ctrl+A
Type "L"
Sleep 2s

# Jump straight to a workspace by name.
Ctrl+A
Type "o"
Sleep 1.5s
Type "web"
Sleep 1.5s
Enter
Sleep 3s
