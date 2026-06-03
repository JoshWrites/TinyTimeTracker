# TinyTimeTracker

A tiny tool that turns a list of work time ranges (like `10:55-12:20`) into
**payroll hours** and saves them to a spreadsheet file (CSV) you can open in Excel.

## Credit

**Conceived, specified, and coded entirely by [Nili-L (Anny Levine)](https://github.com/Nili-L).**

This repository was published on her behalf by [@JoshWrites](https://github.com/JoshWrites) while she was unwell. All design and implementation credit belongs to Nili-L.

## What it does

You give it a list of time ranges — one per line, like this:

```
10:55-12:20
13:30-14:30
9:05-9:20
```

…and it works out how long each one is, adds them all up, and gives you a total
in **decimal hours** (so 1 hour 30 minutes becomes `1.5`). It also saves a
spreadsheet file with every entry and the total.

Times are in 24-hour format (so 1:30 PM is `13:30`). Shifts that run past
midnight (like `23:30-00:15`) are handled automatically.

---

## Quick start (Windows)

This guide assumes you've never used the command line before. Just follow the
steps in order.

### Step 1 — Download the tool

1. Go to the project page: <https://github.com/JoshWrites/TinyTimeTracker>
2. Click the green **`< > Code`** button, then **Download ZIP**.
3. Find the downloaded `TinyTimeTracker-main.zip` (usually in your **Downloads**
   folder), **right-click it → Extract All…**, and pick a place you'll remember,
   like your Desktop.

You now have a folder called `TinyTimeTracker-main`.

### Step 2 — Open PowerShell *in that folder*

This is the easiest way, no typing required:

1. Open the `TinyTimeTracker-main` folder in File Explorer.
2. Click the address bar at the top (where the folder path is shown).
3. Type `powershell` and press **Enter**.

A blue or black window will open. That's PowerShell, and it's already pointed at
the right folder. (PowerShell comes built into Windows — nothing to install.)

### Step 3 — Run it

In the PowerShell window, type this and press **Enter**:

```powershell
.\Convert-PayrollHours.ps1
```

It will ask you to enter your time ranges. Type or paste them **one per line**,
then press **Enter on a blank line** when you're done. You'll see a table and a
total, and a file called `payroll_hours.csv` appears in the folder — double-click
it to open in Excel.

> **If you see a red "running scripts is disabled" error**, Windows is blocking
> the script for safety. Allow it once by pasting this line into PowerShell and
> pressing Enter, then try Step 3 again:
>
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```

---

## Using a file instead of typing

If you keep your times in a text file (for example `times.txt` in the same
folder — a sample one is included), you can point the tool at it:

```powershell
.\Convert-PayrollHours.ps1 -InputFile times.txt
```

### Rounding to the nearest 15 minutes (or other increments)

By default the tool uses your exact minutes. Many workplaces round each entry to
the nearest quarter-hour. Add `-Rounding Quarter` to do that:

```powershell
.\Convert-PayrollHours.ps1 -InputFile times.txt -Rounding Quarter
```

| Option    | Rounds each entry to | Common use                     |
| --------- | -------------------- | ------------------------------ |
| `None`    | exact (default)      | no rounding                    |
| `Quarter` | 15 minutes           | classic US payroll rounding    |
| `Tenth`   | 6 minutes            | legal / agency billing         |
| `Sixth`   | 10 minutes           | —                              |

### Choosing where the spreadsheet is saved

Use `-OutputFile` to name the output file:

```powershell
.\Convert-PayrollHours.ps1 -InputFile times.txt -OutputFile june.csv
```

---

## All options at a glance

- `-InputFile` — a `.txt` file with one time range per line. Leave it off to type
  your times in directly.
- `-OutputFile` — name for the saved spreadsheet. Defaults to `payroll_hours.csv`.
- `-Rounding` — `None`, `Quarter`, `Tenth`, or `Sixth` (see table above).

## Tips & troubleshooting

- **Times must look like `9:05-9:20`** — use a colon (`:`), a hyphen (`-`) between
  the two times, and 24-hour format. Lines that don't match are skipped with a
  yellow warning, so glance at the output to make sure nothing was dropped.
- **The total is rounded down** to two decimals, so it never adds up to more than
  the individual entries.
- **To run it again**, just repeat Step 3 — you don't need to reopen anything.

---

*Want the latest PowerShell (version 7)? It's optional. Install it from the
[Microsoft Store](https://apps.microsoft.com/detail/9mz1snwt0n5d) or with
`winget install Microsoft.PowerShell`, then use `pwsh` instead of `powershell`.*
