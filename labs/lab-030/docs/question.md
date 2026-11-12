# Question

Solve this question on: `terminal`

Astronaut, this capstone mission puts the whole briefing pack together on one ship: a ship-wide note for everyone who comes aboard through the main airlock, a personal note for one crew member, and a personal tools deck added to that crew member's search list without letting an impostor in.

Onboarding for this host requires three separate, correctly-scoped configuration changes:

1. Every login shell on this system (fresh SSH connections and console logins) must have `ONBOARD_PORTAL=https://portal.internal/onboarding` set, using the proper system-wide drop-in mechanism for real shell syntax. This does not need to reach non-login interactive shells.
2. User `candidate` (only) wants `EDITOR=nano` set as a personal preference in their own login-shell profile, without affecting any other account.
3. User `candidate` has a personal tools directory at `~/bin` containing `deploy-helper`. Add `~/bin` to `candidate`'s `PATH` persistently, in a way that survives new login shells, without shadowing any existing system command.

Prove all three with evidence from a fresh session, and confirm a same-named decoy script placed in `~/bin` never overrides a real system command.

The grader checks that a script in `/etc/profile.d/` exports `ONBOARD_PORTAL` and that a fresh `su - candidate` sees `https://portal.internal/onboarding`; that `EDITOR=nano` is exported in `candidate`'s `~/.bash_profile`, `~/.bash_login` or `~/.profile`, seen in a fresh login, and set in no other account's dotfiles; and that `/home/candidate/bin` is in `PATH` after `/usr/bin`, `deploy-helper` runs by name, and a decoy `~/bin/id` it plants does not win over the real `id`.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-01](../../../sections/section-030/module-01/course.md), [module-02](../../../sections/section-030/module-02/course.md).

The grader checks:

- Confirms ONBOARD_PORTAL is exported system-wide for login shells via /etc/profile.d/.
- Confirms EDITOR=nano is set only in candidate's own login-shell profile.
- Confirms ~/bin is appended (not prepended) to candidate's PATH and a decoy script there never shadows a real system command.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
