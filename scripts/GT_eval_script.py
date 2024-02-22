#Runs gumtree to get data on diffs, puts result in 2d matrix with axes contract and number of mutations.
#Stores results in pickle file. 

# -----------Gumtree Results----------------
# Contracts |      Diff Results/# Mutations
# ------------------------------------------
# Contract1 | 1 mutation, 2 mutations, ...
# Contract2 | 1 mutation, ...
# ...
# Contractn | ...
# ------------------------------------------
#

import sys
import os
import xml.etree.ElementTree as ET
import subprocess
import pickle
import time


def parse_input():
    if len(sys.argv) != 3:
        raise Exception("Please provide arguments in the form: path to contracts, output path!")
    
    contracts_path = sys.argv[1]
    output_path = sys.argv[2]
    return contracts_path, output_path

#Uses gumtree to get the diff data of two files
def get_GT_diff_data(filepath1, filepath2):
    save_full_diff = True

    diff = subprocess.check_output('gumtree textdiff -f XML ' +  filepath1 + " " + filepath2, shell=True).decode()
    
    #wrap result to get single XML root and convert to tree
    diff = diff.split('\n', 1)
    diff = diff[0] + "<X>" + diff[1] + "</X>"
    tree = ET.fromstring(diff)

    #Get number of edit actions and matches from tree
    n_edits = len(tree.findall('actions')[0])
    n_matches = len(tree.findall('matches')[0])
    
    #Append full diff to res if flag is set and return res
    res = [n_edits, n_matches]
    if save_full_diff:
        res.append(diff)
    return res

#Gets the GT diffs between all mutants of a contract in a directory
def get_contract_diffs(contract_path, contract):
    res = [contract]
    unmutated = contract_path + "/" + "original/" + contract + ".sol"
    num_contracts = len(os.listdir(contract_path))

    for i in range(1, num_contracts):    
        print('Calculating diff ' + str(i) + '/' + str(num_contracts - 1), end='\r')

        diff = get_GT_diff_data(unmutated, contract_path + "/" + str(i) + "/" + contract + ".sol")
        res.append(diff)

    return res
        
#Returns complete 2d matrix containing diff data for all mutants
def calculate_diffs(contracts_path):
    contracts = os.listdir(contracts_path)
    res = []
    for c in contracts:
        seconds = int(time.time())
        print("Calculating diffs for " + c + "...")

        res.append(get_contract_diffs(contracts_path + c, c))

        m, s = divmod(int(time.time()) -  seconds, 60)
        print("Diffs calculated in: " + str(m) + ":" + str(s))
        print("======================================")

    return res

#Saves results as a python object in a results file
def save_res_to_file(results):
    out = output_path + "results.pickle"
    print("\nDumping results to " + out)
    out_file = open(out, "wb")
    pickle.dump(res, out_file)

if __name__ == "__main__":
    seconds = int(time.time())
    
    contracts_path, output_path = parse_input()
    res = calculate_diffs(contracts_path)
    save_res_to_file(res)
    
    m, s = divmod(int(time.time()) -  seconds, 60)
    print("Generated " + str(len(res)*(len(res[0]) - 1)) + " diffs in " + str(m) + "m:" + str(s) + "s")
    