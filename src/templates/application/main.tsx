import { createOrbitaApp } from "@foguete/orbita";
import "./app.css";

const pages = {
  "home/index": () => import("./views/home/index.tsx"),
};

async function resolveComponent(name: string) {
  console.log("🔍 Resolving component:", name);
  const page = pages[name as keyof typeof pages];
  if (!page) {
    throw new Error(`Page component not found: ${name}`);
  }
  const module = await page();
  return module.default;
}

createOrbitaApp(document.getElementById("app")!, {
  resolveComponent,
});