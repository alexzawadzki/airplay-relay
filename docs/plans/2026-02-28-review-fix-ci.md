# Review, Fix, README Update & Balena CI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix README inaccuracies, validate scripts with shellcheck, add GitHub Actions CI to auto-deploy to Balena on push to main.

**Architecture:** Single-service Balena/Docker app (shairport-sync + raspi-gpio). No test framework — shell scripts validated with `shellcheck`. GitHub Actions workflow uses `balena-io/deploy-to-balena-action`.

**Tech Stack:** Bash, Docker, Balena Cloud, GitHub Actions, shellcheck

---

### Task 1: Run shellcheck on shell scripts

**Files:**
- Read: `airplay/start.sh`
- Read: `airplay/gpio_relay_airplay.sh`

**Step 1: Install shellcheck if missing**

```bash
which shellcheck || brew install shellcheck
```
Expected: path printed or installed successfully.

**Step 2: Run shellcheck on both scripts**

```bash
shellcheck airplay/start.sh airplay/gpio_relay_airplay.sh
```
Expected: no errors (exit 0). Note any warnings.

**Step 3: Fix any issues found**

Apply minimal fixes — do not refactor. Only fix shellcheck errors/warnings that affect correctness.

**Step 4: Commit if changes made**

```bash
git add airplay/start.sh airplay/gpio_relay_airplay.sh
git commit -m "fix: address shellcheck warnings in shell scripts"
```

---

### Task 2: Fix README inaccuracies (WiringPi → raspi-gpio)

**Files:**
- Modify: `README.md`

The README troubleshooting section still references WiringPi (`gpio -g`, `gpio -v`) but the code now uses `raspi-gpio`. The license section also credits WiringPi.

**Step 1: Replace the "Relay not switching" troubleshooting block**

Find this block (lines ~357-376):
```markdown
**Check GPIO permissions:**
```bash
gpio -g mode 17 out
gpio -g read 17  # Should show 0 or 1
```

**Verify WiringPi installation:**
```bash
gpio -v
```
```

Replace with:
```markdown
**Check GPIO permissions:**
```bash
raspi-gpio get 17
```

**Verify raspi-gpio installation:**
```bash
raspi-gpio help
```
```

**Step 2: Fix the License section**

Find:
```markdown
- **WiringPi**: [LGPL v3](http://wiringpi.com/)
```

Replace with:
```markdown
- **raspi-gpio**: Part of the Raspberry Pi OS toolchain
```

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: fix WiringPi references — project now uses raspi-gpio"
```

---

### Task 3: Add GitHub Actions workflow for Balena deploy

**Files:**
- Create: `.github/workflows/deploy-balena.yml`

**Step 1: Create the workflow directory**

```bash
mkdir -p .github/workflows
```

**Step 2: Create the workflow file**

Create `.github/workflows/deploy-balena.yml` with:

```yaml
name: Deploy to Balena

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Deploy to Balena
        uses: balena-io/deploy-to-balena-action@master
        id: deploy
        with:
          balena_token: ${{ secrets.BALENA_TOKEN }}
          fleet: alexzawadzki/airplay-relay
          source: .
```

**Step 3: Add GitHub Actions badge to README**

At the top of `README.md`, after the `# AirPlay Relay Controller` heading, add:

```markdown
[![Deploy to Balena](https://github.com/alexzawadzki/airplay-relay/actions/workflows/deploy-balena.yml/badge.svg)](https://github.com/alexzawadzki/airplay-relay/actions/workflows/deploy-balena.yml)
```

**Step 4: Add BALENA_TOKEN setup instructions to README**

Find the "Balena Cloud Deployment" section and add after the prerequisites:

```markdown
#### GitHub Actions Auto-Deploy (Optional)

To enable automatic Balena deployment on every push to `main`:

1. Get your Balena API token from [Balena Dashboard → Account Settings → Access Tokens](https://dashboard.balena-cloud.com/preferences/access-tokens)
2. Add it as a GitHub repository secret named `BALENA_TOKEN`:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `BALENA_TOKEN`, Value: your Balena API token
3. Push to `main` — the action will automatically build and deploy to your fleet
```

**Step 5: Commit**

```bash
git add .github/workflows/deploy-balena.yml README.md
git commit -m "ci: add GitHub Actions workflow to auto-deploy to Balena on push to main"
```

---

### Task 4: Push to main

**Step 1: Verify all commits look correct**

```bash
git log --oneline -5
git status
```
Expected: clean working tree, recent commits visible.

**Step 2: Push to main**

```bash
git push origin main
```
Expected: pushed successfully.
