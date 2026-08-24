# Question

Solve this question on: `terminal`

There is a shared project directory `/srv/projects/orion`, owned by `team-lead:orion-team` with standard `750` permissions.

1. Grant user `contractor-jane` (not a member of `orion-team`, and must not be made one) read-write access to the entire `/srv/projects/orion` tree, including all files and subdirectories already inside it.
2. Grant user `auditor-tom` (also not a member of `orion-team`) read-only access to the same tree.
3. Neither the directory's owner (`team-lead`) nor its group (`orion-team`) may change, and the base permission mode must stay as it is.
4. Configure things so that any file or subdirectory created under `/srv/projects/orion` from now on automatically inherits both contractor-jane's and auditor-tom's access, with no manual `setfacl` re-run required.
