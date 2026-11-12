The rung paths in TypeScript: rung 2 is a module in the page folder, with exported
names that the folder's `index.ts` does not re-export, except an API type that the module
defines (`pages/Cluster/managementPort.ts`). Rung 3 is a shared `src/<domain>/` module.