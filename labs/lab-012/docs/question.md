# Question

Solve this question on: `data-001`

Astronaut, this ship's crew teams need sorting out. A new team must be formed with a fixed number, an old team needs a new name, and one team that nobody uses must be disbanded.

1. Create the group `datateam` with GID `5000` exactly. Add the existing users `marta` and `cilla` to it as a supplementary group, without disturbing either user's existing primary group or other supplementary memberships.
2. Rename the group `legacy-ops` (GID `4200`) to `platform-ops` without changing its GID or losing its membership list.
3. Delete the unused group `temp-audit` entirely.

The grader checks that `datateam` has GID `5000` with `marta` and `cilla` as members, that both users still have `staff` as their primary group, that `platform-ops` has GID `4200` and still lists its member `opadmin` while `legacy-ops` is gone, and that `temp-audit` no longer exists.
