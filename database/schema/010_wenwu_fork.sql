-- v10: provenance-preserving aggregator index; types and restricted indexes are not collection objects.
CREATE TABLE wenwu_entries(
  record_id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL DEFAULT 'WENWU_FORK',
  museum_code TEXT NOT NULL,
  museum_name TEXT,
  entity_key TEXT NOT NULL,
  record_kind TEXT NOT NULL CHECK(record_kind IN('MUSEUM_RECORD','COIN_TYPE','SOURCE_INDEX')),
  original_name TEXT NOT NULL,
  original_dynasty TEXT,
  original_material TEXT,
  original_inventory TEXT,
  accession_number TEXT,
  category_label TEXT,
  official_url TEXT NOT NULL,
  data_license_claim TEXT,
  effective_data_license TEXT NOT NULL REFERENCES licenses(license_id),
  rights_verdict TEXT NOT NULL,
  rights_evidence_url TEXT,
  media_claims_json TEXT NOT NULL CHECK(json_valid(media_claims_json)),
  issues_json TEXT NOT NULL CHECK(json_valid(issues_json)),
  upstream_sha TEXT NOT NULL,
  payload_sha256 TEXT NOT NULL,
  projection_sha256 TEXT NOT NULL,
  object_id TEXT REFERENCES collection_objects(object_id),
  active INTEGER NOT NULL DEFAULT 1 CHECK(active IN(0,1)),
  review_status TEXT NOT NULL DEFAULT 'PENDING' CHECK(review_status IN('PENDING','HUMAN_REVIEWED','DENIED')),
  curated_name TEXT,
  curator_locked INTEGER NOT NULL DEFAULT 0 CHECK(curator_locked IN(0,1)),
  local_note TEXT NOT NULL DEFAULT '',
  FOREIGN KEY(source_id,record_id) REFERENCES source_records(source_id,record_id)
);
CREATE INDEX wenwu_identity ON wenwu_entries(entity_key);
CREATE INDEX wenwu_filters ON wenwu_entries(museum_code,category_label,record_kind,rights_verdict);
CREATE TABLE wenwu_versions(
  record_id TEXT NOT NULL REFERENCES wenwu_entries(record_id),
  payload_sha256 TEXT NOT NULL,
  projection_sha256 TEXT NOT NULL,
  upstream_sha TEXT NOT NULL,
  snapshot_json TEXT NOT NULL CHECK(json_valid(snapshot_json)),
  PRIMARY KEY(record_id,payload_sha256,projection_sha256)
);
CREATE TABLE wenwu_sync_runs(
  run_id INTEGER PRIMARY KEY,
  upstream_sha TEXT NOT NULL,
  complete_scan INTEGER NOT NULL DEFAULT 0,
  report_json TEXT NOT NULL CHECK(json_valid(report_json))
);
