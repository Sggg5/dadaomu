"""Checksum-locked, transactional forward migrations. Never deletes a database."""
import hashlib
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCABS = frozenset(('cultures historical_periods geological_periods regions locations '
                    'object_categories materials techniques taxa formations institutions').split())

def utc_now():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')

def connect(path):
    db = sqlite3.connect(path, isolation_level=None)
    db.row_factory = sqlite3.Row
    db.execute('PRAGMA foreign_keys=ON')
    db.execute('PRAGMA busy_timeout=5000')
    return db

def migrate(db, directory=ROOT / 'schema'):
    has_registry = db.execute("SELECT 1 FROM sqlite_master WHERE name='schema_migrations'").fetchone()
    applied = {r['version']: r for r in db.execute('SELECT * FROM schema_migrations')} if has_registry else {}
    files = sorted(Path(directory).glob('[0-9][0-9][0-9]_*.sql'))
    if set(applied) - {int(p.name[:3]) for p in files}:
        raise ValueError('Database has migrations unknown to this checkout')
    for file in files:
        version = int(file.name[:3])
        script = file.read_text(encoding='utf-8')
        digest = hashlib.sha256(script.encode()).hexdigest()
        if version in applied:
            if applied[version]['sha256'] != digest:
                raise ValueError(f'Migration modified after application: {file.name}')
            continue
        db.execute('BEGIN IMMEDIATE')
        try:
            statement = ''
            for line in script.splitlines(keepends=True):
                statement += line
                if sqlite3.complete_statement(statement):
                    db.execute(statement)
                    statement = ''
            if statement.strip() and not statement.lstrip().startswith('--'):
                raise ValueError('Incomplete migration SQL')
            db.execute('INSERT INTO schema_migrations VALUES(?,?,?,?)',
                       (version, file.name, digest, utc_now()))
            db.execute('COMMIT')
        except Exception:
            db.execute('ROLLBACK')
            raise

def seed_vocab(db, path=ROOT / 'vocab/global_seed.json'):
    vocab = json.loads(Path(path).read_text(encoding='utf-8'))
    db.execute('BEGIN IMMEDIATE')
    try:
        db.executemany('INSERT OR IGNORE INTO licenses VALUES(?,?,?,?,?)', vocab['licenses'])
        for table, rows in vocab['terms'].items():
            if table not in VOCABS:
                raise ValueError(f'Unknown vocabulary: {table}')
            for row in rows:
                db.execute(f'INSERT OR IGNORE INTO {table}(id,parent_id,label,external_id,authority_url) VALUES(?,?,?,?,?)',
                           tuple(row.get(k) for k in ('id', 'parent_id', 'label', 'external_id', 'authority_url')))
                db.execute('INSERT OR IGNORE INTO vocab_names VALUES(?,?,?,?,?)',
                           (table, row['id'], 'en', 'PRIMARY', row['label']))
        for table in ('human_chronology', 'geological_timescale'):
            columns = [r['name'] for r in db.execute(f'PRAGMA table_info({table})')]
            for row in vocab[table]:
                db.execute(f'INSERT OR IGNORE INTO {table} VALUES({",".join("?" for _ in columns)})',
                           tuple(row.get(k) for k in columns))
        db.execute('COMMIT')
    except Exception:
        db.execute('ROLLBACK')
        raise

def init_db(path):
    if str(path) != ':memory:':
        Path(path).parent.mkdir(parents=True, exist_ok=True)
    db = connect(path)
    try:
        migrate(db)
        seed_vocab(db)
    except Exception:
        db.close()
        raise
    return db
