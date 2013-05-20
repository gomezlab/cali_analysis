Cali Analysis Software
=============

This repository contains software designed to help quantify the effect on
protein localization at specific distances from the edge of a cell before and
after a perturbation. This software was originally developed to quantify the
effect of CALI perturbation of Cofilin, but the methods should be general
enough to work for other proteins and perturbations assuming the caveats listed below are true. Both full cell and
kymograph images can be processed. To do this the software follows several
steps:

1. Identification of the cell edge. This is done using a user provided
   threshold suitable for identifying the cell body and background regions.

2. Binning of Pixel Intensities Back from the Cell Edge. The pixels behind the
   cell edge are binned according to their distance from the cell edge. The
   size of the bins are specified by the user.

3. Analysis of Binned Pixels. The value of the average, standard deviation and
   the upper and lower 95% confidence intervals around the mean (T-test based)
   are calculated for each set of binned pixels. Plots and raw data files are
   produced.

All of the code is written in matlab and a gui interface is provided. After downloading the software, start MATLAB and change your working directory to the 'src' directory. There are two commands which will start a GUI, one for whole cell and another for kymographs, to gather the needed information concerning your data.

Caveats
=======

* These methods will not work if your images don't clearly idenfity the cell edge before and after perturbation. Currently, the methods only use the input image set to identify the cell edge. If your protein of interest doesn't mark the cell edge adequately, the distance from the cell edge binning won't work correctly. If there is demand, using a second marker which marks the cell body would be possible.


Publication
=========

The software has been used in the following publication:

* EA Vitriol, et al. Instantaneous Inactivation of Cofilin Reveals its Function of F-actin Disassembly in Lamellipodia. Mol Biol Cell, 2013 [HTML](http://dx.doi.org/10.1091/mbc.E13-03-0156)
