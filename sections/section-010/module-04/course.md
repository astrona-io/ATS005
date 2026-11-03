# Sudoers Drop-ins, Aliases & Group Rules

Astronaut, one scoped `sudo` rule is easy to write. A real ship has a whole crew, and the captain's standing orders must stay readable as it grows. This module shows you how to keep each team's orders on their own page, give those orders short names, and hand the same permission to a whole team at once.

You will also learn what happens when the orders have a typo, and how the clerk (`visudo`) keeps one typo from locking everyone out.

## Learning objectives

After this module you can:

- Say which files `sudo` reads, in which order, and which file names it skips.
- Create a drop-in file in `/etc/sudoers.d/` with the right owner and mode `0440`.
- Check a rules file for mistakes with `visudo -c` and `visudo -cf <file>` before `sudo` ever reads it.
- Write a `Cmnd_Alias` (a named list of commands) and give it to a group with `%groupname`.
- Use `NOPASSWD:` for one rule and keep password prompts for another.
- List what any user may run with `sudo -l -U <user>`, and prove a refusal with `sudo -n`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **A scoped rule.** One line of the form `user host=(runas) command` that grants one command.
- **Groups.** What a supplementary group is, and that `id <user>` lists it.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- The users `anna` and `ben`, both in the group `webops`, and the user `cleo`, who is not in `webops`.
- A file `/etc/sudoers.d/old-ops.bak` that holds a very generous rule for `cleo`.
- The `ssh` service running, so you have a real service to point rules at.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh sudoers-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [Drop-in Files And visudo](./course-01-drop-in-files-and-visudo.md): which files `sudo` reads, which names it skips, and how to check a file safely.
2. [Aliases And Group Rules](./course-02-aliases-and-group-rules.md): `Cmnd_Alias`, `%group`, `NOPASSWD` and `sudo -l -U`.
   - Mission: [Group Sudo Rules With Aliases Lab](../../../labs/lab-014/docs/question.md)
3. [Wrap-Up: Mission Debrief](./course-03-wrap-up.md)

## Why this matters

On the exam you rarely write one rule for one user. You give a team the same few commands, you keep the rules in a file you can remove again, and you leave the machine with `sudo` still working. A broken rules file can lock every crew member out of the captain's authority.

> *Write rules in drop-in files, check them with `visudo` before they go live, and prove each grant with `sudo -l -U`.*
