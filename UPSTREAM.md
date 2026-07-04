# Upstream attribution

This repository is a **derivative work** of [GMOD/jbrowse-components](https://github.com/GMOD/jbrowse-components), the canonical source of the JBrowse 2 genome browser. It extracts the `products/jbrowse-web` application at a pinned upstream tag and patches it into a self-contained npm project.

- **Upstream project:** [GMOD/jbrowse-components](https://github.com/GMOD/jbrowse-components)
- **Pinned upstream tag:** [v4.1.14](https://github.com/GMOD/jbrowse-components/releases/tag/v4.1.14)
- **Original maintainer:** [GMOD](https://gmod.org/) — the Generic Model Organism Database project
- **Upstream license:** Apache License 2.0 — see the [upstream LICENSE](https://github.com/GMOD/jbrowse-components/blob/v4.1.14/LICENSE)

## License relationship

Both this repository and upstream are licensed under the **Apache License 2.0**. The local [LICENSE](LICENSE) file applies to this repository's contributions; the work as a whole inherits and remains compatible with the upstream Apache-2.0 grant. Source files copied from upstream retain their original copyright; modifications are documented below and in the README.

## What was copied from upstream

At tag `v4.1.14`, the following directories and files were copied from `products/jbrowse-web/` and the monorepo root, then patched to remove monorepo-only assumptions:

- `src/` — the JBrowse Web application source
- `scripts/` — build and dev-server entry points
- `public/` — static assets (favicon, manifest, html template)
- `webpack/` — shared webpack config (originally lived at the monorepo root)
- `package.json`, `tsconfig.json`

See the [README's "How this was extracted from the monorepo" section](README.md#how-this-was-extracted-from-the-monorepo) for the precise patch sequence.

## What differs from upstream

- `src/components/JBrowse.tsx` — added a `postMessage` listener for `add-tracks` messages and a `jbrowse-ready` signal to the parent window (enables iframe-embedded JBrowse instances to receive tracks without a full reload).
- `package.json` — `workspace:^` references replaced with published `^4.1.14` versions; explicit devDependencies added; tsx-based start/build scripts in place of upstream's custom Node loader.
- `webpack/config/webpack.config.ts` — the `getWorkspaces()` `pnpm recursive list` call replaced with a static path resolving `node_modules/@jbrowse`.
- `scripts/build.ts`, `scripts/start.ts` — webpack imports rewritten from monorepo-relative (`../../../webpack/...`) to local paths.
- Monorepo-only files removed: `public/test_data` (broken symlink), `public/umd_plugin.js`, `src/tests/`, `src/__snapshots__/`, `src/*.test.ts`.

## Citing JBrowse

If you use JBrowse 2 in published work, please cite the upstream project per [their guidance](https://jbrowse.org/jb2/docs/user_guides/cite/). This repository is infrastructure around the upstream codebase and does not change the citation expectation.

## Contributing back

Bug fixes and improvements that are not specific to the standalone-npm packaging belong upstream at [GMOD/jbrowse-components](https://github.com/GMOD/jbrowse-components). Issues specific to this extraction (build pipeline, packaging, the standalone scripts) belong in [this repo's issue tracker](https://github.com/Abrar-Abir/jbrowse-web/issues).
