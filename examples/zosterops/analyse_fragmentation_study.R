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

autorun = FALSE ## automatically run all analyses?

datadir = "results" ## "results" by default
experiment = "tolerance" ## "tolerance", "habitat", "mutation", "linkage"
worldend = 300     ## apocalypse...
## On that note: is it ethical to terminate virtual organisms in a mass-extinction
## at the end of an experiment, or should they not rather be released back into the wild?

defaultspecies = "silvanus"

## read and pre-process data
loadData = function(exp=experiment, saveData=TRUE) {
    popfiles = Sys.glob(paste0(datadir, "/*", exp, "_*/*tsv"))
    metrics = c("time", "x", "y", "prec", "capacity", "replicate", "conf",
                "lineage", "adults", "heterozygosity", "precadaptationmean",
                "dispmeanmean", "dispmeanstd", "dispshapemean", "dispshapestd",
                "precoptmean", "precoptstd", "prectolmean", "prectolstd",
                "tempoptmean", "temptolmean", "repsizemean")
    results = tibble()
    for (filepath in popfiles) {
        nexttsv = read_tsv(filepath) %>% select(all_of(metrics)) %>%
            mutate(Scenario=str_replace(conf, "_\\d+\\.config", "")) %>%
            select(-conf)
        results = bind_rows(results, nexttsv)
    }
    if (saveData) save(file=paste0("results_", experiment, ".dat"), results)
    return(results)
}


### INDIVIDUAL PLOTS

## population sizes over time
adultplot = function(results, species=defaultspecies) {
    ##globalcapacity = results %>% filter(time==0, Scenario=="tol0") %>% select(capacity) %>% sum()
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage %in% species) %>% summarise(popsize=sum(adults)) %>%
        mutate(Scenario=str_replace(Scenario, paste0("^", experiment, "_"), "")) %>%
        ggplot(aes(time, popsize, group=Scenario)) + #ylim(c(0,80000)) +
        ##geom_hline(aes(yintercept=globalcapacity), linetype=2, color="grey", size=0.5) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        ylab("Number of adults") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## heterozygosity over time
hetplot = function(results, species=defaultspecies) {
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage %in% species) %>% summarise(pophet=mean(heterozygosity)) %>%
        mutate(Scenario=str_replace(Scenario, paste0("^", experiment, "_"), "")) %>%
        ggplot(aes(time, pophet, group=Scenario)) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        ylab("Mean heterozygosity (%)") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## precipitation tolerance over time
precoptplot = function(results, species=defaultspecies) {
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage %in% species) %>% summarise(popprec=mean(precoptmean)) %>%
        mutate(Scenario=str_replace(Scenario, paste0("^", experiment, "_"), "")) %>%
        ggplot(aes(time, popprec, group=Scenario)) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        geom_hline(aes(color="lightgrey"), yintercept=90, linetype=2) +
        ylab("Mean AGC optimum") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## precipitation tolerance over time
prectolplot = function(results, species=defaultspecies) {
    results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage %in% species) %>% summarise(popprec=mean(prectolmean)) %>%
        mutate(Scenario=str_replace(Scenario, paste0("^", experiment, "_"), "")) %>%
        ggplot(aes(time, popprec, group=Scenario)) +
        stat_summary(aes(color=Scenario), fun.y = mean, geom="line", size=1) +
        stat_summary(fun.data=mean_cl_boot, geom="ribbon", alpha=0.1) +
        ylab("Mean AGC tolerance") + xlab("Year") +
        scale_color_viridis_d() + theme_bw() %>%
        return()
}

## heterozygosity over space
hetmap = function(results, scenario, species=defaultspecies, date=worldend,  plot=TRUE) {
    hetplot = results %>% filter(time==date) %>% filter(Scenario==scenario) %>%
        filter(lineage %in% species) %>% select(x, y, replicate, heterozygosity) %>%
        group_by(x, y) %>% summarise(avghet=mean(heterozygosity)) %>%
        ggplot(aes(x, y, fill=avghet)) +
        geom_raster(interpolate=TRUE) +
        scale_fill_gradient(low="lightgrey", high="darkred", guide="none") +
        scale_y_reverse() + theme_void() +
        theme(panel.border=element_rect(size=1, linetype="solid"))
    if (plot) {
        ggsave(paste0("heterozygosity_map_", scenario, "_", species, ".pdf"),
               hetplot, width=5, height=5)
    }
    else { return(hetplot) }
}

