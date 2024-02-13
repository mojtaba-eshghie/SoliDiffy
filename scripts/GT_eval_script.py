#Run gumtree to get data on diffs, split into contract and number of mutations.
#Store results in format that can be accessed later for analysis and figures. 

#Json/XML? Python 2d matrix of lists to file? 


# -----------Gumtree Results----------------
# Contracts |      Diff Results/# Mutations
# ------------------------------------------
# Contract1 | 1 mutation, 2 mutations, ...
# Contract2 | ...
# ...
# Contractn | ...
# ------------------------------------------
#

import sys
import os
import xml.etree.ElementTree as ET
import subprocess
import pickle

logging = True

def parse_input():
    if len(sys.argv) != 3:
        raise Exception("Please provide arguments in the form: path to contracts, output path!")
    
    contracts_path = sys.argv[1]
    output_path = sys.argv[2]
    return contracts_path, output_path

#Uses gumtree to get the diff data of two files
def get_GT_diff_data(filepath1, filepath2):
    diff = subprocess.check_output('gumtree textdiff -f XML ' +  filepath1 + " " + filepath2, shell=True).decode()
    
    #wrap result to get single XML root and convert to tree
    diff = diff.split('\n', 1)
    diff = diff[0] + "<X>" + diff[1] + "</X>"
    tree = ET.fromstring(diff)

    #Get number of edit actions and matches from tree
    n_edits = len(tree.findall('actions')[0])
    n_matches = len(tree.findall('matches')[0])
    return (n_edits, n_matches)

#Gets the GT diffs between all mutants of a contract in a directory
def get_contract_diffs(contract_path, contract):
    res = [contract]
    unmutated = contract_path + "/" + "original/" + contract + ".sol"
    num_contracts = len(os.listdir(contract_path))

    for i in range(1, num_contracts):
        if(logging):
            print('Calculating diff ' + str(i) + '/' + str(num_contracts - 1), end='\r')

        diff = get_GT_diff_data(unmutated, contract_path + "/" + str(i) + "/" + contract + ".sol")
        res.append(diff)

    return res
        
#Returns complete 2d matrix containing diff data for all mutants
def calculate_diffs(contracts_path):
    contracts = os.listdir(contracts_path)
    res = []

    for c in contracts:
        if(logging):
            print("Calculating diffs for " + c + "...")

        res.append(get_contract_diffs(contracts_path + c, c))

        if(logging): 
            print("===========================")
    return res

#Saves results as a python object in a results file
def save_res_to_file():
    print("dummy")

if __name__ == "__main__":
    contracts_path, output_path = parse_input()
    res = calculate_diffs(contracts_path)

    print(res)
    out = output_path + "results.pickle"
    print("Dumping results to " + out)
    
    
    out_file = open(out, "wb")
    pickle.dump(res, out_file)

    