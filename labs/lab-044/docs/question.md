# Question

Solve this question on: `terminal`

Astronaut, this ship reads its users from a fleet registry through `sssd`. The users `lfcsuser` and `newcomer` resolve with `getent passwd`, but neither has a home folder, and a first login drops them into `/`.

1. Switch on home creation for logins, using the supported Ubuntu tool, so the shared login steps create a missing home.
2. Add a file `/etc/skel/WELCOME.txt` with any text, so every new home gets a welcome note.
3. Do not create any home folder by hand, and do not change `sssd.conf` or `nsswitch.conf`.

The grader checks that `pam_mkhomedir.so` is an active session line, that `/etc/skel/WELCOME.txt` exists, and then adds a brand new directory user, logs in as that user, and checks that the home was created, is owned by the user and holds `WELCOME.txt` and the shell start files.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-04](../../../sections/section-040/module-04/course.md).

The grader checks:

- Confirms pam_mkhomedir is active in the shared session steps and /etc/skel/WELCOME.txt exists.
- Logs in as a brand new directory user and checks the created home, its owner and the starter file.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
