# Question

Solve this question on: `terminal`

Onboarding for this host requires three separate, correctly-scoped configuration changes:

1. Every login shell on this system (fresh SSH connections and console logins) must have `ONBOARD_PORTAL=https://portal.internal/onboarding` set, using the proper system-wide drop-in mechanism for real shell syntax — this does not need to reach non-login interactive shells.
2. User `candidate` (only) wants `EDITOR=nano` set as a personal preference in their own login-shell profile, without affecting any other account.
3. User `candidate` has a personal tools directory at `~/bin` containing `deploy-helper`. Add `~/bin` to `candidate`'s `PATH` persistently, in a way that survives new login shells, without shadowing any existing system command.

Prove all three with evidence from a fresh session, and confirm a same-named decoy script placed in `~/bin` never overrides a real system command.