## population size over space
popmap = function(results, scenario, species=defaultspecies, date=worldend, plot=TRUE) {
    popplot = results %>% filter(time==date) %>% filter(Scenario==scenario) %>%
        filter(lineage %in% species) %>% select(x, y, replicate, adults) %>%
        group_by(x, y) %>% summarise(avgpop=mean(adults)) %>%
        ggplot(aes(x, y, fill=avgpop)) +
        geom_raster(interpolate=TRUE) +
        scale_fill_gradient(low="lightgrey", high="purple", guide="none") +
        scale_y_reverse() + theme_void() +
        theme(panel.border=element_rect(size=1, linetype="solid"))
    if (plot) {
        ggsave(paste0("population_map_", scenario, "_", species, ".pdf"),
               popplot, width=5, height=5)
    }
    else { return(popplot) }
}

## trait shift after time
traitplot = function(results, species=defaultspecies) {
    filteredresults = results %>% filter((time==0 | time==worldend) & lineage==species) %>%
        mutate(Scenario=as.factor(Scenario)) %>% group_by(time, Scenario, replicate) %>%
        summarise(precopt=mean(precoptmean), prectol=mean(prectolmean),
                  repsize=mean(repsizemean),#tempopt=mean(tempoptmean),temptol=mean(temptolmean),
                  dispmeans=mean(dispmeanmean), dispshape=mean(dispshapemean)) %>%
        select(-ends_with("mean"))
    inittraits = filteredresults %>% filter(time==0)
    endtraits = filteredresults %>% filter(time==worldend)
    endresults = as_tibble(cbind(Scenario=as.character(endtraits$Scenario),
                                 precopt=endtraits$precopt-inittraits$precopt,
                                 prectol=endtraits$prectol-inittraits$prectol,
                                 ##tempopt=endtraits$tempopt-inittraits$tempopt,
                                 ##temptol=endtraits$temptol-inittraits$temptol,
                                 dispmean=endtraits$dispmeans-inittraits$dispmeans,
                                 dispshape=endtraits$dispshape-inittraits$dispshape)) %>%
        mutate(Scenario=str_replace(Scenario, paste0("^", experiment, "_"), ""),
               precopt=as.numeric(precopt), prectol=as.numeric(prectol),
               dispmean=as.numeric(dispmean), dispshape=as.numeric(dispshape)) %>%
               ##tempopt=as.numeric(tempopt), temptol=as.numeric(temptol)) %>%
        melt(id.vars=c("Scenario"), variable.name="Trait")

    traitresponses = endresults %>% 
        ggplot(aes(Scenario, value)) +
        geom_hline(yintercept = 0, linetype = "dashed", color = "grey", size = 1) +
        geom_boxplot(aes(fill=Trait)) +
        facet_wrap(~Trait, scales="free", ncol=2) +
        xlab("") + ylab(paste("Shift in population trait means after", worldend, "years")) +
        coord_flip() + scale_fill_npg(guide="none")
    ggsave(paste0("trait_means_", experiment, "_", species, ".pdf"), width = 6, height = 5)
}

## boxplot of population growths after simulation end
growthplot = function(results, species=defaultspecies, endtime=worldend) {
    ## Calculate population sizes at the start and end of each run
    filteredresults = results %>% group_by(time, Scenario, replicate) %>%
        filter(lineage %in% species) %>% summarise(popsize=sum(adults))
    initpops = filteredresults %>% filter(time==0)
    endpops = filteredresults %>% filter(time==endtime)
    endresults = as_tibble(cbind(Scenario=as.character(initpops$Scenario),
                                 popgrowth=initpops$popsize)) %>%
        mutate(Scenario=str_replace(Scenario, paste0("^", experiment, "_"), ""),
               popgrowth=as.numeric(popgrowth))
    ## Calculate the population difference (i.e. growth), keeping in mind that
    ## due to extinctions not all runs present in initpops are also present in endpops
    print(paste(dim(initpops)[1]-dim(endpops)[1], "extinctions"))
    i = 1
    j = 1
    while (i <= dim(initpops)[1]) {
        if ((j <= dim(endpops)[1]) && (initpops[i,]$Scenario == endpops[j,]$Scenario) &&
            (initpops[i,]$replicate == endpops[j,]$replicate)) {
            endresults[i,]$popgrowth = endpops[j,]$popsize - initpops[i,]$popsize
            i = i+1
            j = j+1
        }
        else {
            endresults[i,]$popgrowth = 0 - initpops[i,]$popsize
            i = i+1
        }
    }

    ## Plot the effective growth as violin/boxplot
    effects = endresults %>% ggplot(aes(Scenario, popgrowth)) +
        geom_violin(aes(fill=Scenario)) +
        geom_boxplot(fill="white", width=0.1) +
        ylab(paste0("Population growth after ", endtime, " years")) + xlab(experiment) +
        scale_fill_viridis_d(guide="none") + theme_bw()
    ggsave(paste0("population_growth_", experiment, "_", species, ".pdf"), width=5, height=5)
}


### GROUP PLOTS

