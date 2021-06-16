#!/usr/bin/Rscript
### This is an analysis script for the island invasion model, specifically for
### the trait analyses (these were originally done by Ludwig, but his work was
### lost in the mists of time...).

## for plotting
library(ggplot2)
library(cowplot) ## arrange ggplots in a grid
library(ggsci) ## scientific color scales
## for Herberich test
library(multcomp)
library(multcompView)
library(sandwich)
## for LME
library(lme4)
library(lmerTest)
library(MuMIn)
## libraries for general data handling
library(tidyverse)
library(ggfortify)
library(reshape2)
library(Hmisc)

## To detach all packages if necessary, use:
## invisible(lapply(paste0('package:', names(sessionInfo()$otherPkgs)),
##                detach, character.only=TRUE, unload=TRUE))

datadir = "results_final" ## "results" by default

## Preferred output format
outformat = ".eps" ## default: ".jpg", for publication: ".eps"

## The minimum number of cells an alien species must be in to be considered invasive
invasiveThreshold = 2 ## default: 2

## D-Day and apocalypse
invasionstart = 500
worldend = 1500

## If individuals have not undergone establishment yet, the adaptation values are set to a
## default of 1, leading to "inverse" graph shapes. So, we calculate adaptation manually.
gauss = function(opt, tol, x) {
    a = 1 / (tol * sqrt(2 * pi))
    return(a * exp(-(x-opt)^2/(2*tol^2)))
}

## read and pre-process data
loadData = function(dir=datadir, saveData=TRUE, onlyworldend=TRUE) {
    popfiles = Sys.glob(paste0(dir, "/*/*tsv"))
    metrics = c("time", "x", "y", "temp", "prec", "area", "conf",
                "lineage", "adults", "maxage", "maxsize")
    results = tibble()
    for (filepath in popfiles) {
        nexttsv = read_tsv(filepath) %>% select(all_of(metrics), ends_with("med")) %>%
            mutate(Scenario=str_replace_all(conf, "^invasion\\d?_r\\d+_|\\.conf$", "")) %>%
            mutate(run=str_split(filepath, "/")[[1]][2], replicate=str_extract(run, "\\d_r\\d+")) %>%
            select(-ends_with("sdmed"), -conf)
        if (onlyworldend) nexttsv = nexttsv %>% filter(time == worldend)
        natives = nexttsv %>% filter(time == invasionstart) %>% pull(lineage) %>% unique
        nexttsv = nexttsv %>% filter(adults>0) %>%
            add_count(lineage) %>% rename(speciesrange=n) %>%
            mutate(adaptation=gauss(tempoptmed,temptolmed,temp)*gauss(precoptmed,prectolmed,prec),
                   ##XXX Status could probably be saved more neatly as a factor
                   Status=ifelse(lineage %in% natives, "a-native",
                          ifelse(speciesrange >= invasiveThreshold, "b-invasive", "c-alien")))
        results = bind_rows(results, nexttsv)
    }
    if (saveData) save(file="results.dat", results)
    return(results)
}

## Calculate how many alien species were introduced over the course
## of each experiment (global species pool size is 100).
## Note: requires `loadData()` to be run with `onlyworldend=FALSE`.
introducedSpecies = function(results) {
    results = results %>% filter(time >= invasionstart & Status != "a-native")
    intspec = tibble(run=unique(results$run),
                     species=rep(0, length(unique(results$run))),
                     proppressure=rep(0, length(unique(results$run))))
    for (i in 1:dim(intspec)[1]) {
        intspec[i, 2] = results %>% filter(run==as.character(intspec[i,1])) %>%
            pull(lineage) %>% unique %>% length
        intspec[i, 3] = as.character(intspec[i,1]) %>% str_extract("\\d+PP") %>%
            str_replace("PP", "") %>% as.numeric
    }
    return(intspec)
}

