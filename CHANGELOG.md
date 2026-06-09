# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-06-09

UX hardening release: 39 verified findings from a multi-agent review of the skills,
hooks, installers, and docs, implemented and adversarially re-verified.

### Added
- `/handoff draft` (or `--no-push`): write and archive `HANDOFF.md` without committing
  or pushing, printing the manual commands instead.
- Mechanical secret scan over the written `HANDOFF.md` before any commit/push, as a
  backstop to the prose security gate (AWS/Slack/GitHub token shapes, private keys,
  credentials embedded in URLs, bearer tokens).
- `/handoff` precondition for non-git directories: writes a local-only handoff and
  skips the git steps instead of surfacing raw `fatal:` errors.
- `/catchup` staleness check: warns when `HEAD` has advanced past the commit recorded
  in the handoff, with a commit count.
- Merge-conflict awareness in both skills: `/catchup` refuses to brief from a handoff
  containing conflict markers; `/handoff` refuses to archive over one.
- Front-matter sourcing for `operator`, `repo` (owner/repo slug), `base` (default
  branch, never blindly `main`), and `handoff_reason` from live git context.
- Installer self-verification: both installers confirm the SessionStart hook actually
  registered and name the two commands (`/handoff`, `/catchup`) on completion.
- `python3` fallback for the settings.json merge in `install.sh`, so the hook
  registers on macOS/Linux machines without `jq` (parity with Windows).
- README: Uninstall section, Troubleshooting section, License section, verify-install
  instructions, and a documented `author` front-matter field.
- This changelog.

### Changed
- `/handoff`'s rejected-push handling is now an explicit recipe: rebase and keep the
  newer handoff (`git checkout --theirs HANDOFF.md` during the rebase), never
  `git push --force`.
- No-remote repos are treated as a successful local-only handoff instead of a push
  failure; detached `HEAD` stops before creating an unreachable commit.
- Staging is guarded by `git check-ignore` so a project `.gitignore` can never
  silently swallow the handoff.
- Machine-local memory is folded in during synthesis, before the security gate, so
  folded-in content is covered by the secret checks.
- Archive names use second-precision UTC (`YYYYMMDDTHHMMSSZ-prev.md`) with a
  collision suffix and non-clobbering moves, so an archive is never overwritten.
- Both SessionStart hooks resolve the git repo root, so the `/catchup` nudge fires
  from any subdirectory of the repo, not only the root.
- `/catchup` is explicitly read-only until the user confirms, and gates its
  `git switch` suggestion on a clean working tree.
- `/handoff`'s final report names the branch and remote it pushed to, and whether a
  prior handoff was archived.
- Installers: hook command paths are quoted (usernames with spaces), the settings.json
  backup is create-once (never clobbers a good backup), `install.ps1` survives JSONC
  comments in settings.json instead of crashing, and serialization depth was raised.
- Update scripts guard for a missing `git` and state that `~/.claude` is unchanged
  when a `--ff-only` pull fails.
- `.gitattributes` pins `*.md` to LF so synced handoffs are byte-stable across OSes.
- README install/update snippets share one working directory convention (`cd` after
  clone) and the update one-liner keeps the `-ExecutionPolicy Bypass` wrapper.

### Fixed
- README contradictions about auto-push: three passages promised a confirmation
  prompt ("with your OK", "offers to commit + push", "only after you confirm") that
  the skill never gives. All now accurately describe the automatic, secret-gated push.
- README front-matter list omitted the `author` field; the layout tree omitted
  `LICENSE`; the bash hook emitted CRLF-tainted previews on CRLF checkouts.

## [0.1.0] - 2026-06-09

Initial release.

### Added
- `/handoff` skill: synthesize the session into a curated `HANDOFF.md` at the repo
  root, archive the prior one to `.handoffs/`, commit and push.
- `/catchup` skill: read the handoff plus live git state and brief a fresh session.
- SessionStart hook (PowerShell + bash) that surfaces an existing `HANDOFF.md` and
  nudges `/catchup`.
- Idempotent installers for Windows and macOS/Linux, update scripts (pull +
  re-install in one step), and the MIT license.

[0.2.0]: https://github.com/briansmith80/claude-handoff/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/briansmith80/claude-handoff/releases/tag/v0.1.0
