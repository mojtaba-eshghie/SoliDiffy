import pickle
import pprint


difft_file = open("results-difft.pickle", "rb")
gt_file = open("results-GT.pickle", "rb")

difft = pickle.load(difft_file)
GT = pickle.load(gt_file)

difft_res = [0] * 5
difft_count = [0] * 5
GT_res = [0] * 5
GT_count = [0] * 5

for contract in difft:
    for i in range(len(difft[contract])):
        d_sum = sum(difft[contract][i].values())
        difft_count[i] += len(difft[contract][i])
        difft_res[i] += d_sum

difft_res = [i / j for i, j in zip(difft_res, difft_count)]    

for contract in GT:
    for i in range(len(GT[contract])):
        for mut in GT[contract][i]:
            if GT[contract][i][mut]:
                GT_count[i] += 1
                GT_res[i] += GT[contract][i][mut][0]

GT_res = [i / j for i, j in zip(GT_res, GT_count)]  

print("difftastic average: " + str(difft_res))
print("Gumtree average: " + str(GT_res))
print("successful # of mutations: ", difft_count)
