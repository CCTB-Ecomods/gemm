#!/usr/bin/Rscript
## Load pre-saved diversity plots from multiple scenarios and combine them
## into single figures for additional (supplementary) analysis.

library(tidyverse)
library(cowplot)

# Data files to load were generated with analysis.R, contain diversity plots and `tworesults`.
load("reference.dat")
load("small.dat")
load("reflecting.dat")
load("absorbing.dat")
load("constrained.dat")

## species diversity grid plot
plot_grid(betaReference, ttlrichReference, rangeReference,
          betaReflecting, ttlrichReflecting, rangeReflecting,
          betaAbsorbing, ttlrichAbsorbing, rangeAbsorbing,
          betaSmall, ttlrichSmall, rangeSmall,
          ncol=3)
ggsave("scenarios_species_diversity_raw.pdf", width=10, height=7)

## genetic diversity grid plot
plot_grid(traitresponsesReference,
          traitresponsesReflecting,
          traitresponsesAbsorbing,
          traitresponsesSmall,
          ncol=1)
ggsave("scenarios_genetic_diversity_raw.pdf", width=8, height=12)

## constrained vs reference species numbers
plot_grid(lclrichReference, lclrichConstrained,
          betaReference, betaConstrained,
          ttlrichReference, ttlrichConstrained,
          ncol=2)
ggsave("constrained_vs_reference_diversity_raw.pdf", width=8, height=6)

## Comparison of species numbers between reference and constrained scenarios

##
## Reference:
## Species surviving only in static runs: 52
## Species surviving only in variable runs: 4
## Species surviving in both runs: 16
##
## Constrained:
## Species surviving only in static runs: 91
## Species surviving only in variable runs: 7
## Species surviving in both runs: 13
##

speciesperrun = function(worldend, rep, scen) {
    runs = intersect(which(worldend$replicate==rep), which(worldend$scenario==scen))
    length(unique(worldend[runs,]$lineage))
}

worldendcon = tworesults[which(tworesultsConstrained$time==dday),]
worldendref = tworesults[which(tworesultsReference$time==dday),]

specconcon = sapply(unique(worldendcon$replicate),
                    function(r) speciesperrun(worldendcon, r, "static"))
specconvar = sapply(unique(worldendcon$replicate),
                    function(r) speciesperrun(worldendcon, r, "variable"))
specrefcon = sapply(unique(worldendref$replicate),
                    function(r) speciesperrun(worldendref, r, "static"))
specrefvar = sapply(unique(worldendref$replicate),
                    function(r) speciesperrun(worldendref, r, "variable"))

pdf("species_numbers_constrained.pdf", width=9, height=5)
boxplot(specrefcon, specconcon, specrefvar, specconvar,
        names=c("Reference/static", "Constrained/static", "Reference/variable", "Constrained/variable"),
        ylab="Number of surviving species per run", ylim=c(0,30))
points(c(2,4), c(30,30))
text(c(2.2, 4.2), c(30,30), labels=c("(185)", "(56)"))
dev.off()
