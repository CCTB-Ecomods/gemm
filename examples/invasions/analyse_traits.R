#!/usr/bin/Rscript
### This is an analysis script for the island invasion model, specifically for
### the trait analyses (these were originally done by Ludwig, but his work was
### lost in the mists of time...). Partly copied from my Zosterops analysis script.

library(raster)
library(tidyverse)
library(ggplot2)
library(cowplot) ## arrange ggplots in a grid
library(ggsci) ## scientific color scales
library(ggfortify)
library(reshape2)
library(Hmisc)
library(lme4)

## To detach all packages if necessary, use:
## invisible(lapply(paste0('package:', names(sessionInfo()$otherPkgs)),
##                  detach, character.only=TRUE, unload=TRUE))

autorun = FALSE ## automatically run all analyses?

datadir = "results_final" ## "results" by default

## Preferred output format
outformat = ".eps" ## default: ".jpg", for publication: ".eps"

## The minimum number of cells an alien species must be in to be considered invasive
invasiveThreshold = 2 ## default: 2

## D-Day and apocalypse
invasionstart = 500
worldend = 1500

## read and pre-process data
loadData = function(dir=datadir, saveData=TRUE) {
    popfiles = Sys.glob(paste0(dir, "/*/*tsv"))
    metrics = c("time", "x", "y", "temp", "prec", "area", "conf",
                "lineage", "adults", "maxage", "maxsize")
    results = tibble()
    for (filepath in popfiles) {
        nexttsv = read_tsv(filepath) %>% select(all_of(metrics), ends_with("med")) %>%
            mutate(Scenario=str_replace_all(conf, "^invasion\\d_r\\d+_|\\.conf$", "")) %>%
            mutate(replicate=str_extract(filepath, "\\d_r\\d+")) %>%
            select(-ends_with("sdmed"), -conf)
        results = bind_rows(results, nexttsv)
    }
    if (saveData) save(file="results.dat", results)
    return(results)
}


