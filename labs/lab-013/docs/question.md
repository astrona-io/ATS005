# Question

Solve this question on: `app-srv1`

Astronaut, three crew members on this ship are at different stages of their time aboard. One is new, one is under investigation, and one has left for good.

1. Create the user `contractor7` using the system's normal defaults. Do not override the shell or the home base path, and confirm what those defaults really are before you rely on them. Force `contractor7` to set their own password at the next login (they must not start with a usable password already set). Set the account to fully expire (not just the password) in 30 days.
2. The existing account `contractor3` is under investigation and must be locked out immediately, without deleting the account or losing its configuration.
3. The fully offboarded account `contractor1` must be removed entirely, including its home directory.

The grader checks that `contractor7` has the shell and home base from `useradd -D` with its home on disk, that its password "last changed" field is `0`, and that its account expires in about 30 days; that `contractor3` still exists with `passwd -S` status `L` and a `!` in front of its hash; and that `contractor1` and `/home/contractor1` are gone.
