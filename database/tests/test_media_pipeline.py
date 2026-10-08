import io,json,tempfile,unittest
from pathlib import Path
from PIL import Image
from database.schema.migrate import init_db,ROOT
from database.preview.__main__ import prepare_content,preview_payload
from database.media_pipeline.pipeline import checked_image,safe_url,active_media,revoke,local_file,SafeRedirect
class MediaPipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');prepare_content(cls.db)
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_twenty_real_licensed_photographs(self):
        rows=active_media(self.db);self.assertEqual(20,len(json.loads((ROOT/'media_pipeline/manifest.json').read_text(encoding='utf-8'))['images']));self.assertGreaterEqual(len(rows),2)
        for r in rows:
            self.assertEqual('CC0',r['license_id']);self.assertEqual('CC0',r['rights_evidence']['share_license_status']);self.assertTrue(r['source_sha256']);self.assertTrue(r['attribution'])
            for kind,bound in [('thumb',320),('detail',1024)]:
                self.assertLessEqual(max(r[kind+'_size']),bound)
                self.assertLess(abs(r[kind+'_size'][0]/r[kind+'_size'][1]-r['source_size'][0]/r['source_size'][1]),.035)
    def test_html_and_mime_disagreement_rejected(self):
        for b,mime in [(b'<html>not image</html>','image/jpeg'),(b'\xff\xd8\xffbad','text/html')]:
            with self.assertRaises(ValueError):checked_image(b,mime)
    def test_tiny_and_corrupt_images_rejected(self):
        image=Image.new('RGB',(8,8));buf=io.BytesIO();image.save(buf,'PNG')
        with self.assertRaises(ValueError):checked_image(buf.getvalue(),'image/png')
        with self.assertRaises(Exception):checked_image(b'\xff\xd8\xffnot a real jpeg','image/jpeg')
    def test_unapproved_and_redirect_hosts_denied(self):
        for url in ['http://openaccess-cdn.clevelandart.org/x.jpg','https://openaccess-cdn.clevelandart.org.evil.test/x','https://user@openaccess-cdn.clevelandart.org/x','https://127.0.0.1/x']:
            with self.assertRaises(ValueError):safe_url(url)
        with self.assertRaises(ValueError):SafeRedirect().redirect_request(None,None,302,'',{},'https://evil.test/image.jpg')
    def test_revocation_and_unknown_excluded_on_reexport(self):
        before=len(active_media(self.db));first=active_media(self.db)[0]
        with tempfile.TemporaryDirectory() as tmp:
            manifest=Path(tmp)/'manifest.json';manifest.write_bytes((ROOT/'media_pipeline/manifest.json').read_bytes())
            revoke(self.db,first['media_id'],'Fixture withdrawal',manifest)
            self.assertNotIn(first['media_id'],[r['media_id'] for r in active_media(self.db,manifest)])
            self.assertTrue(json.loads(manifest.read_text(encoding='utf-8'))['images'][0]['revoked'])
        self.db.execute("UPDATE media SET verification_status='VERIFIED',commercial_allowed=1 WHERE media_id=?",(first['media_id'],))
        self.db.execute('SAVEPOINT unknown_media');self.db.execute("UPDATE media SET license_id='UNKNOWN' WHERE media_id=?",(first['media_id'],));self.assertEqual(before-1,len(active_media(self.db)));self.db.execute('ROLLBACK TO unknown_media');self.db.execute('RELEASE unknown_media')
    def test_tampered_or_external_path_excluded(self):
        self.assertIsNone(local_file('database/previews/media/../../../private.jpg'))
        self.assertIsNone(local_file('https://example.test/image.jpg'))
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'manifest.json';data=json.loads((ROOT/'media_pipeline/manifest.json').read_text(encoding='utf-8'));data['images'][0]['detail_sha256']='tampered';p.write_text(json.dumps(data),encoding='utf-8')
            self.assertEqual(len(active_media(self.db))-1,len(active_media(self.db,p)))
    def test_preview_has_local_images_and_no_game_assets(self):
        payload=preview_payload(self.db);self.assertEqual(len(active_media(self.db)),sum(bool(r['images']) for r in payload['objects']))
        self.assertTrue(all(not r['local_asset_path'] for r in self.db.execute('SELECT local_asset_path FROM media')))
