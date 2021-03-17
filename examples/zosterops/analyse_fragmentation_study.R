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
library(Hmisc)
library(xtable)

datadir = "results" ## "results" by default
experiment = "tolerance" ## "tolerance", "habitat", "mutation", "linkage"
popfiles = Sys.glob(paste0(datadir, "/*", experiment, "*/*tsv"))
worldend = 300     ## apocalypse...
## On that note: is it ethical to terminate virtual organisms in a mass-extinction
## at the end of an experiment, or should they not rather be released back into the wild?


## read and pre-process data
loadData = function(files=popfiles, saveData=TRUE) {
    metrics = c("time", "x", "y", "prec", "capacity", "replicate", "conf",
                "lineage", "adults", "heterozygosity", "precadaptationmean",
                "dispmeanmean", "dispmeanstd", "dispshapemean", "dispshapestd",
                "precoptmean", "precoptstd", "prectolmean", "prectolstd",
                "tempoptmean", "temptolmean", "repsizemean")
    results = tibble()
    for (filepath in files) {
        nexttsv = read_tsv(filepath) %>% select(all_of(metrics)) %>%
            mutate(Scenario=str_replace(conf, "_\\d+\\.config", "")) %>%
            select(-conf)
        results = bind_rows(results, nexttsv)
    }
    if (saveData) save(file=paste0("results_", experiment, ".dat"), results)
    return(results)
}

## population sizes over time
adultplot = function(results, species="silvanus") {
    ##globalcapacity = results %>% filter(time==0, Scenario=="tol0") %>% select(capacity) %>% sum()
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage==any_of(species)) %>% summarise(popsize=sum(adults)) %>%
        ggplot(aes(time, popsize, group=Scenario)) + #ylim(c(0,80000)) +
        ##geom_hline(aes(yintercept=globalcapacity), linetype=2, color="grey", size=0.5) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        ylab("Number of adults") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## heterozygosity over time
hetplot = function(results, species="silvanus") {
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage==any_of(species)) %>% summarise(pophet=mean(heterozygosity)) %>%
        ggplot(aes(time, pophet, group=Scenario)) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        ylab("Mean heterozygosity (%)") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## precipitation tolerance over time
precoptplot = function(results, species="silvanus") {
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage==any_of(species)) %>% summarise(popprec=mean(precoptmean)) %>%
        ggplot(aes(time, popprec, group=Scenario)) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        ylab("Mean AGC optimum") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## precipitation tolerance over time
prectolplot = function(results, species="silvanus") {
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage==any_of(species)) %>% summarise(popprec=mean(prectolmean)) %>%
        ggplot(aes(time, popprec, group=Scenario)) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        ylab("Mean AGC tolerance") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## heterozygosity over space
hetmap = function(results) {
    ##TODO
}

## population size over space
popmap = function(results, scenario, species=c("silvanus", "jubaensis"), plot=TRUE) {
    popmap = results %>% filter(time==worldend) %>% filter(Scenario==scenario) %>%
        filter(lineage %in% species) %>% select(x, y, replicate, adults) %>%
        group_by(x, y) %>% summarise(avgpop=mean(adults)) %>%
        ggplot(aes(x, y, fill=avgpop)) +
        geom_raster(interpolate=TRUE) +
        scale_fill_gradient(low="white", high="purple", guide="none") +
        scale_y_reverse() +
        theme_void()
    if (plot) { ggsave(paste0("population_map_", scenario, ".pdf"), width=5, height=5) }
    else { return(popmap) }
}

## trait shift after time
traitplot = function(results, species="silvanus") {
    ##TODO
    filteredresults = results %>% filter((time==0 | time==worldend) & lineage==species) %>%
        mutate(Scenario=as.factor(Scenario)) %>% group_by(time, Scenario, replicate) %>%
        summarise(precopt=mean(precoptmean), prectol=mean(prectolmean),
                  ##repsize=mean(repsizemean),tempopt=mean(tempoptmean),temptol=mean(temptolmean),
                  dispmeans=mean(dispmeanmean), dispshape=mean(dispshapemean)) %>%
        select(-ends_with("mean"))
    inittraits = filteredresults %>% filter(time==0)
    endtraits = filteredresults %>% filter(time==worldend)
    endresults = as_tibble(cbind(Scenario=as.character(endtraits$Scenario),
                                 precopt=endtraits$precopt-inittraits$precopt,
                                 prectol=endtraits$prectol-inittraits$prectol,
                                 dispmean=endtraits$dispmeans-inittraits$dispmeans,
                                 dispshape=endtraits$dispshape-inittraits$dispshape))

    ## <<< WORKS UP TO HERE >>>
    
    traitnames = endtraits %>% select(ends_with("diff")) %>% names() %>% str_replace("diff", "")

    traitresponses = endtraits %>%
        ggplot(aes(traitnames, endtraits[traitnames], fill = ifelse(Estimate > 0, "1", "-1"))) +
        geom_hline(yintercept = 0, linetype = "dashed", color = "grey", size = 1) +
        geom_bar(stat = "identity", width = 0.5, position = "dodge") +
        geom_errorbar(aes(ymin = Estimate - `Std. Error`, ymax = Estimate + `Std. Error`),
                      position = position_dodge(.5), width = 0) +
        scale_y_continuous(limits = c(min(lme_table[,"Estimate"] - lme_table[,"Std. Error"]),
                                      max(lme_table[,"Estimate"] + lme_table[,"Std. Error"]) + 0.01)) +
        xlab("") + ylab("Difference in means between scenarios") + coord_flip() +
        facet_grid(traitnames) +
        scale_fill_npg(guide = FALSE)
    ggsave(paste0("diffs_means_", dispmode, "_nolinkage.pdf"), width = 5, height = 5)
}

## Plot each graph as an individual file
plotSingle = function(results, species="silvanus") {
    ggsave(paste0("adults_over_time_", experiment, "_", species, ".pdf"),
           adultplot(results, species), width=6, height=4)
    ggsave(paste0("heterozygosity_over_time_", experiment, "_", species, ".pdf"),
           hetplot(results,species), width=6, height=4)
    ggsave(paste0("precopt_over_time_", experiment, "_", species, ".pdf"),
           precoptplot(results,species), width=6, height=4)
    ggsave(paste0("prectol_over_time_", experiment, "_", species, ".pdf"),
           prectolplot(results,species), width=6, height=4)
}

## Combine the above plots into a single gridded plot
plotGrid = function(results, species="silvanus") {
    gridplot = plot_grid(adultplot(results, species) + theme(legend.position="none"),
              hetplot(results, species) + theme(legend.position="left"),
              precoptplot(results, species) + theme(legend.position="none"),
              prectolplot(results, species) + theme(legend.position="none"),
              ncol=2, align="vh")
    ggsave(paste0("hybridisation_over_time_", experiment, "_", species, ".pdf"),
           gridplot, width=7, height=5)
}
