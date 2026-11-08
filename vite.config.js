import { defineConfig } from "vite";
import elm from "vite-plugin-elm";

export default defineConfig({
  plugins: [elm()],
  server: {
    // Listen on all interfaces so the host can reach the dev server in Docker.
    host: "0.0.0.0",
    port: 5173,
    // Fail rather than silently move to another port the host can't reach.
    strictPort: true,
  },
});
