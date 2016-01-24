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
        function CreateLogString
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True)]
                [string]$Message
            )

            return (Get-Date).ToUniversalTime().ToString("[HH:mm:ss.fff") + " GMT] Get-MailboxStatisticsAndAlias : " + $Message
        }

        function Setup {
            Write-Verbose (CreateLogString "Beginning processing.")
            Write-Verbose (CreateLogString "Starting setup process.")

            Set-Variable -Name Parameters -Value @{
                Archive = $Archive
                IncludeMoveHistory = $IncludeMoveHistory
                IncludeMoveReport = $IncludeMoveReport
            } -Scope 1

            Write-Verbose (CreateLogString (([string[]](($Parameters.GetEnumerator() | select @{n="a";e={($_.Name + ":" + $_.Value)}})  | %{"$($_.a)"})) -join "; "))

            Set-Variable -Name ObjectType -Value "MailboxStatisticsAndAlias" -Scope 1

            Set-Variable -Name HostVersion -Value $Host.Version.Major -Scope 1

            if (($HostVersion -ge 3) -and ((Get-TypeData $ObjectType) -eq $null))
            {
                $p = "Alias","DisplayName","ItemCount","StorageLimitStatus","LastLogonTime"
                Update-TypeData -TypeName $ObjectType -DefaultDisplayPropertySet $p
                Write-Verbose (CreateLogString "Custom TypeData was updated.")
            }

            Set-Variable -Name SetupDone -Value $true -Scope 1

            Write-Verbose (CreateLogString "Setup was completed.")
        }

        Setup
    }

    Process
    {
        if (-not $SetupDone) { Setup }

        foreach ($Mailbox in $Identity)
        {
            Write-Verbose (CreateLogString "Processing object `"$Mailbox`".")
            $Result = $null

            if ($Mailbox.GetType().Name -eq "String")
            {
                Write-Verbose (CreateLogString "Invoke Get-MailboxStatistics for `"$Mailbox`".")
                $Result = Get-MailboxStatistics -Identity $Mailbox @Parameters

                if ($Result -ne $null)
                {
                    Write-Verbose (CreateLogString "Get-MailboxStatistics cmdlet for `"$Mailbox`" was completed.")
                    Write-Verbose (CreateLogString "Invoke Get-Mailbox for `"$Mailbox`" to get Alias.")
                    $Result = $Result| Select @{n="Alias"; e={(Get-Mailbox $Mailbox).Alias}},*
                    Write-Verbose (CreateLogString "Get-Mailbox cmdlet for `"$Mailbox`" was completed.")
                }
                else
                {
                     Write-Verbose (CreateLogString "Get-MailboxStatistics for `"$Mailbox`" was failed.")
                     continue
                }
            }
            else
            {
                Write-Verbose (CreateLogString "Invoke Get-MailboxStatistics for `"$Mailbox`".")
                $Result = Get-MailboxStatistics -Identity $Mailbox.UserPrincipalName @Parameters | Select @{n="Alias"; e={$Mailbox.Alias}},*

                if ($Result -ne $null)
                {
                    Write-Verbose (CreateLogString "Get-MailboxStatistics cmdlet for `"$Mailbox`" was completed.")
                }
                else
                {
                     Write-Verbose (CreateLogString "Get-MailboxStatistics cmdlet for `"$Mailbox`" was failed.")
                     continue
                }
            }

            if ($HostVersion -ge 3) { $Result.PSTypeNames.Add($ObjectType) }

            Write-Verbose (CreateLogString "Preparing output for `"$Mailbox`".")
            $Result
        }
    }

    End {}
}