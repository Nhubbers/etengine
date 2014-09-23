import matplotlib.pyplot as plt
import numpy as np
import os
import csv

# Clean plot
plt.close()
plt.figure(figsize=(15, 10), dpi=100)
x_plots = 1
y_plots = 1

# load curves
nl2013 = np.genfromtxt("/Users/kruip/Projects/etengine/tmp/convergence/20130923_1502/NL_373837_2014-09-23_15-01-42/demand.csv", delimiter = ',')

#ofile = open("/Users/kruip/Projects/merit-convergence/data/nl/interconnector_load_curves/NOR_NL_2023.csv","w")
#for i in range(0,len(nor2013)):
#    if i > 7234 and i < 8481:
#        ofile.write("700\n")
#    else:
#        ofile.write(""+str(nor2013[i])+"\n")
#
#ofile.close()

year = 8760

plt.title("Demand for electricity")
plt.subplot(y_plots, x_plots, 1)
plt.plot(nl2013, label="NL 2013")

plt.legend(bbox_to_anchor=[0.99, 0.99])
plt.ylabel('MW')
plt.xlabel('hours')
plt.show()

total = np.sum(nl2013)/1e6
print "Total demand in NL: ", total, " TWh = ", total * 3.6, " PJ"
