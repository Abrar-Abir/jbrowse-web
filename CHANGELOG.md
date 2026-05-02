# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [4.1.14] - 2026-05-02

Initial release. Standalone extraction of [JBrowse Web](https://jbrowse.org) from the [GMOD/jbrowse-components](https://github.com/GMOD/jbrowse-components) monorepo at upstream tag [v4.1.14](https://github.com/GMOD/jbrowse-components/releases/tag/v4.1.14). See [UPSTREAM.md](UPSTREAM.md) for the derivative-work relationship and [README.md](README.md#how-this-was-extracted-from-the-monorepo) for the precise patch sequence.

### Added

- Self-contained npm project for `products/jbrowse-web` — no pnpm or monorepo required.
- Local copy of the shared webpack config (originally at the monorepo root); `getWorkspaces()` rewired to a static `node_modules/@jbrowse` path.
- `tsx`-based `start` and `build` scripts in place of upstream's custom Node loader; `npm start`, `npm run build`, and `npm run serve` work out of the box.
- `add-tracks` `postMessage` listener and `jbrowse-ready` parent-window signal in `src/components/JBrowse.tsx` for iframe-embedded use.
- Minimal `public/config.json` shipping a default hg38 assembly so a fresh clone renders without manual configuration.
- Published as [`@abrarabir235/jbrowse-web`](https://www.npmjs.com/package/@abrarabir235/jbrowse-web) on npm with `./rootModel` and `./makeWorkerInstance` exports for downstream customization (TypeScript-aware bundler required).

### Changed

- `workspace:^` references in `package.json` replaced with published `^4.1.14` versions of `@jbrowse/*` packages from npm.
- Monorepo-relative webpack imports in `scripts/build.ts` and `scripts/start.ts` rewritten to local paths.
- Devdependencies (previously inherited from the monorepo root) declared explicitly.

### Removed

- Monorepo-only artifacts: `public/test_data` (broken symlink), `public/umd_plugin.js`, `src/tests/`, `src/__snapshots__/`, `src/*.test.ts`.
