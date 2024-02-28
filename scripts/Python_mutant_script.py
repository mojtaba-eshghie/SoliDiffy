import sys
import os
import subprocess
import re
from pathlib import Path


logging = False

def handle_input():
    if len(sys.argv) != 3:
        raise Exception("Please provide path to source code files and number of mutants!")
    
    path = sys.argv[1]
    num_mutants = int(sys.argv[2])
    
    files = os.listdir(path)
    pattern = '.*\.py$'
    files =[x for x in files if re.match(pattern, x)]
    if len(files) == 0:
        raise Exception("No Python source code in specified directory!")

    return (path, files, num_mutants)

#Mutates a contract and returns mutant info
def generate_mutations(source_path, sc_file):
    args = " -p " + source_path + " -t " + sc_file + " -u dummy_test_file -m" #+ "--mutation-number 1 -o ASR"
    mutpy_info = subprocess.check_output('mut.py' +  args, shell=True).decode()
    mutpy_info = mutpy_info.split('\n')

    #Use regex to extract the mutated lines with line numbers
    pattern = '^\+.*'
    new_lines_info = [x for x in mutpy_info if re.match(pattern, x)]
    line_numbers = []
    new_lines = []

    for line in new_lines_info:
        line = line.split()
        line_numbers.append(int(line[1][:-1]))
        new_lines.append(" ".join(line[2:]))

    if(logging):
        print(new_lines)
        print(line_numbers)

    return (line_numbers, new_lines)

#Combines Gambit mutations into files with multiple mutations
def generate_mutants(file_path, line_numbers, new_lines, n_mutations, output_path):
    #Get python file name, ommiting file format
    name = file_path.split('/')[-1].split('.')[0]

    #open python file and split into lines, then add original to results
    lines = open(file_path).read().split('\n')
    output = Path(output_path + name + '/original/' + name + '.py')
    output.parent.mkdir(exist_ok=True, parents=True)
    output.write_text('\n'.join(lines))

    #Keep track of number of mutations and already mutated lines
    used_lines = []
    mutants = 0
    
    #Loop creating mutants
    for i in range(len(new_lines)):
        if(mutants >= n_mutations):
            break  
        if line_numbers[i] not in used_lines:
            if(logging):
                print('\n\nGenerating mutant #' + str(mutants+1) + ":")
                print("line #" + str(line_numbers[i]) + " mutated with " + new_lines[i])
            lines[line_numbers[i]] = new_lines[i]
            used_lines.append(line_numbers[i])
        
            #Save finished mutant to file
            output = Path(output_path + name + '/' + str(mutants+1) + '/' + name + '.py')
            output.parent.mkdir(exist_ok=True, parents=True)
            output.write_text('\n'.join(lines))
            mutants += 1 
    return
   
if __name__ ==  '__main__':
    (source_path, source_files, num_mutants) = handle_input()
    if(logging):
        print("Input:")
        print("path : " + source_path + "\nPython files: " + str(source_files) + " \nmutations: " + str(num_mutants))
        print("=====================================")

    output_path = "/home/vboxuser/Documents/solidity-code-diff/contracts/py_mutants/"

    for sc in source_files:
        if(logging):
            print("Generating mutants for python file: " + sc)

        (line_numbers, new_lines) = generate_mutations(source_path, sc)
        generate_mutants(source_path + sc, line_numbers, new_lines, num_mutants, output_path)

        if(logging):
            print("=====================================\n")
  

