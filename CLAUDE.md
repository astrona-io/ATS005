# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Plain English

Write the text in Plain English for a general adult audience (18+) without a
university degree. The content must be highly accessible and easy to
understand for non-technical readers, without feeling childish.

Strict guidelines:

1. Target a Flesch-Kincaid Grade Level of 8 or 9 (equivalent to a standard
   newspaper article).
2. Avoid all technical jargon, acronyms, and corporate buzzwords. If a
   technical term is necessary, explain it immediately using an everyday
   analogy.
3. Keep sentences conversational and direct. Split long sentences into two.
4. Use short paragraphs (max 3-4 sentences per paragraph) and clear
   subheadings to make the text scannable.
5. Use the active voice (e.g., "We did this" instead of "This was done by us").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page and a few
  deep-dive parts. The landing page is a map: goals, what to know first, the
  order of the parts, where it fits. The real teaching goes in the parts. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module, the wrap-up links and `astrona.yaml`.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `dev` group to exist"). The wrap-up page is the one
  exception: it recaps each part and links to it.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Keep them, but explain
  each one in plain words, with an everyday analogy, the first time it appears
  in a file. Spell out acronyms on first use, with a short plain meaning.
- **Analogies come from space, and the reader is an astronaut.** When a term
  needs an everyday picture, use space: spaceships, planets, solar systems,
  space stations, mission control, signals, docking, star charts, airlocks,
  even the Death Star. Talk to the reader as an astronaut (for example "your
  first mission", "astronaut, check your flight log"), but not in every
  sentence. Requests are **signals** that ships send to each other. Use one
  analogy per hard idea, keep it short, and keep it the same everywhere (if
  the repository has an analogy glossary, use it). The analogy helps the reader; it
  never replaces the real term, and it never changes code or output.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are normal page
  content, not boxes: a short `###` subsection (for example "See it in your
  playground") with one sentence saying what to do, the command, the real
  output, and one or two sentences saying what it shows. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`. The
  wrap-up lists the missions and ends with cleaning up the playground
  (`astrona list`, `astrona destroy <playground name>`).
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), wrap-up pages or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"slapd"`, `"sssd"`, `"/etc/profile"`).
  - Put the logic on the arrows: `L -->|"sources"| P`,
    `N -->|"getent passwd"| S`, `C -->|"StartTLS"| D`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant C as client`)
    and short message text.
  - Anything longer (full paths, full hostnames) goes in the sentence under
    the diagram.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`ldap://127.0.0.1`,
  `ldaps://localhost:636`), and the Mission Briefing's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  a configuration file (an LDIF file, `sssd.conf`, a `limits.d` drop-in, a
  `profile.d` script, a `sudoers.d` rule) in course parts, playground docs or
  labs, use three separate steps:
  1. "Save this as `/etc/security/limits.d/jackie-nproc.conf`:" followed by a
     plain block (` ```ldif `, ` ```ini `, ` ```bash `, ` ```text `) with only
     the file's content. No `cat > file <<'EOF'`, no `sudo tee file <<EOF`, no
     shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only the command that
     makes the system use the file (`sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f set-tls.ldif`,
     `sudo systemctl restart sssd`, `sudo visudo -c`).
  3. "Then check the result:" followed by the check commands, if any.
  The file name says what the file is for. If a value must come from the
  reader's machine (an IP address), use a placeholder like `<PARTNER>` in the
  file and say how to get the value (`echo $PARTNER`); never put shell
  variables inside a configuration file that does not expand them. Apply a
  file the first time its content appears; do not show it once "to read"
  and paste it again later. Never tell the reader to apply something from
  the playground's `examples/` folder: they start the playground with
  `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_group`, `count_members`,
  `$HOME_DIR`), never single letters.

## About this repo (ATS005 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** pass the **Users and Groups** domain of the **Linux
  Foundation Certified System Administrator (LFCS)** exam. It is 10% of the
  exam.
- **What the exam really tests:** doing real identity and access work on a
  live Linux machine, from a terminal, under time pressure, and leaving the
  machine in the right state. So the student must *do* things (move an
  account's home, add a group without wiping the others, write a scoped
  `sudo` rule, set an ACL, set a limit, export a variable for the right
  shells, wire a client into LDAP), not just recognise words. Every
  explanation should lead to something they can run, and every result should
  be proved with a check command (`id`, `getent`, `chage -l`, `getfacl`,
  `sudo -l -U`, `ldapsearch`, a fresh `bash -lc`).
