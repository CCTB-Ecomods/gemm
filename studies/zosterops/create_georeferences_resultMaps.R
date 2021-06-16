library(raster)


load("mapdata_tolerance_0.1.dat")
basemap <- raster("taita_agc_resampled.tif") #Petri's AGC basemap
plot(basemap)

rasres <- basemap #creates copy
rasres[rasres!=0] <- NA #make everything empty

mapdata2 <- as.data.frame(mapdata) #convert to dataframe (easier to handle for me)
for(i in 1:nrow(mapdata)){
  cellNo <- cellFromRowCol(rasres, mapdata2[i,2], mapdata2[i,1]) #reads out the position in the raster to put value in
  rasres[cellNo] <- mapdata2[i, 3] #puts value at the position
}
plot(rasres)

TH_patches <- shapefile("silvanus_habitat_patches.shp") #the Patch shape files

plot(TH_patches, add = TRUE) 
vals <- extract(rasres, TH_patches) #extracts values from each patch in a list

#output table
res <- data.frame(TH_patches$FRAG, unlist(lapply(vals, length)), unlist(lapply(vals, mean, na.rm = T)), unlist(lapply(vals, sd, na.rm = T)))
names(res) <- c("patch name","patch size [ha]", "mean", "sd")



##### compare different time layers
load("mapdata_tolerance0.1_t0_t90.dat")

basemap <- raster("taita_agc_resampled.tif")
plot(basemap)

rasres <- basemap
rasres[rasres==0] <- NA # makes the border values from the AGC dataset NA
rasres[rasres!=0] <- 0 # sets all info back to zero

rasres0 <- rasres #creates two empty rasters for later comparison 
rasres90 <- rasres #suffix "90" from t90 in the initial comparison

mapdata0 <- as.data.frame(mapdata0fl) #transform the t0 layer
mapdata90 <- as.data.frame(mapdata90fl) #transforms the t-whatever layer 

## for t0
for(i in 1:nrow(mapdata0)){ #IMPORTANT do a separate for loop for each layer (since information content varies between time steps)
  cellNo0 <- cellFromRowCol(rasres0, mapdata0[i,2], mapdata0[i,1])
  rasres0[cellNo0] <- mapdata0[i, 3]

}

## for t-whatever (dev'd with t90)
for(i in 1:nrow(mapdata90)){
  cellNo90 <- cellFromRowCol(rasres90, mapdata90[i,2], mapdata90[i,1])
  rasres90[cellNo90] <- mapdata90[i, 3]
}
#rasres0[rasres0==0] <- NA ##optional zum ausblenden der zellen mit CC = 0 zu t0
par(mfrow=c(1,2)) # plot both raster side-by-side
plot(rasres0)
plot(rasres90)

par(mfrow=c(1,1)) #plots a difference
plot(rasres90-rasres0)

# second version with custom color ramp
pal <- colorRampPalette(c("red","red", "deepskyblue", "deepskyblue", "black"))
plot(rasres90-rasres0, col = pal(20))

rasdiff<- rasres90-rasres0 #write delta raster

TH_patches <- shapefile("silvanus_habitat_patches.shp")

plot(TH_patches, add = TRUE, col = "darkgreen")
vals <- extract(rasdiff, TH_patches) #extract differences from the patches

# summarizes patch-specific results (here with median over mean to reduce potential skewnesses)
res <- data.frame(TH_patches$FRAG, unlist(lapply(vals, length)), unlist(lapply(vals, median, na.rm = T)), unlist(lapply(vals, sd, na.rm = T)))
names(res) <- c("patch name","patch size [ha]", "median", "sd")
