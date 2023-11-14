# List of Works Related to Solidity Code Differencing
This list is an informal summary of all the papers we reviewed during the project. 

## [Fine-grained and Accurate Source Code Differencing](https://dl.acm.org/doi/10.1145/2642937.2642982)
- Main GumTree paper
- Contains basic information on AST differencing and edit scripts.
- Presents algorithm used in GumTree.
- Two phase algorithm that traverses ASTs and finds similarities between them in a few different ways.
  - Top-down (very straight-forward greedy search mapping between isomorphic subtrees) and Buttom-up phases (finding container mappings and then, recovery mappings)
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

## [Generating Accurate and Compact Edit Scripts Using Tree Differencing](https://ieeexplore.ieee.org/abstract/document/8530035)
- Presents a AST-diff tool called IJM (Iterative Java Matcher)
- Compares itself to GT and another diff tool. Is itself based on GT in many ways.
- The shortcomings of the other diff tools is described as inaccurate update and move actions.
- What they seem to mean by this is that when as a developer looking at the diff, you will sometimes find non-sensical edit actions that don't correspond to the actual changes.
- IJM has three improvements: partial matching, name-aware matching, and merging name nodes.
- Partial matching means that the scope is limited for each match, for example code within a method is more likely to be moved within that method. Note that not all types of statements are affected
- Merged name nodes reduces the size of ASTs by merging nodes containing names with their parents. This also prevents faulty mathcings between different types of statements with the same name.
- Name aware matching makes sure GT is name-aware in bottom up phase, since is otherwise leads to unnecessary move and update actions.

## [A Differential Testing Approach for Evaluating Abstract Syntax Tree Mapping Algorithms](https://ieeexplore.ieee.org/document/9401960)
- Approach for evaluating the correctness of different AST diff approaches.
- They state the need for automatic evaluation of AST diffing. 
- Uses differential testing to find differences between different diffing tools.
- GumTree, MTDiff, and IJM (previous source in this list) are evaluated.
- When inconsistencies between diffing approaches are found, the similarities between the matched nodes in all the cases are established and used to determine which match is correcct.
- However, the process for finding out the similarity between nodes is just a manual review, so the tool is not automatic.
- Interestingly GumTree is found to have the highest performance, contradicting the findings of the IJM study. 

## [Pruning the AST with Hunks to Speed up Tree Differencing](https://ieeexplore.ieee.org/document/8668032)
- Talks about the inefficiency of AST diff compared to line based diff. Line based diff is much faster, especially for larger codebases.
- Proposes technique that speeds up AST diff by using line based diff.
- Prunes nodes of ASTs if they do not appear in "hunks" (line based differences.)
- This reduces the size of the ASTs by omitting unchanged code, and speeds up performance.
- GumTree saw a 70-75% reduction in runtime with this approach!

## [Beyond GumTree: A Hybrid Approach to Generate Edit Scripts](https://ieeexplore.ieee.org/document/8816807)
- Hybrid approach utilizing both line based and AST diff.
- Aims to improve accuracy of move and update actions.
- Splits AST nodes into ones found in line based diff and ones not.
- Line matched nodes are only matched with other matched nodes and vice versa.
- Results are not very interesing, there is an improvement, but only by a few %.
- The idea of combining line diff with AST diff is interesting.

  ## [HyperAST: Enabling Efficient Analysis of Software Histories at Scale](https://dl.acm.org/doi/10.1145/3551349.3560423)
  - Proposes a new type of AST data structure to improve analysis.
  - Adjacent topic to the project, not directly linked but probably relevant enough.
  - Haven't looked into technical details, but as I understand it it works as follows: Instead of multitudes of ASTs being built for every version of a file, one HyperAST is built instead containing extra information about what nodes were changed and when. 
  - Compared to Spoon, a java AST builder and analyzer their approach performs orders of magnitudes better in terms of runtime and memory usage.

  ## [Move-Optimized Source Code Tree Differencing](https://dl.acm.org/doi/10.1145/2970276.2970315)
  - Presents 5 optimizations that can be applied to AST diff algorithms.
  - Presents algorithm they call MTDIFF, which is based on Changedistiller and uses optimizations.
  - One of the optimizations already included in Gumtree.
  - All of the other benefit GT and are directlly related to the matching process.
  - For example, one optimization helps find move actions for smaller subtrees, which GumTree would've used the RTED algorithm for which does not detect moves.
  - The results are not very convincing though. The main metric is "% of cases where x algorithm was better" which does not state how much better.
  - What is stated is that the edit scripts are identical in around 80% of caes when using the optimizations/MTDIFF when compared to GT.
  - In around 20% of cases GT is improved by optimizations, around 20% of cases MTDIFF outperforms GT with optimizations. 
    