- **The exam topics this course covers:** creating and managing local user
  and group accounts; managing personal and system-wide environment
  profiles; configuring user resource limits; configuring and managing ACLs;
  and configuring the system to use LDAP user and group accounts.
- **The sections:**

  | Section | Title | Exam topic |
  | --- | --- | --- |
  | 010 | Local Account & Group Lifecycle | Create and manage local user and group accounts |
  | 020 | Access Control & Resource Limits | Configure and manage ACLs; configure user resource limits |
  | 030 | Shell Environment, Profiles & PATH | Manage personal and system-wide environment profiles |
  | 040 | Centralized Identity with LDAP | Configure the system to use LDAP user and group accounts |

- **The version:** every playground and lab runs on **Ubuntu 24.04** in a
  `qemu` virtual machine built from
  `ghcr.io/astrona-io/ubuntu-qcow2-image:24.04-lfcs-{ARCH}`, with **bash**
  as the shell, the `shadow` tools (`useradd`, `usermod`, `chage`),
  **sudo**, **Linux-PAM** (`pam_limits`), **OpenLDAP** (`slapd` with the
  `cn=config` backend) and **SSSD**. Do not teach options or behaviour from
  other distributions without saying so (for example the `wheel` group, or
  `authconfig`, are not how Ubuntu does it).
- **The main sources:** the manual pages on the lab machine (`man useradd`,
  `man usermod`, `man chage`, `man 5 sudoers`, `man setfacl`,
  `man limits.conf`, `man bash`, `man sssd.conf`, `man slapd-config`) and the
  OpenLDAP Administrator's Guide. Check every page against them.

### Space analogy glossary

Use these pictures for these terms, in every course page, lab and playground.
Keep them consistent so the astronaut builds one picture of the universe. It
is the same universe as the other Astrona courses: the learner is an
astronaut, and a single Linux machine is one spaceship. Most pages written
before these rules have no space analogies yet; add them when you rework a
page, using this table.

**The ship**

| Term | Space picture |
| --- | --- |
| The learner | An astronaut (a cadet on their first missions) |
| Linux machine / virtual machine | A spaceship |
| Lab or playground virtual machine (`qemu`) | A training ship in the simulator |
| Kernel | The ship's core: it runs everything and hands out power and time |
| Process | A crew member doing one job |
| Shell (`bash`) | The bridge console where the astronaut types orders |
| `root` / `sudo` | The captain / borrowing the captain's authority for one order |
| File / directory | A crate in the cargo hold / a cargo compartment that holds crates |

**The crew roster: users and groups**

| Term | Space picture |
| --- | --- |
| User account | A crew member's entry on the ship's crew roster |
| `/etc/passwd` | The crew roster: one line per crew member |
| `/etc/shadow` | The locked safe that holds each crew member's door code and its dates |
| `/etc/group` | The list of crew teams and who is on each team |
| UID / GID | The crew member's badge number / the team's number |
| Primary group | The crew member's home team: every new crate they pack gets this team's tag |
| Supplementary group | An extra team badge the crew member also carries, for access only |
| Home directory | The crew member's own quarters |
| `/etc/skel` | The welcome kit placed in every new crew member's quarters |
| `useradd -D` / `/etc/default/useradd` | The standard boarding form: what every new crew member gets unless you say otherwise |
| `usermod -G` vs `usermod -aG` | Taking away every extra badge and handing out new ones vs adding one more badge |
| Login shell (`/bin/bash`, `/usr/sbin/nologin`) | The console a crew member sits at when they come aboard, or none at all |
| `getent` | Asking the ship's records officer, who checks every roster the ship trusts |
| `newgrp` / a fresh login | Putting on a new badge only takes effect when you come aboard again |

**Door codes and account life**

