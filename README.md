# SoliDiffy: AST Differencing for Solidity Smart Contracts
This is a project that aims to explore the topic of AST differencing for the programming language Solidity. We have looked at the state-of-the-art, and identied the need for more research in this area. We have extended the AST differencing tool Gumtree to be able to work with Soldidity. We then have performed a thorough evaluation where we compare our implementation with the popular diffing tool difftastic. 


## Setup & Usage
The setup steps neccessary for running the project differ depending on what you want to do. If you only want to use the modified Gumtree parser, simply initialize the gumtree and tree-sitter-parser submodules and follow their respective setup & usage instructions. 

If you want to reproduce the evaluation itself, there are a few more steps.
### Dataset & Mutation
The dataset used in our evaluation is a subset of the DAppSCAN-source dataset. Around ten thousand files were used, and around 90% successfully mutated and diffed. This dataset can be found in the repo.

We used the mutation testing tool Sumo, along with a python script, to generate files with differing amounts of mutations. Sumo can be installed with npm, and requires some modifications to its config file in order to run. Refer to the sumo reposotiry for further details. 

Once sumo is working, the python script Mutatant_gen_script.py can be ran to generate mutants. It takes only one argument, the number of mutations you want per mutation operator and Solidity file. The files mutated are specified in the Sumo config file, and the output will be placed in /contracts/mutants in the project. 

### Difftastic
Difftastic is evaluated and compared to the Gumtree implementation in this project. It is written in Rust, and can be installed using cargo.

### Evaluation
Once Gumtree, the Tree Sitter Parser for Gumtree, difftastic, and Sumo are working, you can run the main diffing script. The script, diff_script.py, takes two arguments: the path to the mutants used for diffing (usually /contracts/mutants), and what diff tool you want to use (GT/difft). The process of diffing thousands of files takes a long time, especially in the case of Gumtree, so if using the entire dataset it is recommended to run it on a processor with a larger number of cores.