## create violin plots of trait value distributions for natives, aliens, and invasives
traitViolinPlots = function(results) {
    endresults = results %>%
        mutate(Status=factor(str_replace(Status, "^.{1}-", ""),
                             level=c("native", "invasive", "alien"))) %>%
        select(dispmeanmed, dispshapemed, prectolmed, temptolmed,
               repsizemed, seedsizemed, adaptation, Status) %>%
        rename("Mean dispersal distance"=dispmeanmed,
               "Long distance dispersal"=dispshapemed,
               "Precipitation tolerance"=prectolmed,
               "Temperature tolerance"=temptolmed,
               "Adult biomass"=repsizemed,
               "Seed biomass"=seedsizemed,
               "Adaptation"=adaptation) %>%
        melt(id.vars="Status")
    traitplot = endresults %>% ggplot(aes(Status, log(value+1))) +
        geom_violin(aes(fill=Status)) +
        geom_boxplot(fill="white", width=0.1) +
        facet_wrap(~variable, scales="free", ncol=3, strip.position="left") +
        ##scale_fill_viridis_d("Species category") +
        scale_fill_manual("Species category", values=c("#0D0887","#CC4678","#F0F921")) +
        ylab(NULL) + xlab(NULL) + theme_classic() +
        theme(strip.background=element_blank(),
              strip.placement="outside",
              legend.position=c(0.5, 0.15))
    ggsave(paste0("traits.pdf"), width=6, height=6)
    ##Note: panel letters and significance letters (from Herberich test) have to added manually!
}

#Herberich Tests for violin plots (code from Juliano)
herberichTests = function(results) {
    ##Herberich test across response variables
    Heteroaov=list()
    paircomp=list()
    ##List letters indication pairwise comparions, letters arranged by height of variance
    levels(as.factor(results$Status))
    divnames=c("a-native","b-invasive","c-alien")
    responses=c("dispmeanmed", "dispshapemed", "prectolmed", "temptolmed",
                "repsizemed", "seedsizemed", "adaptation")
    yAxisLabels=c("Mean dispersal distance", "Long distance dispersal",
                  "Temperature tolerance", "Precipitation tolerance",
                  "Adult biomass", "Seed biomass", "Adaptation")
    row.numbers=match(responses,names(results))
    for (i in 1:length(responses))
    {
        Histdata = cbind(results[,row.numbers[i]],as.factor(results$Status))
        colnames(Histdata) = c(responses[i],"Status")
        Histdata2 = as.data.frame(Histdata)
        Histdata2[,1] = as.numeric(as.character(Histdata2[,1]))
        aov = aov(log(Histdata2[,1]+1)~Status, data=Histdata2)
        Heteroaov[[i]] = glht(aov,mcp(Status="Tukey") , vcov=vcovHC)
        paircomp[[i]] = cld(Heteroaov[[i]], level = 0.05, decreasing = T)
        plot(Histdata2$Status,as.numeric(as.character(Histdata2[,1])),
             ylab=yAxisLabels[i], xlab="Species category")
    }
    return(paircomp) ##Lettering link non-significant differences with the same letters 
}

## calculate linear mixed models of trait differences between natives, aliens, and invasives
traitModels = function(results) {
    ## XXX This is ugly, but I haven't figured out how to loop it :-(
    sink("trait_models.txt") ## route output to file
    cat("\n --- Mean dispersal distance ---\n")
    mdispmod = lmer(log(dispmeanmed+1) ~ Status + (1 | run), results)
    print(coef(summary(mdispmod)))
    print(r.squaredGLMM(mdispmod))
    cat("\n --- Long-distance dispersal ---\n")
    ldispmod = lmer(log(dispshapemed+1) ~ Status + (1 | run), results)
    print(coef(summary(ldispmod)))
    print(r.squaredGLMM(ldispmod))
    cat("\n --- Precipitation tolerance ---\n")
    ptolmod = lmer(log(prectolmed+1) ~ Status + (1 | run), results)
    print(coef(summary(ptolmod)))
    print(r.squaredGLMM(ptolmod))
    cat("\n --- Temperature tolerance ---\n")
    ttolmod = lmer(log(temptolmed+1) ~ Status + (1 | run), results)
    print(coef(summary(ttolmod)))
    print(r.squaredGLMM(ttolmod))
    cat("\n --- Adult biomass ---\n")
    rsizemod = lmer(log(repsizemed+1) ~ Status + (1 | run), results)
    print(coef(summary(rsizemod)))
    print(r.squaredGLMM(rsizemod))
    cat("\n --- Seed biomass ---\n")
    ssizemod = lmer(log(seedsizemed+1) ~ Status + (1 | run), results)
    print(coef(summary(ssizemod)))
    print(r.squaredGLMM(ssizemod))
    cat("\n --- Adaptation ---\n")
    adaptmod = lmer(log(adaptation+1) ~ Status + (1 | run), results)
    print(coef(summary(adaptmod)))
    print(r.squaredGLMM(adaptmod))
    sink() ## return output to stdout
}
