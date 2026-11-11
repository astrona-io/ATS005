# Extending PATH Safely

Astronaut, when you type a command name, the ship searches a list of decks, in order, until it finds a crew member with that name. That list is `PATH`. Adding a personal scripts directory to it looks like one `export` line. It stays that easy right up until you put the directory in the wrong place.

Put the directory at the *front* of the search order, and any file in it with the same name as a real command runs *instead* of that command. A script named `ls`, or `sudo`, in a directory you can write to has quietly taken over that name. It is an impostor on an earlier deck. This module builds `PATH` changes the way a security-minded ship expects: in the right order, and saved in the right file.

## Learning objectives

After this module you can:

- Explain how the shell finds a bare command name through `PATH`: left to right, first match wins.
- Use `type` instead of `which` to see what a name will really run, aliases and built-in commands included.
- Explain why putting a writable directory at the front of `PATH` is a shadowing risk, and putting it at the end is not.
- Add a directory to the end of `PATH` permanently, in the login-shell dotfile the account really reads.
- Use `hash -r` to clear bash's memory of command locations before you trust a `type` result after a `PATH` change.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **What `PATH` looks like.** It is a list of directories separated by colons.
- **What `export` does**, and how to make a file executable with `chmod +x`.
- **How to edit a dotfile.** `su - candidate` (a login shell as that user) is how the checks below test a fresh session.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- The user `candidate`: an ordinary account. Reach it with `su - candidate` from `root`, with no password.
- `/home/candidate/work/helper-tool`: an executable script whose name matches no system command.
- `candidate`'s dotfiles left at the Ubuntu defaults, with no decoy planted.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh safe-path-playground
```

Every command block in the parts runs **inside that virtual machine**, as `root` unless it says otherwise. Become `root` first with `sudo -i`.

## How this module is laid out

1. [How The Shell Finds A Command](./course-01-how-the-shell-finds-a-command.md): the left-to-right search, `type`, and the shadowing trap.
2. [Appending And Saving PATH](./course-02-appending-and-saving-path.md): why the end of the list is safe, and which dotfile keeps the change.
3. [The Command-Location Cache](./course-03-the-command-location-cache.md): `hash -r`, and why a lookup can show an old answer.
   - Mission: [Safe PATH Extension & Precedence Lab](../../../labs/lab-032/docs/question.md)
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

A `PATH` entry in the wrong *position* is worse than one in the wrong *file*. It can let a directory that a user (or an attacker who fooled that user) can write to override a real command, `sudo` included. That breaks the same privilege boundary that careful `sudo` rules protect.

> *`PATH` is searched left to right, and the first match wins. Where a new directory goes in that list is a security decision, not a formatting one.*

<!-- curriculum-practice -->
## Practice and assessment

- [Safe PATH Extension & Precedence Lab](../../../labs/lab-032/docs/question.md): Add a personal directory to PATH so it survives new login shells; Append the directory so a same-named script never replaces a system command.
- [Shell Environment & PATH Capstone Lab](../../../labs/lab-030/docs/question.md): Export a variable for every login shell through a profile.d script; Set a personal variable and extend PATH for one user only; Prove that a decoy script never replaces a real system command.
