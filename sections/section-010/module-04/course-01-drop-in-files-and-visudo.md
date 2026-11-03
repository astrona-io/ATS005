# Drop-in Files And visudo

Astronaut, the captain's standing orders are not one long scroll. They are a main page with extra pages clipped to it. This part shows you which pages `sudo` reads, which pages it skips on purpose, and how to ask the clerk to check a page before it goes live.

## Which files sudo reads

`sudo` starts with the main file, `/etc/sudoers`. That file ends with an instruction to read every file in the folder `/etc/sudoers.d/` too. Each team can have its own page, and you can remove a page without touching the main file.

### See the include line and the folder

Look for the include line, then list the folder:

<!-- astrona:playground:renew -->

```sh
sudo grep -n includedir /etc/sudoers
sudo ls /etc/sudoers.d
```

Expect something like:

```text
@includedir /etc/sudoers.d
README  old-ops.bak
```

The first line tells `sudo` to read the folder. Your list may show more files, but you should see `README` and `old-ops.bak`. `sudo` reads the files in sorted order by name, one after the other.

### Names that sudo skips

`sudo` does not read every file in the folder. It skips a file whose name contains a dot (`.`) or ends with a tilde (`~`). The reason is safety: backup and package files such as `old-ops.bak` or `webops.dpkg-old` must never become live rules by accident.

The playground file `old-ops.bak` holds a rule that would give `cleo` full authority. Ask `sudo` what `cleo` may run:

```sh
sudo -l -U cleo
```

Expect something like this (shortened):

```text
User cleo is not allowed to run sudo on ...
```

`sudo` skipped the file, so `cleo` has no rights at all. The skipped name is also the trap in the other direction: if you save a real rule as `webops.conf`, `sudo` never reads it. Name your drop-in files with letters, digits, hyphens or underscores only.

## Letting the clerk check first

One broken line in the standing orders can stop `sudo` for everyone. Your safety net is `visudo`, the clerk who checks the orders before they are filed. It has two jobs: it edits a file and refuses to save a broken one, and it checks files that already exist.

### Check a file you have not installed

`visudo -c` (**c**heck) reads the main file and every drop-in. `visudo -c -f <path>` checks one file, wherever it is, without installing it. Save this as `/tmp/bad-rule`. It has a bracket that never closes:

```text
anna ALL=(root NOPASSWD: /usr/bin/id
```

Check it:

```sh
sudo visudo -c -f /tmp/bad-rule; echo "exit: $?"
```

Expect `visudo` to print a syntax error that names the file and the line, and then `exit: 1`. A file that parses cleanly makes `visudo` exit with `0`. The exit code is what a script, and a grader, looks at.

### Create a drop-in the safe way

To create or change a real drop-in, open it with `visudo -f`. It checks the file when you save, and it offers to let you edit again if the file is broken. A file created this way gets owner `root:root` and mode `0440`.

```sh
sudo visudo -f /etc/sudoers.d/ops-notes
```

Type one comment line, such as `# notes for the ops team`, then save and quit. Check the folder:

```sh
sudo ls -l /etc/sudoers.d/ops-notes
sudo visudo -c
```

Expect a line that starts with `-r--r-----` and shows `root root`, and one `parsed OK` line for every file `sudo` read. `0440` means the owner and group can read, and nobody can write. `sudo` refuses to trust a rules file that other users can write to.

## Why not edit with a plain editor

A plain editor saves whatever you type. If the file then holds a typo, `sudo` stops working for everybody, and you need `sudo` to fix it. `visudo` also locks the file so two people cannot edit it at once.

> [!TIP]
> Make a habit: after every change to a rules file, run `sudo visudo -c` before you close the terminal. It takes one second and it is the only warning you get.

## Common pitfalls

> [!WARNING]
> - **A dot in the file name.** `webops.conf` and `webops.bak` are skipped without any message. Use `webops`.
> - **Wrong mode.** A drop-in that is not `0440` (or `0640`) can make `sudo` complain or ignore the file. Fix it with `sudo chmod 0440 <file>`.
> - **Editing with `nano` or `vi` directly.** Use `sudo visudo -f <file>`. A saved typo locks the crew out.
> - **Closing your last working terminal too early.** Keep one session open until `sudo visudo -c` says every file parses.
