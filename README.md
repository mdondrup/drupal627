# drupal627
A little script to do the -almost- whole Drupal 6 to 7 of a Tripal site  in a single shell script
using drush.
 - Psql 8.4, including some patches
 - The Drupal >7.42 environment needs to be install

The script runs:
 - Applies patches to the DB prior to update
 - Applies patches to Tripal and other modules
 - Drupal core update
 - Views updates
 - CCK to Fields migration updates
 - fixes images
 - installs modules
 - applies DB fixes to restore images 
