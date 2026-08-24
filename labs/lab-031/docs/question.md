# Question

Solve this question on: `terminal`

The infrastructure team needs `COMPANY_PROXY=http://proxy.internal:3128` available to every user on this system, for both login **and** non-login interactive shells, without editing any individual user's dotfiles — using the proper system-wide drop-in mechanism.

Separately, user `candidate` (only) wants `EDITOR=vim` set as a personal preference in their own profile, without affecting any other account.

Demonstrate that both are correctly applied in a fresh session for each case.
