import sys
import json
import subprocess
from pathlib import Path

logging = False

def handle_input():
    if len(sys.argv) != 2:
        raise Exception("Please provide number of mutations!")
    
    n_mutations = int(sys.argv[1])

    return n_mutations

#Generates sumo mutations
def run_sumo():
    subprocess.run('npx sumo lookup > /dev/null', shell=True)

#Combines Sumo mutations into files with multiple mutations
def generate_mutants(output_path, n_mutants):
    file = open("../sumo/results/mutations.json")
    sumo_res = json.load(file)

    for c in sumo_res:
        print("\n==================================================================")
        print("Mutating contract: " + c)
        name = c.split('.')[0]
        sumo_res[c] =  sorted(sumo_res[c], key=lambda d: d['start']) 
        
        contract = open("../contracts/dataset/" +  c).read()
        output = Path(output_path + name + '/original/' + c)
        output.parent.mkdir(exist_ok=True, parents=True)
        output.write_text(contract)

        i = 0                                                   #The index of the next possible mutation
        offset = 0                                              #The offset in character indices caused by mutations
        used_characters = [True for i in range(len(contract))]  #'Bitmap' tracking already mutated characters
        counter = 0                                             #The number of successful mutaions
        prev_start = 0                                          #Keeps track of last mutation start index to avoid case where mutations become 'unsorted' after applying offset
        while counter < n_mutants:
            try:
                mutation = sumo_res[c][i]
            except:
                print("Warning: there weren't enough mutants to mutate contract: " + name)
                print("# of successful mutants for " + c + ": " + str(counter) + "/" + str(num_mutants))
                break
            i += 1

            mut_start, mut_end = mutation["start"] + offset, mutation["end"] + offset
            new_content, old_content = mutation["replace"], mutation["original"]
            line_start, line_end = mutation["startLine"], mutation["endLine"]
            if line_start != line_end:
                if logging:
                    print("------------------------------------------")
                    print("Warning: Mutation spans over multiple lines. Mutation operator: " + mutation["operator"] + ". Skipping mutation...")
                continue

            if  all(used_characters[mut_start:mut_end]) and prev_start < mut_start:
                if logging:
                    print("------------------------------------------")
                    print("Mutating line " + str(line_start) + " characters " + str(mut_start) + "-" + str(mut_end))
                    print(old_content + " --> " + new_content)
                    print("Offset for replacement: " + str(len(new_content) - len(old_content)))

                contract = contract[0:mut_start] + new_content + contract[mut_end:]
                offs = len(new_content) - len(old_content)
                offset += offs
                used_characters = used_characters[0:mut_start] + [False for j in range(mut_end - mut_start + offs)] + used_characters[mut_end+offs:]
                counter += 1
                prev_start = mut_start

                output = Path(output_path + name + '/' + str(counter) + '/' + c)
                output.parent.mkdir(exist_ok=True, parents=True)
                output.write_text(contract)
            else:
                continue
       

if __name__ ==  '__main__':
    num_mutants = handle_input()

    sumo_res_path = "../sumo/results"
    output_path = "../contracts/mutants/"

    run_sumo()
    generate_mutants(output_path, num_mutants)
  

