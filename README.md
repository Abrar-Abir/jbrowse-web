# jbrowse-web

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/jbrowse-v4.1.14-green.svg)](https://github.com/GMOD/jbrowse-components/releases/tag/v4.1.14)

A standalone, self-contained npm project for building custom [JBrowse 2 Web](https://jbrowse.org) genome browser applications — no monorepo required.

## Why this exists

JBrowse Web lives inside a large pnpm monorepo ([jbrowse-components](https://github.com/GMOD/jbrowse-components)) with ~30 cross-referenced packages. Building a custom JBrowse-based application normally means cloning and managing that entire monorepo. There is no supported path to just run `jbrowse-web` on its own.

This repo extracts `products/jbrowse-web` at a pinned version (**v4.1.14**) and patches it into a self-contained npm project: workspace references replaced with published npm versions, build paths fixed, shared webpack config included locally, and all devDependencies declared explicitly. Clone it, `npm install`, and `npm run build` — no pnpm, no monorepo.

## Prerequisites

- Node.js 18+
- npm

## Quick start

```bash
npm install
npm start        # dev server → http://localhost:3000
```

## Commands

| Command | Description |
|---|---|
| `npm start` | Dev server with HMR on port 3000 (override with `PORT=`) |
| `npm run build` | Production build → `build/` |
| `npm run serve` | Serve production build on port 4000 |

## Configuration

Place your `config.json` in `public/config.json`. JBrowse reads this on startup to load assemblies and tracks. See the [JBrowse config docs](https://jbrowse.org/jb2/docs/config_guides/assemblies/) for the full schema.

## Custom modifications

The following files differ from upstream JBrowse v4.1.14:

- **`src/components/JBrowse.tsx`** — Added a `postMessage` listener for `add-tracks` messages (inject tracks without reloading an iframe) and a `jbrowse-ready` signal to the parent window.

## Upgrading

```bash
bash scripts/upgrade.sh v4.2.0
```

Review and re-apply any custom modifications afterward. See [Upgrading to a newer JBrowse version](#upgrading-to-a-newer-jbrowse-version) below for a manual walkthrough.

---

## How this was extracted from the monorepo

Follow these steps to recreate or upgrade the standalone setup from scratch.

### 1. Clone the monorepo at the target version

```bash
git clone --depth 1 --branch v4.1.14 https://github.com/GMOD/jbrowse-components.git /tmp/jbrowse-src
```

### 2. Copy source files

```bash
cp -r /tmp/jbrowse-src/products/jbrowse-web/src .
cp -r /tmp/jbrowse-src/products/jbrowse-web/scripts .
cp -r /tmp/jbrowse-src/products/jbrowse-web/public .
cp /tmp/jbrowse-src/products/jbrowse-web/package.json .
cp /tmp/jbrowse-src/products/jbrowse-web/tsconfig.json .

# Shared webpack config (used by build scripts)
cp -r /tmp/jbrowse-src/webpack .
```

### 3. Remove monorepo-only files

```bash
rm -f public/test_data      # broken symlink to monorepo test data
rm -f public/umd_plugin.js  # test-only file
rm -rf src/tests src/__snapshots__ src/*.test.ts src/rootModel/__snapshots__ src/rootModel/*.test.ts
```

### 4. Add your config

```bash
cp build/config.json public/config.json
```

### 5. Patch package.json

**Replace workspace dependencies:**

```bash
sed -i 's/"workspace:\^"/"^4.1.14"/g' package.json
```

**Add missing peer dependencies** (MUI requires Emotion packages declared at monorepo root):

```json
"@emotion/cache": "^11.14.0",
"@emotion/react": "^11.14.0",
"@emotion/styled": "^11.14.1"
```

**Add devDependencies** (provided by monorepo root, must be declared explicitly here):

```json
"devDependencies": {
  "@babel/core": "^7.29.0",
  "@babel/preset-react": "^7.28.5",
  "@babel/preset-typescript": "^7.28.5",
  "@pmmmwh/react-refresh-webpack-plugin": "^0.6.2",
  "@types/node": "^20.19.33",
  "@types/react": "^19.2.14",
  "@types/react-dom": "^19.2.3",
  "babel-loader": "^10.0.0",
  "babel-plugin-react-compiler": "^1.0.0",
  "browserslist": "^4.28.1",
  "chalk": "^5.6.2",
  "css-loader": "^7.1.4",
  "html-webpack-plugin": "^5.6.6",
  "mini-css-extract-plugin": "^2.10.0",
  "react-refresh": "^0.18.0",
  "rimraf": "^5.0.10",
  "source-map-loader": "^5.0.0",
  "style-loader": "^4.0.0",
  "tsx": "^4.21.0",
  "typescript": "^5.9.3",
  "webpack": "^5.105.4",
  "webpack-cli": "^5.1.4",
  "webpack-dev-server": "^5.2.3"
}
```

**Update scripts** (the monorepo runs `.ts` files via custom Node loaders; standalone uses `tsx`):

```json
"scripts": {
  "start": "NODE_ENV=development tsx scripts/start.ts",
  "build": "NODE_ENV=production tsx scripts/build.ts",
  "prebuild": "rimraf build",
  "serve": "npx http-server build -c 3600 -p 4000 --gzip --brotli"
}
```

### 6. Fix monorepo-relative imports in build scripts

`scripts/build.ts` and `scripts/start.ts` reference webpack config three levels up. Change to the local path:

```typescript
// Before
import configFactory from '../../../webpack/config/webpack.config.ts'
import build from '../../../webpack/scripts/build.ts'

// After
import configFactory from '../webpack/config/webpack.config.ts'
import build from '../webpack/scripts/build.ts'
```

### 7. Patch webpack config

In `webpack/config/webpack.config.ts`, replace the `getWorkspaces()` function that calls `pnpm recursive list` with a static path:

```typescript
// Before
import { execSync } from 'child_process'
function getWorkspaces() {
  const workspacesStr = execSync('pnpm recursive list --json --depth=-1', {
    cwd: process.cwd(),
  }).toString()
  return Object.values(
    JSON.parse(workspacesStr) as Record<string, { path: string }>,
  ).map(e => e.path)
}

// After
import path from 'path'
function getWorkspaces() {
  return [path.resolve(process.cwd(), 'node_modules/@jbrowse')]
}
```

This tells webpack's babel-loader to transpile `@jbrowse/*` packages from node_modules (they ship TypeScript source).

### 8. Install and build

```bash
npm install
npm run build
npm run serve   # http://localhost:4000
```

## Upgrading to a newer JBrowse version

1. Clone the new tag: `git clone --depth 1 --branch v<NEW> https://github.com/GMOD/jbrowse-components.git /tmp/jbrowse-src`
2. Diff `products/jbrowse-web/` against current `src/` to identify upstream changes
3. Copy updated files and re-apply the patches above
4. Replace `workspace:^` with `^<NEW>` in package.json
5. Check if `webpack/` config changed upstream and merge
6. Run `npm install && npm run build` to verify
7. Re-apply any custom modifications

## Upstream

Based on [GMOD/jbrowse-components](https://github.com/GMOD/jbrowse-components) v4.1.14.
