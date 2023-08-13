
Param([switch]$display_chart_url, [switch]$save_iframe)

$base = 'https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/dts'

# $date = '2022-12-15'
# 
# $result_raw = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:eq:{0}&page[number]=1&page[size]=300' -f $date)
# 
# $result_raw.data | ft *

# $date = '2022-01-01'

# $date = '2000-01-01'

$date = (Get-Date).AddDays(-1000).ToString('yyyy-MM-dd')

$result_issues_bills_regular_series = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:gte:{0},transaction_type:eq:Issues,security_type:eq:Bills,security_type_desc:eq:Regular Series&fields=record_date,transaction_today_amt&page[number]=1&page[size]=600' -f $date) 
$result_issues_bills_cash_series    = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:gte:{0},transaction_type:eq:Issues,security_type:eq:Bills,security_type_desc:eq:Cash Management Series&fields=record_date,transaction_today_amt&page[number]=1&page[size]=600' -f $date) 
$result_issues_notes =                Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:gte:{0},transaction_type:eq:Issues,security_type:eq:Notes&fields=record_date,transaction_today_amt&page[number]=1&page[size]=600' -f $date) 
$result_issues_bonds =                Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:gte:{0},transaction_type:eq:Issues,security_type:eq:Bonds&fields=record_date,transaction_today_amt&page[number]=1&page[size]=600' -f $date) 

$result_redemptions_bills = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:gte:{0},transaction_type:eq:Redemptions,security_type:eq:Bills&fields=record_date,transaction_today_amt&page[number]=1&page[size]=1000' -f $date) 
$result_redemptions_notes = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:gte:{0},transaction_type:eq:Redemptions,security_type:eq:Notes&fields=record_date,transaction_today_amt&page[number]=1&page[size]=1000' -f $date) 
$result_redemptions_bonds = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_3a?filter=record_date:gte:{0},transaction_type:eq:Redemptions,security_type:eq:Bonds&fields=record_date,transaction_today_amt&page[number]=1&page[size]=1000' -f $date) 

function null_small_amounts ($data)
{
    foreach ($row in $data)
    {
        if ([decimal]$row.transaction_today_amt -lt 100)
        {
            $row.transaction_today_amt = $null
        }
    }
}

# null_small_amounts $result_issues_bills_regular_series.data
# null_small_amounts $result_issues_bills_cash_series.data
# null_small_amounts $result_issues_notes.data
# null_small_amounts $result_issues_bonds.data
# 
# null_small_amounts $result_redemptions_bills.data
# null_small_amounts $result_redemptions_notes.data
# null_small_amounts $result_redemptions_bonds.data

# ----------------------------------------------------------------------

$result_bills_change = for ($i = 0; $i -lt $result_issues_bills_regular_series.data.Count; $i++)
{
    [pscustomobject] @{
        record_date = $result_issues_bills_regular_series.data[$i].record_date
        # transaction_today_amt = $result_pdci[$i].transaction_today_amt - $result_pdcr[$i].transaction_today_amt

        transaction_today_amt = ([decimal]$result_issues_bills_regular_series.data[$i].transaction_today_amt + [decimal]$result_issues_bills_cash_series.data[$i].transaction_today_amt) - [decimal]$result_redemptions_bills.data[$i].transaction_today_amt
    }
}

$result_notes_change = for ($i = 0; $i -lt $result_issues_notes.data.Count; $i++)
{
    [pscustomobject] @{
        record_date = $result_issues_notes.data[$i].record_date
        transaction_today_amt = $result_issues_notes.data[$i].transaction_today_amt - $result_redemptions_notes.data[$i].transaction_today_amt
    }
}

$result_bonds_change = for ($i = 0; $i -lt $result_issues_bonds.data.Count; $i++)
{
    [pscustomobject] @{
        record_date = $result_issues_bonds.data[$i].record_date
        transaction_today_amt = $result_issues_bonds.data[$i].transaction_today_amt - $result_redemptions_bonds.data[$i].transaction_today_amt
    }
}

