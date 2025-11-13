#!/bin/bash
# AVIR - Image Resizing to 4:3 Aspect Ratio
# Recursively resizes all images in a folder (SchoolLinks uses this to optimize game thumbnails for quicker load speeds)
# This script requires https://github.com/avaneev/avir linux binary to be in the same dir named "avir" in order to run


INPUT_DIR="${1:-.}"
OUTPUT_SUFFIX=""
ALGORITHM="ultra"
THREADS="1"
DITHER="-d"

calculate_4x3() {
    local width=$1
    local height=$2
    local target_ratio=1.333333  # 4/3
    
    current_ratio=$(echo "scale=6; $width / $height" | bc)
    
    if (( $(echo "$current_ratio > 1.32 && $current_ratio < 1.35" | bc -l) )); then
        echo "${width}x${height}"
        return
    fi
    
    if (( $(echo "$current_ratio > $target_ratio" | bc -l) )); then
        new_width=$(echo "scale=0; $height * $target_ratio / 1" | bc)
        echo "${new_width}x${height}"
    else
        new_height=$(echo "scale=0; $width / $target_ratio / 1" | bc)
        echo "${width}x${new_height}"
    fi
}

shopt -s nullglob
shopt -s nocaseglob

echo "Searching for images in: $INPUT_DIR"
echo "Algorithm: $ALGORITHM"
echo "Threads: $THREADS"
echo ""

count=0
processed=0

for ext in jpg jpeg png bmp tiff tif webp; do
    while IFS= read -r -d '' file; do
        ((count++))
        
        if command -v identify &> /dev/null; then
            dimensions=$(identify -format "%wx%h" "$file" 2>/dev/null)
            width=$(echo "$dimensions" | cut -d'x' -f1)
            height=$(echo "$dimensions" | cut -d'x' -f2)
            
            if [ -n "$width" ] && [ -n "$height" ]; then
                new_dimensions=$(calculate_4x3 "$width" "$height")
            else
                echo "Warning: Could not read dimensions for $file, using default 4:3"
                new_dimensions="1024x768"
            fi
        else
            new_dimensions="1024x768"
        fi
        
        output_file="$file"
        
        echo "Processing: $file"
        echo "  Dimensions: $new_dimensions"
        
        input_file="$file"
        temp_file=""
        file_ext="${file##*.}"
        file_ext_lower=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')
        
        needs_conversion=false
        
        if [[ "$file_ext_lower" == "webp" ]] || [[ "$file_ext_lower" == "bmp" ]] || [[ "$file_ext_lower" == "tiff" ]] || [[ "$file_ext_lower" == "tif" ]]; then
            needs_conversion=true
        fi
        
        if [[ "$file_ext_lower" == "jpg" ]] || [[ "$file_ext_lower" == "jpeg" ]]; then
            if ! ./avir "$file" /dev/null "$new_dimensions" $DITHER --algparams=$ALGORITHM -t $THREADS &>/dev/null; then
                echo "  ! JPEG has issues, re-encoding..."
                needs_conversion=true
            fi
        fi
        
        if [ "$needs_conversion" = true ]; then
            if command -v convert &> /dev/null; then
                if [[ "$file_ext_lower" == "jpg" ]] || [[ "$file_ext_lower" == "jpeg" ]]; then
                    temp_file=$(mktemp --suffix=.jpg)
                else
                    temp_file=$(mktemp --suffix=.png)
                fi
                echo "  Converting to temporary file..."
                if ! convert "$file" -quality 95 "$temp_file" 2>/dev/null; then
                    echo "  ✗ Failed to convert: $file"
                    rm -f "$temp_file"
                    echo ""
                    continue
                fi
                input_file="$temp_file"
            else
                echo "  ✗ ImageMagick 'convert' required for problematic files"
                echo ""
                continue
            fi
        fi
        
        if ./avir "$input_file" "$output_file" "$new_dimensions" $DITHER --algparams=$ALGORITHM -t $THREADS; then
            echo "  ✓ Resized: $output_file"
            ((processed++))
        else
            echo "  ✗ Failed: $file"
        fi
        
        [ -n "$temp_file" ] && rm -f "$temp_file"
        
        echo ""
        
    done < <(find "$INPUT_DIR" -type f -iname "*.${ext}" -print0)
done

echo "========================================"
echo "Complete: Processed $processed of $count images"
echo "========================================"