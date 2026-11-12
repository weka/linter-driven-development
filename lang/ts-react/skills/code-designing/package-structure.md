Package Structure:
pages/Snapshots/
  ├── index.ts               # the public surface: what another page imports
  ├── SnapshotsPage.tsx      # the component: its render tree is the story
  ├── useSnapshots.ts        # the hook: the query and state the page reads
  ├── snapshotsApi.ts        # the api module: fetch and parse at the boundary
  ├── snapshot.ts            # each juicy type of the feature's API in its own module (Snapshot, parseSnapshot)
  ├── [helper].ts            # a juicy helper: its own module, index.ts does not re-export it (R4 rung 2)
  └── SnapshotsPage.test.tsx
