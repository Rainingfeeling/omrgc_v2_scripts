# OM-GRC v2 ==============================================================================
# Code associated with the om-rgc v2 and tara prok metaT paper
# Figure 5: Metabolism ===================================================================

rm(list = ls())
if (basename(getwd()) != 'analysis'){
  setwd('analysis')
} 

# Libraries ------------------------------------------------------------------------------

library(vegan)
library(ggrepel)
library(data.table)
library(patchwork)
library(tidyverse)
library(cowplot)
source("../lib/Cell_Press_Guidelines.R")

# Variables ------------------------------------------------------------------------------

pval.correction<-"holm"


# Load & Transform data ------------------------------------------------------------------

metaG.norm.match.log2<-fread("../../data/OM-RGC_v2_functional_profile_KEGG/KO_metaG.norm.match.log2.tsv.gz",header=T,sep="\t",data.table = F)
rownames(metaG.norm.match.log2)<-metaG.norm.match.log2$V1
metaG.norm.match.log2<-metaG.norm.match.log2[,-1]

metaT.norm.match.log2<-fread("../../data/OM-RGC_v2_functional_profile_KEGG/KO_metaT.norm.match.log2.tsv.gz",header=T,sep="\t",data.table = F)
rownames(metaT.norm.match.log2)<-metaT.norm.match.log2$V1
metaT.norm.match.log2<-metaT.norm.match.log2[,-1]

ratio.mat<-fread("../../data/OM-RGC_v2_functional_profile_KEGG/KO_exp.norm.match.log2.tsv.gz",header=T,sep="\t",data.table = F)
rownames(ratio.mat)<-ratio.mat$V1
ratio.mat<-ratio.mat[,-1]

env.mat.match<-fread("../../data/OM-RGC_v2_auxiliary_data/OM-RGC_v2_auxiliary_data_matched.tsv",header=T,sep="\t",data.table = F,stringsAsFactors = T)
rownames(env.mat.match)<-env.mat.match$`PANGAEA sample id`
env.mat.match<-env.mat.match[,-1]

env.mat.match$epi<-env.mat.match$Layer
levels(env.mat.match$epi)<-c("EPI","MES","EPI","EPI")
env.mat.match<-env.mat.match[match(rownames(metaG.norm.match.log2),rownames(env.mat.match)),]
env.mat.match$date<-as.POSIXct(sapply(strsplit(as.character(env.mat.match$Event.date),"T"),"[[",1),format="%Y-%m-%d")

# Load selected marker genes
sel.genes<-read.table("../lib/kegg/Selection_Genes.txt",header=T,sep="\t")
sel.genes<-sel.genes[which(sel.genes$KO %in% colnames(metaG.norm.match.log2)),]
sel.genes<-sel.genes %>% separate(ko_description,"gene",sep=";",extra = "drop")
sel.genes$nom<-paste(sel.genes$KO,sel.genes$gene,sep=": ")

# Compute differential gene abundances and expression levels... --------------------------

fun<-function(x,env.var){
  res<-wilcox.test(x~env.var)
  tmp<-c(pval=res$p.value,mean.lev1=mean(x[env.var==levels(env.var)[1]]),mean.lev2=mean(x[env.var==levels(env.var)[2]]))
  names(tmp)<-c("pval",paste("mean",levels(env.var)[1],sep="."),paste("mean",levels(env.var)[2],sep="."))
  tmp
}

# EPI vs MESO #### 

# Gene abundance
res.ab<-as.data.frame(t(apply(metaG.norm.match.log2,2,fun,env.var=env.mat.match$epi)))
res.ab$pval.fdr<-p.adjust(res.ab$pval,method = pval.correction)
sign<-NULL
for (i in 1:nrow(res.ab)){
  if (is.na(res.ab[i,'pval.fdr'])) sign<-c(sign,"N.S.") else if (res.ab[i,'pval.fdr']<=0.05 & res.ab[i,'mean.EPI']>res.ab[i,'mean.MES']) sign<-c(sign,"EPI") else if (res.ab[i,'pval.fdr']<=0.05 & res.ab[i,'mean.EPI']<res.ab[i,'mean.MES']) sign<-c(sign,"MES") else if (res.ab[i,'pval.fdr']>0.05) sign<-c(sign,"N.S.")
}
res.ab$sign<-sign

