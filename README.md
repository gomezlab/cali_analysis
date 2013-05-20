Cali Analysis Software
=============

This repository contains software designed to help quantify the effect on protein localization at specific distances from the edge of a cell before and after a perturbation. Both full cell and kymograph images can be processed. To do this the software follows several steps:

1. Identification of the cell edge. This is done using a user provided threshold suitable for identifying the cell body and background regions.

2. Binning of Pixel Intensities Back from the Cell Edge. The pixels behind the cell edge are binned according to their distance from the cell edge. The size of the bins are specified by the user.

3. Analysis of Binned Pixels. The value of the average, standard deviation and the upper and lower 95% confidence intervals around the mean (T-test based) are calculated for each set of binned pixels. Plots and raw data files are produced.


