# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module gave registry users a home on their first login.

**From [The Missing Home](./course-01-the-missing-home.md):**

- The directory stores a home path, not a home folder.
- A login without a home falls back to `/`.
- `/etc/skel` is copied into every new home. Existing homes never change.

**From [Creating Homes On First Login](./course-02-creating-homes-on-first-login.md):**

- `sudo pam-auth-update --enable mkhomedir` adds `pam_mkhomedir` to the shared session steps.
- Files in `/etc/skel` reach every home created after that point.
- Test with `su -` as a user who never logged in.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Home Directories For Directory Users Lab](../../../labs/lab-044/docs/question.md) | Creating Homes On First Login | enabled mkhomedir, added a starter file, and a brand new directory user got a stocked home on first login |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Why does a directory user have no home folder?</summary>

The directory stores only the path. Nothing creates the folder unless a login step does.
</details>

<details>
<summary>2. Which command switches on home creation?</summary>

`sudo pam-auth-update --enable mkhomedir`.
</details>

<details>
<summary>3. In which PAM phase does <code>pam_mkhomedir</code> run?</summary>

The session phase, from `common-session`.
</details>

<details>
<summary>4. You add a file to <code>/etc/skel</code>. Which homes get it?</summary>

Only homes created after that. Existing homes stay as they are.
</details>

<details>
<summary>5. Why test with <code>su -</code> and not <code>su</code>?</summary>

The dash starts a login, which runs the session steps. Plain `su` skips them.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy mkhomedir-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-044
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-040/module-04/playground`. It always starts clean, so nothing you broke carries over.

> *A cabin number in the registry is not a cabin.*
