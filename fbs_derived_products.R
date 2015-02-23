## Create tables describing the intended relationship between FAOSTAT
##  Food Balance Sheet (FBS) items.
## The 'Processing' FBS element is intended to show the quantity of 
##  the food item that is listed as a derived/manufactured product
##  Using both Processing and Food elements can therefore result in
##  double-counting if relationships between items are not taken into
##  account.
## 
## Two sources are used:
##  1. The Food Balance Sheet classification
##     http://faostat3.fao.org/mes/classifications/E
##     This document lists the commodities that make up each food item
##  2. The Definition and Classification of Commodities
##     http://www.fao.org/es/faodef/faodefe.htm
##     This document describes primary agricultural commodities and their 
##     derived, processed products.

#######################################################
## Prepare Food Balance Sheet classification
## data.frame 'fbs.classification'

# Load downloaded Food Balance Sheet classification
x=read.csv2("food balance sheet classification 5fbefbcc-a1a3-46a5-be03-d4699ab517d7.csv",stringsAsFactors=FALSE)

fbs.classification=do.call(rbind,apply(x,1,function(x) {
  # Parse third column of table
  components=x[[3]]
  # Remove text
  components=gsub("Default composition: ","",components)
  components=gsub("; nutrient data only:",",",components) #TODO: keep this information
  # Split the list of commodities
  components=strsplit(components,", {0,1}(?=\\d)",perl=TRUE)[[1]]
  if(length(components)==0) components=NA
  # Create row of table
  data.frame(IncludedInCode=x[[1]],
             IncludedInName=x[[2]],
             ProductName=components,stringsAsFactors=FALSE)
}))
fbs.classification$ProductCode<-as.numeric(gsub(" .*","",fbs.classification$ProductName))
## Add placeholder column
fbs.classification$DerivedCode<-NA

# Remove NAs - population and miscellaneous
#fbs.classification[is.na(fbs.classification$ProductCode),]
fbs.classification<-fbs.classification[!is.na(fbs.classification$ProductCode),]

# View the resulting table 
#View(fbs.classification[order(fbs.classification$ProductCode),])
#View(fbs.classification[order(fbs.classification$IncludedInCode),])


#######################################################
## Prepare table of relationships between commodities
## data.frame 'derived'
library(XML)

# Table of format
# PRIMARY1
# Secondary
# PRIMARY2
# Seconday
parseSubheadings<-function(tt){
  names(tt)<-c("FAOSTATCODE","COMMODITY","DEFINITION")
  first.word=sapply(strsplit(tt$COMMODITY,"[^\\w]",perl=TRUE),head,n=1)
  is.primary=first.word==toupper(first.word)
  tt$DerivedCode<-NA
  for(i in 1:length(is.primary)){
    if(is.primary[i]) {
      tt$DerivedCode[i]=0
      primary=as.numeric(tt[i,1])
    } else {
      tt$DerivedCode[i]=primary
    }
  }
  tt
}

# Table with no clear relationship
# - just parse whether or not commodity is primary
parseCase<-function(tt){
  names(tt)<-c("FAOSTATCODE","COMMODITY","DEFINITION")
  first.word=sapply(strsplit(tt$COMMODITY,"[^\\w]",perl=TRUE),head,n=1)
  is.primary=first.word==toupper(first.word)
  tt$DerivedCode<-NA
  tt$DerivedCode[is.primary]<-0
  tt$DerivedCode[!is.primary]<- -1
  tt
}


derived=NULL

# URLS WHERE PROCESSED PRODUCTS ARE GROUPED UNDER THE PRIMARY PRODUCT
urls=c(
  # Cereals
  # "Each cereal product is listed after the cereal from which it is derived."
  "http://www.fao.org/es/faodef/fdef01e.htm",
  # ROOTS AND TUBERS AND DERIVED PRODUCTS
  # The processed products of roots and tubers are listed together with their parent primary crops.
  "http://www.fao.org/es/faodef/fdef02e.htm",
  # SUGAR TODO
  "http://www.fao.org/es/faodef/fdef03e.htm",
  # OIL-BEARING CROPS AND DERIVED PRODUCTS
  #  FAO lists 21 primary oil crops. The code and name of each crop appears in the list that follows, along with its botanical name, or names, and a short description where necessary.
  #  PRODUCTS DERIVED FROM OIL CROPS. Edible processed products from oil crops, other than oil, include flour, flakes or grits, groundnut preparations (butter, salted nuts, candy), preserved olives, desiccated coconut and fermented and non-fermented soya products. 
  "http://www.fao.org/es/faodef/fdef06e.htm"
)
for(u in urls){
  tables=readHTMLTable(u,stringsAsFactors=FALSE,header=TRUE)
  tables=lapply(tables,function(tt){
    names(tt)<-c("FAOSTATCODE","COMMODITY","DEFINITION")
    tt$DerivedCode=as.numeric(tt$FAOSTATCODE[1])
    tt$DerivedCode[1]=0
    tt
  })
  tables=do.call(rbind,tables)
  derived=rbind(derived,tables)
}

