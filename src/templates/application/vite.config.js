import { defineConfig } from "vite";
import preact from "@preact/preset-vite";

export default defineConfig({
  plugins: [preact()],
  build: {
    outDir: "public/assets",
    rollupOptions: {
      input: "app/main.tsx",
      output: {
        entryFileNames: "app.js",
        chunkFileNames: "[name].js",
        assetFileNames: "[name].[ext]",
      },
    },
  },
  server: {
    proxy: {
      // Proxy API routes to Lua server
      "/api": "http://localhost:8080",
      // Proxy HTML page routes to Lua server (but not assets)
      "^(?!/(app/|assets/|@|node_modules)).*": {
        target: "http://localhost:8080",
        changeOrigin: true,
      },
    },
  },
});