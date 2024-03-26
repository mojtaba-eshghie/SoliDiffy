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

'''
removed = ["ICM", "ORFD", "CCD", "OLFD", "LSC", "HLR", "GVR"]
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
'''

for contract in difft:
    for i in range(len(difft[contract])):
        for mut in difft[contract][i]:
            difft_count[i] += 1
            difft_res[i] += difft[contract][i][mut]

            if not mut in difft_mut_res.keys():
                difft_mut_res[mut] = [0] * 5
                difft_mut_res_count[mut] = [0] * 5
            difft_mut_res[mut][i] += difft[contract][i][mut]
            difft_mut_res_count[mut][i] += 1    

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


print("difftastic average: " + str(difft_res))
print("Gumtree average: " + str(GT_res))
print("successful # of mutations: ", difft_count)


plt.title("Results")
#plt.figure(200)
for mut in difft_mut_res:
    x = [i+0.985 for i in range(len(difft_mut_res[mut]))]
    plt.scatter(x, difft_mut_res[mut], color="blue", s=6)

#plt.title("Difftastic Results")
plt.plot([1,2,3,4,5] ,difft_res, label=("difft_avg"), color="blue")
#lt.ylabel("edit actions")
#plt.xlabel("# of mutations")
#plt.xticks([1,2,3,4,5])
#plt.yticks([0,5,10,15,20,25,30,35,40,45,50])
#plt.yticks([0,5,10,15,20])
#plt.legend()

plt.minorticks_on()
#plt.figure(300)
for mut in GT_mut_res:
    x = [i+1.015 for i in range(len(GT_mut_res[mut]))]
    plt.scatter(x, GT_mut_res[mut], color="red", s=6)

#plt.title("Gumtree Results")
plt.plot([1,2,3,4,5], GT_res, label ="GT_avg", color = "red")
plt.ylabel("edit actions")
plt.xlabel("# of mutations")
plt.xticks([1,2,3,4,5])
#plt.yticks([0,5,10,15,20,25,30,35,40,45,50])
plt.yticks([0,5,10,15])
plt.legend()
plt.show()