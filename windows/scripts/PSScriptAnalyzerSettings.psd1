@{
    ExcludeRules = @(
        'PSUseApprovedVerbs',                              # We use custom verb-like functions
        'PSUseShouldProcessForStateChangingFunctions',     # Interactive script - user confirms each action
        'PSAvoidUsingWriteHost',                           # This project uses Write-Host intentionally for UI
        'PSUseConsistentIndentation'                       # Minor linting - code is readable
    )

    Rules = @{
        PSAvoidGlobalAliases = @{
            Enable = $true
        }
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
        }
        PSUseOutputTypeCorrectly = @{
            Enable = $true
        }
    }
}
