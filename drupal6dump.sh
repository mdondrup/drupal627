#!/bin/sh
set -eux

# usage: drupal6dump.sh dumpfile.sql

drush --version
# Drush Version   :  6.7.0 

### http://tripal.info/tutorials/v2.0/upgrade

#Step 0:
### Preparation
#In Drupal 6: 
## --- Change type of field_sex from option_widgets select to simple text

## --- Change type of _dev_stage fields in datatypes RNAi and In-situ are set to
## autocomplete from existing field data
# Run this on Drupal6 site
# Set Drupal 6 site into maintenance mode
# Temprarily disable all enabled modules
MYMODS=`drush pm-list --no-core --type=module --status=enabled --pipe`
drush -y pm-disable $MYMODS
drush vset site_offline 1
drush sql-dump --result-file=$1
drush -y pm-enable $MYMODS
drush vset site_offline 0
# make a SQL dump of the Drupal 6 site

echo Sql dump with deactivated modules created in $1
