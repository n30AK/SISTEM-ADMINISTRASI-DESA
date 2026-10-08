# OpenSID Schema Discovery

Before field mapping, run:

`php bin/opensid-inspect.php`

Optional:

`php bin/opensid-inspect.php tweb_penduduk tweb_keluarga surat_keluar`

The command reads metadata only from the connected OpenSID-compatible MySQL database. It does not modify data.

The resulting schema inventory is the gate for field-by-field mapping. Unknown columns are never guessed or promoted automatically.
