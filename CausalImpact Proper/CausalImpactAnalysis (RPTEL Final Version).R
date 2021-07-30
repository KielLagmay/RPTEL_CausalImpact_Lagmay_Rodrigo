# Sources:
# http://google.github.io/CausalImpact/CausalImpact.html
# https://swcarpentry.github.io/r-novice-inflammation/11-supp-read-write-csv/
# https://www.geeksforgeeks.org/taking-input-from-user-in-r-programming/#:~:text=In%20R%20language%20readline(),the%20format%20that%20he%20needs.
# https://www.tutorialspoint.com/how-to-find-the-unique-values-in-a-column-of-an-r-data-frame
# https://stackoverflow.com/questions/2854625/select-only-rows-if-its-value-in-a-particular-column-is-less-than-the-value-in-t
# https://www.listendata.com/2015/06/r-keep-drop-columns-from-data-frame.html
# https://dplyr.tidyverse.org/reference/arrange.html
# https://stackoverflow.com/questions/20643166/set-a-data-frame-column-as-the-index-of-r-data-frame-object
# https://www.math.ucla.edu/~anderson/rw1001/library/base/html/paste.html
# https://riptutorial.com/r/example/4492/matplot
# https://www.r-graph-gallery.com/279-plotting-time-series-with-ggplot2.html
# https://www.earthdatascience.org/courses/earth-analytics/time-series-data/date-class-in-r/
# https://www.statmethods.net/input/dates.html
# https://stackoverflow.com/questions/4739837/how-do-i-install-an-r-package-from-the-source-tarball-on-windows/31281819
# https://stackoverflow.com/questions/29046311/how-to-convert-dataframe-into-time-series
# https://www.rdocumentation.org/packages/zoo/versions/1.8-8/topics/zoo
# https://stats.stackexchange.com/questions/358145/how-to-study-the-causal-impact-on-multiple-time-series-of-interest-against-multi
# https://www.rappler.com/nation/weather/typhoon-rolly-pagasa-forecast-october-29-2020-11pm
# https://www.rappler.com/nation/weather/typhoon-ulysses-pagasa-forecast-november-13-2020-11am
# https://stackoverflow.com/questions/29773714/r-pivot-the-rows-into-columns-and-use-n-as-for-missing-values
# https://stackoverflow.com/questions/3777174/plotting-two-variables-as-lines-using-ggplot2-on-the-same-graph
# https://stackoverflow.com/questions/8161836/how-do-i-replace-na-values-with-zeros-in-an-r-dataframe
# https://www.datanovia.com/en/lessons/rename-data-frame-columns-in-r/
# https://stackoverflow.com/questions/9996452/r-find-and-add-missing-non-existing-rows-in-time-related-data-frame
# https://www.datanovia.com/en/lessons/identify-and-remove-duplicate-data-in-r/
# https://stackoverflow.com/questions/1299871/how-to-join-merge-data-frames-inner-outer-left-right
# https://www.r-bloggers.com/2018/07/how-to-aggregate-data-in-r/
# https://stackoverflow.com/questions/9676212/how-to-sum-data-frame-column-values
# https://stackoverflow.com/questions/42379751/how-do-i-find-the-percentage-of-something-in-r
# https://www.rdocumentation.org/packages/dplyr/versions/0.7.8/topics/arrange
# https://stat.ethz.ch/R-manual/R-devel/library/base/html/sets.html
# https://www.mathstopia.net/sets/intersection-set#:~:text=If%20A%2C%20B%20and%20C,A%E2%88%A9B)%E2%88%A9C.
# https://stackoverflow.com/questions/1169248/test-if-a-vector-contains-a-given-element
# https://stackoverflow.com/questions/53107014/replace-space-between-two-words-with-an-underscore-in-a-vector
# https://stackoverflow.com/questions/12861734/calculating-standard-deviation-of-each-row
# https://stackoverflow.com/questions/21322034/how-to-square-all-the-values-in-a-vector-in-r
# https://stackoverflow.com/questions/1299871/how-to-join-merge-data-frames-inner-outer-left-right
# https://stackoverflow.com/questions/9809166/count-number-of-rows-within-each-group

library(CausalImpact)
library(MarketMatching)
library(dplyr)
library(ggplot2)
library(zoo)
library(tidyr)
library(reshape2)
library(mctest)
library(ppcor)
library(fsMTS)

# Set working directory
dirpath <- readline("Enter the directory of the csv file to be analyzed: ")
setwd(dirpath)

# Input CSV File
dataname <- readline("csv file to be analyzed: ")
data <- read.csv(paste(dataname, ".csv", sep=""))
head(data)

totalComponentsPerUserType <- aggregate(data$Total, by=list(data$User.Type, data$Component), FUN = sum)
totalComponentsPerUserType <- aggregate(totalComponentsPerUserType$Group.2, by=list(totalComponentsPerUserType$Group.1), FUN = length)

totalLogs <- sum(data$Total)

