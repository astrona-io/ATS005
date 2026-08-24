# Question

Solve this question on: `terminal`

User `candidate` has a personal scripts directory at `~/work` containing a helper tool called `helper-tool`, and wants to be able to run it by name from anywhere without typing the full path.

1. Add `~/work` to `candidate`'s `PATH` persistently, in a way that survives new login shells — without shadowing any existing system command (a script in `~/work` should only run if no system command by that name already exists).
2. Prove the change works by running `helper-tool` by name alone in a fresh session.
3. Prove it does **not** shadow an existing command: a same-named decoy script named `ls` will be placed in `~/work`, and the real system `ls` must still win.