## Plot each time graph as an individual file
plotSingle = function(results, species=defaultspecies) {
    ggsave(paste0("adults_over_time_", experiment, "_", species, ".pdf"),
           adultplot(results, species), width=6, height=4)
    ggsave(paste0("heterozygosity_over_time_", experiment, "_", species, ".pdf"),
           hetplot(results,species), width=6, height=4)
    ggsave(paste0("precopt_over_time_", experiment, "_", species, ".pdf"),
           precoptplot(results,species), width=6, height=4)
    ggsave(paste0("prectol_over_time_", experiment, "_", species, ".pdf"),
           prectolplot(results,species), width=6, height=4)
}

## Combine the time plots into a single gridded plot
plotGrid = function(results, species=defaultspecies) {
    gridplot = plot_grid(adultplot(results, species) + theme(legend.position="none"),
              hetplot(results, species) + theme(legend.position="left"),
              precoptplot(results, species) + theme(legend.position="none"),
              prectolplot(results, species) + theme(legend.position="none"),
              ncol=2, align="vh", labels="auto")
    ggsave(paste0("hybridisation_over_time_", experiment, "_", species, ".pdf"),
           gridplot, width=7, height=5)
}

## Plot population density and heterozygosity maps for all scenarios
plotMaps = function(results, species=defaultspecies, date=worldend) {
    scenarios = unique(results$Scenario)
    for (s in scenarios) {
        popmap(results, s, species)
        hetmap(results, s, species)
    }
}

## Plot a grid of population & heterozygosity maps of the four specified scenarios
## scen1-4: names of scenarios to plot; metric: "population" or "heterozygosity"
plotMapGrid = function(results, scen1, scen2, scen3, scen4, metric, spec=defaultspecies) {
    if (metric == "population") { func = popmap }
    else if (metric == "heterozygosity") { func = hetmap }
    gridplot = plot_grid(func(results, scen1, spec, plot=FALSE) + theme(legend.position="none"),
                         func(results, scen2, spec, plot=FALSE) + theme(legend.position="none"),
                         func(results, scen3, spec, plot=FALSE) + theme(legend.position="none"),
                         func(results, scen4, spec, plot=FALSE) + theme(legend.position="none"),
              ncol=2, align="vh", labels="auto")
    ggsave(paste0(metric, "_over_space_", experiment, "_", spec, ".pdf"),
           gridplot, width=5, height=5)    
}

## Plot a grid of population & heterozygosity maps of the two specified time steps
## scen: name of scenario; t1-4: timesteps to plot; metric: "population" or "heterozygosity"
plotMapTimeseries = function(results, scen, t1, t2, t3, t4, metric, spec=defaultspecies) {
    if (metric == "population") { func = popmap }
    else if (metric == "heterozygosity") { func = hetmap }
    gridplot = plot_grid(func(results, scen, spec, t1, plot=FALSE) + theme(legend.position="none"),
                         func(results, scen, spec, t2, plot=FALSE) + theme(legend.position="none"),
                         func(results, scen, spec, t3, plot=FALSE) + theme(legend.position="none"),
                         func(results, scen, spec, t4, plot=FALSE) + theme(legend.position="none"),
              ncol=2, align="vh", labels=c(t1, t2, t3, t4))
    ggsave(paste0(metric, "_over_space_timeseries_", scen, "_", spec, ".pdf"),
           gridplot, width=5, height=5)    
}

## Summary function to plot everything
plotAll = function(results, species=defaultspecies) {
    plotSingle(results, species)
    plotGrid(results, species)
    ##plotMaps(results, species)
    traitplot(results, species)
    growthplot(results, species)
    if ("tolerance" %in% experiment) {
        plotMapGrid(results, paste0(experiment, "_0"),
                    paste0(experiment, "_0.01"),
                    paste0(experiment, "_0.1"),
                    paste0(experiment, "_1.0"),
                    "population", species)
        plotMapGrid(results, paste0(experiment, "_0"),
                    paste0(experiment, "_0.01"),
                    paste0(experiment, "_0.1"),
                    paste0(experiment, "_1.0"),
                    "heterozygosity", species)
    }
    else if ("habitat" %in% experiment) {
        plotMapGrid(results, paste0(experiment, "_edgedepletion"),
                    paste0(experiment, "_patchclearing"),
                    paste0(experiment, "_corridors"),
                    paste0(experiment, "_plantations"),
                    "population", species)
        plotMapGrid(results, paste0(experiment, "_edgedepletion"),
                    paste0(experiment, "_patchclearing"),
                    paste0(experiment, "_corridors"),
                    paste0(experiment, "_plantations"),
                    "heterozygosity", species)
    }
    if (species=="silvanus") { plotGrid(results, "flavilateralis") }
}

## If autorun is set, run the experiment specified via commandline argument
if (autorun) {
    arg = commandArgs()[length(commandArgs())]
    if (arg %in% c("tolerance", "habitat", "mutation", "linkage")) {
        experiment = arg
    }
    results = loadData(experiment)
    plotAll(results)
}
