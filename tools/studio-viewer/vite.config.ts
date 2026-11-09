import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";

const toolRoot = fileURLToPath(new URL(".", import.meta.url));

export default defineConfig({
  root: fileURLToPath(new URL("./client", import.meta.url)),
  server: {
    fs: { allow: [toolRoot] },
  },
  test: {
    root: toolRoot,
    include: ["tests/**/*.test.ts"],
    environment: "node",
  },
} as Parameters<typeof defineConfig>[0]);
