from contextlib import closing
import copy,json,unittest
from database.schema.migrate import init_db
from database.importers.wenwu_fork_adapter import project
from database.importers.wenwu_fork_sync import Sync
SHA='1'*40

def row(rid='MET-1',name='Bowl',acc='A1'):
 return {'relic_id':rid,'name':name,'dynasty':'汉','category':'陶器','material':'Earthenware','collection':{'museum':'The Met','region':'北美洲','inventory_no':acc},'source_url':'https://www.metmuseum.org/art/collection/search/'+rid.split('-')[1],'license':'CC0','year_range':[-100,100],'dynasty_confidence':'low','images':[{'url':'https://images.metmuseum.org/one.jpg','license':'CC0','credit':'The Met'}]}

class WenwuTests(unittest.TestCase):
 def setUp(self):self.db=init_db(':memory:');self.sync=Sync(self.db,SHA)
 def tearDown(self):self.db.close()
 def test_open_mapping_and_raw_provenance(self):
  raw=row();self.sync.ingest(raw)
  entry=self.db.execute('SELECT * FROM wenwu_entries').fetchone()
  self.assertEqual(entry['original_name'],'Bowl');self.assertEqual(entry['original_dynasty'],'汉');self.assertEqual(entry['original_material'],'Earthenware');self.assertEqual(entry['effective_data_license'],'CC0')
  self.assertTrue({'relic_id','name','dynasty','year_range','material','collection','source_url','license'} <= {r[0] for r in self.db.execute('SELECT field_path FROM field_evidence')})
  self.assertEqual(self.db.execute('SELECT count(*) FROM object_cultures').fetchone()[0],0)
 def test_legitimate_original_id_space_preserved(self):
  raw=row('MET-8225 test');raw['source_url']='https://www.metmuseum.org/art/collection/search/8225'
  self.sync.ingest(raw);self.assertEqual(self.db.execute('SELECT record_id FROM wenwu_entries').fetchone()[0],'MET-8225 test')
 def test_idempotent(self):
  self.sync.ingest(row());result=self.sync.ingest(row());self.assertEqual(result['entry'],'duplicate');self.assertEqual(result['normalized_added'],0)
  self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],1)
 def test_name_is_not_identity(self):
  self.sync.ingest(row());self.sync.ingest(row('MET-2',acc='A2'))
  self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],2)
 def test_same_accession_cross_reference(self):
  self.sync.ingest(row());self.sync.ingest(row('MET-2',acc='A1'))
  self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],1)
  self.assertEqual(self.db.execute('SELECT count(*) FROM source_records WHERE object_id IS NOT NULL').fetchone()[0],2)
 def test_reviewed_fields_and_index_survive_update(self):
  self.sync.ingest(row());oid=self.db.execute('SELECT object_id FROM wenwu_entries').fetchone()[0]
  self.db.execute("UPDATE collection_objects SET primary_name='Human',editor_locked=1 WHERE object_id=?",(oid,))
  self.db.execute("UPDATE wenwu_entries SET curated_name='Human index',curator_locked=1,review_status='HUMAN_REVIEWED',local_note='Keep' WHERE record_id='MET-1'")
  self.db.execute("UPDATE field_evidence SET source_value='human evidence',status='CURATED' WHERE object_id=? AND field_path='name'",(oid,))
  Sync(self.db,'2'*40).ingest(row(name='Changed upstream'))
  self.assertEqual(self.db.execute('SELECT primary_name FROM collection_objects').fetchone()[0],'Human')
  index=self.db.execute('SELECT * FROM wenwu_entries').fetchone();self.assertEqual(index['curated_name'],'Human index');self.assertEqual(index['local_note'],'Keep');self.assertEqual(index['review_status'],'HUMAN_REVIEWED');self.assertEqual(index['original_name'],'Changed upstream')
  self.assertEqual(self.db.execute("SELECT source_value FROM field_evidence WHERE field_path='name'").fetchone()[0],'human evidence')
  self.assertEqual(self.db.execute('SELECT count(*) FROM wenwu_versions').fetchone()[0],2)
 def test_api_id_not_accession(self):
  r=row('AIC-12');r['source_url']='https://www.artic.edu/artworks/12';r['collection']['inventory_no']='12'
  self.sync.ingest(r);self.assertIsNone(self.db.execute('SELECT accession_number FROM collection_objects').fetchone()[0])
 def test_aggregate_coin_does_not_create_specimen(self):
  r=row('SXHM-1');r.update(source_url='https://www.sxhm.com/down/news/499.html',category='钱币',license='©Museum',raw_ref='raw/sxhm/499.xlsx',summary='同名称品种汇总记录')
  self.sync.ingest(r)
  self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],0)
  self.assertEqual(self.db.execute('SELECT record_kind FROM wenwu_entries').fetchone()[0],'COIN_TYPE')
 def test_rights_conflict_index_only(self):
  r=row('NPM-1');r.update(source_url='https://digitalarchive.npm.gov.tw/opendata/Pub/Detail/1?dep=P',license='CC0 1.0')
  self.sync.ingest(r);self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],0)
  self.assertEqual(self.db.execute('SELECT rights_verdict FROM wenwu_entries').fetchone()[0],'RIGHTS_CONFLICT_INDEX_ONLY')
 def test_mit_not_metadata_permission(self):
  r=row();r['license']='MIT';self.sync.ingest(r)
  self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],0)
 def test_media_independent_not_auto_approved(self):
  self.sync.ingest(row());media=self.db.execute('SELECT * FROM media').fetchone()
  self.assertEqual(media['license_id'],'UNKNOWN');self.assertEqual(media['verification_status'],'UNVERIFIED');self.assertIsNone(media['commercial_allowed'])
 def test_invalid_url_and_missing_fields_rejected(self):
  for field,value in [('source_url','javascript:alert(1)'),('name',''),('relic_id','')]:
   r=row();r[field]=value
   with self.assertRaises(ValueError):project(r,SHA)
 def test_no_input_mutation_or_game_rows(self):
  r=row();before=copy.deepcopy(r);self.sync.ingest(r);self.assertEqual(r,before)
  self.assertEqual(self.db.execute('SELECT count(*) FROM game_collection_candidates').fetchone()[0],0)
 def test_different_museum_same_title_not_merged(self):
  self.sync.ingest(row());r=row('AIC-12');r['source_url']='https://www.artic.edu/artworks/12';r['collection']['inventory_no']='12';self.sync.ingest(r)
  self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],2)
if __name__=='__main__':unittest.main()


class PreviewTests(unittest.TestCase):
 def test_paginated_readonly_export_escapes_untrusted_markup(self):
  import tempfile
  from pathlib import Path
  from database.wenwu_catalog import connect,search,export
  with tempfile.TemporaryDirectory() as temp:
   path=Path(temp)/'test.sqlite';db=init_db(path);sync=Sync(db,SHA)
   for index in range(3):sync.ingest(row('MET-'+str(index),name='</script><img src=x onerror=alert(1)>',acc=str(index+1)))
   db.close()
   with closing(connect(path)) as db:
    self.assertEqual(search(db,size=2)['total'],3);self.assertEqual(len(search(db,size=2,page=2)['records']),1)
    with self.assertRaises(Exception):db.execute('DELETE FROM wenwu_entries')
    out=Path(temp)/'preview';self.assertEqual(export(db,out),1)
    text=(out/'index.html').read_text(encoding='utf-8');self.assertNotIn('</script><img',text);self.assertIn('textContent',text)
    self.assertIn('&lt;/script&gt;', (out/'page-1.html').read_text(encoding='utf-8'))
