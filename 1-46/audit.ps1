param(
  [string]$Region = "us-east-2",
  [string]$OutFile = ".\aws-audit.html"
)

function RunJson($cmd) {
  try {
    $out = Invoke-Expression $cmd
    if (-not $out) { return @() }
    return $out | ConvertFrom-Json
  } catch {
    return $null
  }
}

# 1) EC2 Running instances
$instances = RunJson "aws ec2 describe-instances --region $Region --output json"
$running = @()
if ($instances) {
  foreach ($r in $instances.Reservations) {
    foreach ($i in $r.Instances) {
      if ($i.State.Name -eq "running") {
        $nameTag = ($i.Tags | Where-Object {$_.Key -eq "Name"} | Select-Object -First 1).Value
        $running += [pscustomobject]@{
          Name = $nameTag
          InstanceId = $i.InstanceId
          Type = $i.InstanceType
          AZ = $i.Placement.AvailabilityZone
          PublicIp = $i.PublicIpAddress
          PrivateIp = $i.PrivateIpAddress
        }
      }
    }
  }
}

# 2) Elastic IPs
$eips = RunJson "aws ec2 describe-addresses --region $Region --output json"
$eipList = @()
if ($eips) {
  foreach ($a in $eips.Addresses) {
    $eipList += [pscustomobject]@{
      PublicIp = $a.PublicIp
      AllocationId = $a.AllocationId
      AssociationId = $a.AssociationId
      InstanceId = $a.InstanceId
      NetworkInterfaceId = $a.NetworkInterfaceId
    }
  }
}

# 3) NAT Gateways (often expensive if left on)
$nats = RunJson "aws ec2 describe-nat-gateways --region $Region --output json"
$natList = @()
if ($nats) {
  foreach ($ngw in $nats.NatGateways) {
    $natList += [pscustomobject]@{
      NatGatewayId = $ngw.NatGatewayId
      State = $ngw.State
      VpcId = $ngw.VpcId
      SubnetId = $ngw.SubnetId
    }
  }
}

# 4) Load Balancers (can cost)
$lbs = RunJson "aws elbv2 describe-load-balancers --region $Region --output json"
$lbList = @()
if ($lbs) {
  foreach ($lb in $lbs.LoadBalancers) {
    $lbList += [pscustomobject]@{
      Name = $lb.LoadBalancerName
      Type = $lb.Type
      Scheme = $lb.Scheme
      State = $lb.State.Code
      DNS = $lb.DNSName
    }
  }
}

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$esc = { param($s) if ($null -eq $s) { "" } else { [System.Web.HttpUtility]::HtmlEncode([string]$s) } }

function ToTable($rows) {
  if (-not $rows -or $rows.Count -eq 0) { return "<p><em>None</em></p>" }
  $cols = $rows[0].PSObject.Properties.Name
  $th = ($cols | ForEach-Object { "<th>$($_)</th>" }) -join ""
  $trs = foreach ($row in $rows) {
    $tds = foreach ($c in $cols) { "<td>$(& $esc $row.$c)</td>" }
    "<tr>" + ($tds -join "") + "</tr>"
  }
  "<table><thead><tr>$th</tr></thead><tbody>" + ($trs -join "") + "</tbody></table>"
}

$html = @"
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta http-equiv="refresh" content="0" />
  <title>AWS Quick Audit ($Region)</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { margin-bottom: 6px; }
    .meta { color: #555; margin-bottom: 18px; }
    table { border-collapse: collapse; width: 100%; margin: 10px 0 24px; }
    th, td { border: 1px solid #ddd; padding: 8px; font-size: 14px; }
    th { background: #f4f4f4; text-align: left; }
    .warn { padding: 10px; background: #fff7e6; border: 1px solid #ffe1a3; margin: 14px 0; }
    code { background: #f6f8fa; padding: 2px 4px; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>AWS Quick Audit</h1>
  <div class="meta">Region: <b>$Region</b> &nbsp;|&nbsp; Generated: <b>$now</b></div>

  <div class="warn">
    <b>Cost traps to watch:</b> NAT Gateways, Load Balancers, unassociated Elastic IPs.
    This page only checks a few common ones.
  </div>

  <h2>Running EC2 Instances</h2>
  $(ToTable $running)

  <h2>Elastic IPs</h2>
  $(ToTable $eipList)

  <h2>NAT Gateways</h2>
  $(ToTable $natList)

  <h2>Load Balancers (ELBv2)</h2>
  $(ToTable $lbList)

  <p style="color:#666">Refresh workflow: run <code>.\aws-audit.ps1 -Region $Region</code> again, then refresh this page.</p>
</body>
</html>
"@

Set-Content -Path $OutFile -Value $html -Encoding UTF8
Write-Host "Wrote report: $OutFile"
Start-Process $OutFile
