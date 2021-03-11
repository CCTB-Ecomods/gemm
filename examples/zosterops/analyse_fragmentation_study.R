#!/usr/bin/Rscript
### This is the analysis script for the Taita habitat fragmentation / Zosterops
### hybridisation study. It creates graphs of population and heterozygosity development
### over time. (Much of this was copied from the invasion/gradient analysis scripts.)
###
### (c) Daniel Vedder, 2021
### Licensed under the terms of the MIT license
###

library(tidyverse)
library(ggplot2)
library(cowplot) ## arrange ggplots in a grid
library(ggsci) ## scientific color scales
library(ggfortify)
library(reshape2)

datadir = "data" ## "results" by default
experiment = "tolerance" ## "tolerance" or "habitat"
popfiles = Sys.glob(paste0(datadir, "/*", experiment, "*9/*tsv"))
worldend = 300     ## apocalypse...
## On that note: is it ethical to terminate virtual organisms in a mass-extinction
## at the end of an experiment, or should they not rather be released back into the wild?


## read and pre-process data
metrics = c("time", "x", "y", "prec", "capacity", "replicate", "conf",
            "lineage", "adults", "heterozygosity", "precadaptationmean",
            "dispmeanmean", "dispmeanstd", "dispshapemean", "dispshapestd",
            "precoptmean", "precoptstd", "prectolmean", "prectolstd")

results = tibble()
for (filepath in popfiles) {
    nexttsv = read_tsv(filepath) %>% select(all_of(metrics)) %>%
        mutate(Scenario=strsplit(conf, "_")[[1]][3]) %>% ##FIXME
        select(-conf)
    results = bind_rows(results, nexttsv)
}

## population sizes over time
globalcapacity = results %>% filter(time==0, Scenario=="tol0") %>% select(capacity) %>% sum()
adultplot = results %>% group_by(time, Scenario, replicate) %>%
    filter(lineage=="silvanus") %>% summarise(popsize=sum(adults)) %>%
    ggplot(aes(time, popsize, group=Scenario)) + #ylim(c(0,80000)) +
    ##geom_hline(aes(yintercept=globalcapacity), linetype=2, color="grey", size=0.5) +
    stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
    stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
    ylab("Number of adults") + xlab("Year") +
    scale_color_viridis_d() + theme_bw()
ggsave(paste0("adults_over_time_", experiment, ".pdf"), adultplot, width=6, height=4)

## heterozygosity over time
hetplot = results %>% group_by(time, Scenario, replicate) %>%
    filter(lineage=="silvanus") %>% summarise(pophet=mean(heterozygosity)) %>%
    ggplot(aes(time, pophet, group=Scenario)) +
    stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
    stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
    ylab("Mean heterozygosity (%)") + xlab("Year") +
    scale_color_viridis_d() + theme_bw()
ggsave(paste0("heterozygosity_over_time_", experiment, ".pdf"), hetplot, width=6, height=4)

## precipitation tolerance over time
precoptplot = results %>% group_by(time, Scenario, replicate) %>%
    filter(lineage=="silvanus") %>% summarise(popprec=mean(precoptmean)) %>%
    ggplot(aes(time, popprec, group=Scenario)) +
    stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
    stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
    ylab("Mean AGC optimum") + xlab("Year") +
    scale_color_viridis_d() + theme_bw()
ggsave(paste0("precopt_over_time_", experiment, ".pdf"), precoptplot, width=6, height=4)

## precipitation tolerance over time
prectolplot = results %>% group_by(time, Scenario, replicate) %>%
    filter(lineage=="silvanus") %>% summarise(popprec=mean(prectolmean)) %>%
    ggplot(aes(time, popprec, group=Scenario)) +
    stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
    stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
    ylab("Mean AGC tolerance") + xlab("Year") +
    scale_color_viridis_d() + theme_bw()
ggsave(paste0("prectol_over_time_", experiment, ".pdf"), prectolplot, width=6, height=4)

## combine the above plots into a single gridded plot
gridplot = plot_grid(adultplot + theme(legend.position="none"),
                     ##c(.8, .65)), + theme(legend.position="none"),
                     hetplot + theme(legend.position="left"),
                     precoptplot + theme(legend.position="none"),
                     prectolplot + theme(legend.position="none"),
                     ncol=2, align="vh")
ggsave(paste0("hybridisation_over_time_", experiment, "_silvanus.pdf"), gridplot, width=7, height=5)
