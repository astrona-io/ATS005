# Question

Solve this question on: `terminal`

Astronaut, two notes must go into the briefing pack on this ship. One is for every crew member, whichever door they come aboard through. The other is for one crew member only.

The infrastructure team needs `COMPANY_PROXY=http://proxy.internal:3128` available to every user on this system, for both login **and** non-login interactive shells, without editing any individual user's dotfiles, using the proper system-wide drop-in mechanism.

Separately, user `candidate` (only) wants `EDITOR=vim` set as a personal preference in their own profile, without affecting any other account.

Demonstrate that both are correctly applied in a fresh session for each case.

The grader checks that `/etc/environment` has a bare `COMPANY_PROXY=http://proxy.internal:3128` line with no `export`, that no user's dotfiles set `COMPANY_PROXY`, that a fresh `su - candidate` sees it, that `EDITOR=vim` is exported in `candidate`'s `~/.bash_profile`, `~/.bash_login` or `~/.profile`, that a fresh `su - candidate` sees `EDITOR` as `vim`, and that no other account (including `root`) sets `EDITOR` in its dotfiles.
