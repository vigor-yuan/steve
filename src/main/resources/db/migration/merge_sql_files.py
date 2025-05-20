#!/usr/bin/env python3
import os
import re

def natural_sort_key(s):
    """
    Sort strings with embedded numbers in natural order.
    This ensures SQL files are processed in the correct version order.
    """
    return [int(text) if text.isdigit() else text.lower() for text in re.split(r'(\d+)', s)]

def merge_sql_files(directory, output_file):
    """
    Merge all SQL files in the given directory into a single SQL file.
    Files are sorted by their version numbers to maintain the correct order.
    """
    # Get all SQL files in the directory
    sql_files = [f for f in os.listdir(directory) if f.endswith('.sql') and f != output_file]
    
    # Sort files by version number
    sql_files.sort(key=natural_sort_key)
    
    print(f"Found {len(sql_files)} SQL files to merge")
    
    # Open the output file for writing
    with open(os.path.join(directory, output_file), 'w', encoding='utf-8') as outfile:
        outfile.write("-- Combined SQL migration file\n")
        outfile.write("-- Generated automatically by merge_sql_files.py\n")
        outfile.write("-- Contains all migrations from the SteVe project\n\n")
        
        # Process each SQL file
        for i, sql_file in enumerate(sql_files):
            print(f"Processing {sql_file}...")
            
            # Add a separator and file information
            outfile.write(f"\n-- ============================================================\n")
            outfile.write(f"-- Migration: {sql_file}\n")
            outfile.write(f"-- ============================================================\n\n")
            
            # Read and write the content of the SQL file
            with open(os.path.join(directory, sql_file), 'r', encoding='utf-8') as infile:
                content = infile.read()
                outfile.write(content)
                
                # Add a newline if the file doesn't end with one
                if content and not content.endswith('\n'):
                    outfile.write('\n')
    
    print(f"Successfully merged {len(sql_files)} SQL files into {output_file}")

if __name__ == "__main__":
    # Directory containing the SQL files
    directory = os.path.dirname(os.path.abspath(__file__))
    
    # Output file name
    output_file = "combined_migrations.sql"
    
    merge_sql_files(directory, output_file)
