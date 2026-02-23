param(
  [string]$Region = "us-east-2",
  [string]$OutFile = ".\aws-audit.html",
  [string]$Profile = ""   # 可选：例如 -Profile "dev"
)

# Build CLI prefix
$Aws = "aws"
if ($Profile -and $Profile.Trim().Length -gt 0) {
  $Aws = "aws --profile $Profile"
}

function RunJson($cmd) {
  try {
    $out = Invoke-Expression $cmd
    if (-not $out) { return @() }
    return $out | ConvertFrom-Json
  } catch {
    return $null
  }
}

function RunText($cmd) {
  try {
    return Invoke-Expression $cmd
  } catch {
    return $null
  }
}

# HTML escape
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

# ---------- 1) EC2 Running Instances ----------
$instances = RunJson "$Aws ec2 describe-instances --region $Region --output json"
$running = @()
if ($instances) {
  foreach ($r in $instances.Reservations) {
    foreach ($i in $r.Instances) {
      if ($i.State.Name -eq "running") {
        $nameTag = ($i.Tags | Where-Object {$_.Key -eq "Name"} | Select-Object -First 1).Value
        $running += [pscustomobject]@{
          Name       = $nameTag
          InstanceId = $i.InstanceId
          Type       = $i.InstanceType
          AZ         = $i.Placement.AvailabilityZone
          PublicIp   = $i.PublicIpAddress
          PrivateIp  = $i.PrivateIpAddress
        }
      }
    }
  }
}

# ---------- 2) Elastic IPs ----------
$eips = RunJson "$Aws ec2 describe-addresses --region $Region --output json"
$eipList = @()
if ($eips) {
  foreach ($a in $eips.Addresses) {
    $eipList += [pscustomobject]@{
      PublicIp          = $a.PublicIp
      AllocationId      = $a.AllocationId
      AssociationId     = $a.AssociationId
      InstanceId        = $a.InstanceId
      NetworkInterfaceId= $a.NetworkInterfaceId
      Unassociated      = [bool](-not $a.AssociationId -and -not $a.InstanceId -and -not $a.NetworkInterfaceId)
    }
  }
}

# ---------- 3) NAT Gateways ----------
$nats = RunJson "$Aws ec2 describe-nat-gateways --region $Region --output json"
$natList = @()
if ($nats) {
  foreach ($ngw in $nats.NatGateways) {
    $natList += [pscustomobject]@{
      NatGatewayId = $ngw.NatGatewayId
      State        = $ngw.State
      VpcId        = $ngw.VpcId
      SubnetId     = $ngw.SubnetId
    }
  }
}

# ---------- 4) Load Balancers (ELBv2) ----------
$lbs = RunJson "$Aws elbv2 describe-load-balancers --region $Region --output json"
$lbList = @()
if ($lbs) {
  foreach ($lb in $lbs.LoadBalancers) {
    $lbList += [pscustomobject]@{
      Name   = $lb.LoadBalancerName
      Type   = $lb.Type
      Scheme = $lb.Scheme
      State  = $lb.State.Code
      DNS    = $lb.DNSName
    }
  }
}

# ---------- 5) Security Groups ----------
$sgs = RunJson "$Aws ec2 describe-security-groups --region $Region --output json"
$sgList = @()
if ($sgs) {
  foreach ($sg in $sgs.SecurityGroups) {
    $inCount  = if ($sg.IpPermissions) { $sg.IpPermissions.Count } else { 0 }
    $outCount = if ($sg.IpPermissionsEgress) { $sg.IpPermissionsEgress.Count } else { 0 }

    # quick & dirty "wide open" detection
    $wideOpenIn = $false
    if ($sg.IpPermissions) {
      foreach ($perm in $sg.IpPermissions) {
        if ($perm.IpRanges) {
          foreach ($r in $perm.IpRanges) {
            if ($r.CidrIp -eq "0.0.0.0/0") { $wideOpenIn = $true }
          }
        }
        if ($perm.Ipv6Ranges) {
          foreach ($r6 in $perm.Ipv6Ranges) {
            if ($r6.CidrIpv6 -eq "::/0") { $wideOpenIn = $true }
          }
        }
      }
    }

    $sgList += [pscustomobject]@{
      GroupName     = $sg.GroupName
      GroupId       = $sg.GroupId
      VpcId         = $sg.VpcId
      InRules       = $inCount
      OutRules      = $outCount
      WideOpenIn    = $wideOpenIn
      Description   = $sg.Description
    }
  }
}

# ---------- 6) Lambda Functions ----------
$lambdas = RunJson "$Aws lambda list-functions --region $Region --output json"
$lambdaList = @()
if ($lambdas) {
  foreach ($fn in $lambdas.Functions) {
    $lambdaList += [pscustomobject]@{
      FunctionName = $fn.FunctionName
      Runtime      = $fn.Runtime
      MemoryMB     = $fn.MemorySize
      TimeoutSec   = $fn.Timeout
      LastModified = $fn.LastModified
      Version      = $fn.Version
    }
  }
}

# ---------- 7) RDS Instances ----------
$rds = RunJson "$Aws rds describe-db-instances --region $Region --output json"
$rdsList = @()
if ($rds) {
  foreach ($db in $rds.DBInstances) {
    $rdsList += [pscustomobject]@{
      DBIdentifier = $db.DBInstanceIdentifier
      Engine       = $db.Engine
      EngineVer    = $db.EngineVersion
      Class        = $db.DBInstanceClass
      Status       = $db.DBInstanceStatus
      MultiAZ      = $db.MultiAZ
      StorageGB    = $db.AllocatedStorage
      Public       = $db.PubliclyAccessible
    }
  }
}

