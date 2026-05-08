# Security policy

OCS reads keystrokes via a global hotkey to open its capture panel. Vulnerabilities in this path can have outsized impact, and are taken seriously.

## Supported versions

Only the latest release receives security fixes. Older versions are not patched.

| Version | Supported |
| ------- | --------- |
| Latest  | Yes       |
| Older   | No        |

## Reporting a vulnerability

Please report privately, not via a public issue.

- Preferred: GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repository.
- Email fallback: rodrigo@optcmd.space.

Include reproduction steps, the affected version, and the impact you observed. A response should arrive within 7 days. If you don't hear back, please follow up.

## Scope

In scope: the OCS macOS app, the build scripts, and any release artifacts hosted under this repository.

Out of scope: bugs in third-party dependencies (report those upstream), denial-of-service against your own machine, and issues that require physical access plus an unlocked session.

## Coordinated disclosure

The goal is a fix released within 90 days of a confirmed report. If more time is needed, you'll be told why. If less time is needed because the issue is being exploited, you'll be told that too.

Please don't test the issue against other users' machines, and please don't share details publicly until a fix is out.

## Disclosure

Once a fix lands and a release is out, the advisory will be published with credit to the reporter, unless the reporter prefers to stay anonymous.

## Safe harbor

Good-faith security research on this project will not be pursued legally. "Good-faith" means: you tested only against your own machine or accounts, you reported privately before disclosing, and you avoided privacy violations, data destruction, and service degradation.
