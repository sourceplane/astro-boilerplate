import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import { describe, expect, it } from 'vitest';
import Home from '../pages/index.astro';
import { SITE_NAME } from '../site';

// Astro escapes text it renders; a site name may carry `&` or `'`.
const escaped = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');

describe('site identity (src/site.ts)', () => {
  it('names the site', () => {
    expect(SITE_NAME.trim()).not.toBe('');
  });

  it('is what the home page is titled and headed with', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Home);
    expect(html).toContain(`<title>Welcome to ${escaped(SITE_NAME)}.</title>`);
    expect(html).toMatch(new RegExp(`<h1[^>]*>Welcome to <span[^>]*>${escaped(SITE_NAME).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}</span></h1>`));
  });
});
