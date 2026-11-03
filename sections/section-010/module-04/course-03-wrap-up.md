# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about keeping the captain's standing orders tidy: one page per team, short names for command lists, and a clerk who checks every page.

**From [Drop-in Files And visudo](./course-01-drop-in-files-and-visudo.md):**

- `/etc/sudoers` includes every file in `/etc/sudoers.d/`, in sorted name order. A name with a dot or ending in `~` is skipped.
- `visudo -c` checks every file. `visudo -c -f <path>` checks one file. `visudo -f <path>` edits a file and refuses to save a broken one.
- A drop-in belongs to `root:root` with mode `0440`.

**From [Aliases And Group Rules](./course-02-aliases-and-group-rules.md):**

- `Cmnd_Alias NAME = cmd1, cmd2` names a list of commands. `%group` in a rule means every member of that group.
- `NOPASSWD:` applies to one rule. A rule without it asks for the user's own password.
- `sudo -l -U <user>` lists another user's rules. `sudo -n` proves a refusal. The last matching rule wins.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Group Sudo Rules With Aliases Lab](../../../labs/lab-014/docs/question.md) | Aliases And Group Rules | wrote a drop-in with a command alias, gave it to a group without a password, kept the password for another user, and passed `visudo -c` |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You save a rule as <code>/etc/sudoers.d/webops.conf</code>. Why does <code>sudo</code> ignore it?</summary>

The name contains a dot. `sudo` skips names with a dot or a trailing `~`. Use `webops`.
</details>

<details>
<summary>2. What is the difference between <code>visudo -c</code> and <code>visudo -c -f /tmp/rule</code>?</summary>

`visudo -c` checks the main file and every drop-in. With `-f <path>` it checks only that one file.
</details>

<details>
<summary>3. What does the percent sign mean in <code>%webops ALL=(root) NOPASSWD: SERVICE_CMDS</code>?</summary>

It marks a group. Every member of `webops` gets the rule.
</details>

<details>
<summary>4. A rule allows <code>/usr/bin/systemctl status ssh</code>. Does it allow the same command with <code>--no-pager</code>?</summary>

No. `sudo` matches the command word for word, so the extra option makes it a different command.
</details>

<details>
<summary>5. How do you see what another user may run, without becoming that user?</summary>

`sudo -l -U <user>`.
</details>

<details>
<summary>6. Two rules match the same command. Which one wins?</summary>

The last one `sudo` reads. Drop-ins are read in sorted name order after the main file.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy sudoers-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-014
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-04/playground`. It always starts clean, so nothing you broke carries over.

> *A rule you did not check with `visudo` is a rule you have not written yet.*
