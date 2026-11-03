# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about crew allowances that really hold: limits set at the airlock by PAM, not in one crew member's startup notes.

**From [Why A .bashrc Limit Is Not Enough](./course-01-why-a-bashrc-limit-is-not-enough.md):**

- `~/.bashrc` is read only by interactive shells. Cron jobs, `ssh host cmd` and many systemd sessions skip it.
- A soft limit can be raised by the user up to the hard limit. The hard limit is the real ceiling.
- Read the live value with `sudo -u <user> -i ulimit -Su`, or from the kernel with `prlimit --pid <pid> --nproc`.

**From [Hard Limits Through PAM](./course-02-hard-limits-through-pam.md):**

- A `limits.d` line has four columns: `<domain> <type> <item> <value>`, for example `jackie  hard  nproc  150`.
- `pam_limits.so` must be in the `session` stack of the login path, or the file does nothing.
- Limits apply when a session starts, so check from a fresh login, and remove the old `~/.bashrc` line.

**From [One Login Per Group Member](./course-03-one-login-per-group-member.md):**

- `@operators  hard  maxlogins  1` gives each member of `operators` at most one session at a time.
- Check the members with `getent group <group>` before you set the cap.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [PAM Hard Limits & maxlogins Lab](../../../labs/lab-022/docs/question.md) | One Login Per Group Member | turned a `~/.bashrc` limit into a hard `nproc` limit in `limits.d`, removed the old line, and capped `operators` to one login each |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. A <code>ulimit</code> line in <code>~/.bashrc</code> limits a user's terminal sessions. Name one way the user can still run without the limit.</summary>

A cron job, a non-interactive `ssh host cmd`, or a session started by systemd. None of them read `~/.bashrc`.
</details>

<details>
<summary>2. What is the difference between a soft and a hard limit?</summary>

The soft limit is the value in force now, and the user may raise it up to the hard limit. Only `root` can raise the hard limit.
</details>

<details>
<summary>3. Write the <code>limits.d</code> line that gives user <code>jackie</code> a hard ceiling of 150 processes.</summary>

`jackie  hard  nproc  150`
</details>

<details>
<summary>4. The line is correct, but a fresh login still shows no limit. What do you check first?</summary>

That `pam_limits.so` is in the `session` stack of the PAM service used for that login, for example `session required pam_limits.so` in `/etc/pam.d/common-session`.
</details>

<details>
<summary>5. You set the limit and run <code>ulimit -Hu</code> in the shell you were already using. Why does it still show the old value?</summary>

`pam_limits.so` applies limits only when a session starts. Open a fresh login, for example `sudo -u jackie -i`.
</details>

<details>
<summary>6. What does <code>@operators  hard  maxlogins  1</code> do?</summary>

It allows each member of the group `operators` at most one login session at a time. The `@` marks a group.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy pam-limits-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-022
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-020/module-02/playground`. It always starts clean, so nothing you broke carries over.

> *The limit applies at session start, and only if `pam_limits.so` reads it.*
