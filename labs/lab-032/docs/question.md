# Question

Solve this question on: `terminal`

Astronaut, a crew member keeps their own tools on a personal deck and wants to call them by name from anywhere. Add that deck to the search list so no impostor there can ever answer to a real crew member's name.

User `candidate` has a personal scripts directory at `~/work` containing a helper tool called `helper-tool`, and wants to be able to run it by name from anywhere without typing the full path.

1. Add `~/work` to `candidate`'s `PATH` persistently, in a way that survives new login shells, without shadowing any existing system command (a script in `~/work` should only run if no system command by that name already exists).
2. Prove the change works by running `helper-tool` by name alone in a fresh session.
3. Prove it does **not** shadow an existing command: a same-named decoy script named `ls` will be placed in `~/work`, and the real system `ls` must still win.

The grader checks, from a fresh `su - candidate` login shell, that `/home/candidate/work` is in `PATH` after `/usr/bin` and that `helper-tool` runs by name. It then plants its own decoy `~/work/ls` and checks that `type -P ls` does not point at it and that running `ls` does not run the decoy.
