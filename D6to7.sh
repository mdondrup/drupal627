#!/bin/sh
set -eux

DRUPALBASE=/

# Drush Version   :  6.7.0 

### http://tripal.info/tutorials/v2.0/upgrade



Step 0:
### Preparation

In the Drupal7 test site:
 -  Export all Views that were rebuilt into code to import them later
 -  Make a backup of sites/default/settings.php
 -  move the modules directory aside from sites/all/modules, but keep them as they
    might be needed
 -  make a backup of the test database for our reference

# Following (mostly) the update guide for Tripal until step 13:
# http://tripal.info/tutorials/v2.0/upgrade

Step 1: Backup your current Drupal Site D6 (create DB dump)
- database dump
- copy data files
- play back db dump into d7 database


# SKIP Step 2: Export Custom View Integration 

Step 3:  Reset PostgreSQL's search_path variable
 /!\ Very IMPORTANT to have the search path set correctly, only public /!\
#'

ALTER USER  SET search_path TO public;


IMPORTANT: make sure Core Module "Database logging" is OFF!

- APPLY DB patches before the migration

psql -U javier -d d7 -h trekantspinner.cbu.uib.no -f ~/db_patches/contact.sql
### move misplaced tables from chado to public
psql -U javier -d d7 -h trekantspinner.cbu.uib.no -f ~/db_patches/tripal_schema_chado_to_public.sql


Step 4:  Upgrade Drupal 6 to Drupal 7
 Skip installing over old system 
 Instead we are working on the already installed copy

## place site in Maintenance mode # already done 
#drush vset site_offline 1

## default theme already set
# drush vset theme_default garland

## drush pm-update already run

Skip Step 6,7,8,9  of the tripal update manual

 SKIP 10. No patches to be applied prior to migration.

 # possibly patches already applied
Make sure Drupal core is vanilla and clean of any patch.
  

