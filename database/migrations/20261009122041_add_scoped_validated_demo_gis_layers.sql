-- Expose only active, valid demo geometries for interactive GIS QA.
-- These polygons are explicitly marked DEMO and must never be presented as official boundaries.
create or replace function village.gis_demo_layers()
returns table (
  id uuid,
  name text,
  level text,
  geometry_geojson jsonb,
  centroid_geojson jsonb
)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public', 'village'
as $function$
  select
    mt.id,
    mt.name,
    mt.level,
    ST_AsGeoJSON(ST_Force2D(mt.polygon))::jsonb as geometry_geojson,
    case when mt.centroid is not null
      then ST_AsGeoJSON(ST_Force2D(mt.centroid))::jsonb
      else null
    end as centroid_geojson
  from public.sv_master_territories mt
  where auth.uid() is not null
    and mt.active = true
    and mt.name ilike '%demo%'
    and mt.polygon is not null
    and ST_SRID(mt.polygon) = 4326
    and ST_IsValid(mt.polygon)
    and GeometryType(mt.polygon) in ('POLYGON','MULTIPOLYGON')
  order by
    case mt.level when 'VILLAGE' then 0 when 'RW' then 1 when 'RT' then 2 else 3 end,
    mt.name;
$function$;

revoke all on function village.gis_demo_layers() from public, anon;
grant execute on function village.gis_demo_layers() to authenticated;
