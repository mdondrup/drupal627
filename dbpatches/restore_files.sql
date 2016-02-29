BEGIN TRANSACTION;

CREATE TABLE file_managed_bak AS SELECT * FROM file_managed;


UPDATE file_managed  AS fm set uri = c.new_uri FROM (
    SELECT regexp_replace(uri, '/export/storage/licebase/web-production/files/', '') new_uri, ff.fid AS of
    FROM file_managed AS ff WHERE ff.fid=fid) AS c
     WHERE uri LIKE '%export/storage/licebase/web-production/files%' AND fm.fid=c.of;
-- 25

  
UPDATE file_managed  AS fm set uri = c.new_uri FROM (
    SELECT regexp_replace(uri, 'sites/default/files/', '') new_uri, ff.fid AS of
    FROM file_managed AS ff WHERE ff.fid=fid) AS c
     WHERE uri LIKE '%sites/default/files%' AND fm.fid=c.of;
-- 155

-- Make everything else private:
UPDATE file_managed  AS fm set uri = c.new_uri FROM
( SELECT  'private://' || ff.uri  AS new_uri, ff.fid AS of
  FROM file_managed AS ff
  WHERE ff.uri NOT LIKE 'private:%' AND ff.uri NOT LIKE 'public:%' AND ff.fid=fid ) AS c
  WHERE (fm.uri NOT LIKE 'private:%' AND fm.uri NOT LIKE 'public:%' AND fm.fid=c.of );

UPDATE file_managed  AS fm set uri = c.new_uri FROM (
    SELECT regexp_replace(uri, 'public:', 'private:') new_uri, ff.fid AS of
    FROM file_managed AS ff WHERE ff.fid=fid) AS c
     WHERE uri LIKE 'public:%' AND fm.fid=c.of;

-- only user pictures are public
     
UPDATE file_managed  AS fm SET uri = c.new_uri FROM
( SELECT  'public://pictures/' || ff.filename  AS new_uri, ff.fid AS of
  FROM file_managed AS ff WHERE ff.filename LIKE 'picture%' AND ff.fid=fid ) AS c
  WHERE (fm.filename LIKE 'picture%' AND fm.fid=c.of );
-- UPDATE 26
  

-- Bring back missing file sizes:
-- The file sizes must be correct otherwise the display will be truncated.
-- The update mechanism will check file sizes and set all to 0 for files that cant be found.
-- Fortunately the d6 files table is maintained and still contains the data in question.

UPDATE file_managed fm SET filesize = fs FROM (SELECT f.filesize AS fs, f.fid AS of FROM files f LEFT JOIN file_managed fmm ON fmm.fid = f.fid) c WHERE fm.fid = c.of;

-- if the file name operations crash drop the unique constraint
ALTER TABLE file_managed
   DROP CONSTRAINT file_managed_uri_key;

ALTER TABLE file_managed
  ADD  CONSTRAINT file_managed_uri_key;

COMMIT;
