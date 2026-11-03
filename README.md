# Hey Joe Edit Bay

A video editing room where you tell Claude what to make. Drop in your footage, describe the cut,
and Edit Bay makes it with the editing rules and your brand built in.

## Install

You need a Mac with Apple silicon (M1 or newer) and a Claude plan: your own Pro or Max, or a
seat on your company's Claude Team or Enterprise plan. Open Terminal
(press Command-Space, type Terminal, press Return), paste this line and press Return:

```
curl -fsSL https://raw.githubusercontent.com/jbrundige/hey-joe-edit-bay-releases/main/install.sh | bash
```

It takes a few minutes, mostly for the 1.6 GB transcription model. When it finishes, Edit Bay
opens and walks you through signing in to Claude. You sign in through Claude Code's own login
page; Edit Bay never sees your Claude password.

Edit Bay updates itself. If it ever needs repairing, run the same line again. Your projects,
chats and settings are kept.

## What goes where

- The app: `~/Applications/Hey Joe Edit Bay.app`
- Your projects: `~/Movies/Hey Joe Edit Bay`
- Everything else (the code, video tools, transcription model, your settings and chats):
  `~/Library/Application Support/Hey Joe Edit Bay`

To remove it, quit the app and move those to the Trash. Your projects folder is yours to keep or
delete.

## Third-party software

The installer downloads these alongside Edit Bay:

- **FFmpeg** 9.0.2, a static Apple silicon build from https://www.martin-riedl.de, licensed under
  the GPL. Source: https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz. Build scripts:
  https://gitlab.com/martinr92/ffmpeg.
- **whisper.cpp** 1.9.5 (`whisper-cli`), MIT licence, https://github.com/ggml-org/whisper.cpp.
- **Whisper large-v3-turbo** model in ggml format, downloaded from
  https://huggingface.co/ggerganov/whisper.cpp (MIT licence, from OpenAI's Whisper).
- **Electron** 33.4.11, MIT licence, https://www.electronjs.org.
- **Claude Code**, installed from Anthropic's own installer (https://claude.ai/install.sh) and
  used under your own Claude plan and Anthropic's terms.

Hey Joe Edit Bay itself is © Hey Joe. All rights reserved. It's published here so Hey Joe and its
partners can install it.
