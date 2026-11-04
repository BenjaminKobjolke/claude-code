#!/usr/bin/env pwsh
# Runs the patched node wrapper so the Windows daemon pre-start happens (see patch.bat)
$basedir = Split-Path $MyInvocation.MyCommand.Definition -Parent
$wrapper = "$basedir/node_modules/agent-browser/bin/agent-browser.js"
if (Test-Path "$basedir/node.exe") {
  & "$basedir/node.exe" $wrapper $args
} else {
  & node $wrapper $args
}
exit $LASTEXITCODE
