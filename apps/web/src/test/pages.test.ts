import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import { describe, expect, it } from 'vitest';
import Card from '../components/Card.astro';
import Layout from '../layouts/Layout.astro';

describe('the boilerplate components', () => {
  it('renders a link card with its title, body and href', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Card, {
      props: { href: 'https://docs.astro.build/', title: 'Documentation', body: 'Learn how Astro works.' },
    });
    expect(html).toContain('href="https://docs.astro.build/"');
    expect(html).toContain('Documentation');
    expect(html).toContain('Learn how Astro works.');
  });

  it('renders the layout with the page title and no analytics beacon by default', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Layout, {
      props: { title: 'Welcome to Astro.' },
      slots: { default: '<main>hello</main>' },
    });
    expect(html).toContain('<title>Welcome to Astro.</title>');
    expect(html).toContain('<main>hello</main>');
    expect(html).not.toContain('static.cloudflareinsights.com');
  });
});
