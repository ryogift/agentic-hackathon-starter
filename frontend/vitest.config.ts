import { defineConfig } from 'vitest/config';
import { svelte } from '@sveltejs/vite-plugin-svelte';

export default defineConfig({
  plugins: [
    svelte({
      hot: !process.env.VITEST,
      compilerOptions: {
        // Svelte 5でブラウザモードを強制
        hmr: false
      }
    })
  ],
  test: {
    include: ['src/**/*.{test,spec}.{js,ts}'],
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/setupTests.ts'],
    // Svelte 5 + SvelteKitのテスト用設定
    alias: {
      $lib: new URL('./src/lib', import.meta.url).pathname,
      '$app/environment': new URL('./src/mocks/app-environment.ts', import.meta.url).pathname
    }
  },
  resolve: {
    conditions: ['browser']
  }
});