dataAllLogsName <- readline("csv file of all logs: ")
dataAllLogs <- read.csv(paste(dataAllLogsName, ".csv", sep=""))
dataAllLogs$Component <- "All Logs"
head(dataAllLogs)

data <- rbind(data, dataAllLogs)
data <- data[!(data$User.Type == "AS_NON-EDITING-TEACHERS"), ]

# Get the list of dates and their count
dateData <- unique(data[c("Date")])
dateData <- arrange(dateData, Date)
head(dateData)
totalDates <- length(dateData$Date)

# Get the list of user types and their count
userTypes <- unique(data[c("User.Type")])
userTypes <- arrange(userTypes, User.Type)
print(userTypes)
userType <- readline("Enter the User Type: ")
totalUserTypes <- length(userTypes$User.Type)

uniqueComponents <- unique(data[c("Component")])
allCombinations <- merge(userTypes, uniqueComponents, by = NULL)
allCombinations <- merge(dateData, allCombinations, by = NULL)
dataAllCombinations <- merge(allCombinations, data, by = c("Date", "User.Type", "Component"), all.x = TRUE)
dataAllCombinations[is.na(dataAllCombinations)] <- 0

# Normalize the Data Per User Type and Event
dataMaxValues <- aggregate(dataAllCombinations$Total, by = list(dataAllCombinations$User.Type, dataAllCombinations$Component), FUN = max)
names(dataMaxValues)[names(dataMaxValues) == "Group.1"] <- "User.Type"
names(dataMaxValues)[names(dataMaxValues) == "Group.2"] <- "Component"
names(dataMaxValues)[names(dataMaxValues) == "x"] <- "Max"

dataNorm <- merge(dataAllCombinations, dataMaxValues, by = c("User.Type", "Component"))
dataNorm$TotalNorm <- dataNorm$Total / dataNorm$Max
#dataNorm <- subset(dataNorm, select = -c(Max))
dataNorm[is.na(dataNorm)] <- 0

write.csv(dataNorm, "MoodleLogsNormalizationSample.csv", row.names = FALSE)

dataNorm$Total <- dataNorm$TotalNorm
dataNorm <- subset(dataNorm, select = -c(Max, TotalNorm))

# Get the General Average of each Event Type across Dates and User Types
dataGenAve <- aggregate(dataNorm$Total, by = list(dataNorm$Component), FUN = mean)
names(dataGenAve)[names(dataGenAve) == "Group.1"] <- "Component"
names(dataGenAve)[names(dataGenAve) == "x"] <- "Gen_Ave"

# Extract rows with the most frequent events
mostFreqEvents <- head(arrange(dataGenAve[!(dataGenAve$Component == "All Logs"), ], desc(Gen_Ave)), 10)
totalFreq <- sum((data[is.element(data$Component, mostFreqEvents$Component), ])$Total)
(totalFreq / totalLogs) * 100
mostFreqEvents <- rbind(mostFreqEvents, dataGenAve[dataGenAve$Component == "All Logs", ])
dataFreqEvents <- dataNorm[is.element(dataNorm$Component, mostFreqEvents$Component), ]

print(mostFreqEvents)
eventType <- readline("Enter the Component: ")

totalComp <- sum((data[data$Component == eventType, ])$Total)
(totalComp / totalLogs) * 100

# Create dataframe for response variable
userType_data <- dataFreqEvents[dataFreqEvents$User.Type == userType, ]
head(userType_data)
userType_data <- userType_data[userType_data$Component == eventType, ]
head(userType_data)
userType_data$Component <- gsub("\\s", "_", userType_data$Component)
userType_data$Component <- paste(userType_data$User.Type, userType_data$Component, sep = "_")
userType_data <- subset(userType_data, select = -c(User.Type))
head(userType_data)

userTypeEvent <- userType_data$Component[1]

# Create dataframe for predictor variables
otherTypes_data <- dataFreqEvents[!(dataFreqEvents$User.Type == userType), ]
head(otherTypes_data)
otherTypes_data <- otherTypes_data[!(otherTypes_data$Component == "All Logs"), ]
head(otherTypes_data)
otherTypes_data$Component <- gsub("\\s", "_", otherTypes_data$Component)
otherTypes_data$Component <- paste(otherTypes_data$User.Type, otherTypes_data$Component, sep="_")
otherTypes_data <- subset(otherTypes_data, select = -c(User.Type))
head(otherTypes_data)

otherTypes_data_feature_select <- spread(otherTypes_data, Component, Total)
head(otherTypes_data_feature_select)
otherTypes_data_feature_select$Date <- as.Date(otherTypes_data_feature_select$Date)
otherTypes_data_feature_select <- arrange(otherTypes_data_feature_select, Date)
otherTypes_data_feature_select <- subset(otherTypes_data_feature_select,  Date < as.Date("2020-10-29"))
rownames(otherTypes_data_feature_select) <- otherTypes_data_feature_select$Date
mlist <- fsMTS(read.zoo(otherTypes_data_feature_select, format = "%Y-%m-%d"), max.lag=1, method="GLASSO")
mlist[["EnsembleRank"]] <- fsEnsemble(mlist, threshold = 0.3, method="ranking")

