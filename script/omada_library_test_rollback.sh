#!/bin/sh
# Two-phase rollback; usage: sh script prepare|finish.
# Restart Core manually after prepare, then verify official-wheel evidence.
set -eu
mode=${1:?Use prepare or finish}
state=/config/realsw-ha-config/state/omada-null-sections-221976f
component=/config/custom_components/tplink_omada
quarantine=$(cat "$state/quarantine-path.txt")
case "$quarantine" in /config/quarantine/tplink_omada/library-null-sections-*) ;; *) exit 1 ;; esac
case "$mode" in
prepare)
    test -d "$quarantine/original-component"
    cp "$component/manifest.json" "$quarantine/test-manifest-$(date -u +%Y%m%d_%H%M%S).json"
    jq '.requirements = ["tplink-omada-client @ file:///config/realsw-ha-config/state/omada-null-sections-221976f/artifacts/rollback/tplink_omada_client-1.5.10-py3-none-any.whl#sha256=ede7bc8e6c1a512f0c1023257cd0ba6998d23735e7e5595b09063cb37641c157"]' "$component/manifest.json" > "$state/rollback-manifest.json"
    jq -e '.requirements | length == 1' "$state/rollback-manifest.json" >/dev/null
    mv "$state/rollback-manifest.json" "$component/manifest.json"
    printf 'Official-wheel rollback requirement staged. Run ha core check and restart Core manually.
'
    ;;
finish)
    jq -e '.version == "1.5.10" and (.direct_url.url | contains("/artifacts/rollback/")) and (.direct_url.url | contains("ede7bc8e6c1a512f0c1023257cd0ba6998d23735e7e5595b09063cb37641c157"))' "$state/runtime-official-evidence.json" >/dev/null
    test ! -e "$state/original-component-staged"
    cp -a "$quarantine/original-component" "$state/original-component-staged"
    (cd "$state/original-component-staged" && sha256sum -c /config/realsw-ha-config/state/omada-184946-stage/files.sha256)
    mv "$component" "$quarantine/test-component-$(date -u +%Y%m%d_%H%M%S)"
    mv "$state/original-component-staged" "$component"
    (cd "$component" && sha256sum -c /config/realsw-ha-config/state/omada-184946-stage/files.sha256)
    printf 'Original integration restored byte-for-byte; official library was verified before restoration.
'
    ;;
*) printf 'Use prepare or finish.
' >&2; exit 1 ;;
esac
