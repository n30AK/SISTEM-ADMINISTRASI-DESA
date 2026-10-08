<?php
require __DIR__.'/../app/db.php';
$view=$_GET['view']??'dashboard';
$allowed=['dashboard','penduduk','keluarga','perangkat','surat','permohonan','keuangan','pembangunan','aset','bantuan'];
if(!in_array($view,$allowed,true))$view='dashboard';
$stats=[
 'penduduk'=>scalar('SELECT COUNT(*) FROM tweb_penduduk'),
 'keluarga'=>scalar('SELECT COUNT(*) FROM tweb_keluarga'),
 'perangkat'=>scalar('SELECT COUNT(*) FROM tweb_desa_pamong WHERE pamong_status=1'),
 'surat'=>scalar('SELECT COUNT(*) FROM surat_keluar'),
 'permohonan'=>scalar('SELECT COUNT(*) FROM permohonan_surat'),
 'keuangan'=>scalar('SELECT COUNT(*) FROM keuangan_master'),
 'pembangunan'=>scalar('SELECT COUNT(*) FROM pembangunan'),
 'aset'=>scalar('SELECT COUNT(*) FROM inventaris_asset'),
 'bantuan'=>scalar('SELECT COUNT(*) FROM dtks'),
];
$labels=['penduduk'=>'Penduduk','keluarga'=>'Keluarga','perangkat'=>'Perangkat Desa','surat'=>'Surat Keluar','permohonan'=>'Permohonan Surat','keuangan'=>'Keuangan','pembangunan'=>'Pembangunan','aset'=>'Aset Desa','bantuan'=>'DTKS & Bantuan'];
$queries=[
 'penduduk'=>'SELECT id,nama,nik,sex,tanggallahir,telepon FROM tweb_penduduk ORDER BY nama LIMIT 100',
 'keluarga'=>'SELECT id,no_kk,nik_kepala,alamat FROM tweb_keluarga ORDER BY id DESC LIMIT 100',
 'perangkat'=>'SELECT id,nama,jabatan,pamong_status FROM tweb_desa_pamong ORDER BY nama LIMIT 100',
 'surat'=>'SELECT id,nomor,jenis,tanggal,tujuan FROM surat_keluar ORDER BY id DESC LIMIT 100',
 'permohonan'=>'SELECT id,nik,jenis_surat,status FROM permohonan_surat ORDER BY id DESC LIMIT 100',
 'keuangan'=>'SELECT * FROM keuangan_master ORDER BY id DESC LIMIT 100',
 'pembangunan'=>'SELECT * FROM pembangunan ORDER BY id DESC LIMIT 100',
 'aset'=>'SELECT * FROM inventaris_asset ORDER BY id DESC LIMIT 100',
 'bantuan'=>'SELECT * FROM dtks ORDER BY id DESC LIMIT 100'
];
function h($v){return htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');}
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title><?=h($labels[$view]??'Dashboard')?> — Sistem Administrasi Desa</title><link rel="stylesheet" href="assets/app.css"></head><body>
<aside class="sidebar"><div class="brand"><div class="mark">SA</div><div><b>Sistem Administrasi Desa</b><small>OpenSID Data Layer</small></div></div><nav>
<?php foreach(array_merge(['dashboard'=>'Dashboard'],$labels) as $k=>$v):?><a class="<?=$view===$k?'active':''?>" href="?view=<?=$k?>"><?=h($v)?></a><?php endforeach;?>
</nav><div class="foot">Data layer: OpenSID-compatible<br>Mode: Read-first</div></aside>
<main><header><div><span class="eyebrow">PEMERINTAHAN DESA</span><h1><?=h($view==='dashboard'?'Dashboard Administrasi Desa':$labels[$view])?></h1></div><div class="status">● DATA LAYER</div></header>
<?php if($view==='dashboard'):?><section class="hero"><span class="eyebrow">PUSAT KENDALI</span><h2>Satu pusat untuk administrasi desa.</h2><p>Kependudukan, layanan surat, pemerintahan, pembangunan, aset, bantuan, dan keuangan dipantau melalui satu antarmuka.</p></section><section class="grid"><?php foreach($labels as $k=>$v):?><a class="card" href="?view=<?=$k?>"><span><?=h($v)?></span><strong><?=number_format($stats[$k],0,',','.')?></strong><small>Data tersimpan</small></a><?php endforeach;?></section>
<?php else:$data=rows($queries[$view]);?><section class="panel"><div class="panelhead"><div><span class="eyebrow">DATA OPEN SID</span><h2><?=h($labels[$view])?></h2></div><span class="count"><?=count($data)?> baris</span></div><div class="tablewrap"><table><thead><tr><?php if($data):foreach(array_keys($data[0]) as $col):?><th><?=h($col)?></th><?php endforeach;endif;?></tr></thead><tbody><?php foreach($data as $row):?><tr><?php foreach($row as $value):?><td><?=h($value)?></td><?php endforeach;?></tr><?php endforeach;if(!$data):?><tr><td class="empty">Belum ada data atau tabel belum tersedia pada database.</td></tr><?php endif;?></tbody></table></div></section><?php endif;?></main></body></html>
