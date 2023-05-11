#!/bin/bash
Rscript norm_gess.R > log/logGess.txt 2>&1 &
Rscript norm_latent.R > log/logLatent.txt 2>&1 &
Rscript norm_rand_walk.R > log/logRandWalk.txt 2>&1 &
Rscript norm_stepping_out.R >log/logSteppingOut.txt 2>&1 &
Rscript norm_transform.R > log/logTransform.txt 2>&1 &