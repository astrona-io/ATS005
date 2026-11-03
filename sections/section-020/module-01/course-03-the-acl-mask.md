# The ACL Mask

Astronaut, every guest list has a ceiling written at the bottom, and almost nobody reads it. This part shows you what the `mask` entry caps, how to see it cap an entry, and how to clear it.

## What the mask caps

Every extended ACL has a `mask` entry. Think of it as the ceiling on the guest list: nobody on the list gets more than the mask allows. You saw `mask::rwx` appear on its own the first time you added named entries.

### Narrow the mask and watch an entry get capped

Set the mask on `/srv/projects/orion` to `r-x` by hand, read the ACL, then add an entry again and read the mask once more:

<!-- astrona:playground:renew -->

```sh
sudo setfacl -m m::r-x /srv/projects/orion
getfacl /srv/projects/orion
sudo setfacl -m u:contractor-jane:rwx /srv/projects/orion
getfacl /srv/projects/orion | grep -E 'mask|contractor-jane'
```

Expect something like:

```text
user:contractor-jane:rwx			#effective:r-x
user:auditor-tom:r-x
mask::r-x
...
user:contractor-jane:rwx
mask::rwx
```

With `mask::r-x`, `contractor-jane`'s `rwx` entry is marked `#effective:r-x`. She loses write access even though her entry says `rwx`. Running any `setfacl -m u:…` again recalculates the mask back to `rwx`, which clears the cap.

### The rule behind it

The mask **caps the real permission** of every named-user entry, every named-group entry and the owning-group entry. It does not cap the file owner entry or `other`; the standard bits still govern those. That makes the mask the one place to restrict every extended entry at once.

`setfacl -m` recalculates the mask by itself, to the combination of every entry's permissions. That is why `mask::rwx` appeared without you setting it. The same automatic step is also the trap. If someone sets the mask *by hand* to something narrower, every named entry is quietly capped to it, whatever the entry itself says. An entry that reads `rwx` against an `r-x` mask behaves as `r-x`. `getfacl` marks a capped entry with `#effective:`.

> [!TIP]
> If an ACL ever grants less than it reads, check the `mask::` line and look for `#effective:` before you change anything else.

## Common pitfalls

> [!WARNING]
> - **An entry that "does not work".** A narrowed `mask` is capping it. `getfacl` shows `#effective:`. Run `setfacl -m` on any entry to recalculate the mask.
> - **Expecting the mask to cap the owner or `other`.** It caps named entries and the owning group only. The owner and `other` follow the standard bits.
> - **Fixing a capped entry with `chmod`.** On a file with an ACL, `chmod` on the group bits changes the mask, not the owning group. Check `getfacl` afterwards.
