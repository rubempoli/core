"""Temporary in-process evidence for the null-section library test."""

import hashlib
from importlib.metadata import distribution
import json
import os
from pathlib import Path
import sys

from tplink_omada_client import definitions


def collect_library_test_evidence() -> str:
    """Inspect the imported library and exercise models without controller access."""
    package = distribution("tplink-omada-client")
    source = Path(definitions.__file__)
    valid = {
        "upgrade": True,
        "currentVersion": "1.0.0",
        "latestVersion": "1.0.1",
        "fwReleaseLog": "Test notes.",
        "releaseLog": "Test notes.",
        "downloadLink": "https://example.com/test",
    }
    checks = {}
    for label, data, expected in (
        ("missing", {}, [False, None, None, None, None]),
        ("null_hardware", {"hardware": None}, [False, None, None, None, None]),
        ("null_software", {"software": None}, [False, None, None, None, None]),
        (
            "both_null",
            {"hardware": None, "software": None},
            [False, None, None, None, None],
        ),
        (
            "valid_software",
            {"hardware": None, "software": valid},
            [True, "1.0.0", "1.0.1", "Test notes.", "https://example.com/test"],
        ),
        (
            "valid_hardware",
            {"hardware": valid, "software": None},
            [True, "1.0.0", "1.0.1", "Test notes.", "https://example.com/test"],
        ),
    ):
        model = definitions.OmadaControllerUpdateInfo(data)
        try:
            actual = [
                model.upgrade,
                model.current_version,
                model.latest_version,
                model.release_notes,
                model.release_url,
            ]
            sections_match = all(
                (getattr(model, section) is None) == (data.get(section) is None)
                for section in ("hardware", "software")
            )
            checks[label] = {
                "passed": actual == expected and sections_match,
                "values": actual,
            }
        except (AttributeError, KeyError, TypeError) as err:
            checks[label] = {"passed": False, "error": type(err).__name__}
    empty = definitions.OmadaControllerUpdateInfo({"hardware": {}, "software": valid})
    checks["empty_hardware_precedence"] = {
        "passed": isinstance(empty.update, definitions.OmadaHardwareUpdateInfo)
        and empty.update.raw_data == {}
    }
    return json.dumps(
        {
            "expected_library_commit": "221976f769189fc38c36bc1c0d0069c9ac16b1f4",
            "pid": os.getpid(),
            "python": sys.version.split()[0],
            "version": package.version,
            "module_path": str(source),
            "definitions_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "direct_url": json.loads(package.read_text("direct_url.json") or "null"),
            "checks": checks,
        },
        sort_keys=True,
    )
