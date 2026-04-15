# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Project

This is a standalone extraction of [JBrowse Web](https://jbrowse.org) v4.1.14 from the GMOD monorepo. It provides a self-contained npm project for building genome browser applications without needing the full pnpm monorepo.

## Commands

```bash
npm start          # Dev server on port 3000 (configurable via PORT env)
npm run build      # Production build → build/
npm run serve      # Serve production build on port 4000
```

There are no test commands in this standalone extraction. TypeScript type checking: `npx tsc --noEmit`.

## Architecture

### Startup Flow

`src/index.tsx` → `src/InitialLoad.tsx` (React Suspense wrapper) → `src/components/Loader.tsx` (main orchestrator)

**Loader.tsx** reads URL query params, creates a `SessionLoader` MST model, and drives initialization through three states:
1. Config error → `<StartScreenErrorMessage>`
2. Session needs triage → `<SessionTriaged>`
3. Ready → `<JBrowse>` (main app)

### State Management (MobX State Tree)

- **SessionLoader** (`src/SessionLoader.ts`): Coordinates loading config and session from URL params, remote sources, or hubs. Contains computed properties (`ready`, `sessionTriaged`) that drive the Loader component.
- **RootModel** (`src/rootModel/rootModel.ts`): Composed from `@jbrowse/product-core` mixins. Manages assemblies, text search, RPC, menus, and session metadata. Persists sessions to IndexedDB.
- **SessionModel** (`src/sessionModel/index.ts`): Extends `BaseWebSession` from `@jbrowse/web-core`. Manages views and tracks.
- **JBrowseModel** (`src/jbrowseModel.ts`): Wraps `JBrowseModelF` from `@jbrowse/app-core`; strips `baseUri` from snapshots.

### Plugin System

`src/corePlugins.ts` lists ~30 core plugins (view types, data formats, UI features). `src/createPluginManager.ts` assembles a `PluginManager` from core + runtime (config) + session plugins, then creates RootModel and loads the initial session.

### Build System

Custom Webpack 5 config in `webpack/` (not CRA). Entry: `src/index.tsx`, output: `build/`. Dev uses HMR + style-loader; production uses versioned chunks + MiniCssExtractPlugin. Babel with the React compiler plugin. TypeScript is non-strict for compatibility with upstream `@jbrowse/*` packages.

### Key Patterns

- `window.JBrowseRootModel` and `window.JBrowseSession` are exposed in development for debugging.
- When `adminKey` is present in query params, session config snapshots are POSTed to `/updateConfig`.
- HMR saves/restores session across hot reloads.
- All `@jbrowse/*` packages come from npm — do not look for them in a local monorepo.

## Upgrading Upstream

```bash
bash scripts/upgrade.sh <new-version>
```
