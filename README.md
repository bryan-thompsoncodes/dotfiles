# Dotfiles
This contains dotfiles for my personal develop environment config. Meant to be utilized with GNU stow to allow easy referencing of dotfiles.

# Installation
First install [homebrew](https://brew.sh/)
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Then use brew to install [GNU stow](https://formulae.brew.sh/formula/stow)
```
brew install stow
```
Finally stow this repo, from this repo's root directory run
```
stow . --adopt --dotfiles --target=$HOME
```
this will sym link all of the dot-files to your home user directory, replacing dot- with . for files and folders.