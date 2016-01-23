function Get-MailboxStatisticsAndAlias
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True)]
        $Identity,
        [switch]$Archive,
        [switch]$IncludeMoveHistory,
        [switch]$IncludeMoveReport
    )

    Begin
    {
        function Setup {
            Set-Variable -Name Parameters -Value @{
                Archive = $Archive
                IncludeMoveHistory = $IncludeMoveHistory
                IncludeMoveReport = $IncludeMoveReport
            } -Scope 1

            Set-Variable -Name ObjectType -Value "MailboxStatisticsAndAlias" -Scope 1

            Set-Variable -Name HostVersion -Value $Host.Version.Major -Scope 1

            if (($HostVersion -ge 3) -and ((Get-TypeData $ObjectType) -eq $null))
            {
                $p = "Alias","DisplayName","ItemCount","StorageLimitStatus","LastLogonTime"
                Update-TypeData -TypeName $ObjectType -DefaultDisplayPropertySet $p 
            }

            Set-Variable -Name SetupDone -Value $true -Scope 1

            Write-Verbose "Setup completed."
        }

        Setup
    }

    Process
    {
        if (-not $SetupDone) { Setup }

        foreach ($Mailbox in $Identity)
        {
            Write-Verbose $Mailbox

            $Result = $null

            if ($Mailbox.GetType().Name -eq "String")
            {
                $Result = Get-MailboxStatistics -Identity $Mailbox @Parameters | Select @{n="Alias"; e={(Get-Mailbox $Mailbox).Alias}},*
            }
            else
            {
                $Result = Get-MailboxStatistics -Identity $Mailbox.UserPrincipalName @Parameters | Select @{n="Alias"; e={$Mailbox.Alias}},*
            }

            if (($Result -ne $null) -and ($HostVersion -ge 3)) { $Result.PSTypeNames.Add($ObjectType) }

            $Result
        }
    }

    End {}
}