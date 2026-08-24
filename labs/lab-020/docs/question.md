# Question

Solve this question on: `terminal`

Your team selected you for this task because of your access-control and resource-limit expertise. Solve the following steps:

There is a shared directory `/srv/data/atlas`, owned by `lead-dev:atlas-team` with mode `750`. An external vendor contact, `vendor-lee`, is not a member of `atlas-team` and must not be added to it, but needs read-write access to the entire tree, including existing files. A QA reviewer, `qa-nina`, similarly needs read-only access without joining the group. Set this up with ACLs, and make sure any file or subdirectory created under `/srv/data/atlas` from now on automatically inherits both grants.

Separately, user `derek` has a `.bashrc` line that sets only a **soft** `nproc` limit — find the value currently in effect for him, configure that same number as a proper PAM-enforced **hard** limit, and remove the old `.bashrc` line. Finally, enforce that every member of group `supportstaff` can only ever have one login session at a time, using `maxlogins`.
