# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |

## Reporting a vulnerability

If you discover a security issue, please **do not** open a public GitHub issue.

Instead, report it privately via [GitHub Security Advisories](https://github.com/tomisacat/CodableDefault/security/advisories/new) or by emailing the repository owner through their GitHub profile contact options.

Include:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You can expect an initial response within **7 days**. We will work with you to understand and address the issue before any public disclosure.

## Scope

CodableDefault is a compile-time Swift macro library for JSON decoding defaults. Typical security concerns include:

- Unexpected decode behavior that could cause data integrity issues
- Macro expansion producing unsafe or incorrect code
- Dependency vulnerabilities (notably `swift-syntax`)

Out of scope: issues in consumer applications that use CodableDefault, or general Swift compiler bugs.
