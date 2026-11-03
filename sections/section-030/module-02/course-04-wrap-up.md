# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about the list of decks the ship searches to find a crew member by name, and how to add a deck without letting an impostor in.

**From [How The Shell Finds A Command](./course-01-how-the-shell-finds-a-command.md):**

- The shell searches `PATH` from left to right and runs the first match.
- `type` shows what a name will really run, including aliases, functions and built-in commands. `which` only scans `PATH`.
- A writable directory at the front of `PATH` lets a same-named file shadow a real command.

**From [Appending And Saving PATH](./course-02-appending-and-saving-path.md):**

- `export PATH="$PATH:$HOME/work"` adds the directory at the end: new tools work, real commands still win.
- Save the line in the login-shell file the account reads first (`~/.profile` on stock Ubuntu), not only in `~/.bashrc`, and check from a fresh login.

**From [The Command-Location Cache](./course-03-the-command-location-cache.md):**

- Bash remembers where it found each command. `hash -r` clears that memory.
- Run `hash -r` before you trust `type` or `which` after a `PATH` change.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Safe PATH Extension & Precedence Lab](../../../labs/lab-032/docs/question.md) | The Command-Location Cache | appended `~/work` to `candidate`'s `PATH` for good, ran `helper-tool` by name, and showed that a decoy `ls` never wins |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Two directories in <code>PATH</code> both contain <code>backup</code>. Which one runs?</summary>

The one in the directory that comes first, reading `PATH` from left to right.
</details>

<details>
<summary>2. Why is <code>type</code> a better check than <code>which</code>?</summary>

`type` also knows about aliases, shell functions and built-in commands, which run before `PATH` is searched. `which` only scans `PATH`.
</details>

<details>
<summary>3. What is the risk of <code>export PATH="$HOME/work:$PATH"</code>?</summary>

A file in `~/work` with the name of a real command, such as `ls` or `sudo`, runs instead of that command.
</details>

<details>
<summary>4. On a stock Ubuntu account, which file should hold a permanent <code>PATH</code> line, and why not <code>~/.bashrc</code>?</summary>

`~/.profile`, the login-shell file the account reads. `~/.bashrc` is read by interactive non-login shells and does not run for every way a session starts.
</details>

<details>
<summary>5. You changed <code>PATH</code>, but <code>type ls</code> still shows the old location. What do you run?</summary>

`hash -r`. It clears bash's memory of command locations so the next lookup is fresh.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy safe-path-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-032
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-030/module-02/playground`. It always starts clean, so nothing you broke carries over.

> *Append, save it in the login file, clear the cache, then trust what `type` tells you.*