# - But check if patch says 'alredy applied':

 [DON'T APPLY!!]
# cd [drupal dir]
# wget  http://tripal.info/sites/default/files/book_pages/taxonomy_install.patch
# patch -p1 <  taxonomy_install.patch

DON'T APPLY!!
# Also bytea patch should be applied, check with patch needs to be applied.
 # See: https://www.drupal.org/node/1031122

# wget https://www.drupal.org/files/issues/1031122-2.122.patch
# patch -p1 <  1031122-2.122.patch
 
SKIP Step 11

# keep the already adapted settings.php

Step 12:

# Run db update, but via Drush

drush updb

 - Check for potential errors.

Check the layout, if broken layout
> navigate to theme settings and simply press Save.

To log in got to https://blowfly-test.cbu.uib.no/user
To log out: https://blowfly-test.cbu.uib.no/user/logout

 Step 13:

 drush -y pm-download views ctools
drush updatedb
# SQLSTATE[42703]: Undefined column: 7 ERROR:  column "weight" of relation "contact" does not     [error]
# exist
# This indicates: wrong search path: must be public ONLY!
### Beware there are tables name contact in both public and chado!

drush -y pm-enable ctools views views_ui
drush updb

### 
# all OK SNAPSHOT take named: step13

Step 14: modified to get latest version of tripal

cd sites/all/modules
git clone https://github.com/tripal/tripal.git # -b 7.x-2.1-beta2
# warning: Remote branch 7.x-2.1-beta2 not found in upstream origin, using HEAD instead
cd tripal/
### 7.x-2.1-beta2 is a tag
# git checkout 7.x-2.1-beta2
### Now head should work for the whole migration as well if not try beta2
git checkout 7.x-2.x

### Step 15: 
drush updatedb
## all ok???

### Step 16:

drush -y pm-enable tripal_core
## all ok
drush -y pm-enable tripal_views
drush updb
# Warnings: many times
# [site https://...] [TRIPAL NOTICE] [TRIPAL_VIEWS] DEPRECATED: Currently using tripal_views_handlers to store relationship for studyprop_feature => feature when you should be using tripal_views_joins.

Step 17: Administration -> Tripal -> Views Integration -> click 'Delete All Integrations'
# Successfully deleted all views integration.
# Successfully rebuilt default Tripal Views Integrations

### Change repo to latest development code if we used anything else before
# git checkout 7.x-2.x
# git pull

Step 18: To access the Tripal features enable all other tripal modules:
drush -y pm-enable tripal_db tripal_cv
drush updb
drush -y pm-enable tripal_organism
drush updb
drush -y pm-enable tripal_feature tripal_analysis tripal_stock tripal_contact
drush updb
drush -y pm-enable tripal_library tripal_project tripal_bulk_loader
drush updb
drush -y pm-enable tripal_pub tripal_featuremap tripal_phenotype
drush updb
# drush pm-enable tripal_genetic tripal_natural_diversity
## All OK
## Features should visible and searchable

drush -y en tripal_analysis_blast
drush updb
drush -y en tripal_analysis_interpro
drush updb
drush -y en tripal_analysis_kegg
drush updb
drush -y en tripal_analysis_go
drush updb

## should one of the modules fail the update, try to use the code from the module backup instead

Step 20:

drush pm-enable toolbar
drush pm-enable shortcut

Step 21: 
# We have never set this to TRUE!
# Ensure that $update_free_access is FALSE


Step 22:
drush cc all

Step 23: verify status report page

Step 24:
Review Tripal Permissions

SKIP Step 25:
This should be done at step 10 already.

# Apply bytea patch to core, needs to be applied for each core update
# don't use no-check-certificate, the certificate is valid
# questionable if this is OK
#cd [drupal dir]
#wget  https://drupal.org/files/drupal.pgsql-bytea.27.patch
#patch -p1 < drupal.pgsql-bytea.27.patch

Step 26:

cd [drupal dir]/sites/all/modules/views
patch -p1 < ../tripal/tripal_views/views-sql-compliant-three-tier-naming-1971160-22.patch


Step 27:
Finally, the Views cache must be cleared.  This can be done simply by using the administrative menu to go to 'Structure' -> 'Views'.  Loading this page is enough to refresh the Views cache

Step 28:
Re-enable your desired theme by  clicking the 'Appearance' link in the administrative menu and configuring appropriately.
Should not be necessary as we are using Garland.

Done, Tripal migration.

Continue with the rest:
===========================================================================================================
Step 29:
#############################################
# Migrate CCK to Fields
# AGAIN: Database logging core module must be off!
drush -y en cck content_migrate
drush updb

# check if field sex can be restored, check the data types,
# and edit functions.

 - Go to Structure/Migrate fields, and check for all modules not installed activated

# If you are getting "exception 'PDOException' with message 'SQLSTATE[42000]: Syntax error or access violato# on: 1064" errors while migrating fields with autocomplete_widgets, you should install version 7.x-1.x-dev
# of Autocomplete Widgets for Text and Number Fields module as 

# if we are still using widgets of type autocomplete_widgets_cvdata (should not, because we export a clean system, but....) we can still get a PDOException, Then:

  # UPDATE content_node_field_instance SET widget_type = 'autocomplete_widgets_flddata' WHERE widget_type LIKE '%cvdata';

#    The _cvdata widget was defined in a custom module, so we don't have it in d7 yet
 IGNORE WARNINGS about missing widget type image and matrix and invalid field/widget combinations, will be fixed.


Step 30:

#############################################
# Bring images back up

# remove old path information that could have been transfered into the uri:



  UPDATE file_managed_test  AS fm set uri = c.new_uri FROM (
    SELECT regexp_replace(uri, '/export/storage/licebase/web-production/files/', '') new_uri, ff.fid AS of
    FROM file_managed_test AS ff WHERE ff.fid=fid) AS c
     WHERE uri LIKE '%export/storage/licebase/web-production/files%' AND fm.fid=c.of;
-- 25

  
UPDATE file_managed_test  AS fm set uri = c.new_uri FROM (
    SELECT regexp_replace(uri, 'sites/default/files/', '') new_uri, ff.fid AS of
    FROM file_managed_test AS ff WHERE ff.fid=fid) AS c
     WHERE uri LIKE '%sites/default/files%' AND fm.fid=c.of;
-- 155

-- Make everything else private:
UPDATE file_managed_test  AS fm set uri = c.new_uri FROM
( SELECT  'private://' || ff.uri  AS new_uri, ff.fid AS of
  FROM file_managed_test AS ff
  WHERE ff.uri NOT LIKE 'private:%' AND ff.uri NOT LIKE 'public:%' AND ff.fid=fid ) AS c
  WHERE (fm.uri NOT LIKE 'private:%' AND fm.uri NOT LIKE 'public:%' AND fm.fid=c.of );

UPDATE file_managed_test  AS fm set uri = c.new_uri FROM (
    SELECT regexp_replace(uri, 'public:', 'private:') new_uri, ff.fid AS of
    FROM file_managed_test AS ff WHERE ff.fid=fid) AS c
     WHERE uri LIKE 'public:%' AND fm.fid=c.of;

-- only user pictures are public
     
UPDATE file_managed_test  AS fm SET uri = c.new_uri FROM
( SELECT  'public://pictures/' || ff.filename  AS new_uri, ff.fid AS of
  FROM file_managed_test AS ff WHERE ff.filename LIKE 'picture%' AND ff.fid=fid ) AS c
  WHERE (fm.filename LIKE 'picture%' AND fm.fid=c.of );
-- UPDATE 26
  

-- Bring back missing file sizes:
-- The file sizes must be correct otherwise the display will be truncated.
-- The update mechanism will check file sizes and set all to 0 for files that cant be found.
-- Fortunately the d6 files table is maintained and still contains the data in question.

UPDATE file_managed_test fm SET filesize = fs FROM (SELECT f.filesize AS fs, f.fid AS of FROM files f LEFT JOIN file_managed fmm ON fmm.fid = f.fid) c WHERE fm.fid = c.of;

-- if the file name operations crash drop the unique constraint
ALTER TABLE file_managed
   DROP CONSTRAINT file_managed_uri_key;

ALTER TABLE file_managed
  ADD  CONSTRAINT file_managed_uri_key;


 - To bring back image thumbnails:
  see:
  https://www.drupal.org/node/1109312
  Only thing that worked so far:
  Add this line to sites/default/settings.php
  # Done
  #  $conf['image_allow_insecure_derivatives'] = TRUE;

  
Step 31:
#############################################
# Activate all remaining modules and run updb
# one/by/one
use the full module list

shortcut: use the back-up module directory


## rebuild access permissions

  drush eval 'node_access_rebuild();'
 
  ##############################################

Step 32:
  Restore all Views (from manual exports generated)

Step 33:  
##############################################
# Repair menu entries under node/add
# http://drupal.stackexchange.com/a/190379/25238
-- in SQL
DELETE FROM menu_links WHERE menu = 'system';
 # If that doesn't work, delete everything
  DELETE FROM menu_router;

  
  drush updb
  drush cc menu
  drush eval 'menu_rebuild();'
  drush cc menu

 - Rebuild Menues, if they got lost
 - addsite search to menu (add missing search block)

 
 Step 34:
 - Check Roles and Permissions, are they correctly transferred and set?

 Step 35:
 - Check for any deviations by direct comparison

 Step 36:
 - Check crontab and update it if necessary
 crontab -e

 #######################################################################################
 - Blocks: reorder menus and content blocks



 - admin/config/people/realname
 Set Realname pattern to [user:profile-full-name]

Enable contextual links module

 

 AFTER FINAL DEPLOYMENT:
 Use crontab, turn off Drupal's poor man's cron:

 admin/config/system/cron
 

 
 ================================================================================= 

  Expected Functional Degradation (Missing functions, issues, bugs) after update

  - field_sex in RNAi not working, will be re/activated later, if possible
  - not all views ready, only main RNAi without Target search, in-situ (missing 3)
  - some (?) users cannot be referenced in content creation, maybe no new RNAi, in-situ content until fixed
  - Autocomplete for Dev stages does not use the Ontology, but will use existing values
  - Ajax errrors when trying to change data types
  - During the (fields) migration process we got warnings that some views would need "reference" added  
  - When editing RNAi and In-situ data type notes, node body/Description* field is always empty, even thoug h, nodes have the description field.

  Tripal
  - Tripal Features not found by standard search (reindex site only?)
  - Fasta export in Feature search doesn't work (bulk exporter module needs a view to function)
  - Resource links to Ensembl, Blast, and GBrowse missing in the Tripal Feature overview (rebuild TOC?)
  - No GO Browser
  