| Term | Space picture |
| --- | --- |
| Password | The crew member's door code |
| Password aging (`chage -M`, `-m`, `-W`) | The rule that the door code must change every few weeks |
| Forced change (`chage -d 0`, `passwd -e`) | "Choose a new door code the next time you come aboard" |
| Account expiration (`chage -E`, `usermod -e`) | The date the crew member's boarding pass stops working, whatever the code |
| Lock (`usermod -L`, `passwd -l`) | Putting a `!` on the door code so it never matches; the crew member stays on the roster |
| `userdel -r` | Taking the crew member off the roster and clearing out their quarters |

**The captain's authority: sudo**

| Term | Space picture |
| --- | --- |
| `/etc/sudoers`, `/etc/sudoers.d/` | The captain's standing orders / extra pages clipped to them |
| Scoped rule (one exact command) | Permission to use the captain's authority for one named order only |
| `NOPASSWD` | That order needs no door code |
| `visudo` | The clerk who checks the standing orders for mistakes before filing them |

**Locks on the cargo: ACLs and limits**

| Term | Space picture |
| --- | --- |
| Owner, group, other bits | The crate's owner, the owner's team, everyone else aboard |
| ACL (access control list) | A guest list taped to one crate or compartment, naming extra crew members and what they may do |
| Named user / named group entry | One line on that guest list |
| ACL mask | The ceiling on that guest list: nobody on it gets more than the mask allows |
| Default ACL | The guest list every new crate in this compartment is born with |
| PAM (Pluggable Authentication Modules) | The airlock checklist every crew member passes through when coming aboard |
| `pam_limits`, `/etc/security/limits.conf`, `limits.d/` | The checklist step that sets each crew member's allowance, and the allowance tables it reads |
| Soft limit / hard limit | The allowance a crew member starts with / the ceiling only the captain can raise |
| `nproc` | How many helpers (processes) one crew member may run at once |
| `maxlogins` | How many times one crew member may be aboard at the same time |
| `ulimit` | A crew member checking or lowering their own allowance from the console |

**The briefing pack: environment and PATH**

| Term | Space picture |
| --- | --- |
| Environment variable / `export` | A line in the briefing pack every new crew member receives / putting a note into that pack |
| Login shell / non-login shell | Coming aboard through the main airlock (full briefing) / opening a new console on a ship you are already on |
| `/etc/environment` | The ship-wide notice board: plain `NAME=value` lines, read by PAM at the airlock |
| `/etc/profile`, `/etc/profile.d/*.sh` | The ship-wide briefing read to everyone who comes aboard through the main airlock |
| `~/.bash_profile`, `~/.profile` | A crew member's personal briefing, read at the main airlock |
| `~/.bashrc` | Notes read every time a new console opens |
| `PATH` | The list of decks the ship searches, in order, to find a crew member by name |
| Shadowing a command | An impostor on an earlier deck answering to a real crew member's name |

**The fleet registry: LDAP and SSSD**

| Term | Space picture |
| --- | --- |
| LDAP directory (`slapd`) | The fleet registry: one shared crew roster that many ships ask |
| DN (distinguished name), base DN `dc=example,dc=com` | The full address of one entry in the registry / the registry's top shelf |
| `ou=people`, `ou=groups` | Drawers in the registry |
| `posixAccount`, `posixGroup` | Registry cards with the fields a ship needs (badge number, quarters, console) |
| LDIF | The paper form you fill in to add or change registry cards |
| `cn=config` | The registry office's own rule book, kept as registry cards too |
| Bind (`-D`, `-W`) | Showing your credentials at the registry window before you ask anything |
| StartTLS (port 389) / LDAPS (port 636) | Sealing a signal after the channel opens / a channel that is sealed from the first moment |
| TLS certificate | The registry's ID badge |
| SSSD | The ship's records officer who asks the fleet registry and keeps a short-term copy |
| NSS, `/etc/nsswitch.conf` | The ship's list of which rosters to ask, and in which order |

### The sample environment the playgrounds and labs use

There is no shared sample application. Every playground and graded lab boots
its own training ship (one Ubuntu 24.04 virtual machine) and its `bootstrap/`
script sets up a small scenario. The account names, group names, paths and
passwords are part of the scenario; use them exactly as the scripts create
them:

