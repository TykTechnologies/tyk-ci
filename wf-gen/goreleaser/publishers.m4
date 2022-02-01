publishers:
  - name: xPC_REPO-unstable
    env:
      - PACKAGECLOUD_TOKEN={{ .Env.PACKAGECLOUD_TOKEN }}
      - REPO=tyk/xPC_REPO-unstable
      - RPMVERS={{ .Env.RPMVERS }}
      - DEBVERS={{ .Env.DEBVERS }}
    cmd: /pc.sh {{ .ArtifactPath }}
