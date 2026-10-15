#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the 01-scaffold landing (the commit its first PR merges), run what
#      `checks.yml` runs on that PR — install with the lockfile the phase
#      pruned, render fixtures, typecheck, lint, test, build. That landing
#      WAITS on its checks, so a scaffold they refuse is a bootstrap that never
#      gets past phase one;
#   2. at the finished site, the same Checks sequence;
#   3. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `verify-app-structure` (the deploy
#      config must exist BEFORE the build), `build-app` — the component's
#      buildCommand, the same step the deploy profile runs —
#      `verify-build-output` and `deploy-dry-run` (`wrangler deploy --dry-run
#      --config <wranglerConfig> --name <reponame>-web-stage`). They run IN THE
#      TREE THE RUNNER STAGES for the job (testing/lib/stage-job.py), with the
#      dependency layout the pinned composition produces: if its install step
#      is `scope: lane`, the top-level node_modules is a symlink to the source
#      checkout's; if not, the job's own install step runs inside the staged
#      tree. A staged tree has no dist/, which is what makes the structure
#      check honest: had the component named the adapter's generated
#      dist/server/wrangler.json, the check would fail here as it would in
#      every real lane. Then the committed deploy config is held to the
#      generated one: a dry run of each must upload the same Worker and the
#      same assets;
#   4. serve the built Worker with `wrangler dev` over the component's own
#      wranglerConfig and run the component's OWN `smokeCommand` against it,
#      verbatim — the check the real deploy ends with — and then read every
#      route the site promises: the home page's heading and title carry the
#      site's name, /ssr and /ssr-with-swr-caching are rendered per request
#      (the latter with its cache header), /image serves its image, an
#      unknown path is a 404.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: two installs and builds.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false ASTRO_TELEMETRY_DISABLED=1 TURBO_TELEMETRY_DISABLED=1

# What checks.yml runs, step for step, read out of the workflow the site
# carries so the two cannot drift: every `run:` of its one job, in order.
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  while IFS= read -r cmd; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done < <(python3 - "$dir/.github/workflows/checks.yml" <<'PY'
import sys, yaml
wf = yaml.safe_load(open(sys.argv[1]))
for job in wf["jobs"].values():
    for step in job["steps"]:
        if "run" in step:
            print(step["run"].strip())
PY
)
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   3 phases placed and landed"

# ── 1. the scaffold's own pull request ─────────────────────────────────────
echo "── 01-scaffold's landing, under the checks its PR waits on"
git -C "$tree" worktree add -q "$scratch/at-01" "$(git -C "$tree" rev-parse HEAD~2)"
checks "$scratch/at-01" "$scratch/checks-01.log"

# ── 2. the finished site ───────────────────────────────────────────────────
echo "── the finished site, under the same checks"
checks "$tree" "$scratch/checks-site.log"

# ── 3. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: verify-app-structure, build-app, verify-build-output, deploy-dry-run"
s01="$(git -C "$tree" rev-parse HEAD~2)"; s02="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s01" --head "$s02" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "web" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("verify-app-structure", "build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/web")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 2
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/web/dist" "$tree/apps/web/.wrangler"
work="$tree/.orun/runs/e2e/web.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in verify-app-structure build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done

# The deploy hands wrangler a COMMITTED config (the lane checks for it before
# it builds), and the adapter writes its own beside the Worker it emitted.
# They must ship the same thing: dry-run both over the build just made and
# compare what each would upload — the modules, their sizes, the assets and
# the bindings.
echo "   ▸ the committed deploy config uploads what the adapter's generated one would"
cfg="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['wranglerConfig'])" "$tree/apps/web/component.yaml")"
for side in committed:"$cfg" generated:dist/server/wrangler.json; do
  (cd "$work/apps/web" && pnpm exec wrangler deploy --dry-run --config "${side#*:}" --name "$repo-web-stage" \
     --outdir "$scratch/dry-${side%%:*}") > "$scratch/dry-${side%%:*}.log" 2>&1 \
    || { echo "FAIL: wrangler deploy --dry-run --config ${side#*:}" >&2; tail -20 "$scratch/dry-${side%%:*}.log" >&2; exit 1; }
  # What would be uploaded, without the run's own paths and timestamps.
  grep -E '│|Total|Binding|env\.|Read [0-9]+ files' "$scratch/dry-${side%%:*}.log" \
    | sed -E 's#(from the assets directory ).*#\1<dir>#' > "$scratch/dry-${side%%:*}.upload"
