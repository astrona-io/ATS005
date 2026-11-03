# One Login Per Group Member

Astronaut, some crew members should only ever be aboard once at a time. This part shows you how to cap concurrent logins for every member of a group with one `limits.d` line.

## Who the cap will hit

Before you limit a whole group, check who is in it. You do not want to find out afterwards that someone in the group needs two sessions at once.

### List the members with `getent`

`getent` (short for *get entries*) asks the ship's records officer for a record, the same way the system itself does. It sees members from local files *and* from a directory service. List the `operators` group:

<!-- astrona:playground:renew -->

```sh
getent group operators
```

Expect something like:

```text
operators:x:1005:ops-anna,ops-ben,ops-carl
```

These three crew members are exactly who the cap will hit.

## The `maxlogins` line

`maxlogins` caps how many times one crew member may be aboard at the same time. It is an item that only `pam_limits.so` knows, not a raw kernel limit like `nproc`. It counts the user's open login sessions and refuses a new one past the ceiling.

### Write the group drop-in

Save this as `/etc/security/limits.d/operators-maxlogins.conf`:

```text
@operators  hard  maxlogins  1
```

The `@` prefix makes the domain a group. The line applies to each current and future member of `operators` on their own; it is not one shared pool of logins for the whole group. It relies on the same `session required pam_limits.so` line as any other limit, so it needs no extra PAM wiring.

Nothing needs reloading. Then check the result, by listing every line in every drop-in:

```sh
sudo grep -rn . /etc/security/limits.d/
```

Expect something like:

```text
/etc/security/limits.d/jackie-nproc.conf:1:jackie  hard  nproc  150
/etc/security/limits.d/operators-maxlogins.conf:1:@operators  hard  maxlogins  1
```

Both drop-ins are in place, each with its four columns. A live test, where you open a second login and watch it bounce, needs two separate sessions. That is not always possible from inside one SSH connection. The configuration, checked by inspection like this `grep`, is what you produce.

## Common pitfalls

> [!WARNING]
> - **Forgetting the `@`.** `operators  hard  maxlogins  1` limits a *user* called `operators`, not the group.
> - **Not checking the members first.** `getent group operators` shows exactly who the cap will lock out of a second session.
> - **Expecting a shared pool.** `@operators ... maxlogins 1` gives each member one session; it does not limit the whole group to one session in total.

## Your mission: PAM Hard Limits & maxlogins Lab

You can now replace a `~/.bashrc` limit with a hard PAM limit and cap a group to one login per member. Now prove it in a graded mission: on a fresh ship, `jackie` has a coworker's `ulimit` line in `~/.bashrc`, and the `operators` group needs a login cap.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop pam-limits-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-022
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-022
```

Read the task in [`question.md`](../../../labs/lab-022/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-022
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-022
astrona start pam-limits-playground
```