# Gene expression
res.exp<-as.data.frame(t(apply(ratio.mat,2,fun,env.var=env.mat.match$epi)))
res.exp$pval.fdr<-p.adjust(res.exp$pval,method = pval.correction)
sign<-NULL
for (i in 1:nrow(res.exp)){
  if (is.na(res.exp[i,'pval.fdr'])) sign<-c(sign,"N.S.") else if (res.exp[i,'pval.fdr']<=0.05 & res.exp[i,'mean.EPI']>res.exp[i,'mean.MES']) sign<-c(sign,"EPI") else if (res.exp[i,'pval.fdr']<=0.05 & res.exp[i,'mean.EPI']<res.exp[i,'mean.MES']) sign<-c(sign,"MES") else if (res.exp[i,'pval.fdr']>0.05) sign<-c(sign,"N.S.")
}
res.exp$sign<-sign

# Transcript abundance
res.tra<-as.data.frame(t(apply(metaT.norm.match.log2,2,fun,env.var=env.mat.match$epi)))
res.tra$pval.fdr<-p.adjust(res.tra$pval,method = pval.correction)
sign<-NULL
for (i in 1:nrow(res.tra)){
  if (is.na(res.tra[i,'pval.fdr'])) sign<-c(sign,"N.S.") else if (res.tra[i,'pval.fdr']<=0.05 & res.tra[i,'mean.EPI']>res.tra[i,'mean.MES']) sign<-c(sign,"EPI") else if (res.tra[i,'pval.fdr']<=0.05 & res.tra[i,'mean.EPI']<res.tra[i,'mean.MES']) sign<-c(sign,"MES") else if (res.tra[i,'pval.fdr']>0.05) sign<-c(sign,"N.S.")
}
res.tra$sign<-sign

colnames(res.ab)<-paste("ab",colnames(res.ab),sep=".")
colnames(res.exp)<-paste("exp",colnames(res.exp),sep=".")
colnames(res.tra)<-paste("tra",colnames(res.tra),sep=".")

# Merge data
wilcox.df.epi.mes<-res.ab %>%
  rownames_to_column(var="OG") %>%
  bind_cols(res.exp) %>%
  bind_cols(res.tra) %>%
  mutate(ab.diff=ab.mean.EPI-ab.mean.MES,exp.diff=exp.mean.EPI-exp.mean.MES,tra.diff=tra.mean.EPI-tra.mean.MES) %>%
  left_join(sel.genes,by=c("OG"="KO")) %>%
  filter(!is.na(nom)) %>%
  filter(Metabolism %in% c("CARBON FIXATION","NITROGEN","PHOTOSYNTHESIS","SULFUR")) %>%
  mutate(Metabolism=fct_relevel(Metabolism,"CARBON FIXATION","PHOTOSYNTHESIS","NITROGEN","SULFUR"))

# POLAR VS NON-POLAR #### 

# Gene abundance
res.ab<-as.data.frame(t(apply(metaG.norm.match.log2,2,fun,env.var=env.mat.match$polar)))
res.ab$pval.fdr<-p.adjust(res.ab$pval,method = pval.correction)
sign<-NULL
for (i in 1:nrow(res.ab)){
  if (is.na(res.ab[i,'pval.fdr'])) sign<-c(sign,"N.S.") else if (res.ab[i,'pval.fdr']<=0.05 & res.ab[i,'mean.polar']>res.ab[i,'mean.non polar']) sign<-c(sign,"polar") else if (res.ab[i,'pval.fdr']<=0.05 & res.ab[i,'mean.polar']<res.ab[i,'mean.non polar']) sign<-c(sign,"non polar") else if (res.ab[i,'pval.fdr']>0.05) sign<-c(sign,"N.S.")
}
res.ab$sign<-sign

# Gene expression
res.exp<-as.data.frame(t(apply(ratio.mat,2,fun,env.var=env.mat.match$polar)))
res.exp$pval.fdr<-p.adjust(res.exp$pval,method = pval.correction)
sign<-NULL
for (i in 1:nrow(res.exp)){
  if (is.na(res.exp[i,'pval.fdr'])) sign<-c(sign,"N.S.") else if (res.exp[i,'pval.fdr']<=0.05 & res.exp[i,'mean.polar']>res.exp[i,'mean.non polar']) sign<-c(sign,"polar") else if (res.exp[i,'pval.fdr']<=0.05 & res.exp[i,'mean.polar']<res.exp[i,'mean.non polar']) sign<-c(sign,"non polar") else if (res.exp[i,'pval.fdr']>0.05) sign<-c(sign,"N.S.")
}
res.exp$sign<-sign

