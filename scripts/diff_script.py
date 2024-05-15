# Runs gumtree to get data on diffs, puts result in 2d matrix with axes contract and number of mutations.
# Stores results in pickle file. 

# -----------Gumtree Results----------------
# Contracts |      Diff Results/# Mutations
# ------------------------------------------
# Contract1 | 1 mutation, 2 mutations, ...
# Contract2 | 1 mutation, ...
# ...
# Contractn | ...
# ------------------------------------------

import sys
import os
import xml.etree.ElementTree as ET
import subprocess
import pickle
import json
import time
import concurrent.futures as cc


def parse_input():
    if len(sys.argv) != 3:
        raise Exception("Please provide arguments in the form: [PATH TO MUTANTS], [DIFFING TOOL] (GT/difft)!")
    
    contracts_path = sys.argv[1]
    diff_tool = sys.argv[2]

    if diff_tool != "difft" and diff_tool != "GT":
        raise Exception("Error: invalid diff tool provided!")

    return contracts_path, diff_tool

#Uses gumtree to get the diff between two files
def get_GT_diff_data(filepath1, filepath2):
    save_full_diff = False

    diff = subprocess.check_output('gumtree textdiff -f XML ' +  filepath1 + " " + filepath2, shell=True).decode()
    if not diff:
        print("mutant causing error:" + filepath2)
        return -1
    
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

#Uses difftastic to get the diff between two files
def get_diffts_data(filepath1, filepath2):
    os.environ['DFT_UNSTABLE'] = 'yes'
    diff = subprocess.check_output('difft --display json ' +  filepath1 + " " + filepath2, shell=True).decode()
    if not diff:
        return -1 
    
    diff = json.loads(diff)
    if diff["status"] == "unchanged":
        print("WARNING: difft failed to detect change in contract " + filepath2 + "!!!")
        return 0
    
    #Have to keep track of the left hand and right hand side changes, so that no changes are double counted. Can probably by done in a much better way. 
    count = 0
    for li in diff["chunks"]:
        for line in li:
            used_changes = {}
             
            if "lhs" in line.keys():
                for ch in line["lhs"]["changes"]:
                    counted = False
                    for i in range(ch["start"], ch["end"]):
                        if str(i) in used_changes.keys():
                            counted = True

                    if not counted:
                        for i in range(ch["start"], ch["end"]):
                            used_changes[str(i)] = 1
                        count += 1
            
            if "rhs" in line.keys():
                for ch in line["rhs"]["changes"]:
                    counted = False
                    for i in range(ch["start"], ch["end"]):
                        if str(i) in used_changes.keys():
                            counted = True

                    if not counted:
                        for i in range(ch["start"], ch["end"]):
                            used_changes[str(i)] = 1
                        count += 1
    return count
    
#Gets the diffs between all mutants of a contract in a directory
def get_contract_diffs(contract_path, contract, result, diff_tool):
    res = []
    unmutated_path = contract_path + "/" + "original/" + contract + ".sol"
    num_contracts = len(os.listdir(contract_path))
    for i in range(1, num_contracts):
        operators = os.listdir(contract_path + "/" + str(i))
        diffs = {}
        for op in operators:
            mutated_path = contract_path + "/" + str(i) + "/" + op + "/" + contract + ".sol"
            if diff_tool == "GT":
                diff = get_GT_diff_data(unmutated_path, mutated_path)
                if diff == -1:
                    diff = []
            elif diff_tool == "difft":
                diff = get_diffts_data(unmutated_path, mutated_path)
                if diff == -1:
                    diff = 0
            else:
                raise Exception("Error: invalid diff tool!")
            diffs[op] = diff
        res.append(diffs)
    result[contract] = res
       
#Returns complete 2d matrix containing diff data for all mutants. Calculates each contract's diff concurrently.
def calculate_diffs(contracts_path, diff_tool):
    contracts = os.listdir(contracts_path)
    res = {}
    executor = cc.ThreadPoolExecutor(max_workers = os.cpu_count())
    futures = []

    for c in contracts:
        futures.append(executor.submit(get_contract_diffs, contracts_path+c, c, res, diff_tool))

    while len(futures) > 0:
        time.sleep(1)
        for i in range(len(futures)-1, -1, -1):
            if(futures[i].done()):
                future = futures.pop(i)

        print('Contracts done: ' + str(len(contracts) - len(futures)) + '/' + str(len(contracts)), end=('\r'))
    return res

#Saves results as a python object in a pickle file
def save_res_to_file(results, diff_tool):
    out = "./results/results" + "-" + diff_tool +  ".pickle"
    print("\nDumping results to " + out)
    out_file = open(out, "wb")
    pickle.dump(results, out_file)


if __name__ ==  '__main__':
    seconds = int(time.time())

    contracts_path, diff_tool = parse_input()
    res = calculate_diffs(contracts_path, diff_tool)
    save_res_to_file(res, diff_tool)
    
    m, s = divmod(int(time.time()) -  seconds, 60)
    print("Generated diffs in " + str(m) + "m:" + str(s) + "s")
    
    