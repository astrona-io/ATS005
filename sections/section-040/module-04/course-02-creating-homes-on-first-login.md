# Creating Homes On First Login

Astronaut, you know why the home is missing. This part shows you how to have the login steps build it, from the starter kit, the first time each crew member arrives.

## One switch in the login steps

`pam_mkhomedir` is a login step that runs in the session phase. When a user logs in and the home folder is not there, it creates the folder, sets the owner, and copies `/etc/skel` into it. Ubuntu ships it as a profile you can switch on with one command.

### Add a starter file first

Create a welcome note in the starter kit.

Save this as `/etc/skel/WELCOME.txt`:

<!-- astrona:playground:renew -->

```text
Welcome aboard. Your home was created on your first login.
```

Apply it, by making the note readable for every user:

```sh
sudo chmod 644 /etc/skel/WELCOME.txt
```

Then check the result:

```sh
ls -l /etc/skel/WELCOME.txt
```

### Switch on mkhomedir

Enable the profile. This edits the shared PAM files for you:

```sh
sudo pam-auth-update --enable mkhomedir
grep -n mkhomedir /etc/pam.d/common-session
```

Expect one line in `common-session` that names `pam_mkhomedir.so`. It belongs to the session phase, so it runs on every login that uses the shared files, including `su -` and SSH.

## Prove it with a first login

Run a login as a user who never had a home:

```sh
sudo su - newcomer -c pwd
ls -A /home/newcomer
ls -ld /home/newcomer
```

Expect `/home/newcomer` from `pwd`, the starter files plus `WELCOME.txt` in the listing, and the owner `newcomer` on the folder. A second user, such as `lfcsuser`, gets the same result on their first login.

## Common pitfalls

> [!WARNING]
> - **Editing `common-session` by hand.** The next `pam-auth-update` run can overwrite it. Use the profile.
> - **Adding the starter file after the first login.** That home never gets it. Add files to `/etc/skel` before users arrive.
> - **Testing with the user who already has a home.** Nothing is created the second time. Use a user who never logged in.
> - **Forgetting that mkhomedir is only for the login steps.** A background program that reads `/home/<name>` does not create it.

## Your mission: Home Directories For Directory Users Lab

You can now see why a directory user has no home, and you can have the login steps build one from a starter kit. The mission asks you to do the same on a fresh ship, and the grader will log in as a brand new user.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop mkhomedir-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-044
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-044
```

Read the task in [`question.md`](../../../labs/lab-044/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-044
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-044
astrona start mkhomedir-playground
```