# Transcript abundance
res.tra<-as.data.frame(t(apply(metaT.norm.match.log2,2,fun,env.var=env.mat.match$polar)))
res.tra$pval.fdr<-p.adjust(res.tra$pval,method = pval.correction)
sign<-NULL
for (i in 1:nrow(res.tra)){
  if (is.na(res.tra[i,'pval.fdr'])) sign<-c(sign,"N.S.") else if (res.tra[i,'pval.fdr']<=0.05 & res.tra[i,'mean.polar']>res.tra[i,'mean.non polar']) sign<-c(sign,"polar") else if (res.tra[i,'pval.fdr']<=0.05 & res.tra[i,'mean.polar']<res.tra[i,'mean.non polar']) sign<-c(sign,"non polar") else if (res.tra[i,'pval.fdr']>0.05) sign<-c(sign,"N.S.")
}
res.tra$sign<-sign

colnames(res.ab)<-paste("ab",colnames(res.ab),sep=".")
colnames(res.exp)<-paste("exp",colnames(res.exp),sep=".")
colnames(res.tra)<-paste("tra",colnames(res.tra),sep=".")

# Merge data
wilcox.df.pol.nonpol<-res.ab %>%
  rownames_to_column(var="OG") %>%
  bind_cols(res.exp) %>%
  bind_cols(res.tra) %>%
  rename(ab.mean.non.polar="ab.mean.non polar",exp.mean.non.polar="exp.mean.non polar",tra.mean.non.polar="tra.mean.non polar") %>%
  mutate(ab.diff=ab.mean.polar-ab.mean.non.polar,exp.diff=exp.mean.polar-exp.mean.non.polar,tra.diff=tra.mean.polar-tra.mean.non.polar) %>%
  left_join(sel.genes,by=c("OG"="KO")) %>%
  filter(!is.na(nom)) %>%
  filter(Metabolism %in% c("CARBON FIXATION","NITROGEN","PHOTOSYNTHESIS","SULFUR")) %>%
  mutate(Metabolism=fct_relevel(Metabolism,"CARBON FIXATION","PHOTOSYNTHESIS","NITROGEN","SULFUR"))


# Plots. ---------------------------------------------------------------------------------

# EPI - MES
tmp1<-wilcox.df.epi.mes %>%
  select(KO=OG,Abundance=ab.diff,Expression=exp.diff,Transcription=tra.diff) %>%
  gather(key = "measure",value="difference",-KO)
tmp2<-wilcox.df.epi.mes %>%
  select(KO=OG,Abundance=ab.sign,Expression=exp.sign,Transcription=tra.sign) %>%
  gather(key = "measure",value="significance",-KO)
toplot_epi_mes<-left_join(tmp1,tmp2,by=c("KO","measure")) %>%
  left_join(sel.genes,by="KO") %>%
  mutate(measure=fct_recode(measure,"Transcript\nabundance"="Transcription","Gene\nabundance"="Abundance","Gene\nexpression"="Expression")) %>%
  mutate(measure=fct_relevel(measure,"Transcript\nabundance","Gene\nabundance","Gene\nexpression")) %>%
  mutate(nom=fct_relevel(nom,"K14138: acsB","K01895: ACSS, acs","K14534: abfD","K14470: mct","K03520: coxL, cutL","K03519: coxM, cutM","K03518: coxS","K01602: rbcS","K01601: rbcL","K00855: PRK, prkB","K01674: cah","K01673: cynT, can","K01672: CA","K09709: meh","K02588: nifH","K02586: nifD","K02591: nifK","K17877: NIT-6","K10535: hao","K10534: NR","K00372: nasA","K00367: narB","K00366: nirA","K10944: pmoA-amoA","K00371: narH, narY, nxrB","K00370: narG, narZ, nxrA","K03385: nrfA","K02567: napA","K15864: nirS","K04561: norB","K00376: nosZ","K00368: nirK","K08907: LHCA1","K08912: LHCB1","K05383: cpeT","K05376: cpeA, mpeA","K02284: cpcA","K02097: apcF","K02092: apcA","K08929: pufM","K02703: psbA","K02689: psaA","K02641: petH","K02638: petE","K02636: petC","K00957: cysD","K00956: cysN","K00381: cysI","K00380: cysJ","K00390: cysH","K12339: cysM","K01738: cysK","K00860: cysC","K00392: sir","K00387: SUOX","K00395: aprB","K00394: aprA","K00958: sat, met3"))

