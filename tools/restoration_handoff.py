"""Summarize verified saved restoration artifacts without rebuilding them."""
import argparse
import hashlib
import json
from pathlib import Path

from build_object_images import CODE_SIZE
from compare_exe import TARGET_SHA256


CATEGORIES = ('compiler_generated', 'inline_assembly', 'standalone_assembly', 'unattributed')


def _json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def _digest(data):
    return hashlib.sha256(data).hexdigest()


def _object_path(build, name):
    if not isinstance(name, str) or not name:
        raise ValueError('Invalid object path in C inventory')
    root = build.resolve()
    path = (root / name).resolve()
    if path == root or not path.is_relative_to(root):
        raise ValueError(f'Object path escapes build directory: {name}')
    return path


def summarize(build, audit_path):
    build = Path(build).resolve()
    audit_path = Path(audit_path).resolve()
    validation_path = build / 'validation.json'
    inventory_path = build / 'c.json'
    executable_path = build / 'FATE.EXE'
    validation = _json(validation_path)
    inventory_bytes = inventory_path.read_bytes()
    inventory = json.loads(inventory_bytes.decode('utf-8'))
    audit = _json(audit_path)

    if (validation.get('status') != 'passed' or
            validation.get('mode') not in ('exact', 'full') or
            validation.get('whole_image_verified') is not True):
        raise ValueError('Build validation is not a passed whole-image exact/full report')
    executable = executable_path.read_bytes()
    executable_hash = _digest(executable)
    expected = validation.get('executable_sha256')
    if not (TARGET_SHA256 == expected == audit.get('target_sha256') == executable_hash):
        raise ValueError('Pinned executable SHA-256 differs across saved artifacts')
    if inventory.get('target_sha256') != TARGET_SHA256:
        raise ValueError('C inventory target SHA-256 differs from pinned executable')
    if _digest(inventory_bytes) != audit.get('inventory_sha256'):
        raise ValueError('C inventory SHA-256 differs from marker audit')

    object_digests = {}
    rows = inventory.get('spans', []) + inventory.get('non_routine_code_spans', [])
    for row in rows:
        name = row.get('object')
        path = _object_path(build, name)
        actual_digest = object_digests.get(name)
        if actual_digest is None:
            actual_digest = _digest(path.read_bytes())
            object_digests[name] = actual_digest
        if actual_digest != row.get('object_sha256'):
            raise ValueError(f'Object SHA-256 differs: {name}')

    code_segment = audit.get('code_segment')
    if not isinstance(code_segment, dict) or set(code_segment) != set(CATEGORIES):
        raise ValueError('Marker audit must contain exactly the four code_segment categories')
    categories = {}
    for key in CATEGORIES:
        value = code_segment.get(key)
        count = value.get('bytes') if isinstance(value, dict) else None
        if type(count) is not int or count < 0:
            raise ValueError(f'Invalid byte count for category {key}')
        categories[key] = {'bytes': count, 'percent': 100 * count / CODE_SIZE}
    if sum(item['bytes'] for item in categories.values()) != CODE_SIZE:
        raise ValueError('Marker audit categories do not sum to CODE_SIZE')

    totals = audit.get('totals', {})
    result = {
        'build_path': str(build),
        'validation_path': str(validation_path),
        'audit_path': str(audit_path),
        'mode': validation['mode'],
        'executable_bytes': len(executable),
        'executable_sha256': executable_hash,
        'fixture_count': len(validation.get('fixtures', [])),
        'categories': categories,
        'remaining_assembly_bytes': categories['inline_assembly']['bytes'] + categories['standalone_assembly']['bytes'],
        'scope': 'verified saved artifacts; current source freshness requires restore.py doctor',
    }
    for key in ('target_routines', 'measured_routines', 'unknown_routines'):
        if key in totals:
            result[key] = totals[key]
    return result


def _reject_output_collision(output, build, audit_path):
    build = Path(build).resolve()
    audit_path = Path(audit_path).resolve()
    inventory_path = build / 'c.json'
    inventory = _json(inventory_path)
    inputs = {
        build / 'FATE.EXE', build / 'validation.json', inventory_path, audit_path,
    }
    for row in inventory.get('spans', []) + inventory.get('non_routine_code_spans', []):
        inputs.add(_object_path(build, row.get('object')))
    output_path = Path(output).resolve()
    if output_path in {path.resolve() for path in inputs}:
        raise ValueError(f'Output path would overwrite an input artifact: {output_path}')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build', type=Path, help='Saved build directory')
    parser.add_argument('--audit', required=True, type=Path, help='Saved marker audit JSON')
    parser.add_argument('--output', type=Path, help='Optional JSON output path')
    args = parser.parse_args(argv)
    result = summarize(args.build, args.audit)
    serialized = json.dumps(result, indent=2) + '\n'
    if args.output:
        _reject_output_collision(args.output, args.build, args.audit)
        args.output.write_text(serialized, encoding='utf-8')
        print(f'PASS: saved evidence summary to {args.output}')
    else:
        print(serialized, end='')


if __name__ == '__main__':
    main()