mlist <- list(Independent = fsMTS(read.zoo(otherTypes_data_feature_select, format = "%Y-%m-%d"), max.lag=1, method="ownlags"),
              CCF = fsMTS(read.zoo(otherTypes_data_feature_select, format = "%Y-%m-%d"), max.lag=1, method="CCF"))
th<-0.30
mlist[["EnsembleRank"]] <- fsEnsemble(mlist, threshold = th, method="ranking")
mlist[["EnsembleMajV"]] <- fsEnsemble(mlist, threshold = th, method="majority")
# Merge response variable and predictor variables into a single dataframe
dataSanityCheck <- rbind(userType_data, otherTypes_data)
dataSanityCheck$Date <- as.Date(dataSanityCheck$Date)

mm <- best_matches(data=dataSanityCheck,
                   id_variable="Component",
                   date_variable="Date",
                   markets_to_be_matched=c(userTypeEvent),
                   matching_variable="Total",
                   warping_limit=1, # warping limit=1
                   dtw_emphasis=1, # rely only on dtw for pre-screening
                   start_match_period="2020-09-09",
                   end_match_period="2020-10-28")

userType_data <- subset(userType_data, select = -c(Component))
head(userType_data)
names(userType_data)[names(userType_data) == "Total"] <- userTypeEvent
head(userType_data)

otherTypes_data <- otherTypes_data[is.element(otherTypes_data$Component, mm$BestMatches$BestControl), ]
head(otherTypes_data)
otherTypes_data <- spread(otherTypes_data, Component, Total)
head(otherTypes_data)

otherTypes_data_temp <- otherTypes_data
otherTypes_data_temp$Date <- as.Date(otherTypes_data_temp$Date)
otherTypes_data_temp <- arrange(otherTypes_data_temp, Date)
checkMulticollinear <- subset(otherTypes_data_temp,  Date < as.Date("2020-10-29"))
rownames(checkMulticollinear) <- checkMulticollinear$Date
checkMulticollinear <- subset(checkMulticollinear, select = -c(Date))
fsMTS(read.zoo(checkMulticollinear, format = "%Y-%m-%d"), max.lag=3)

# Merge response variable and predictor variables into a single dataframe
dataInput <- merge(userType_data, otherTypes_data, by="Date")

# Arrange data according to date and transform NAs to 0s
dataInput$Date <- as.Date(dataInput$Date)
dataInput <- arrange(dataInput, Date)
checkMulticollinear <- subset(dataInput,  Date < as.Date("2020-10-29"))
rownames(checkMulticollinear) <- checkMulticollinear$Date
checkMulticollinear <- subset(checkMulticollinear, select = -c(Date))
rownames(dataInput) <- dataInput$Date
head(dataInput)

write.csv(dataInput, paste(eventType, '_predictorVariables.csv', sep=""), row.names=FALSE)

checkMulticollinearModel <- lm(paste(userTypeEvent, '~.'), data=checkMulticollinear)
checkMulticollinearModel <- ar.ols(checkMulticollinear)#lm(paste(userTypeEvent, '~.'), data=checkMulticollinear)
omcdiag(checkMulticollinearModel)
omcdiag(checkMulticollinear)
imcdiag(checkMulticollinearModel)
pcor(subset(otherTypes_data, select = -c(Date)), method = "pearson")

# Visualize the data
data_viz <- melt(dataInput, id="Date")

ggplot(data=data_viz, aes(x=Date, y=value, colour=variable)) +
  geom_line() +
  labs(
    title="Data Summary",
    subtitle=eventType,
    x="Date",
    y="Total"
  )

# CausalImpact proper
data_timeseries <- read.zoo(dataInput, format = "%Y-%m-%d")
head(data_timeseries)

before_rolly_ulysses <- as.Date(c("2020-09-09", "2020-10-29"))
after_rolly_ulysses <- as.Date(c("2020-11-13", "2021-01-09"))

before_rolly_ulysses <- as.Date(c("2020-09-09", "2020-10-29"))
after_rolly_ulysses <- as.Date(c("2020-11-13", "2020-12-23"))

before_rolly_ulysses <- as.Date(c("2020-09-09", "2020-10-29"))
after_rolly_ulysses <- as.Date(c("2020-11-21", "2021-01-09"))

before_rolly_ulysses <- as.Date(c("2020-09-09", "2020-10-29"))
after_rolly_ulysses <- as.Date(c("2020-11-21", "2020-12-23"))

impact_rolly_ulysses <- CausalImpact(data_timeseries, before_rolly_ulysses, after_rolly_ulysses)
plot(impact_rolly_ulysses)
summary(impact_rolly_ulysses)
summary(impact_rolly_ulysses, "report")