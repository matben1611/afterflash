@{
    ExcludeRules = @(
        'PSUseApprovedVerbs'  # We use custom verb-like functions
    )

    Rules = @{
        PSAvoidGlobalAliases = @{
            Enable = $true
        }
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSAvoidUsingWriteHost = @{
            Enable = $false  # This project uses Write-Host intentionally for UI
        }
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            Kind = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
        }
        PSUseOutputTypeCorrectly = @{
            Enable = $true
        }
    }
}
