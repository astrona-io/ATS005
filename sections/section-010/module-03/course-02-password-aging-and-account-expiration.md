# Password Aging And Account Expiration

Astronaut, a door code can run out, and so can a boarding pass. They are two different things, and a task that says "password" or "account" is testing whether you know which one to set. This part shows you both and how to read them back.

## Two different fields

People often mix these two up. Seeing them side by side in one `chage -l` listing is the fastest way to keep them apart.

### Set both, read both back

Give `contractor7` a 30-day maximum password age and an account that expires in 30 days, then list the dates:

<!-- astrona:playground:renew -->

```sh
sudo chage -M 30 contractor7
sudo chage -E "$(date -d '+30 days' +%F)" contractor7
sudo chage -l contractor7
```

Expect something like:

```text
Last password change					: password must be changed
Password expires					: password must be changed
Password inactive					: never
Account expires						: Sep 29, 2026
Minimum number of days between password change		: 0
Maximum number of days between password change		: 30
```

`-M` changed "Maximum number of days between password change" to `30`. `-E` set "Account expires" to a real date. They are different lines because they are different mechanisms. `chage -l` (for **l**ist) is how you confirm a change landed, because `chage` itself prints nothing when it succeeds.

### What each option limits

Now the rule behind that output:

- `chage -M <days>` sets the **maximum password age**: how long the *current password* stays valid before the user must change it. The account itself lives on; only the password's life is limited. Think of it as the rule that the door code must change every few weeks.
- `chage -E <date>` sets a hard **account expiration date**. After it, the account cannot log in *at all*, whatever the password. Think of it as the date the crew member's boarding pass stops working.

### Expiry is checked at login

The expiration date is checked when someone logs in, not afterwards. Setting it does not end a session that is already open. If a task means "remove them now", ending their running sessions is a separate step.

## Common pitfalls

> [!WARNING]
> - **Using `-M` when the task says the account must expire.** `-M` only limits the password. Use `-E` with a date.
> - **Trusting a silent `chage`.** It prints nothing on success. Read the result with `chage -l <user>`.
> - **Expecting `-E` to end an open session.** It only stops new logins.