# ----------------------------------------------------------------------

# $json = @{
#     chart = @{
#         type = 'line'
#         # type = 'bar'
#         data = @{
#             labels = $result_issues_bills_regular_series.data.ForEach({ $_.record_date })
#             datasets = @(
#                 @{ label = 'Bills : Regular Series';            data = $result_issues_bills_regular_series.data.ForEach({ $_.transaction_today_amt }); spanGaps = $true; lineTension = 0; fill = $false }
#                 @{ label = 'Notes';                             data = $result_issues_notes.data.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
#                 @{ label = 'Bonds';                             data = $result_issues_bonds.data.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
#                 @{ label = 'Bills : Cash Management Series';    data = $result_issues_bills_cash_series.data.ForEach({ $_.transaction_today_amt }); spanGaps = $true; lineTension = 0; fill = $false }                
#             )
#         }
#         options = @{
#             title = @{ display = $true; text = 'Issues' }
#             scales = @{ }
#         }
#     }
# } | ConvertTo-Json -Depth 100
# 
# $result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'
# 
# # Start-Process $result.url
# 
# $id = ([System.Uri] $result.url).Segments[-1]
# 
# Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)

# ----------------------------------------------------------------------

# $json = @{
#     chart = @{
#         type = 'line'
#         # type = 'bar'
#         data = @{
#             labels = $result_redemptions_bills.data.ForEach({ $_.record_date })
#             datasets = @(
#                 @{ label = 'Bills';                     data = $result_redemptions_bills.data.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
#                 @{ label = 'Notes';                     data = $result_redemptions_notes.data.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
#                 @{ label = 'Bonds';                     data = $result_redemptions_bonds.data.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
#             )
#         }
#         options = @{
#             title = @{ display = $true; text = 'Redemptions' }
#             scales = @{ }
#         }
#     }
# } | ConvertTo-Json -Depth 100
# 
# $result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'
# 
# # Start-Process $result.url
# 
# $id = ([System.Uri] $result.url).Segments[-1]
# 
# Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)

# ----------------------------------------------------------------------

$json = @{
    chart = @{
        # type = 'line'
        type = 'bar'
        data = @{
            labels = $result_bills_change.ForEach({ $_.record_date })
            datasets = @(
                @{ label = 'Bills';                     data = $result_bills_change.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
                @{ label = 'Notes';                     data = $result_notes_change.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
                @{ label = 'Bonds';                     data = $result_bonds_change.ForEach({ $_.transaction_today_amt })               ; spanGaps = $true; lineTension = 0; fill = $false }
            )
        }
        options = @{
            title = @{ display = $true; text = 'Public Debt : Issues - Redemptions' }
            scales = @{ 

                xAxes = @( @{ stacked = $true } ) 
                yAxes = @( @{ stacked = $true } )                                 

            }
        }
    }
} | ConvertTo-Json -Depth 100

$result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'

# Start-Process $result.url

$id = ([System.Uri] $result.url).Segments[-1]

if ($display_chart_url)
{
    Write-Host

    Write-Host ('https://quickchart.io/chart-maker/view/{0}' -f $id) -ForegroundColor Yellow
}
else
{
    Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
}
# ----------------------------------------------------------------------
$html_template = @"
<!DOCTYPE html>
<html>
    <head>
        <title>{0}</title>
    </head>
    <body>
        <div style="padding-bottom: 56.25%; position: relative; display:block; width: 100%;">
            <iframe width="100%" height="100%" src="https://quickchart.io/chart-maker/view/{1}" frameborder="0" style="position: absolute; top:0; left: 0"></iframe>
        </div>
    </body>
</html>
"@

if ($save_iframe)
{
    $html_template -f 'Public Debt : Issues - Redemptions', $id > public-debt-issues-redemptions.html
}


# ----------------------------------------------------------------------
exit
# ----------------------------------------------------------------------

.\treasury-gov-tga-chart-table-iii-a-public-debt-transactions.ps1 -display_chart_url -save_iframe