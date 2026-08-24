# Question

Solve this question on: `terminal`

User `jackie` caused an issue by running a program that forked far too many subprocesses. A coworker already tried to limit this by adding a `ulimit -Sp <n>` line to jackie's `.bashrc`, which only sets a **soft** limit and only applies to interactive shells. Jackie's password is `brown` if needed.

1. Find the soft `nproc` limit currently in effect for jackie.
2. Configure that exact number as a proper **hard** `nproc` limit for jackie, enforced the correct way (not via `.bashrc`).
3. Remove the old `.bashrc` hack now that the proper fix is in place.
4. Separately, enforce that members of group `operators` can only ever have one login session at a time, using `maxlogins`.

Note: an interactive live-login test of the `maxlogins` restriction may not be possible from this session — the configuration itself, verified by inspection, is the deliverable.
