import matplotlib.pyplot as plt
import numpy as np
import os
import csv

# Clean plot
plt.close()
plt.figure(figsize=(15, 10), dpi=100)
x_plots = 1
y_plots = 2

# load curves
filepath = "/Users/kruip/Projects/etengine/tmp/convergence/20140923_1502/NL_373837_2014-09-23_15-01-42/demand.csv"
nl2013 = np.genfromtxt(filepath, delimiter = ',')

filepath = "/Users/kruip/Projects/etengine/tmp/convergence/20140923_1502/DE_373832_2014-09-23_09-22-31/demand.csv"
de2013 = np.genfromtxt(filepath, delimiter = ',')

plt.title("Demand for electricity")
plt.subplot(y_plots, x_plots, 1)
plt.plot(nl2013, label="NL 2013")
plt.plot([np.mean(nl2013)]*8760, linewidth=2, label="mean")
plt.plot([np.mean(nl2013)+np.std(nl2013)]*8760, 'r--', linewidth=2, label="standard-deviation")
plt.plot([np.mean(nl2013)-np.std(nl2013)]*8760, 'r--', linewidth=2)
plt.legend(bbox_to_anchor=[0.99, 0.99])

plt.subplot(y_plots, x_plots, 2)
plt.plot(de2013, label="DE 2013")
plt.plot([np.mean(de2013)]*8760, linewidth=2, label="mean")
plt.plot([np.mean(de2013)+np.std(de2013)]*8760, 'r--', linewidth=2, label="standard-deviation")
plt.plot([np.mean(de2013)-np.std(de2013)]*8760, 'r--', linewidth=2)

plt.legend(bbox_to_anchor=[0.99, 0.99])
plt.ylabel('MW')
plt.xlabel('hours')
plt.show()

