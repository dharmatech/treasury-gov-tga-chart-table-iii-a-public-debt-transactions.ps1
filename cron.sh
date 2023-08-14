#!/bin/sh

cd /var/www/dharmatech.dev/data/treasury-gov-tga-chart-table-iii-a-public-debt-transactions.ps1

pwsh ./treasury-gov-tga-chart-table-iii-a-public-debt-transactions.ps1 -display_chart_url -save_iframe

cp public-debt-issues-redemptions.html ../reports

# tmux new-session -d -x 300 bash -c 'script -q -c ./to-report.sh'
