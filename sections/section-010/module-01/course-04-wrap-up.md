# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about fixing and creating crew roster entries correctly, and about handing out the captain's authority one order at a time.

**From [Primary Groups And Moving A Home](./course-01-primary-groups-and-moving-a-home.md):**

- Every user has one primary group (`gid=` in `id`) and any number of supplementary groups (the rest of `groups=`).
- `usermod -g` changes the primary group in `/etc/passwd` and nothing else. Existing files keep their group.
- `usermod -d` alone changes only the home pointer. `usermod -d <path> -m` also moves the contents. Create a missing parent directory first, and make sure the user is logged out.

**From [Creating A New Account In One Command](./course-02-creating-a-new-account.md):**

- `useradd -m -d <home> -G <groups> -s <shell> <user>` builds a whole account in one call.
- On an existing account, `usermod -G` replaces every supplementary group. `usermod -aG` adds one and keeps the rest.

**From [A Scoped sudo Rule](./course-03-a-scoped-sudo-rule.md):**

- A rule such as `user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh` grants one exact command, word for word.
- Write rules with `visudo -f` in `/etc/sudoers.d/`, set the file to `0440` and `root:root`, and check with `visudo -c`.
- `sudo -l -U <user>` lists another user's rules, and `sudo -n` fails at once instead of asking for a password.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [User & Group Provisioning and Scoped Sudo Lab](../../../labs/lab-011/docs/question.md) | A Scoped sudo Rule | moved `user1` to a new group and home with its files, created `user2` with the right groups, and granted one exact `sudo` command |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. In the line <code>uid=1001(user1) gid=1003(dev) groups=1003(dev),1002(web)</code>, which is the primary group?</summary>

`dev`. The `gid=` field is the primary group. `web` is a supplementary group.
</details>

<details>
<summary>2. You run <code>sudo usermod -d /home/accounts/user1 user1</code>. Where are the user's files now?</summary>

Still in the old home directory. `-d` alone only changes the path in the account record. Add `-m` to move the contents.
</details>

<details>
<summary>3. <code>usermod -m -d /home/accounts/user1 user1</code> fails with "cannot create directory". What is the most likely cause?</summary>

The parent directory `/home/accounts` does not exist. Create it with `mkdir -p` and run the command again.
</details>

<details>
<summary>4. What is the difference between <code>usermod -G op user1</code> and <code>usermod -aG op user1</code>?</summary>

`-G op` replaces every supplementary group with `op` alone. `-aG op` adds `op` and keeps the groups the user already has.
</details>

<details>
<summary>5. A rule allows <code>/root/dangerous.sh</code>, but <code>sudo bash /root/dangerous.sh</code> asks for a password. Why?</summary>

`sudo` matches the command word for word. `bash /root/dangerous.sh` is the `bash` program with an argument, which is a different command from the script on its own.
</details>

<details>
<summary>6. Why use <code>visudo -f</code> instead of a normal editor for a file in <code>/etc/sudoers.d/</code>?</summary>

`visudo` checks the syntax and refuses to save a broken rule. One bad line saved with a normal editor can stop `sudo` working for everyone.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy user-group-mgmt-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-011
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-01/playground`. It always starts clean, so nothing you broke carries over.

> *Add badges with `-aG`, move quarters with `-m`, and grant the captain's authority one exact order at a time.*
