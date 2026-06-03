<#
.SYNOPSIS
    Converts start/end time ranges into payroll hour entries and writes a CSV.

.DESCRIPTION
    Reads time ranges in "H:MM-H:MM" format (e.g. "10:55-12:20"), one per line,
    computes the duration of each, and totals them into decimal payroll hours.

    Input can come from:
      - a text file passed with -InputFile
      - pasted/typed interactively (just run the script with no -InputFile)

.PARAMETER InputFile
    Optional path to a .txt file with one time range per line.

.PARAMETER OutputFile
    Path for the CSV output. Defaults to "payroll_hours.csv" in the current folder.

.PARAMETER Rounding
    Rounding policy applied to EACH entry's decimal hours before totaling.
    One of: None, Quarter, Tenth, Sixth  (see Get-RoundedHours below).

.EXAMPLE
    .\Convert-PayrollHours.ps1
    (then paste your times, press Enter on a blank line to finish)

.EXAMPLE
    .\Convert-PayrollHours.ps1 -InputFile times.txt -OutputFile june.csv -Rounding Quarter
#>

param(
    [string]$InputFile,
    [string]$OutputFile = "payroll_hours.csv",
    [ValidateSet("None", "Quarter", "Tenth", "Sixth")]
    [string]$Rounding = "None"
)

# --- Rounding policy ---------------------------------------------------------
# Rounds a single entry's raw decimal hours to the nearest increment for the
# chosen policy, using BANKER'S ROUNDING (round-half-to-even) at the exact
# midpoint. Banker's is [math]::Round's default, and it's "neutral" — over many
# exactly-half cases it doesn't systematically favor employer or employee.
#
# Increments:
#   "Quarter" -> nearest 0.25 hr (15-min) — classic US "7-minute rule".
#   "Tenth"   -> nearest 0.10 hr (6-min)  — common in legal/agency billing.
#   "Sixth"   -> nearest 1/6 hr (10-min).
#   "None"    -> exact, no increment rounding.
#
# Note on the totaling strategy (handled in the main loop, not here):
#   each entry is kept to 3 decimals and those are SUMMED; the grand total is
#   then floored to 2 decimals. So this function only owns the per-entry
#   increment + midpoint rule.
function Get-RoundedHours {
    param(
        [double]$Hours,
        [string]$Policy
    )

    # "None" returns the exact value; the caller still trims it to 3 decimals.
    if ($Policy -eq "None") { return $Hours }

    $increment = switch ($Policy) {
        "Quarter" { 0.25 }
        "Tenth"   { 0.10 }
        "Sixth"   { 1.0 / 6.0 }
    }

    # Round to the nearest whole number of increments. [math]::Round with no
    # digit count uses MidpointRounding.ToEven (banker's), so an exact half
    # (e.g. 0.125 hr under quarter rounding) breaks toward the even increment.
    return [math]::Round($Hours / $increment) * $increment
}
# -----------------------------------------------------------------------------

function Get-EntryMinutes {
    param([string]$Start, [string]$End)

    $startTime = [datetime]::ParseExact($Start.Trim(), "H:mm", $null)
    $endTime   = [datetime]::ParseExact($End.Trim(),   "H:mm", $null)

    $minutes = ($endTime - $startTime).TotalMinutes

    # Handle shifts that cross midnight (e.g. 23:30-00:15): end is "earlier"
    # than start, so add a full day.
    if ($minutes -lt 0) {
        $minutes += 24 * 60
    }

    return $minutes
}

# --- Gather input ------------------------------------------------------------
if ($InputFile) {
    if (-not (Test-Path $InputFile)) {
        Write-Error "Input file not found: $InputFile"
        exit 1
    }
    $lines = Get-Content $InputFile
}
else {
    Write-Host "Enter time ranges one per line (e.g. 10:55-12:20)."
    Write-Host "Press Enter on a blank line when done:`n"
    $lines = @()
    while ($true) {
        $line = Read-Host
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        $lines += $line
    }
}

# --- Process -----------------------------------------------------------------
$entries = @()
$index = 0
$totalMinutes = 0
$hoursSum = 0.0   # running sum of the per-entry (3-decimal) hours

foreach ($line in $lines) {
    $line = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    if ($line -notmatch '^\s*(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\s*$') {
        Write-Warning "Skipping unrecognized line: '$line'"
        continue
    }

    $start = $matches[1]
    $end   = $matches[2]
    $index++

    $minutes = Get-EntryMinutes -Start $start -End $end
    $totalMinutes += $minutes

    # Per-entry: increment + banker's rounding, then trimmed to 3 decimals.
    # These 3-decimal values are what we sum for the total.
    $decimal = [math]::Round((Get-RoundedHours -Hours ($minutes / 60) -Policy $Rounding), 3)
    $hoursSum += $decimal

    $entries += [pscustomobject]@{
        Entry          = $index
        Start          = $start
        End            = $end
        Minutes        = [int]$minutes
        "Decimal Hours" = $decimal
    }
}

# --- Total row ---------------------------------------------------------------
# Sum of the per-entry 3-decimal hours, then rounded DOWN (floored) to 2
# decimals. Floor — not round — so the paid total never exceeds the summed
# line items.
$totalDecimal = [math]::Floor($hoursSum * 100) / 100
$entries += [pscustomobject]@{
    Entry          = "TOTAL"
    Start          = ""
    End            = ""
    Minutes        = [int]$totalMinutes
    "Decimal Hours" = $totalDecimal
}

# --- Output ------------------------------------------------------------------
$entries | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
$entries | Format-Table -AutoSize

$hrs = [math]::Floor($totalMinutes / 60)
$min = $totalMinutes % 60
Write-Host ""
Write-Host ("Total: {0} minutes ({1}h {2}m clock time) = {3} payroll hours" -f `
    [int]$totalMinutes, $hrs, $min, $totalDecimal)
Write-Host "Saved to: $OutputFile"
