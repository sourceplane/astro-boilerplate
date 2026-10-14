import { defineConfig } from 'astro/config';
import cloudflare from '@astrojs/cloudflare';

// The Vercel adapter (imageService + webAnalytics) becomes the Cloudflare
// adapter: `output: 'server'` keeps the SSR pages server-rendered in the
// Worker, `prerender = true` pages become static assets, and images are
// optimised at build time (`compile`) since the Worker has no sharp.
// The template keeps no session state, so the adapter's default KV-backed
// sessions (and the KV namespace they would need) are off. Web analytics is
// the Cloudflare beacon in src/layouts/Layout.astro.
export default defineConfig({
  output: 'server',
  session: false,
  adapter: cloudflare({
    imageService: 'compile',
  }),
});