| Module | Playground (`metadata.name`) | What the playground sets up |
| --- | --- | --- |
| 010-01 | `user-group-mgmt-playground` | Groups `dev`, `op`, `web`; `user1` (own primary group, in `web`, marker file `ORIGINAL-HOME-MARKER.txt`); `/root/dangerous.sh`; no `/home/accounts` |
| 010-02 | `group-lifecycle-playground` | `marta` (in `staff`, `projectx`), `cilla` (in `staff`, `legacy-ops`); `legacy-ops` GID `4200` with `/srv/legacy-ops`; unused `temp-audit` GID `4300`; GID `5000` free |
| 010-03 | `account-lifecycle-playground` | `contractor3` (password and SSH key, private key at `/root/contractor3_key`); `contractor1` with a file at `/var/backups/contractor1/dump.sql`; `sshd` running |
| 020-01 | `posix-acl-playground` | `/srv/projects/orion` owned by `team-lead:orion-team`, mode `750`; `contractor-jane` and `auditor-tom` outside the group |
| 020-02 | `pam-limits-playground` | `jackie` (password `brown`, `ulimit -Su 150` in `~/.bashrc`), unit `jackie-sleeper`; group `operators` (`ops-anna`, `ops-ben`, `ops-carl`) |
| 030-01 | `env-profiles-playground` | Users `candidate` and `otheruser`; cron job `/etc/cron.d/env-probe`; `env-probe.service` |
| 030-02 | `safe-path-playground` | `candidate` with `/home/candidate/work/helper-tool` |
| 040-01 | `ldap-server-tls-playground` | `slapd` with package defaults on port `389`; certificate and key in `/etc/ldap/certs/` (`ldap-server.crt`, `ldap-server.key`) |
| 040-02 | `ldap-populate-playground` | A TLS-enabled, empty `dc=example,dc=com`; admin `cn=admin,dc=example,dc=com`, password `LdapRoot!2024` |
| 040-03 | `sssd-client-playground` | The populated directory (`developers` GID `5000`, `lfcsuser` UID `10001`, password `LfcsLdap!2024`); `sssd` packages installed, not configured |

| Lab | What the bootstrap sets up |
| --- | --- |
| lab-011 | `user1` with a stale primary group and home, groups for the task, `/root/dangerous.sh` |
| lab-012 | `marta` and `cilla` with primary group `staff`; `legacy-ops` (GID `4200`) with member `opadmin`; unused `temp-audit` |
| lab-013 | `contractor3` (active) and `contractor1` (offboarded, with a home marker file) |
| lab-010 | `analyst9`, `legacy-billing` (GID `7000`, member `billingclerk`), `temp-scratch`, `/root/rotate-logs.sh`, `audit2`, `shortterm3`, `leaver5` |
| lab-021 | `orion-team`, owner `team-lead`, `/srv/projects/orion`, `contractor-jane`, `auditor-tom` |
| lab-022 | `jackie` (password `brown`) with a soft `ulimit -Sp` line in `~/.bashrc`; group `operators` |
| lab-020 | `atlas-team`, `lead-dev`, `/srv/data/atlas`, `vendor-lee`, `qa-nina`; `derek` with a `~/.bashrc` limit line; group `supportstaff` |
| lab-031 | `candidate` (password `password123`) with a clean dotfile baseline |
| lab-032 | `candidate` with a `~/work` scripts directory |
| lab-030 | `candidate` with a `~/bin` tools directory |
| lab-041 | `slapd`, `ldap-utils`, `openssl`, and a self-signed certificate to wire in |
| lab-042 | A TLS-enabled, empty `dc=example,dc=com` (admin password `LdapRoot!2024`) |
| lab-043 | The populated directory and the `sssd` packages, not configured |
| lab-040 | All packages and a certificate; the whole server, directory and client wiring is the task |

Course pages may use small made-up examples to show an idea. When a page
shows a playground's or lab's own names, they must match the tables above.

### Environment facts the text must respect

- **Every machine is a `qemu` virtual machine, not a container.** Labs and
  playgrounds use 2 CPUs, 2048 MB of memory and a 15 GB disk. The learner
  reaches a machine with `astrona ssh <name>`, where the name is the
  `metadata.name` from `config.yaml` (the CLI also accepts it with an
  `astro-` prefix, which older pages use). There is no `kubectl`.
- **Work as a normal user with `sudo`.** Commands that change accounts,
  groups, `/etc` files or the directory use `sudo`; `sudo` needs no
  password on the training ships.
