#!/bin/sh
set -eux

# some variables

DRUPALBASE=/home/licebase/d7
BASE=`pwd`
DBUSER=javier
### All modules to be enabled:

MODULELIST="acl, advanced_help, autocomplete_widgets, bundle_copy, cck, cck_table, ckeditor, content_access, ctools, custom_pagers, date, devel, elements, entity, entityreference, eu_cookie_compliance, eva, features, field_group, field_permissions, file_entity, fivestar, getid3, hierarchical_select, imageapi,
jquery_ui, jquery_update, libraries, lightbox2, link, mass_contact, matrix, mimedetect, node_reference_filter, 
nodereference_url, og, prepopulate, realname, references, rules, strongarm, tablefield, token, transliteration, tripal, 
tripal_analysis_blast, tripal_analysis_go, tripal_analysis_interpro, tripal_analysis_kegg, views, 
views_autocomplete_filters, views_bulk_operations,views_data_export, views_gallery, views_php, views_slideshow, votingapi"



cd $DRUPALBASE

drush --version

# Drush Version   :  6.7.0 

### http://tripal.info/tutorials/v2.0/upgrade



### Step 0:
### Preparation
# echo make a dbdump of the D6 site first


# In the Drupal7 test site:
#  -  Export all Views that were rebuilt into code to import them later
#  -  Make a backup of sites/default/settings.php
#  -  move the modules directory aside from sites/all/modules, but keep them as they
#     might be needed
#  -  make a backup of the test database for our reference

# Following (mostly) the update guide for Tripal until step 13:
# http://tripal.info/tutorials/v2.0/upgrade

# Step 1: Backup your current Drupal Site D6 (create DB dump)
# - database dump
# - copy data files
# - play back db dump into d7 database
# This has to be done manually

# SKIP Step 2: Export Custom View Integration 

# Step 3:  Reset PostgreSQL's search_path variable
#  /!\ Very IMPORTANT to have the search path set correctly, only public /!\


echo "ALTER USER $USER SET search_path TO public" | drush sqlc


# IMPORTANT: make sure Core Module "Database logging" is OFF!

# -APPLY DB patches before the migration
# fix contact table
drush sqlc < $BASE/dbpatches/contact.sql
### move misplaced tables from chado to publi
drush sqlc < $BASE/dbpatches/tripal_schema_chado_to_public.sql

# Step 4:  Upgrade Drupal 6 to Drupal 7
# Skip installing over old system 
# Instead we are working on the already installed copy
# If we ever need this we could 

# SKIP 10. No patches to be applied prior to migration.
# DON'T APPLY!!
# Also bytea patch should NOT be applied, check with patch needs to be applied.
# See: https://www.drupal.org/node/1031122

drush -y updb

# - Check for potential errors.

echo Check the layout, if broken layout
echo navigate to theme settings and simply press Save.

echo "To log in got to https://blowfly-test.cbu.uib.no/user"
echo "log out: https://blowfly-test.cbu.uib.no/user/logout"
echo "press RETURN when done"

read CONTINUE

# Step 13:

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

# Step 14: modified to get latest version of tripal

cd $DRUPALBASE/sites/all/modules
git clone https://github.com/tripal/tripal.git
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

# Step 17:
echo In the web interface: 
echo "Administration -> Tripal -> Views Integration -> click 'Delete All Integrations'"
echo press RETURN when done...
echo "To log in got to https://blowfly-test.cbu.uib.no/user"
echo "log out: https://blowfly-test.cbu.uib.no/user/logout"

read CONTINUE

# Successfully deleted all views integration.
# Successfully rebuilt default Tripal Views Integrations

### Change repo to latest development code if we used anything else before
# git checkout 7.x-2.x
# git pull

# Step 18: To access the Tripal features enable all other tripal modules:
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
cd $DRUPALBASE/sites/all/modules
patch -p1 < $BASE/patches/tripal_analysis_blast.patch
drush updb

drush -y en tripal_analysis_interpro
drush updb

drush -y en tripal_analysis_kegg
drush updb
drush -y en tripal_analysis_go
patch -p1 < $BASE/patches/tripal_analysis_go.patch

drush updb

## should one of the modules fail the update, try to use the code from the module backup instead

# Step 20:

drush -y pm-enable toolbar
drush -y pm-enable shortcut


# Step 22:
drush cc all

# Step 23: verify status report page

# Step 24:
# Review Tripal Permissions

# SKIP Step 25:
# This should be done at step 10 already.

# Apply bytea patch to core, needs to be applied for each core update
# don't use no-check-certificate, the certificate is valid
# questionable if this is OK
#cd [drupal dir]
#wget  https://drupal.org/files/drupal.pgsql-bytea.27.patch
#patch -p1 < drupal.pgsql-bytea.27.patch

# Step 26:
# This needs to be applied otherwise the views wont work
cd $DRUPALBASE/sites/all/modules/views
patch -p1 < ../tripal/tripal_views/views-sql-compliant-three-tier-naming-1971160-22.patch


