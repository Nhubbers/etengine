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
filepath = "/Users/kruip/Projects/etengine/tmp/convergence/20130923_1502/NL_373837_2014-09-23_15-01-42/demand.csv"
nl2013 = np.genfromtxt(filepath, delimiter = ',')

total = np.sum(nl2013)/1e6
print "Total demand in NL: ", total, " TWh = ", total * 3.6, " PJ"

old_total = total * 3.6 * 1e9
new_total = 465752837814.0096

scaling_factor = new_total / old_total
print "Scaling factor: ", scaling_factor

# Overwriting the original file!
ofile = open(filepath,"w")
for i in nl2013:
    ofile.write(""+str(i*scaling_factor)+"\n")

ofile.close()

plt.title("Demand for electricity")
plt.subplot(y_plots, x_plots, 1)
plt.plot(nl2013, label="NL 2013")

plt.legend(bbox_to_anchor=[0.99, 0.99])
plt.ylabel('MW')
plt.xlabel('hours')
plt.show()

