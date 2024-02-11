import os
import sys
import subprocess
import xml.etree.ElementTree as ET

#Check input
if len(sys.argv) != 3:
    raise Exception("Please provide arguments in the form: [ORIGINAL_FILE_PATH] [MUTANT_DIR_PATH]")

#Parse input, first argument unmodified file, second argument path to directory of mutants
original = sys.argv[1]
mutants_path = sys.argv[2]
m = os.listdir(mutants_path)

#Keep track of edit actions 
n_edits = 0
max_edits = 0

#Loop though all files in mutant directory and compare to original
for f in m:

    #Run Gumtree textdiff on original and mutant
    args = " textdiff -f XML " + original + " " + mutants_path + f + "/" + os.listdir(mutants_path + f)[0]
    print(args)
    diff = subprocess.check_output('gumtree' +  args, shell=True).decode()
    
    #wrap result to get single XML root and convert to tree
    diff = diff.split('\n', 1)
    diff = diff[0] + "<X>" + diff[1] + "</X>"
    tree = ET.fromstring(diff)

    #Get number of edit actions from tree and add to res
    n = len(tree.findall('actions')[0])
    n_edits += n
    if n > max_edits:
        max_edits = n

n_mutants = len(m)

print("============== RESULTS ==============")
print("Number of mutants examined: " + str(n_mutants))
print("Max edit script length: " + str(max_edits))
print("Total number of edit actions: " + str(n_edits))
print("Average edit script length: " + str(n_edits/n_mutants))
print("=====================================")