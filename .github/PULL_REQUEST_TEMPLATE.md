## Summary

Describe the change and the problem it solves.

## Verification

- [ ] `Invoke-Pester -Script .\Tests -PassThru`
- [ ] `.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools -OutputRoot .\PRDryRunOutput`
- [ ] `.\Create-Distributions.ps1`

## Safety Review

- [ ] No credentials added
- [ ] No destructive automation added
- [ ] No automatic packet capture added
- [ ] New tools are documented and justified
- [ ] README, docs, and Word documentation are aligned

## Notes

Add rollout, compatibility, or follow-up notes if needed.
