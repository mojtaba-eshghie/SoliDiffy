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
import pprint

def parse_input():
    if len(sys.argv) != 3:
        raise Exception("Please provide arguments in the form: [PATH TO MUTANTS], [DIFFING TOOL] (GT/difft)! \n Example: python3 perform_diffs.py ../mutants/ GT")
    
    contracts_path = sys.argv[1]
    diff_tool = sys.argv[2]

    if diff_tool != "difft" and diff_tool != "GT":
        raise Exception("Error: invalid diff tool provided!")

    return contracts_path, diff_tool

#Uses gumtree to get the diff between two files
def get_GT_diff_data(filepath1, filepath2):
    save_full_diff = True

    start = time.time()
    diff = subprocess.check_output('gumtree textdiff -f XML ' +  filepath1 + " " + filepath2, shell=True).decode()
    granular_running_time = time.time() - start
    if not diff:
        print("mutant causing error:" + filepath2)
        return -1
    
    # Wrap result to get single XML root and convert to tree
    diff = diff.split('\n', 1)
    diff = diff[0] + "<X>" + diff[1] + "</X>"
    tree = ET.fromstring(diff)

    # Get number of edit actions and matches from tree
    n_edits = len(tree.findall('actions')[0])
    print(f'Number of edits: {n_edits}')
    
    # Append full diff to res if flag is set and return res
    res = [n_edits, granular_running_time]
    if save_full_diff:
        # Convert the 'actions' element to a string and append
        actions = tree.findall('actions')[0]
        actions_str = ET.tostring(actions, encoding='unicode')
        res.append(actions_str)
    
    return res


#Uses difftastic to get the diff between two files
def get_diffts_data(filepath1, filepath2):
    os.environ['DFT_UNSTABLE'] = 'yes'
    start = time.time()
    diff = subprocess.check_output('difft --display json ' +  filepath1 + " " + filepath2, shell=True).decode()
    granular_running_time = time.time() - start
    if not diff:
        return -1 
    
    diff = json.loads(diff)
    if diff["status"] == "unchanged":
        #print("WARNING: difft failed to detect change in contract " + filepath2 + "!!!")
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
    return [count, granular_running_time, diff["chunks"]]


# Save results incrementally using JSON Lines format
def save_res_to_file_incrementally(results, diff_tool):
    file_path = f"../results/results_{diff_tool}.jsonl"
    with open(file_path, "a") as f:
        for result in results:
            json.dump(result, f)
            f.write('\n')  # Newline separates each JSON object


# Modified get_contract_diffs function
def get_contract_diffs(contract_path, contract, diff_tool):
    res = []
    con_name = os.listdir(contract_path + "/original")[0]
    unmutated_path = contract_path + "/" + "original/" + con_name
    num_contracts = len(os.listdir(contract_path))
    
    for i in range(1, num_contracts):
        operators = os.listdir(contract_path + "/" + str(i))
        diffs = {}
        for op in operators:
            mutated_path = contract_path + "/" + str(i) + "/" + op + "/" + con_name
            if diff_tool == "GT":
                diff = get_GT_diff_data(unmutated_path, mutated_path)
                print(f"Contract: {contract}, Operator: {op}, Diff: {diff}")
                if diff == -1:
                    diff = []
            elif diff_tool == "difft":
                diff = get_diffts_data(unmutated_path, mutated_path)
                if diff == -1:
                    diff = []
            else:
                raise Exception("Error: invalid diff tool!")
            diffs[op] = diff
        res.append(diffs)
    
    # Save each contract's results incrementally
    save_res_to_file_incrementally([{contract: res}], diff_tool)




# Corrected calculate_diffs function
def calculate_diffs(contracts_path, diff_tool):
    contracts = os.listdir(contracts_path)
    executor = cc.ThreadPoolExecutor(max_workers=os.cpu_count())
    futures = []

    # Schedule the execution of get_contract_diffs
    for contract in contracts:
        futures.append(executor.submit(get_contract_diffs, contracts_path + contract, contract, diff_tool))

    # Ensure proper completion of all futures
    completed_count = 0
    for future in cc.as_completed(futures):
        completed_count += 1
        print(f'Contracts done: {completed_count}/{len(contracts)}', end='\r')

    executor.shutdown(wait=True)
    print('All contracts processed.')


#Saves results as a python object in a json file
def save_res_to_file(results, diff_tool):
    with open(f"../results/results_{diff_tool}.json", "w") as f:
        json.dump(results, f)





if __name__ == '__main__':
    start_time = time.time()

    contracts_path, diff_tool = parse_input()
    calculate_diffs(contracts_path, diff_tool)
    
    total_running_time_seconds = time.time() - start_time
    print(f"Generated diffs in {total_running_time_seconds} s")

    # Initialize running_time as an empty dictionary
    running_time = {}

    json_file_path = "../results/running_time.json"

    # Check if the file exists and is not empty
    if os.path.exists(json_file_path) and os.path.getsize(json_file_path) > 0:
        try:
            with open(json_file_path, "r") as f:
                running_time = json.load(f)
        except json.JSONDecodeError:
            print("Error reading the JSON file, initializing with an empty dictionary.")

    # Update the running time for the current diff tool
    running_time[diff_tool] = total_running_time_seconds

    # Save the updated running time data back to the file
    with open(json_file_path, "w") as f:
        json.dump(running_time, f, indent=4)