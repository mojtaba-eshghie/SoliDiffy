# List of Works Related to Solidity Code Differencing
This list is an informal summary of all the papers we reviewed during the project. 

## [Fine-grained and Accurate Source Code Differencing](https://dl.acm.org/doi/10.1145/2642937.2642982)
- Main GumTree paper
- Contains basic information on AST differencing and edit scripts.
- Presents algorithm used in GumTree.
- Two phase algorithm that traverses ASTs and finds similarities between them in a few different ways.
- Makes use of previous effective algorithms in parts of the implementation’
- Main contribution is considering the so-called “move-action” in diffs. This means better results in cases where code blocks have been moved.
- Move action also increases time-complexity and makes it a NP-hard problem
- The other main contribution is the thorough manual and automated evaluation of the tool.

## [Change Detection in Hierarchically Structured Information](https://dl.acm.org/doi/10.1145/235968.233366)
- Older paper from 1996
- Describes optimal algorithm used by GumTree
- Algorithm deduces edit-script between two ASTs given a list of matchings.
- In other words, given the similarities between two ASTs, this is the optimal algorithm for finding the differences between those ASTs.
- 5 phase algorithm where nodes are updated, added, and so on. 
- Time complexity of O(nd), n = # of nodes, d = # of misaligned nodes.

## [RTED: A Robust Algorithm for the Tree Edit Distance](https://dl.acm.org/doi/10.14778/2095686.2095692)
- Another algorithm used in GumTree implementation  
- Determines what of a few previous algorithms to use based on the shape of subtrees
- Improves average performance by avoiding the worst case time complexities for the used algorithms.
- Does not consider the move action

## [Hyperparameter Optimization for AST Differencing](https://arxiv.org/abs/2011.10268)
- Describes hyperparameter tuning of GumTree (and a few other tools)
- Uses “DAT” for tuning, Diff Auto Tuning
- Both global and local optimization
- Global is general performance, local for specific examples
- Evaluates performance by looking at edit script length, changes parameters to minimize it. 

## [SIF: A Framework for Solidity Contract Instrumentation and Analysis](https://ieeexplore.ieee.org/document/8945726)
- SIF is a Solidity framework containing 7 different tools.
- One of these tools is AST differencing
- Move action is not considered 
- No thorough evaluation of the AST diff tool is performed. 
- Only correctness is tested, not for example the edit-script length

## [Mining software repair models for reasoning on the search space of automated program fixing](https://link.springer.com/article/10.1007/s10664-013-9282-8)
- Not very relevant to the project
- It is however an example of a use for AST differencing
- AST differencing is used here for automated program repair
