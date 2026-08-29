# Kazakhstan platform extension boundary

This directory is the isolation boundary for Kazakhstan-specific platform code.
It is intentionally not part of the root Maven reactor yet.

Business rules, tax rates, HR documents, reports, translations, and calculation
formulas belong to the separate `zup-kz-app` lsFusion application. Code may be
added here only when the platform lacks a suitable declarative extension point,
for example a reusable Java integration adapter required by lsFusion actions.

Before adding code, document:

1. the missing platform extension point;
2. why an application module cannot implement the behavior;
3. the public contract used by `zup-kz-app`;
4. a compatibility test against the current upstream platform.

Keep dependencies directed from this extension to public platform APIs. Core
platform modules must not depend on this directory.
