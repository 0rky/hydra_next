#############################
# Author: Manas Jyoti Das
# Description: Script to remove auto generated code from create hydra cluster notebook
#############################

import nbformat
import re
import argparse
import os

def check_extension(filename):
    if not filename.endswith(".ipynb"):
        raise argparse.ArgumentTypeError(f"Input file must be a .ipynb file: {filename}")
    return filename

parser= argparse.ArgumentParser()
parser.add_argument(help="Enter a path to the notebook, the output will be in the same directory as the input file with suffix _clean",dest="notepad_path",type=check_extension)

args=parser.parse_args()
path=args.notepad_path

nb = nbformat.read(path,nbformat.NO_CONVERT)

index = []
for i,c in enumerate(nb.cells):
    cell_source = c.source
    if cell_source.startswith("#Auto_Generated"):
        index.append(i)

print("index:",index)
if len(index) > 0:
    for i,idx in enumerate(index):
        nb.cells.pop(idx-i)

filename=os.path.basename(path)
dot_index = filename.find(".")
if dot_index == -1:
    print ("there is no extension in the file name")
else:
    file = filename[:dot_index]+"_clean" 
    extension = filename[dot_index :]
    out_file = file+extension

    
path_parts = path.rsplit("/", 1)  
if len(path_parts) == 1:
    stripped_path=""
else:
    stripped_path=path_parts[0]+"/"

output_path=stripped_path+out_file

nbformat.write(nb,output_path)