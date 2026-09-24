# Markdown Spoilers
A NeoVim (nvim) plugin that hides text between double vertical pipes (`||`) behind a spoiler.

Spoilers are revealed when hovering over them:
<video src="https://github.com/user-attachments/assets/abe04437-9619-41d8-a39d-1a6455face40"></video>

## Commands

| Command             | Effect                           |
| ------------------- | -------------------------------- |
| `:ShowSpoilers`     | Reveals all spoilers in the file |
| `:HideSpoilers`     | Hides all spoilers in the file   |
| `:ToggleSpoilers`   | Toggles all spoilers in the file |


## Lazy
```lua
{
  "sav-imagines/markdown-spoilers",
  config = {
    color = "#9553a5", -- put whatever color you want
  },
}
```
