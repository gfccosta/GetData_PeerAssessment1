if(!file.exists('UCI_HAR_Dataset.zip')) {
    download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip', destfile = 'UCI_HAR_Dataset.zip', method='curl')
    unzip('UCI_HAR_Dataset.zip')
}

features <- read.table('UCI HAR Dataset/features.txt')
labels <- read.table('UCI HAR Dataset/activity_labels.txt')

train <- read.table('UCI HAR Dataset/train/X_train.txt')
train_labels <- read.table('UCI HAR Dataset/train/Y_train.txt')
train_subject <- read.table('UCI HAR Dataset/train/subject_train.txt')
test <- read.table('UCI HAR Dataset/test/X_test.txt')
test_labels <- read.table('UCI HAR Dataset/test/Y_test.txt')
test_subject <- read.table('UCI HAR Dataset/test/subject_test.txt')

## 1. Merges the training and the test sets to create one data set.

data <- rbind(train, test)
data_labels <- rbind(train_labels, test_labels)
data_subjects <- rbind(train_subject, test_subject)

## cleanup a little bit
rm(train, train_labels, test, test_labels, train_subject, test_subject)

## 2. Extracts only the measurements on the mean and standard deviation for each measurement. 

## cut all but the sums and stds columns
data_filtered <- data[,grep('(mean|std)\\(', features[,2])]
rm(data)

## 3. Uses descriptive activity names to name the activities in the data set

library(dplyr)
## col bind the activity label
data_labeled <- cbind(activity=inner_join(labels, data_labels, by='V1')$V2, data_filtered)
rm(data_filtered)

## 4. Appropriately labels the data set with descriptive variable names. 

## name the columns using names in features wich match the std and mean
names(data_labeled) <- c('activity', as.character(features[grep('(mean|std)\\(', features[,2]),2]))

## 5. From the data set in step 4, creates a second, independent tidy data set with the average of 
## each variable for each activity and each subject.
names(data_subjects) <- c('subject')
data <- cbind(data_subjects, data_labeled) %>% mutate(subject=as.factor(subject))
library(reshape2)
mdata <- melt(data, id=c('subject', 'activity'), variable.name = 'signalVariable')
mdata <- cbind(mdata, colsplit(mdata$signalVariable, "-", c("signal","aggregationAxis")))  %>% select(-signalVariable) %>% mutate(signal=as.factor(signal))
mdata <- cbind(mdata, colsplit(mdata$aggregationAxis, "-", c("aggregation", "axis")))  %>% select(-aggregationAxis) %>% mutate(aggregation=as.factor(aggregation), axis=as.factor(axis))

tidydata <- summarise(group_by(mdata, subject, activity, signal, aggregation, axis), mean(value))

write.table(tidydata, 'tidy-data.txt',row.name=FALSE)