# Step 27:
# Finally, the Views cache must be cleared.  This can be done simply by using the administrative menu to
drush cc views

# echo "go to 'Structure' -> 'Views'.  Loading this page is enough to refresh the Views cache"
# echo press ENTER when done...

# read CONTINUE

# Step 28:
# Re-enable your desired theme by  clicking the 'Appearance' link in the administrative menu and configuring appropriately.
#Should not be necessary as we are using Garland.

echo Done, Tripal migration. Starting CCK migration

#Continue with the rest:
# ===========================================================================================================
# Step 29:
#############################################
# Prepare Migrate CCK to Fields
# AGAIN: Database logging core module must be off!
drush -y en cck content_migrate
drush updb

drush -y dl autocomplete_widgets-7.x-1.x-dev
drush updb
drush en autocomplete_widgets

drush en -y matrix tablefield
drush updb




# check if field sex can be restored, check the data types,
# and edit functions.
# drush -y content-migrate-fields

# - Go to Structure/Migrate fields, and check for all modules not installed activated

# If you are getting "exception 'PDOException' with message 'SQLSTATE[42000]: Syntax error or access violato# on: 1064" errors while migrating fields with autocomplete_widgets, you should install version 7.x-1.x-dev
# of Autocomplete Widgets for Text and Number Fields module as 

# if we are still using widgets of type autocomplete_widgets_cvdata (should not, because we export a clean system, but....) we can still get a PDOException, Then:

  # UPDATE content_node_field_instance SET widget_type = 'autocomplete_widgets_flddata' WHERE widget_type LIKE '%cvdata';

#    The _cvdata widget was defined in a custom module, so we don't have it in d7 yet
#  IGNORE WARNINGS about missing widget type image and matrix and invalid field/widget combinations, will be fixed.


# Step 30:

#############################################
# Bring images back up

# remove old path information that could have been transfered into the uri:





#  - To bring back image thumbnails:
#  see:
#  https://www.drupal.org/node/1109312
#  Only thing that worked so far:
#  Add this line to sites/default/settings.php
#  # Done
#  #  $conf['image_allow_insecure_derivatives'] = TRUE;

  
#Step 31:
#############################################
# Activate all remaining modules and run updb
# one/by/one
#use the full module list
# restore the jquery update file
cp -r $HOME/upgrade/modules/jquery_update $DRUPALBASE/sites/all/modules
cp -r $HOME/upgrade/modules/jquery_ui $DRUPALBASE/sites/all/modules

drush -y en jquery_update
drush -y en jquery_ui
cd $DRUPALBASE/sites/all/modules
drush -y pm-download date
patch -p1 < $BASE/patches/date.patch
drush updb
drush -y en date
drush en -y date_views, date_migrate_example, date_migrate, date_popup, date_tools, date_context, date_repeat, date_repeat_field, date_all_day, date_api



drush en $MODULELIST


# check if field sex can be restored, check the data types,
# and edit functions.
drush -y content-migrate-fields



# - Go to Structure/Migrate fields, and check for all modules not installed activated

# If you are getting "exception 'PDOException' with message 'SQLSTATE[42000]: Syntax error or access violato# on: 1064" errors while migrating fields with autocomplete_widgets, you should install version 7.x-1.x-dev
# of Autocomplete Widgets for Text and Number Fields module as 

# if we are still using widgets of type autocomplete_widgets_cvdata (should not, because we export a clean system, but....) we can still get a PDOException, Then:

  # UPDATE content_node_field_instance SET widget_type = 'autocomplete_widgets_flddata' WHERE widget_type LIKE '%cvdata';

#    The _cvdata widget was defined in a custom module, so we don't have it in d7 yet
#  IGNORE WARNINGS about missing widget type image and matrix and invalid field/widget combinations, will be fixed.


# Step 30:

#############################################
# Bring images back up

# remove old path information that could have been transfered into the uri:

drush sqlc $BASE/dbpatches/restore_files.sql



#  - To bring back image thumbnails:
#  see:
#  https://www.drupal.org/node/1109312
#  Only thing that worked so far:
#  Add this line to sites/default/settings.php
#  # Done
#  #  $conf['image_allow_insecure_derivatives'] = TRUE;

  
#Step 31:
#############################################
# Activate all remaining modules and run updb
# one/by/one
#use the full module list
# restore the jquery update file


# Now enable all other modules:





#shortcut: use the back-up module directory


## rebuild access permissions

  drush eval 'node_access_rebuild();'
 
  ##############################################

#Step 32:
#  Restore all Views (from manual exports generated)

# Step 33:  
##############################################
# Repair menu entries under node/add
# http://drupal.stackexchange.com/a/190379/25238
# -- in SQL
echo "DELETE FROM menu_links WHERE menu = 'system'; DELETE FROM menu_router;" | drush sqlc  

  drush updb
  drush cc menu
  drush eval 'menu_rebuild();'
  drush cc menu

 

 #######################################################################################
echo Update COMPLETED;
  
# - admin/config/people/realname
# Set Realname pattern to [user:profile-full-name]



