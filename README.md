# SoliDiffy: AST Differencing for Solidity Smart Contracts



# Docker Installation/Replication Package


## Prerequisites
To use SoliDiffy, you need the following:

1. [Docker](https://docs.docker.com/get-docker/) - Make sure you have Docker installed on your machine.
   
   - Verify Docker is installed:
     ```bash
     docker --version
     ```

## Installation and Setup

### 1. Clone the Repository
First, clone the SoliDiffy repository:

```bash
git clone https://github.com/mojtaba-eshghie/SoliDiffy.git
cd SoliDiffy
```

### 2. Build the Docker Image
Build the Docker image using the provided `Dockerfile`. This step will compile necessary dependencies, including the Tree-sitter parser, to speed up future runs.

```bash
sudo docker build -t solidiffy-replication .
```

This will create a Docker image named `solidiffy-replication` that includes everything you need to run SoliDiffy.

### 3. Run SoliDiffy with Docker

To run SoliDiffy and compare two Solidity files, use the following Docker command. The files must be located on your host machine, and Docker will mount them into the container.

```bash
sudo docker run --rm \
  -v /path/to/original.sol:/app/original.sol \
  -v /path/to/modified.sol:/app/modified.sol \
  solidiffy-replication textdiff /app/original.sol /app/modified.sol
```

This will run the diff and output the differences between the two Solidity files.

#### Explanation:
- **`/path/to/original.sol`**: Path to your original Solidity file on your local machine.
- **`/path/to/modified.sol`**: Path to your modified Solidity file on your local machine.
- **`solidiffy-replication`**: The Docker image you built.
- **`textdiff`**: SoliDiffy to run the diff comparison between the two files.


### Dataset(s)
The dataset used in our evaluation is a subset of the DAppSCAN-source dataset. Around ten thousand files were used, and around 90% successfully mutated and diffed. This dataset can be found in the repo.

We used the mutation testing tool Sumo, along with a python script, to generate files with differing amounts of mutations. Sumo can be installed with npm, and requires some modifications to its config file in order to run. Refer to the sumo reposotiry for further details. 

Once sumo is working, the python script Mutatant_gen_script.py can be ran to generate mutants. It takes only one argument, the number of mutations you want per mutation operator and Solidity file. The files mutated are specified in the Sumo config file, and the output will be placed in /contracts/mutants in the project. 