## Subheadings
urls=c(
  # 5. NUT PRODUCTS include shelled nuts, whole or split, and further processed products, including roasted nuts, meal/flour, paste, oil, etc.
  #Nut oils are not separately identified in the FAO classification; instead they are included under the heading "oil of vegetable origin nes" (see Chapter .).
  "http://www.fao.org/es/faodef/fdef05e.htm",
  # 7. Veges
  "http://www.fao.org/es/faodef/fdef07e.htm",
  # 8. Fruit
  "http://www.fao.org/es/faodef/fdef08e.htm",
  # 9. Fibres
  "http://www.fao.org/es/faodef/fdef09e.htm",
  # 10. Spices,
  "http://www.fao.org/es/faodef/fdef10e.htm",
  ## 12. Stimulants FIXME - Tea and Mate
  "http://www.fao.org/es/faodef/fdef12e.htm",
  ## 16. Livestock - dummy: all primary
  "http://www.fao.org/es/faodef/fdef16e.htm",
  ## 17. Slaughtered animals
  ## The codes and names of all livestock products _ with primary in uppercase letters and processed in upper and lower case letters _ are shownin the list that follows, along with any accompanying remarks.
  "http://www.fao.org/es/faodef/fdef17e.htm",
  # 18. Products from Live animals
  "http://www.fao.org/es/faodef/fdef18e.htm"
  )
for(u in urls){
  tables=readHTMLTable(u,stringsAsFactors=FALSE,header=TRUE)
  if(u=="http://www.fao.org/es/faodef/fdef17e.htm") {
    derived<-rbind(derived,parseCase(tables[[4]]))
    derived<-rbind(derived,parseCase(tables[[5]]))
    derived<-rbind(derived,parseCase(tables[[6]]))
    tables=tables[1:3]
  }
  tables=lapply(tables,parseSubheadings)
  if(u=="http://www.fao.org/es/faodef/fdef05e.htm")
    tables[[1]][16,4]<- -1 #Prepared nuts is not necessarily NUTS NES?
  ## Extra column for beeswax
  if(u=="http://www.fao.org/es/faodef/fdef18e.htm")  tables[[9]][,4]<-NULL
  tables=do.call(rbind,tables)
  rownames(tables)=NULL
  #View(tables[,c(1,2,4)])
  derived=rbind(derived,tables)
}

# 4. PULSES AND DERIVED PRODUCTS
# Only two processed products are included in the FAO list, namely flour of pulses and bran of pulses. 
tables=readHTMLTable("http://www.fao.org/es/faodef/fdef04e.htm",stringsAsFactors=FALSE,header=TRUE)
tables=lapply(tables,parseCase)
tables=do.call(rbind,tables)
rownames(tables)=NULL
derived=rbind(derived,tables)



## Beverages
## All derived, not primary
## http://www.fao.org/es/faodef/fdef15e.htm

## Add DerivedCode to fbs.classification
fbs.classification$DerivedCode<-NA
idx=match(as.numeric(derived$FAOSTATCODE),fbs.classification$ProductCode)
#as.numeric(derived$FAOSTATCODE)[is.na(idx)]
fbs.classification$DerivedCode[idx[!is.na(idx)]]=derived$DerivedCode[!is.na(idx)]

# Which are still NA?
table(is.na(fbs.classification$DerivedCode))
head(fbs.classification$ProductName[is.na(fbs.classification$DerivedCode)])


####################################################
## Summarise to food balance sheet codes
## data.frame 'fbs.processed'

## Convert DerivedCode to DerivedIncludedInCode
idx=match(as.numeric(fbs.classification$DerivedCode),as.numeric(fbs.classification$ProductCode))
fbs.classification$DerivedIncludedInCode<-NA
fbs.classification$DerivedIncludedInCode[!is.na(idx)] <- fbs.classification$IncludedInCode[idx[!is.na(idx)]]

fbs.processed=split(fbs.classification,fbs.classification$IncludedInCode)
fbs.processed=lapply(fbs.processed,function(x) {
  code=unique(x$IncludedInCode)
  DerivedIncludedInCode=na.omit(unique(x$DerivedIncludedInCode))
  FoodInclProcessed=NA
  if(all(!is.na(x$DerivedCode)) && all(x$DerivedCode>=0)) FoodInclProcessed=FALSE
  if(length(DerivedIncludedInCode)>0 && code %in% DerivedIncludedInCode) FoodInclProcessed=TRUE
  DerivedIncludedInCode=setdiff(DerivedIncludedInCode,code)
  ProcessedAppearsIn=fbs.classification$IncludedInCode[fbs.classification$DerivedIncludedInCode==code]
  ProcessedAppearsIn=setdiff(na.omit(unique(ProcessedAppearsIn)),code)
  IncludedNames=sort(x$ProductName)
  data.frame(IncludedInCode=code,
             IncludedInName=unique(x$IncludedInName),
             IncludedNames=paste(IncludedNames,collapse=", "),
             FoodInclProcessed=FoodInclProcessed,
             DependsOnCode=paste(DerivedIncludedInCode,collapse=", "),
             ProcessedAppearsInCode=paste(ProcessedAppearsIn,collapse=", "),
             stringsAsFactors=FALSE
  )
})
fbs.processed=do.call(rbind,fbs.processed)
idx=match(fbs.processed$DependsOnCode,fbs.processed$IncludedInCode)
fbs.processed$DependsOnName<-NA
fbs.processed$DependsOnName[!is.na(idx)]=as.character(fbs.processed$IncludedInName[idx[!is.na(idx)]])
idx=match(fbs.processed$ProcessedAppearsInCode,fbs.processed$IncludedInCode)
fbs.processed$ProcessedAppearsInName<-NA
fbs.processed$ProcessedAppearsInName[!is.na(idx)]=as.character(fbs.processed$IncludedInName[idx[!is.na(idx)]])

View(fbs.processed)

# How many items have unclear processing
table(is.na(fbs.processed$FoodInclProcessed))

write.csv2(derived,"derived_products.csv",row.names=FALSE)
write.csv2(fbs.processed,"fbs_processed.csv",row.names=FALSE)
write.csv2(fbs.classification,"fbs_classification.csv",row.names=FALSE)