- **Pausing a playground.** The `## Your mission` steps use
  `astrona stop <playground name>` and `astrona start <playground name>`.
  The developer build of the CLI says `stop` and `start` do not support
  `qemu` labs yet; if that is still true when you test, destroy the
  playground instead and run it again after the mission.
- **Packages.** The LDAP labs install `slapd`, `ldap-utils`, `openssl`,
  `sssd`, `sssd-ldap`, `libnss-sss` and `libpam-sss` with `apt-get` in their
  bootstrap scripts (so they need outbound internet); the ACL labs install
  `acl`. Do not tell the reader to install them.
- **Fixed secrets.** The LDAP admin is `cn=admin,dc=example,dc=com` with
  password `LdapRoot!2024`, and `lfcsuser` has `LfcsLdap!2024`. The
  certificate is self-signed for `localhost` and `127.0.0.1`. Graders check
  these exact values.
- **Changes to groups need a new login.** A running session keeps the group
  list it started with. Pages and graders check with `id <user>` or a fresh
  `su - <user>`, not with the reader's own open session.
- **Grading runs from the learner's own terminal** with `astrona submit`, not
  inside the virtual machine.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections table, how to run things | `README.md` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, wrap-up | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Ungraded sandbox for a module | `sections/section-0N0/module-0M/playground/` (`docs/overview.md` says what is in the box, `bootstrap/prepare.sh` sets it up) |
| Section knowledge check (multiple choice) | `sections/section-0N0/quiz.md` |
| Final domain quiz | `sections/final-domain-quiz.md` |
| Graded labs, all in one folder: module labs `lab-0NM` (section `0N0`, module `M`) and section capstones `lab-0N0` | `labs/lab-0NN/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` has `question: "docs/question.md"` and `solution: "docs/solution.md"` |
| `README.md` | Short intro with the run command |
| `docs/question.md` | The exam-style task. Starts with `# Question` and a `Solve this question on:` line that names the machine (`terminal` by default; some labs name the scenario host, for example `app-srv1` or `data-001`); keep that line as it is, the platform may use it to pick a machine |
| `docs/solution.md` | Step-by-step walkthrough with real output |
| `bootstrap/` | Starting state of the machine, never the graded result |
| `validation/` | Grading scripts that check the machine's real state |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has one entry per section under `modules:` (`module-010` to
`module-040`, plus `module-050` for the final quiz). Each section's
`content` lists, in order: the section `README.md`, then for each module its
landing page, its parts, and right after the part a lab tests, a `Question`
reading (`labs/lab-0NN/docs/question.md`) followed by the `type: lab`
entry; the module's wrap-up page comes last. The section quiz and then the
section capstone close the section. Playgrounds are not listed: the landing
page's `<!-- astrona:playground -->` marker shows them.

Every `type: lab` entry (module labs and capstones) carries these fields, in
this order:

```yaml
      - type: reading
        title: Question
        path: labs/lab-011/docs/question.md
      - type: lab
        title: "User & Group Provisioning and Scoped Sudo Lab"
        path: labs/lab-011
        difficulty: intermediate
        estimated_duration: 20m
        topic: local-accounts
        task_kind: build
        tags: [usermod, useradd, primary-group, supplementary-groups, home-directory, sudoers]
        learning_goals:
          - Move an account to a new primary group and home directory, files included
          - Create an account with the right groups, home and shell in one command
          - Grant one exact command through sudo with no password, and nothing more
        resources:
          - name: "useradd manual page (Ubuntu 24.04)"
            url: https://manpages.ubuntu.com/manpages/noble/man8/useradd.8.html
```

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`, `45m`.
- `topic`: exactly one of `local-accounts`, `groups`, `account-lifecycle`,
  `sudo`, `acl`, `resource-limits`, `environment`, `path`, `ldap-server`,
  `ldap-directory`, `ldap-client`.
- `task_kind`: exactly one of `build` (create the result from scratch),
  `troubleshooting` (find and fix what is broken) or `migration` (move a
  working setup to another form or place, for example a `~/.bashrc` hack to
  a real `limits.d` rule). The platform filters labs by it, so it is a
  field of its own, never a tag.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb, saying
  what the learner proves in this lab.
- `resources`: 1 to 4 documentation pages, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed: the
  platform shows them as optional further reading next to the lab.

**Tag list** (lower case, hyphens, never synonyms):

- Accounts: `useradd`, `usermod`, `userdel`, `useradd-defaults`,
  `primary-group`, `supplementary-groups`, `home-directory`, `login-shell`,
  `getent`, `id`
- Groups: `groupadd`, `groupmod`, `groupdel`, `gid`, `gpasswd`, `newgrp`
- Account life: `chage`, `password-aging`, `password-expiry`,
  `account-expiry`, `account-lock`, `shadow`
- Privilege: `sudoers`, `sudoers-d`, `visudo`, `nopasswd`
- ACLs: `setfacl`, `getfacl`, `named-entries`, `acl-mask`, `default-acl`,
  `recursive`
- Limits: `pam`, `pam-limits`, `limits-conf`, `limits-d`, `nproc`,
  `maxlogins`, `ulimit`, `hard-limit`
- Environment: `environment-variables`, `etc-environment`, `profile-d`,
  `bash-profile`, `bashrc`, `login-shell-startup`, `path`,
  `command-shadowing`
- LDAP: `slapd`, `cn-config`, `ldif`, `ldapadd`, `ldapsearch`,
  `ldapwhoami`, `posix-account`, `posix-group`, `starttls`, `ldaps`,
  `tls-certificates`
- Client: `sssd`, `nsswitch`, `nss`, `local-accounts-intact`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-01/playground
astrona ssh user-group-mgmt-playground        # open a terminal on the machine
astrona stop user-group-mgmt-playground       # pause it while a lab runs
astrona start user-group-mgmt-playground
astrona destroy user-group-mgmt-playground    # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live virtual machine)
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-011
astrona ssh ats-005-lab-011
astrona submit -c labs/lab-011
astrona destroy ats-005-lab-011

# Authors: run a local, uncommitted copy and check its configuration
astrona run -c labs/lab-011
astrona validate -c labs/lab-011
```

Names: a playground is named in its `config.yaml` (see the playground table
above). Labs are `ats-005-lab-<section><module>`, for example
`ats-005-lab-011`, and section capstones `ats-005-lab-<section>0`, for
example `ats-005-lab-010`. A new lab takes the next free number in its
section, so two labs never share a name. The local developer build of
`astrona validate` may report `unknown field "solution"` and `"question"` in
`metadata.docs`; that is a validator issue, not a lab issue. Keep the keys.

Graders check **the machine's real state** (the `passwd`, `group` and
`shadow` records, files in the right place, `sudo -l -U` output, the ACL
entries, the `limits.d` files, a fresh login shell's environment, real
`ldapsearch` and `getent` answers), not what the learner typed. A lab's
`question.md` and `solution.md` must match what its `validation/` scripts
actually check.

Test machines on the maintainer's computer: one at a time. Podman has 10 GiB
and also runs the platform stack; parallel labs run it out of memory.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Ubuntu 24.04 manual pages:** <https://manpages.ubuntu.com/> (noble):
  `useradd`, `usermod`, `userdel`, `groupadd`, `groupmod`, `chage`,
  `passwd`, `sudoers`, `visudo`, `setfacl`, `getfacl`, `acl`,
  `limits.conf`, `pam_limits`, `pam_env`, `environment`, `sssd.conf`,
  `sssd-ldap`, `nsswitch.conf`, `slapd-config`, `ldapadd`, `ldapsearch`.
- **Bash startup files:** the Bash Reference Manual,
  <https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html>.
- **OpenLDAP:** the OpenLDAP Software Administrator's Guide,
  <https://www.openldap.org/doc/admin26/> (configuration, TLS).
- **Ubuntu server guides:** <https://documentation.ubuntu.com/server/>
  (OpenLDAP, SSSD with LDAP, user management).
- **SSSD:** <https://sssd.io/docs/>.
- **The exam itself:** the LFCS page on the Linux Foundation training site
  lists the official curriculum. The domain weight (10%) and the exam topic
  names above come from this repository's README and `astrona.yaml` and have
  not been re-checked against it.

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository: planning
(`domain-plan`), creating the tree (`domain-scaffold`), building modules
(`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds (`lab`),
lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
