#!/bin/bash

# Check if the patch file is provided as an argument
if [ $# -ne 1 ]; then
    echo "ERROR: Please provide the patch file as an argument."
    exit 1
fi

# Check if the composer.json file exists in the current directory
if [ ! -f "composer.json" ]; then
    echo "ERROR: Please run this from the root of your Magento project."
    exit 1
fi

# Check if the composer.json file contains "magento-cloud"
if grep -q "magento-cloud" "composer.json"; then
    echo "I see you are running a Magento Cloud website. Just put your patch inside the directory m2-hotfixes and it should work when you deploy to cloud."
    exit 0
fi

# Initialize arrays to store the keys and values
declare -a keys
declare -a values

# Read the patch file and split it into chunks
while IFS= read -r line; do
    if [[ $line =~ ^diff\ --git\ a/(.*)\ b/.* ]]; then
        # Get the file path from the diff command
        file_path=${BASH_REMATCH[1]}

        # Find the composer.json file in the directory or its parents
        for ((i=0; i<6; i++)); do
            if [ -f "$file_path/composer.json" ]; then
                break
            fi
            file_path=$(dirname "$file_path")
        done

        # Check if the composer.json file was found
        if [ ! -f "$file_path/composer.json" ]; then
            echo "ERROR: I couldn't find the module of the file $file_path"
            exit 1
        fi

        # Read the composer.json file and extract the module name
        module_name=$(grep -o '"name": "[^"]*"' "$file_path/composer.json" | cut -d'"' -f4)

        # Check if the module name was found
        if [ -z "$module_name" ]; then
            echo "ERROR: I couldn't find the module of the file $file_path"
            exit 1
        fi

        # Print the module name and add the chunk to the array
        # echo "-- This chunk is for the module: $module_name"

        # Check if the module name already exists in the keys array
        found=0
        for ((i=0; i<${#keys[@]}; i++)); do
            if [ "${keys[$i]}" == "$module_name" ]; then
                values[$i]+="$line"$'\n'
                found=1
                break
            fi
        done

        # If the module name does not exist, add it to the keys and values arrays
        if [ $found -eq 0 ]; then
            keys+=("$module_name")
            values+=("$line"$'\n')
        fi
    else
        # Add the line to the last module's chunk
        if [ ${#values[@]} -gt 0 ]; then
            values[${#values[@]}-1]+="$line"$'\n'
        fi
    fi
done < "$1"

# Check how many different indexes are in the array
num_indexes=${#keys[@]}

# If there is only one index, print the message and exit
if [ $num_indexes -eq 1 ]; then
    echo "This .patch just works with one Module, it is: ${keys[0]}"
    exit 0
fi

# Check if one of the directories exists
if [ -d ".composer_patches" ]; then
    patch_dir=".composer_patches"
elif [ -d "composer_patches" ]; then
    patch_dir="composer_patches"
elif [ -d "patches" ]; then
    patch_dir="patches"
else
    patch_dir=".composer_patches"
    mkdir "$patch_dir"
    echo "--- creating the folder $patch_dir"
fi

# Create a file for each index and write the corresponding chunks
for ((i=0; i<num_indexes; i++)); do
    filename="${1%.*}-$((i+1)).${1##*.}"
    echo "${values[$i]}" > "$patch_dir/$filename"
    echo "I just created the file $patch_dir/$filename that is for the module ${keys[$i]}"
done

echo -e "\n------------------------------------"
echo -e "Inside your composer patch config file, use something like this:"
echo -e " (if the module already exist in that JSON add inside it, or create a new one) \b ";
echo -e "------------------------------------ \n"


for ((i=0; i<num_indexes; i++)); do
    filename="${1%.*}-$((i+1)).${1##*.}"
    echo "  \"${keys[$i]}\": {"
    echo "    \"Split number $((i+1)) of the $1\": \"$patch_dir/$filename\""
    echo "  },"
done

echo -e "\n"


