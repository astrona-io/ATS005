# Question

Solve this question on: `terminal`

Astronaut, this capstone mission puts guest lists and crew allowances together on one ship. Solve the following steps:

There is a shared directory `/srv/data/atlas`, owned by `lead-dev:atlas-team` with mode `750`. An external vendor contact, `vendor-lee`, is not a member of `atlas-team` and must not be added to it, but needs read-write access to the entire tree, including existing files. A quality assurance (QA) reviewer, `qa-nina`, similarly needs read-only access without joining the group. Set this up with access control lists (ACLs), and make sure any file or subdirectory created under `/srv/data/atlas` from now on automatically inherits both grants.

Separately, user `derek` has a `.bashrc` line that sets only a **soft** `nproc` limit — find the value currently in effect for him, configure that same number as a proper PAM-enforced **hard** limit, and remove the old `.bashrc` line. Finally, enforce that every member of group `supportstaff` can only ever have one login session at a time, using `maxlogins`.

The grader checks that `/srv/data/atlas` is still owned by `lead-dev:atlas-team`, that it and the files already inside it carry `user:vendor-lee:rwx` and `user:qa-nina:r-x`, that matching `default:` entries make a new file inherit both, that a `derek hard nproc <n>` line with the number planted in his `.bashrc` exists in `limits.conf` or `limits.d`, that the `ulimit -Sp` line is gone from `/home/derek/.bashrc`, and that a `@supportstaff hard maxlogins 1` line exists.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-01](../../../sections/section-020/module-01/course.md), [module-02](../../../sections/section-020/module-02/course.md), [module-03](../../../sections/section-020/module-03/course.md), [module-04](../../../sections/section-020/module-04/course.md).

The grader checks:

- Confirms vendor-lee (rwx) and qa-nina (r-x) named ACL entries exist on /srv/data/atlas and pre-existing files/ownership are intact.
- Confirms default ACL entries are set and a newly created file automatically inherits both named entries.
- Confirms a proper hard nproc limit for derek exists in limits.d matching the originally planted soft value, and the .bashrc hack is removed.
- Confirms an @supportstaff hard maxlogins 1 entry exists under limits.d.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
