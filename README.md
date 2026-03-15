dotfiles
Personal dotfile management for Debian-based systems. Uses GNU Stow for symlink management and a profile system for targeted installs across different machines.
How It Works
Each piece of software gets its own stow package — a directory whose structure mirrors $HOME. Running stow against a package creates symlinks in $HOME pointing back into the repo. This means config files are version-controlled without needing to live in the home directory directly.
Profiles group stow packages and Debian packages together for a specific use case. Profiles can declare dependencies on other profiles, which get resolved and installed automatically. This allows fine-grained control over what goes on each machine — a headless Pi gets a different profile than a full desktop workstation.
dotfiles/
├── install.sh          # entry point
├── profiles/           # install targets
│   ├── base/
│   ├── dev-tools/
│   ├── term/
│   ├── term-x11/
│   └── st/
└── <package>/          # one directory per stow package
    └── .config/...     # mirrors $HOME structure
Prerequisites
Debian-based system
stow installed (apt install stow)
git (required for --force flag)
Usage
./install.sh -p <profile> [flags]
Flag
Description
-p
Profile to install (required)
-i
Install Debian packages for the profile
-f
Force overwrite existing config files
-s
List stow packages in a profile
-b
List Debian packages in a profile
-l
List available profiles
-q
Quiet — suppress output
-h
Show help
Examples
Link config only (no package installation):
./install.sh -p term
Link config and install all packages:
./install.sh -p term -i
Overwrite existing config files on a machine that already has dotfiles:
./install.sh -p base -f
Preview what a profile includes before installing:
./install.sh -p term -s   # list stow packages
./install.sh -p term -b   # list debian packages
Profiles
base
Core CLI environment. The foundation every other profile builds on.
Installs: neovim, ranger, fzf, ripgrep, fastfetch, trash-cli, less, curl, unzip, glow
Config: bash, neovim, ranger, fzf, grep, less, fastfetch
dev-tools
Git tooling and build utilities. Depends on base.
Installs: git, gh, lazygit, build-essential
Config: git, lazygit
term
Full terminal daily driver. Depends on base, dev-tools.
Installs: tmux, starship, elinks, nala, zoxide, python3-pip, python3-bs4
Config: tmux, starship, elinks, nala, zoxide
term-x11
Minimal X11 kiosk environment running a terminal-first workflow over i3. Depends on base, dev-tools, term, st.
Installs: i3, xinit, xdg-user-dirs, X11/Xft/harfbuzz dev libraries
Config: i3-kiosk, xdg-user-dir
st
Builds st (suckless terminal) from source. Provides the terminal emulator for the term-x11 profile.
Installs build dependencies, clones the repo, compiles, and installs. Skipped automatically if st is already present.
Build deps: build-essential, libx11-dev, libxft-dev, libxext-dev, libharfbuzz-dev
Profile dependency tree
term-x11
├── base
├── dev-tools
│   └── base
├── term
│   ├── base
│   └── dev-tools
│       └── base
└── st
Adding a New Stow Package
Create a directory at the repo root named after the package.
Mirror the $HOME structure inside it:
myapp/
└── .config/
    └── myapp/
        └── config.toml
Optionally add shell integration fragments:
myapp/
└── .config/
    └── bash/
        ├── aliases.d/myapp.bash
        └── config.d/myapp.bash
Add the package name to the relevant profile's stow.pkglist.
Bash fragments in aliases.d/, config.d/, functions.d/, completions.d/, and path.d/ are sourced automatically by the modular bash config — no manual wiring needed.
Adding a New Profile
Create a directory under profiles/ with any combination of:
File
Purpose
stow.pkglist
One stow package name per line
debian.pkglist
One apt package name per line
profile.deps
One profile name per line (dependencies)
build.sh
Executable script for building from source
build.sh runs in a child process with its own scope. Use it for anything that can't be handled by apt — suckless tools, language-specific installers, etc. The script is responsible for its own idempotency check.
Handling Existing Systems
By default, install.sh will error if a stow package conflicts with an existing file in $HOME.
The -f flag uses stow --adopt to pull existing files into the repo, then restores the repo versions with git reset --hard. This will overwrite your existing config with the versions in this repo. The flag will abort if the repo has any uncommitted changes before stowing begins.
After installation, reload your shell:
source ~/.profile
