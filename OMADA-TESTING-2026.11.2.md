# Omada custom integration test branch for Core 2026.11.2

This branch is for testing only. It is separate from the branch backing
Home Assistant Core PR #191160 and is not intended for upstream submission.

Feature source: `rubempoli/core`, `codex/omada-adopted-device-filter`, commit
`46fd1b8d92b49c1e333dc0c2fdfa3963f71ff5ca`.

It includes **Show only adopted Omada devices** and the software-controller
update availability fix. The dependency remains `tplink-omada-client==1.5.14`.

## Differences from the PR

- `services.py`: use `ATTR_CONFIG_ENTRY_ID` and `ATTR_DEVICE_ID` instead of
  `CommonServiceArgument`, which is unavailable in Core 2026.11.2.
- `switch.py`: use the release type `UndefinedType` instead of `Undefined`.
- `manifest.json`: add custom integration version `0.3.4`.
- Include generated `translations/en.json` so the new option is displayed.
- This testing guide. Feature code is otherwise unchanged.

## Validation

The complete Omada suite passed on Core 2026.11.2 with client 1.5.14:
177 tests and 91 snapshots, including the custom integration loader test.
The isolated release test harness maps the dev `TargetKey.ENTITY_ID` constant
to `ATTR_ENTITY_ID` and reads the release WebSocket result directly instead of
the newer nested `release_notes` response. These test-only adaptations do not
change the integration files installed by a tester.

Core dev's pylint rule requires the new `Undefined` spelling, while its built-in
manifest validator forbids the custom-only `version` field. Those two dev hooks
are inapplicable to this release custom adaptation. Full-repository validation
is not claimed for this testing branch.

## Installation

1. Confirm Core **2026.11.2** and take a full Home Assistant backup.
2. Download or clone branch `codex/omada-test-ha-2026.11.2`. For a clone:
   `git clone --single-branch --branch codex/omada-test-ha-2026.11.2 https://github.com/rubempoli/core.git`
   Record `git rev-parse HEAD` and confirm `git status --porcelain` is empty.
3. If a custom `tplink_omada` directory already exists, move the **entire**
   directory to a timestamped location under `/config/quarantine/tplink_omada/`.
   Keep this outside `custom_components`; preserve any other integrations.
4. Copy the complete `homeassistant/components/tplink_omada/` directory from
   the clean checkout into `/config/custom_components/tplink_omada/`.
   Include `translations/en.json`. Do not copy the rest of Home Assistant Core
   or merge files with the previous custom directory.
5. Restart Home Assistant Core. Confirm custom version **0.3.4** loads and
   inspect logs for Omada import/setup failures.

## What to test

- Open the Omada integration options and enable **Show only adopted Omada
  devices**. Adopted equipment must remain visible; Wi-Fi client tracking
  must stop and client-only devices must not be recreated on refresh/restart.
- Disable the option and confirm Wi-Fi client tracking resumes. Enabling
  this option affects automations that depend on Wi-Fi client presence.
- For a software controller, compare Home Assistant update availability with
  the Omada controller. Report installed/latest versions and whether each
  interface offers an update. Do not perform a controller upgrade just to test
  this indication. A no-update state alone does not verify a positive offer.
- Report Core version, tester branch commit, controller version, custom version,
  results and relevant logs with credentials and identifiers removed.

## Rollback

Move the test custom directory outside `custom_components`, restore the complete
quarantined directory (or leave no custom directory if previously using the
built-in integration), and restart Core. Check setup logs. Restoring source files
does not reverse device-registry cleanup; use the full backup if registry state
also needs restoring. Do not manually edit `.storage`.
