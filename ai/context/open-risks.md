# astro-boilerplate — open risks

What is not yet proven or not yet decided. The full write-up of every risk,
including the accepted and resolved ones, is
`specs/epics/astro-boilerplate/risks-and-open-questions.md`; this page lists
only what is still live, so it should be short.

| ID | Risk | State | What closes it |
|---|---|---|---|
| AB-G | The one-landing shape on `main` (AB4) is not yet proven live; `baseline-v1`'s three phases were (2026-10-15, 7m07s) | OPEN | One console bootstrap from the next tag |

Accepted, and worth knowing before you change them: AB-B (the SWR page's
cache header needs a Cache Rule on Cloudflare), AB-C's caveat (the image page
serves the original PNG, not a resized WebP), AB-D (the tests live in the
app), AB-H (a custom domain is the owner's step), AB-J (stack-tectonic
0.19.0).