# POLAR - NONPOLAR
tmp1<-wilcox.df.pol.nonpol %>%
  select(KO=OG,Abundance=ab.diff,Expression=exp.diff,Transcription=tra.diff) %>%
  gather(key = "measure",value="difference",-KO)
tmp2<-wilcox.df.pol.nonpol %>%
  select(KO=OG,Abundance=ab.sign,Expression=exp.sign,Transcription=tra.sign) %>%
  gather(key = "measure",value="significance",-KO)
toplot_polar_nonpolar<-left_join(tmp1,tmp2,by=c("KO","measure")) %>%
  left_join(sel.genes,by="KO") %>%
  mutate(measure=fct_recode(measure,"Transcript\nabundance"="Transcription","Gene\nabundance"="Abundance","Gene\nexpression"="Expression")) %>%
  mutate(measure=fct_relevel(measure,"Transcript\nabundance","Gene\nabundance","Gene\nexpression")) %>%
  mutate(nom=fct_relevel(nom,"K14138: acsB","K01895: ACSS, acs","K14534: abfD","K14470: mct","K03520: coxL, cutL","K03519: coxM, cutM","K03518: coxS","K01602: rbcS","K01601: rbcL","K00855: PRK, prkB","K01674: cah","K01673: cynT, can","K01672: CA","K09709: meh","K02588: nifH","K02586: nifD","K02591: nifK","K17877: NIT-6","K10535: hao","K10534: NR","K00372: nasA","K00367: narB","K00366: nirA","K10944: pmoA-amoA","K00371: narH, narY, nxrB","K00370: narG, narZ, nxrA","K03385: nrfA","K02567: napA","K15864: nirS","K04561: norB","K00376: nosZ","K00368: nirK","K08907: LHCA1","K08912: LHCB1","K05383: cpeT","K05376: cpeA, mpeA","K02284: cpcA","K02097: apcF","K02092: apcA","K08929: pufM","K02703: psbA","K02689: psaA","K02641: petH","K02638: petE","K02636: petC","K00957: cysD","K00956: cysN","K00381: cysI","K00380: cysJ","K00390: cysH","K12339: cysM","K01738: cysK","K00860: cysC","K00392: sir","K00387: SUOX","K00395: aprB","K00394: aprA","K00958: sat, met3"))

g1<-ggplot(data=toplot_epi_mes,aes(x=nom,y=-difference,col=significance,xend=nom,yend=0)) +
  geom_hline(yintercept = 0) +
  geom_point(size=2) +
  geom_segment() +
  facet_grid(Metabolism~measure,scales = "free_y",space = "free_y") +
  coord_flip() +
  theme_bw() +
  ylab(paste("Difference between means (log2)")) +
  xlab(NULL) +
  theme(legend.position = "bottom",legend.direction = "vertical",strip.background.y = element_blank(),strip.text.y = element_blank(),axis.text=element_text(size=unit(8,"pt")),title = element_text(hjust = 0.5)) +
  scale_color_manual(values=c("#AB8B17","#81B0D2","#BEBEBE"),name="Significance") +
  labs(title="EPI vs. MES")

g2<-ggplot(data=toplot_polar_nonpolar,aes(x=nom,y=-difference,col=significance,xend=nom,yend=0)) +
  geom_hline(yintercept = 0) +
  geom_point(size=2) +
  geom_segment() +
  facet_grid(Metabolism~measure,scales = "free_y",space = "free_y") +
  coord_flip() +
  theme_bw() +
  ylab(expression("Difference between means (log2)")) +
  xlab(NULL) +
  theme(legend.position = "bottom",legend.direction = "vertical",axis.text.y = element_blank(),axis.text=element_text(size=unit(8,"pt")),title = element_text(hjust = 0.5)) +
  scale_color_manual(values=c("#BEBEBE","#F48B12","#1C6EAC"),name="Significance") +
  labs(title="POLAR vs. NON-POLAR")

g<-g1 | g2
ggsave(filename = "../../results/figures/Figure5.pdf",g,width=172,units = "mm",height=210)

