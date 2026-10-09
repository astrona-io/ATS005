# Removing An Account Cleanly

Astronaut, when a crew member leaves for good, you take them off the roster. The one decision is what happens to their quarters. This part shows you exactly what `userdel` removes, with and without `-r`, and what it never looks at.

## What `userdel` removes

`userdel` (short for *user delete*) takes an entry off the crew roster. The `-r` option decides whether it also clears out the quarters.

### The command

This is the command. Do not run it yet; the walk-through below runs it with checks before and after.

<!-- astrona:playground:renew -->

```sh
sudo userdel -r contractor1
```

With `-r` (for **r**emove), `userdel` deletes the account's entries **and** its home directory and mail spool. That is where it stops. It does **not** search the rest of the filesystem for other files the user owns.

Plain `userdel contractor1`, without `-r`, removes the account from `/etc/passwd`, `/etc/shadow` and its groups, but leaves the home directory behind. Which one is right depends on the task: "gone completely", or "keep the data for a handover".

### See exactly what `-r` does and does not touch

Look at the home and the backup file, delete the account with `-r`, and look again:

```sh
ls -la /home/contractor1
ls -l /var/backups/contractor1
sudo userdel -r contractor1
ls /home/ | grep contractor1 || echo "home gone"
ls -l /var/backups/contractor1
```

Expect something like:

```text
... NOTES.txt
-rw-r--r-- 1 contractor1 contractor1 32 Aug 30 12:00 dump.sql
...
home gone
-rw-r--r-- 1 1002 1002 32 Aug 30 12:00 dump.sql
```

The home directory and `NOTES.txt` are gone. `/var/backups/contractor1/dump.sql` is untouched, because `-r` never looked there. It now shows a bare number as its owner, because the name `contractor1` no longer exists on the roster.

> [!TIP]
> Before you remove an account for good, run `find / -xdev -user <name>` to list files it owns outside its home. Afterwards they only show a number, and they are much harder to find.

## Common pitfalls

> [!WARNING]
> - **`userdel` without `-r` when the task says "including the home directory".** The home stays behind. Use `userdel -r`.
> - **Expecting `-r` to clean up the whole disk.** It removes only the home directory and mail spool. Files elsewhere keep a bare UID.
> - **Deleting an account that is under investigation.** Lock it instead. Deleting loses the evidence.

## Your mission: Account Defaults, Password Aging & Locking Lab

You can now create an account with the real defaults, force a new password, set an account expiration date, lock an account and remove one cleanly. Now prove it in a graded mission: create `contractor7` with the system defaults, a forced password change and a 30-day account expiry, lock `contractor3`, and remove `contractor1` with its home.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop account-lifecycle-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-013
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-013
```

Read the task in [`question.md`](../../../labs/lab-013/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-013
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-013
astrona start account-lifecycle-playground
```
