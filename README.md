Getting and Cleaning Data Assignment
=======================

The script **run_analysis.R** performs the following steps:

- It reads the **features.txt** file for the feature names(columns).
- It reads the **activity_labels.txt** file for the activities names.
- It reads the **X_train.txt** and **X_test.txt** files for the data.
- It reads the **Y_train.txt** and **Y_test.txt** files for the subject identification column.
- It reads the **subject_train.txt** and **subject_test.txt** files for the subject identification column.

The above code is performed by the following code:

```r
    features <- read.table('UCI HAR Dataset/features.txt')
    labels <- read.table('UCI HAR Dataset/activity_labels.txt')
    
    train <- read.table('UCI HAR Dataset/train/X_train.txt')
    train_labels <- read.table('UCI HAR Dataset/train/Y_train.txt')
    train_subject <- read.table('UCI HAR Dataset/train/subject_train.txt')
    test <- read.table('UCI HAR Dataset/test/X_test.txt')
    test_labels <- read.table('UCI HAR Dataset/test/Y_test.txt')
    test_subject <- read.table('UCI HAR Dataset/test/subject_test.txt')
```

### 1. Merges the training and the test sets to create one data set.

Fist we bind the train and test tables in just one. The same operation is performed on the label and subject data. These operations is performed on the code-block below.   

```r
    data <- rbind(train, test)
    data_labels <- rbind(train_labels, test_labels)
    data_subjects <- rbind(train_subject, test_subject)

    ## cleanup a little bit
    rm(train, train_labels, test, test_labels, train_subject, test_subject)
```

### 2. Extracts only the measurements on the mean and standard deviation for each measurement. 

After that, the data is filtered, considering only the columns with the 'mean(' and 'std(' substring text.  

```r
    ## cut all but the sums and stds columns
    data_filtered <- data[,grep('(mean|std)\\(', features[,2])]
    ## drops unused varivables
    rm(data)
```

### 3. Uses descriptive activity names to name the activities in the data set

The complete data table is a join of the columns from the *data_fitered* variable and a column with the activity name. The activity name comes from the join from the *labels* and the *data_labels* variable. The *data_labels* identifies the activity from each data sample and the *labels* are the activity list.  

```r
    library(dplyr)
    ## col bind the activity label
    data_labeled <- cbind(activity=inner_join(labels, data_labels, by='V1')$V2, data_filtered)
    ## perform some cleanup
    rm(data_filtered)
```

### 4. Appropriately labels the data set with descriptive variable names. 

The features values are used to select the columns that have 'std' and 'mean' as subtext. The following code-block perform that task and also names the activity column.   

```r
    ## name the columns using names in features wich match the std and mean
    names(data_labeled) <- c('activity', as.character(features[grep('(mean|std)\\(', features[,2]),2]))
```

### 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

After the previous steps, the data has class values in columns contains information (Signal name, aggregation funcion and axis). The tidy data shoud have these broken into row values. That is done by the melt funcion in conjuction with the colsplit. First the column name is splited in signa Name and the second text string is broken into the aggregation function and the axis name.  

These operations are performed by the code below:

```r
    names(data_subjects) <- c('subject')
    data <- cbind(data_subjects, data_labeled) %>% mutate(subject=as.factor(subject))
    
    ## loads the reshape2 to allows the use of melt and colsplit functions
    library(reshape2)
    
    ## adds an primary key to data
    data <- mutate(data, id=seq(along.with=data[,1]))
    
    ## extracts the column name information into column values
    mdata <- melt(data, id=c('id','subject', 'activity'), variable.name = 'signalVariable')
    mdata <- cbind(mdata, colsplit(mdata$signalVariable, "-", c("signal","aggregationAxis")))  %>% select(-signalVariable) %>% mutate(signal=as.factor(signal))
    mdata <- cbind(mdata, colsplit(mdata$aggregationAxis, "-", c("aggregation", "axis")))  %>% select(-aggregationAxis) %>% mutate(aggregation=as.factor(aggregation), axis=as.factor(axis))
```
Finally, the mean from the variables is obtained from the *sumarisize* function, considerin the subject, activity, signal, aggregation, axis columns. The requested *tidydata* variable below have the following columns:

1. subject id (factor)
2. activity name (factor)
3. signal name (factor)
4. aggregation function from the signal data (factor)
5. axis (factor)
6. mean (numeric value)

As requested, the tidy data is saved on a simple text file.

```r
    tidydata <- summarise(group_by(mdata, subject, activity, signal, aggregation, axis), mean(value))
    write.table(tidydata, 'tidy-data.txt',row.name=FALSE)
```

With the **mdata** variable we had all the data in the best normalization. From that we can rebuild any view from the data. For example, it is possible to select the measurements sampled for the X axis without the need of column filtering by name.

