"""Internal transfer entity; source-specific formats never become the SQLite schema."""
import hashlib
import re
import unicodedata
from dataclasses import dataclass, field

def text(value):
    if value is None: return None
    if not isinstance(value, str): value = str(value)
    value = unicodedata.normalize('NFC', value).strip()
    return value or None

def stable_id(namespace, value):
    return namespace + ':' + hashlib.sha256(str(value).encode('utf-8')).hexdigest()[:24]

def license_id(value):
    value = (value or '').lower()
    if 'by-nc' in value: return 'CC_BY_NC'
    if value in ('cc0', 'cc0-1.0') or '/zero/' in value: return 'CC0'
    if value in ('cc-by-4.0', 'cc by 4.0') or '/by/4.0' in value: return 'CC_BY'
    return 'UNKNOWN'

@dataclass
class CollectionRecord:
    source_id: str
    record_id: str
    record_url: str
    raw: dict
    primary_name: str | None
    primary_language: str = 'en'
    object_kind: str = 'CULTURAL_HERITAGE'
    category_id: str = 'ARCHAEOLOGICAL_ARTIFACT'
    museum_id: str | None = None
    accession_number: str | None = None
    description: str | None = None
    data_license: str = 'UNKNOWN'
    copyright_notice: str = ''
    dataset_url: str | None = None
    verification_status: str = 'SOURCE_VERIFIED'
    names: list = field(default_factory=list)
    cultures: list = field(default_factory=list)
    materials: list = field(default_factory=list)
    techniques: list = field(default_factory=list)
    origin: str | None = None
    discovery: str | None = None
    region: str | None = None
    extension_table: str = 'cultural_heritage'
    extension: dict = field(default_factory=dict)
    measurements: list = field(default_factory=list)
    media: list = field(default_factory=list)
    evidence: dict = field(default_factory=dict)
    occurrence: dict | None = None
    context_only: bool = False

    def validate(self):
        if not text(self.record_id) or not self.record_url.startswith(('https://', 'http://')):
            raise ValueError('Missing source identity or record URL')
        if not self.context_only and not text(self.primary_name):
            raise ValueError('Missing name; cannot create a specimen from a taxon alone')
        if not self.context_only and self.object_kind == 'NATURAL_HISTORY' and not self.accession_number:
            raise ValueError('Natural-history object requires an actual specimen catalogue number')
        if self.data_license not in ('CC0', 'CC_BY', 'CC_BY_NC', 'UNKNOWN', 'CONFIRM'):
            raise ValueError('Unsupported licence')
        if self.extension_table not in ('cultural_heritage', 'fossil_specimens', 'mineral_specimens',
                                        'meteorite_specimens', 'rock_specimens', 'biological_specimens', 'geological_specimens'):
            raise ValueError('Unknown extension table')

def inferred_materials(verbatim):
    """Broad material tags only when explicitly named in source technique, never chemistry."""
    result = []
    for word, id in [('bronze','BRONZE'),('jade','JADE'),('ceramic','CERAMIC'),('porcelain','CERAMIC'),('gold','GOLD'),('silver','SILVER')]:
        if re.search(r'\b' + word + r'\b', (verbatim or '').lower()) and id not in result:
            result.append((id, word))
    return result
