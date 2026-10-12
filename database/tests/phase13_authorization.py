from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
AUTH=json.loads((ROOT/'database/samples/phase13_authorized_hashes.json').read_text())['files']
def profession_hash(path,expected,signature=None):
    row=AUTH.get(path,{})
    return row.get('functions',{}).get(signature,expected) if signature is not None else row.get('current',expected)