# ---------- 8) EBS Volumes (unattached is a common cost trap) ----------
$vols = RunJson "$Aws ec2 describe-volumes --region $Region --output json"
$volList = @()
if ($vols) {
  foreach ($v in $vols.Volumes) {
    $att = $null
    if ($v.Attachments -and $v.Attachments.Count -gt 0) {
      $att = $v.Attachments[0].InstanceId
    }
    $volList += [pscustomobject]@{
      VolumeId   = $v.VolumeId
      State      = $v.State
      Type       = $v.VolumeType
      SizeGB     = $v.Size
      AZ         = $v.AvailabilityZone
      AttachedTo = $att
      Unattached = [bool]($v.State -eq "available" -and -not $att)
    }
  }
}

# ---------- 9) EBS Snapshots (can silently accumulate) ----------
$snaps = RunJson "$Aws ec2 describe-snapshots --region $Region --owner-ids self --output json"
$snapList = @()
if ($snaps) {
  foreach ($s in $snaps.Snapshots) {
    $snapList += [pscustomobject]@{
      SnapshotId  = $s.SnapshotId
      VolumeId    = $s.VolumeId
      State       = $s.State
      SizeGB      = $s.VolumeSize
      StartTime   = $s.StartTime
      Description = $s.Description
    }
  }
}

# ---------- 10) CloudWatch Log Groups (retention = cost control) ----------
$logs = RunJson "$Aws logs describe-log-groups --region $Region --output json"
$logList = @()
if ($logs) {
  foreach ($lg in $logs.logGroups) {
    $ret = $lg.retentionInDays
    $logList += [pscustomobject]@{
      LogGroupName     = $lg.logGroupName
      StoredBytes      = $lg.storedBytes
      RetentionInDays  = $(if ($ret) { $ret } else { "NeverExpire" })
      KmsKeyId         = $lg.kmsKeyId
    }
  }
}

# ---------- 11) S3 Buckets (global list; region lookup best-effort) ----------
$s3Buckets = RunJson "$Aws s3api list-buckets --output json"
$s3List = @()
if ($s3Buckets) {
  foreach ($b in $s3Buckets.Buckets) {
    $bucketName = $b.Name
    # get-bucket-location can be slow / sometimes blocked by perms; best effort
    $loc = RunJson "$Aws s3api get-bucket-location --bucket $bucketName --output json"
    $bucketRegion = $null
    if ($loc -and $loc.LocationConstraint) { $bucketRegion = $loc.LocationConstraint }
    elseif ($loc -ne $null) { $bucketRegion = "us-east-1" } # AWS returns null for us-east-1
    else { $bucketRegion = "" }

    $s3List += [pscustomobject]@{
      Bucket      = $bucketName
      Created     = $b.CreationDate
      Region      = $bucketRegion
    }
  }
}

# ---------- Build HTML ----------
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$profileText = $(if ($Profile -and $Profile.Trim().Length -gt 0) { $Profile } else { "(default)" })

$html = @"
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta http-equiv="refresh" content="60" />
  <title>AWS Quick Audit ($Region)</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { margin-bottom: 6px; }
    .meta { color: #555; margin-bottom: 18px; }
    table { border-collapse: collapse; width: 100%; margin: 10px 0 24px; }
    th, td { border: 1px solid #ddd; padding: 8px; font-size: 14px; vertical-align: top; }
    th { background: #f4f4f4; text-align: left; }
    .warn { padding: 10px; background: #fff7e6; border: 1px solid #ffe1a3; margin: 14px 0; }
    .ok { padding: 10px; background: #f0fff4; border: 1px solid #c6f6d5; margin: 14px 0; }
    code { background: #f6f8fa; padding: 2px 4px; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>AWS Quick Audit</h1>
  <div class="meta">
    Profile: <b>$profileText</b> &nbsp;|&nbsp; Region: <b>$Region</b> &nbsp;|&nbsp; Generated: <b>$now</b>
  </div>

  <div class="warn">
    <b>Cost traps to watch:</b>
    NAT Gateways, Load Balancers, unassociated Elastic IPs, unattached EBS volumes, EBS snapshots, CloudWatch logs with no retention, idle RDS.
  </div>

  <h2>Running EC2 Instances</h2>
  $(ToTable $running)

  <h2>Elastic IPs</h2>
  $(ToTable $eipList)

  <h2>NAT Gateways</h2>
  $(ToTable $natList)

  <h2>Load Balancers (ELBv2)</h2>
  $(ToTable $lbList)

  <h2>Security Groups</h2>
  $(ToTable $sgList)

  <h2>Lambda Functions</h2>
  $(ToTable $lambdaList)

  <h2>RDS Instances</h2>
  $(ToTable $rdsList)

  <h2>EBS Volumes</h2>
  $(ToTable $volList)

  <h2>EBS Snapshots</h2>
  $(ToTable $snapList)

  <h2>CloudWatch Log Groups</h2>
  $(ToTable $logList)

  <h2>S3 Buckets</h2>
  $(ToTable $s3List)

  <p style="color:#666">
    Refresh workflow: run <code>.\aws-audit.ps1 -Region $Region</code>
    $(if ($Profile -and $Profile.Trim().Length -gt 0) { " -Profile $Profile" } else { "" })
    again, then refresh this page.
  </p>
</body>
</html>
"@

Set-Content -Path $OutFile -Value $html -Encoding UTF8
Write-Host "Wrote report: $OutFile"
Start-Process $OutFile
