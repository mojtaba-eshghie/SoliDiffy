import pickle
import pprint
import matplotlib.pyplot as plt
import numpy


difft_file = open("results-difft.pickle", "rb")
gt_file = open("results-GT.pickle", "rb")

difft = pickle.load(difft_file)
GT = pickle.load(gt_file)

difft_res = [0] * 5
difft_count = [0] * 5
difft_mut_res = {} 
difft_mut_res_count = {}

GT_res = [0] * 5
GT_count = [0] * 5
GT_mut_res = {}
GT_mut_res_count = {}

"VUR" 
"OLFD" 
"CCD" 
"ORFD" 

"CSC" 
"CCD" 
"GVR"
"ICM" 


#old_removed = ["ICM", "ORFD", "CCD", "OLFD", "LSC","GVR"]
removed = ["VUR", "OLFD", "CCD", "ORFD", "CSC", "CCD", "GVR","ICM"]
for contract in difft:
    for i in range(len(difft[contract])):
        for r in removed:
            if r in difft[contract][i].keys():
                difft[contract][i].pop(r)

for contract in GT:
    for i in range(len(GT[contract])):
        for r in removed:
            if r in GT[contract][i].keys():
                GT[contract][i].pop(r)


for contract in difft:
    #mut_in = False
    #if "CCD" in difft[contract][0].keys():
    #    print("Contract " + contract)
    #    mut_in = True
    for i in range(len(difft[contract])):
        for mut in difft[contract][i]:
            difft_count[i] += 1
            difft_res[i] += difft[contract][i][mut]

            if not mut in difft_mut_res.keys():
                difft_mut_res[mut] = [0] * 5
                difft_mut_res_count[mut] = [0] * 5
            difft_mut_res[mut][i] += difft[contract][i][mut]
            difft_mut_res_count[mut][i] += 1    
    #if mut_in:
    #    print("===========================================")

difft_res = [i / j for i, j in zip(difft_res, difft_count)]

for mut in difft_mut_res:
    for i in range(len(numpy.trim_zeros(difft_mut_res[mut]))):
        difft_mut_res[mut] = numpy.trim_zeros(difft_mut_res[mut])
        difft_mut_res_count[mut] = numpy.trim_zeros(difft_mut_res_count[mut])
        difft_mut_res[mut][i] /= difft_mut_res_count[mut][i]

for contract in GT:
    for i in range(len(GT[contract])):
        for mut in GT[contract][i]:
            if GT[contract][i][mut]:
                GT_count[i] += 1
                GT_res[i] += GT[contract][i][mut][0]
                
                if not mut in GT_mut_res.keys():
                    GT_mut_res[mut] = [0] * 5
                    GT_mut_res_count[mut] = [0] * 5
                GT_mut_res[mut][i] += GT[contract][i][mut][0]
                GT_mut_res_count[mut][i] += 1


GT_res = [i / j for i, j in zip(GT_res, GT_count)]  

for mut in GT_mut_res:
    for i in range(len(numpy.trim_zeros(GT_mut_res[mut]))):
        GT_mut_res[mut] = numpy.trim_zeros(GT_mut_res[mut])
        GT_mut_res_count[mut] = numpy.trim_zeros(GT_mut_res_count[mut])
        GT_mut_res[mut][i] /= GT_mut_res_count[mut][i]

print("====================================")
print("difftastic average: " + str(difft_res))
print("Gumtree average: " + str(GT_res))
print("successful # of mutations: ", difft_count)
print("====================================")

'''
print("GUMTREE RESULTS BY MUTATION: ")
GT_mut_sorted = sorted(GT_mut_res.items(), key = lambda x: x[1][len(x[1])-1])
for mut in GT_mut_sorted:
    print(mut[0], mut[1], " counts:", GT_mut_res_count[mut[0]])
#pprint.pprint(GT_mut_sorted)

print("====================================")
print("DIFFTASTIC RESULTS BY MUTATION: ")
difft_mut_sorted = sorted(difft_mut_res.items(), key = lambda x: x[1][len(x[1])-1])
for mut in difft_mut_sorted:
    print(mut[0], mut[1], " counts:", difft_mut_res_count[mut[0]])

#pprint.pprint(difft_mut_sorted)
'''


plt.plot([1,2,3,4,5] ,difft_res, label=("difft_avg"), color="blue")
for mut in difft_mut_res:
    x = [i+0.985 for i in range(len(difft_mut_res[mut]))]
    plt.scatter(x, difft_mut_res[mut], color="blue", s=6)

plt.plot([1,2,3,4,5], GT_res, label ="GT_avg", color = "red")
for mut in GT_mut_res:
    x = [i+1.015 for i in range(len(GT_mut_res[mut]))]
    plt.scatter(x, GT_mut_res[mut], color="red", s=6)


plt.title("Results")
plt.ylabel("edit actions")
plt.xlabel("# of mutations")
plt.minorticks_on()
plt.xticks([1,2,3,4,5])
#plt.yticks([0,5,10,15])
plt.legend()
plt.show()
