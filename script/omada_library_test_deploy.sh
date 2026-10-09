#!/bin/sh
# Deploy the published Omada library test; usage: sh script expected-core-sha.
# Core restart is deliberately manual. Preserve the issue-184946 workaround.
set -eu
expected=${1:?Expected Core test commit is required}
repo=/config/realsw-ha-config/repos/core-omada-null-library
state=/config/realsw-ha-config/state/omada-null-sections-221976f
component=/config/custom_components/tplink_omada
source=$repo/homeassistant/components/tplink_omada
old_state=/config/realsw-ha-config/state/omada-184946-stage
test "$(git -C "$repo" rev-parse HEAD)" = "$expected"
test -z "$(git -C "$repo" status --porcelain)"
test ! -e "$state/deployment.txt"
test -d "$component"
(cd "$component" && sha256sum -c "$old_state/files.sha256")
jq -e '.version == "2026.10.0.dev184946" and .requirements == ["tplink-omada-client==1.5.10"]' "$component/manifest.json" >/dev/null
printf '%s  %s
' a1d298166ddcd01580af6c281cbab5ca8978de7efbd1db337e324aaf51558e2c "$state/artifacts/test/tplink_omada_client-1.5.10-py3-none-any.whl" | sha256sum -c -
printf '%s  %s
' ede7bc8e6c1a512f0c1023257cd0ba6998d23735e7e5595b09063cb37641c157 "$state/artifacts/rollback/tplink_omada_client-1.5.10-py3-none-any.whl" | sha256sum -c -
quarantine=/config/quarantine/tplink_omada/library-null-sections-$(date -u +%Y%m%d_%H%M%S)
test ! -e "$quarantine"
test ! -e "$state/component-staged"
cp -a "$source" "$state/component-staged"
(cd "$state/component-staged" && find . -type f -exec sha256sum {} \; | sort) > "$state/files.sha256"
mkdir -p "$quarantine"
printf '%s
' "$quarantine" > "$state/quarantine-path.txt"
cat > "$state/deployment.txt" <<EOF
Core repository: https://github.com/rubempoli/core.git
Core branch: codex/omada-null-library-ha-2026.10.0
Core test SHA: $expected
Core base SHA: 95c453caddd1099ef96c4fd09f5a767f6ea8802c
Source git status: clean
Library repository: https://github.com/rubempoli/tplink-omada-api.git
Library branch: codex/controller-update-null-sections
Library SHA: 221976f769189fc38c36bc1c0d0069c9ac16b1f4
Library build source status: clean
Source: $source
Destination: $component
Files copied: see files.sha256
Test wheel SHA256: a1d298166ddcd01580af6c281cbab5ca8978de7efbd1db337e324aaf51558e2c
Official rollback wheel SHA256: ede7bc8e6c1a512f0c1023257cd0ba6998d23735e7e5595b09063cb37641c157
Adaptations: local-wheel requirement; existing custom version; generated English translations; temporary in-process diagnostic
Quarantine: $quarantine/original-component
Rollback script: $repo/script/omada_library_test_rollback.sh
Validation: AppHost 99 library tests; 42 Core tests and 6 snapshots; diagnostic probes; Ruff; build; shell syntax; source parity
Restart: not performed
Runtime verification: pending user restart
EOF
mv "$component" "$quarantine/original-component"
if ! mv "$state/component-staged" "$component"; then
    mv "$quarantine/original-component" "$component"
    exit 1
fi
(cd "$component" && sha256sum -c "$state/files.sha256")
printf 'Test component staged. Core has not been restarted.
'
