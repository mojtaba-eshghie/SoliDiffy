import sys
import os
import subprocess
import re
from pathlib import Path
import shutil


logging = True

def handle_input():
    if len(sys.argv) != 3:
        raise Exception("Please provide path to original contracts and number of mutations!")
    
    contracts_path = sys.argv[1]
    n_mutations = int(sys.argv[2])
    
    contracts = os.listdir(contracts_path)
    pattern = '.*\.sol$'
    contracts =[x for x in contracts if re.match(pattern, x)]
    if len(contracts) == 0:
        raise Exception("No solidity contracts in specified directory!")

    return [contracts_path, contracts, n_mutations]

#Mutates a contract n times using gambit
def mutate_contract(contract_path, n, output_path):
    args = " --sourceroot ~/Documents/solidity-code-diff/ --filename " + contract_path + " -n " + str(n) + " --outdir " + output_path
    subprocess.run('gambit mutate' +  args, shell=True)

#Returns the line numbers as well as the mutated content of mutations on a contract by gambit
def get_gambit_info(gambit_res_path):
    #Get gambit summary
    gambit_summary = subprocess.check_output("gambit summary --mutation-directory " +  gambit_res_path, shell=True).decode()

    #Remove ANSI text encoding and split into str list
    ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
    gambit_summary = ansi_escape.sub('', gambit_summary)
    gambit_summary = gambit_summary.split('\n')
    

    #Use regex to extract the line numbers of mutations and put into list
    pattern = '^@@.*'
    line_numbers_info = [x for x in gambit_summary if re.match(pattern, x)]
    line_numbers = []

    for line in line_numbers_info:
        line_n = re.search('\d+', line)
        line_n = int(line_n.group(0)) + 2 #Line number reported by gambit is 3 too small, and -1 for 0-indexing
        line_numbers.append(line_n)

    #Use regex to extract mutated line contents and put into list of strings
    pattern = '^\+\s+[^/+\s].*'
    new_lines = [x for x in gambit_summary if re.match(pattern, x)]
    for i in range(len(new_lines)): #Drop leading '+'
        new_lines[i] = new_lines[i][1:]
    
    new_lines = [x for _, x in sorted(zip(line_numbers, new_lines))]
    line_numbers.sort()

    if(logging):
        print(new_lines)
        print(line_numbers)

    return(line_numbers, new_lines)

#Combines Gambit mutations into files with multiple mutations
def generate_mutants(contract, line_numbers, new_lines, output_path):
    #Get contract name, ommiting file format
    name = contract.split('/')[-1].split('.')[0]

    #open contract file and split into lines, then add original to results
    lines = open(contract).read().split('\n')
    output = Path(output_path + name + '/original/' + name + '.sol')
    output.parent.mkdir(exist_ok=True, parents=True)
    output.write_text('\n'.join(lines))

    #Keep track of already mutated lines and number of inserts
    used_lines = []
    inserts = 0

    #Loop creating mutants
    for i in range(len(new_lines)):
        if(logging):
            print('\n\nGenerating mutant #' + str(i+1) + ":")
        if line_numbers[i] not in used_lines:
            if(logging):
                print("line #" + str(line_numbers[i] + inserts) + " mutated with " + new_lines[i])
            lines[line_numbers[i] + inserts] = new_lines[i]
            used_lines.append(line_numbers[i])
        else:
            if(logging):
                print("line #" + str(line_numbers[i] + inserts) + " already mutated. Inserting " + new_lines[i] +  " instead")
            if new_lines[i].endswith('{'):
                new_lines[i] = new_lines[i] +  '}'
            lines.insert(line_numbers[i] + inserts, new_lines[i])
            inserts += 1

        #Save finished mutant to file
        output = Path(output_path + name + '/' + str(i+1) + '/' + name + '.sol')
        output.parent.mkdir(exist_ok=True, parents=True)
        output.write_text('\n'.join(lines))
    return
   
if __name__ ==  '__main__':
    [contracts_path, contracts, num_mutants] = handle_input()
    if(logging):
        print("Input:")
        print("path : " + contracts_path + "\ncontracts: " + str(contracts) + " \nmutations: " + str(num_mutants))
        print("=====================================")

    gambit_res_path = "~/Documents/solidity-code-diff/scripts/gambit_out"
    output_path = "/home/vboxuser/Documents/solidity-code-diff/contracts/mutants/"

    for c in contracts:
        if(logging):
            print("Generating mutants for contract: " + c)

        mutate_contract(contracts_path + c, num_mutants, gambit_res_path)
        (line_numbers, new_lines) = get_gambit_info(gambit_res_path)
        generate_mutants(contracts_path + c, line_numbers, new_lines, output_path)

        if(logging):
            print("=====================================\n")

        shutil.rmtree("gambit_out")    

