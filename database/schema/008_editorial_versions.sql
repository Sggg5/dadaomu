-- Editorial versions are append-only snapshots; base seed replay cannot overwrite revised or human-locked text.
ALTER TABLE editorial_articles ADD COLUMN editor_locked INTEGER NOT NULL DEFAULT 0 CHECK(editor_locked IN(0,1));
ALTER TABLE editorial_articles ADD COLUMN editor_version INTEGER NOT NULL DEFAULT 1 CHECK(editor_version>=1);
CREATE TABLE editorial_versions(article_id TEXT NOT NULL REFERENCES editorial_articles(article_id), version INTEGER NOT NULL CHECK(version>=1), payload_json TEXT NOT NULL CHECK(json_valid(payload_json)), content_sha256 TEXT NOT NULL, author_type TEXT NOT NULL CHECK(author_type IN('AI','HUMAN')), review_status TEXT NOT NULL DEFAULT 'DRAFT_PENDING_REVIEW', PRIMARY KEY(article_id,version));
