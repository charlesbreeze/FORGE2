#!/bin/env Rscript

args <- commandArgs(TRUE)
if (length(args) != 1) {
    cat( "Usage:  heatmap.R  filename\n" )
            quit('no', 1, FALSE)
	            }

filename <- as.character( args[1] )

library(pheatmap)

library(RColorBrewer)

breaksList = seq(1.25,6.5, by = 0.01)
#1.25

df=read.table(file = filename,header = TRUE,sep="\t",row.names=1)

#df

pdf("./heatmap.pdf",width=42,height=102) #for erc2,enc,bp use 22,22, for erc use 22,42, chrst 42,102
pheatmap(-log(df),scale="column",cluster_cols=TRUE,cluster_rows=FALSE,color = colorRampPalette((brewer.pal(n = 7, name = "Reds")))(length(breaksList)),breaks = breaksList)
dev.off()


