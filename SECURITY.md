# Security Policy

## Supported Versions

Security fixes are released for the latest published version of swift-fakable.
Please upgrade to the most recent release before reporting an issue.

## Reporting a Vulnerability

Please do not report security vulnerabilities through public GitHub issues.

Instead, report them privately through GitHub's
[private vulnerability reporting](https://github.com/yysskk/swift-fakable/security/advisories/new).
This lets us discuss and address the issue before it is publicly disclosed.

When reporting, please include:

- A description of the vulnerability and its impact.
- Steps to reproduce, or a proof of concept.
- The affected version(s).

We will acknowledge your report as soon as we can and keep you informed of the
progress toward a fix.

## Scope

swift-fakable is a test-only code generation tool: the `fake()` methods it
generates are wrapped in `#if DEBUG` and are not compiled into release builds.
Reports that are most relevant include issues in the macro implementation that
could lead to unexpected code generation.
