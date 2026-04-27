# ADEssentials Website Content

This folder contains curated source content that the Evotec website imports for the ADEssentials project page.

## Layout

- `content/project-docs/` contains short project documentation pages shown under /projects/adessentials/docs/.
- `content/examples/` contains curated website examples shown under /projects/adessentials/examples/.
- API artifacts are not enabled from this folder yet. Add `WebsiteArtifacts/apidocs` and wire it in the website catalog only when external help/API metadata is generated and reviewed.

## Editing Rules

- Keep this folder intentional and small.
- Do not mirror raw `Examples/`, `Example/`, or generated output folders into the public website.
- Add only examples that have a clear explanation, a small code sample, and a link back to the original source file.
- Keep links rooted at /projects/adessentials/ so the same content works on localhost, evotec.xyz, and evotec.pl.

The website pipeline prefers this `Website/content/...` layout over legacy root-level content folders.

