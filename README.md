# Patch Splitter for Magento 2

This script splits a patch file into multiple patch files based on the modules that the patch is changing. It detects the module that is being changed and creates a different patch file for each module. The script also helps the user to configure PHP Composer to use the new patch that works with Composer.

## Usage

1. Run the script from the root of your Magento project.
2. Provide the patch file as an argument, e.g. `./script.sh your_patch_file.patch`.
3. The script will create a new directory called `.composer_patches` (or `composer_patches` or `patches` if one of these directories already exists) and split the patch file into multiple files, each corresponding to a different module.
4. The script will also output a JSON object that can be used to configure PHP Composer to use the new patch files.

## Requirements

* The script must be run from the root of a Magento project.
* The `composer.json` file must exist in the current directory.

## Notes

* If the patch file only affects one module, the script will output a message indicating that the patch file only works with one module and exit.
* If the `composer.json` file contains the string "magento-cloud", the script will output a message indicating that the patch file should be placed in the `m2-hotfixes` directory and exit.
