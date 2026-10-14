/// <reference types="vitest" />
import { getViteConfig } from 'astro/config';

// Astro's own Vite config, so .astro components render in tests through the
// container API. The adapter (and the Cloudflare Vite plugin it brings) is
// left out: the tests render components, not the Worker.
export default getViteConfig(
  {
    test: {
      include: ['src/**/*.test.ts'],
    },
  },
  {
    configFile: false,
    session: false,
  },
);
