import { describe, expect, it } from 'vitest';
import buildRaw from '../../wrangler.jsonc?raw';
import deployRaw from '../../wrangler.deploy.jsonc?raw';

// JSONC without a dependency: comments outside strings dropped, then
// trailing commas.
function jsonc(text: string): Record<string, unknown> {
  let out = '';
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '"') {
      let j = i + 1;
      while (j < text.length && text[j] !== '"') j += text[j] === '\\' ? 2 : 1;
      out += text.slice(i, j + 1);
      i = j;
    } else if (c === '/' && text[i + 1] === '/') {
      while (i < text.length && text[i] !== '\n') i++;
      out += '\n';
    } else if (c === '/' && text[i + 1] === '*') {
      i = text.indexOf('*/', i + 2) + 1;
    } else {
      out += c;
    }
  }
  return JSON.parse(out.replace(/,(\s*[}\]])/g, '$1'));
}

const build = jsonc(buildRaw);
const deploy = jsonc(deployRaw);
// What only a deploy of the BUILT Worker needs (dist/server/wrangler.json
// carries the same): the entry the build emitted, not re-bundled.
const DEPLOY_ONLY = new Set(['$schema', 'main', 'no_bundle', 'rules', 'upload_source_maps']);

describe('the deploy config (wrangler.deploy.jsonc)', () => {
  it('deploys the Worker and the assets astro build emits', () => {
    expect(deploy.main).toBe('./dist/server/entry.mjs');
    expect(deploy.no_bundle).toBe(true);
    expect(deploy.assets).toMatchObject({ directory: './dist/client' });
  });

  it('says everything wrangler.jsonc says — name, compatibility, bindings', () => {
    for (const [key, value] of Object.entries(build)) {
      if (key === '$schema') continue;
      if (key === 'assets') {
        expect(deploy.assets, 'assets.binding').toMatchObject({
          binding: (value as { binding?: string }).binding,
        });
        continue;
      }
      expect(deploy[key], `${key} (wrangler.jsonc) in wrangler.deploy.jsonc`).toEqual(value);
    }
    for (const key of Object.keys(deploy)) {
      if (!DEPLOY_ONLY.has(key)) {
        expect(build, `${key} (wrangler.deploy.jsonc) in wrangler.jsonc`).toHaveProperty(key);
      }
    }
  });
});