done
if ! diff -u "$scratch/dry-generated.upload" "$scratch/dry-committed.upload" > "$scratch/dry.diff"; then
  echo "FAIL: $cfg and the adapter's dist/server/wrangler.json would deploy different Workers:" >&2
  cat "$scratch/dry.diff" >&2; exit 1
fi
grep -q 'Total' "$scratch/dry-committed.upload" || { echo "FAIL: the dry run listed no modules" >&2; exit 1; }

# ── 4. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker ($cfg)"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/web" && exec setsid pnpm exec wrangler dev --config "$cfg" --ip 127.0.0.1 --port "$port" \
   --name "$repo-web-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/web/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the site promises"
python3 - "$url" "$values" <<'PY'
import html, json, re, sys, time, urllib.error, urllib.parse, urllib.request
base, values = sys.argv[1], json.load(open(sys.argv[2]))
name, repo = values["productname"], values["reponame"]
problems = []
def bad(m): problems.append(m)
def get(path):
    try:
        with urllib.request.urlopen(urllib.parse.urljoin(base + "/", path), timeout=30) as r:
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()
def text(fragment):
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()

# / — pre-rendered, served from the assets, named for the site.
status, headers, body = get("/")
page = body.decode()
if status != 200:
    bad(f"/ answered {status}")
h1 = re.search(r"<h1[^>]*>(.*?)</h1>", page, re.S)
if not h1 or text(h1.group(1)) != f"Welcome to {name}":
    bad(f"the home page's heading is {h1 and text(h1.group(1))!r}, not 'Welcome to {name}'")
title = re.search(r"<title>(.*?)</title>", page, re.S)
if not title or html.unescape(title.group(1)) != f"Welcome to {name}.":
    bad(f"the home page's <title> is {title and title.group(1)!r}, not 'Welcome to {name}.'")
challenge = re.search(r"Code Challenge:</strong>(.*?)</p>", page, re.S)
if not challenge or f'"Welcome to {name}"' not in text(challenge.group(1)):
    bad(f"the home page's instructions do not name the site: {challenge and text(challenge.group(1))!r}")
if "astro-boilerplate" in page:
    bad("the home page still carries the baseline's name")

# /ssr — rendered by the Worker on each request.
times = []
for _ in range(2):
    status, headers, body = get("/ssr")
    m = re.search(r"<h1>(.*?)</h1>", body.decode(), re.S)
    if status != 200 or not m or not re.search(r"\d{1,2}:\d{2}:\d{2}", m.group(1)):
        bad(f"/ssr answered {status} without a rendered time: {body[:120]!r}")
        break
    times.append(m.group(1))
    time.sleep(1.1)
if len(times) == 2 and times[0] == times[1]:
    bad(f"/ssr rendered the same time twice ({times[0]}) — it is not rendered per request")

# /ssr-with-swr-caching — the same, with the header the page sets.
status, headers, body = get("/ssr-with-swr-caching")
if status != 200 or "<h1>" not in body.decode():
    bad(f"/ssr-with-swr-caching answered {status}")
cc = headers.get("cache-control", "")
if "s-maxage=10" not in cc or "stale-while-revalidate" not in cc:
    bad(f"/ssr-with-swr-caching sends Cache-Control {cc!r}")

# /image — the page and the image it points at.
status, headers, body = get("/image")
img = re.search(r'<img[^>]*\bsrc="([^"]+)"', body.decode())
if status != 200 or not img:
    bad(f"/image answered {status} without an <img>")
else:
    s, h, b = get(html.unescape(img.group(1)))
    if s != 200 or not h.get("content-type", "").startswith("image/") or not b:
        bad(f"/image's <img> {img.group(1)} answered {s} {h.get('content-type')}")

for path, want in (("/favicon.ico", 200), ("/no-such-page", 404)):
    s, _, _ = get(path)
    if s != want:
        bad(f"{path} answered {s}, want {want}")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, /ssr, /ssr-with-swr-caching, /image and its image, /favicon.ico and a 404 — the site's own, named {name!r}")
PY

echo "e2e.test.sh: ok"
