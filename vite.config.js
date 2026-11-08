import { defineConfig } from "vite";
import elm from "vite-plugin-elm";

// vite-plugin-elm 3.0.1 builds its hot-reload code by pasting the local Elm
// imports into `accept(["..."])`. With no local imports that becomes
// `accept([""])`, and Vite answers 500 because it can't resolve "". This turns
// it into `accept([])`. It only matches the empty case, so it is harmless once
// Main.elm imports another module of ours.
const fixEmptyElmHmrDeps = {
  name: "fix-empty-elm-hmr-deps",
  apply: "serve",
  transform(code, id) {
    if (!id.split("?")[0].endsWith(".elm")) return null;
    return {
      code: code.replace(/import\.meta\.hot\.accept\(\[\s*""\s*\]/, "import.meta.hot.accept([]"),
      map: null,
    };
  },
};

export default defineConfig({
  plugins: [elm(), fixEmptyElmHmrDeps],
  server: {
    // Listen on all interfaces so the host can reach the dev server in Docker.
    host: "0.0.0.0",
    port: 5173,
    // Fail rather than silently move to another port the host can't reach.
    strictPort: true,
  },
});
