-- Permit safe re-normalization when adapters change, without discarding curator locks.
ALTER TABLE source_records ADD COLUMN normalizer_version INTEGER NOT NULL DEFAULT 0;
