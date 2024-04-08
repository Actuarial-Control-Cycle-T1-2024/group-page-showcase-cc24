####################
# ACTL4001 SOA Group Assignment- Term 1 2024
# by Nick Ng and Albert from CC24 
# Title: Lumaria Wellness Program Design
####################
set.seed(1) # for reproducible results

# See if relevant packages installed, if not then install and load it
# Packages for EDA below
if(!require(MASS)) {install.packages("MASS", dependencies = T); library(MASS)}
if(!require(dplyr)) {install.packages("dplyr", dependencies = T); library(dplyr)}
if(!require(ggplot2)) {install.packages("ggplot2", dependencies = T); library(ggplot2)}
if(!require(readxl)) {install.packages("readxl", dependencies = T); library(readxl)}
if(!require(RColorBrewer)) {install.packages("RColorBrewer", dependencies = T); library(RColorBrewer)}
if(!require(stringr)) {install.packages("stringr", dependencies = T); library(stringr)}
if(!require(writexl)) {install.packages("writexl", dependencies = T); library(writexl)}

# Packages for modelling below
if(!require(glmnet)) {install.packages("glmnet", dependencies = T); library(glmnet)}
if(!require(FNN)) {install.packages("FNN", dependencies = T); library(FNN)} # For KNN regression option 1
if(!require(tree)) {install.packages("tree", dependencies = T); library(tree)}
if(!require(ranger)) {install.packages("ranger", dependencies = T); library(ranger)} # for bagging and randomforest. Much faster than the randomforest package!
if(!require(tuneRanger)) {install.packages("tuneRanger", dependencies = T); library(tuneRanger)} # Highly dependent on mlr package, need to switch to mlr3
if(!require(xgboost)) {install.packages('xgboost', dependencies = T); library(xgboost)} # for xgboost
if(!require(pdp)) {install.packages('pdp', dependencies = T); library(pdp)} # for PDP's and ICE curves
if(!require(vip)) {install.packages('vip', dependencies = T); library(vip)} # for VIP's


# Importing datasets below
in_force_data = read.csv("inforce data.csv") # didn't lose any rows or columns from the original
economic_data = read_excel("economic data.xlsx")
intervention_data = read_excel("intervention data.xlsx")
mortality_data = read_excel("lumaria mortality table.xlsx")


################################################################################
################################# EDA ###############################
################################################################################
# Firstly, cleaning in_force_data

# Data cleaning below
in_force_data = in_force_data[-c(1:2),] 
colnames(in_force_data) = in_force_data[1,]
in_force_data = in_force_data[-1,]

# Change string columns to numeric where appropriate
in_force_cols_num = c(3,4,6, 13, 15)
in_force_data[,in_force_cols_num] = apply(in_force_data[,in_force_cols_num], 2, function(x) as.numeric(x))

# Examining NA data
in_force_data %>%
  filter(Death.indicator == 0) %>%
  summarise(num_zero = n()) # according to dataset, no one is alive. 
# This is a data error, because intuitively some should still be alive.

# For death indicator column, replace all NA with "0" to correct for data error
# Now it only has "0" and "1"
in_force_data$Death.indicator[is.na(in_force_data$Death.indicator) == T] = "0"

# For lapse indicator, replace all "Y" with "1", as they mean the same thing
# and encode all NA with "0" also below. After that only has "0" and "1"

in_force_data$Lapse.Indicator[in_force_data$Lapse.Indicator == "Y"] = "1"
in_force_data$Lapse.Indicator[is.na(in_force_data$Lapse.Indicator) == T] = "0"

# Cause.of.Death has "", convert to NA below
in_force_data$Cause.of.Death[in_force_data$Cause.of.Death == ""] = NA

# Add more columns to in_force_data
current_year = 2024
in_force_data = in_force_data %>%
  mutate(birth_year = Issue.year-Issue.age, current_age = current_year - birth_year, age_at_death = Year.of.Death - birth_year, 
   years_b4_death = Year.of.Death-Issue.year, age_at_lapse = Year.of.Lapse - birth_year, years_b4_lapse = Year.of.Lapse-Issue.year) %>%
  select(c(1:13, years_b4_death, age_at_death, Lapse.Indicator, Year.of.Lapse, years_b4_lapse, age_at_lapse, birth_year, current_age, Cause.of.Death))

in_force_data %>%
  filter(is.na(Cause.of.Death) == T) %>%
  summarise(num_na = n()) # There's 939042 NA Cause of Death. So causes of death are 95.96% NA

in_force_dead = in_force_data %>% # Dataset given that they died
  filter(is.na(Cause.of.Death) == F)


# Filtering out outliers below if there's any in in_force_dead
# in_force_data no need to remove outlier rows, as it's not even used in modelling at all
attach(in_force_dead)
Q1 = quantile(age_at_death, probs = 0.25)
Q3 = quantile(age_at_death, probs = 0.75)
iqr = IQR(age_at_death)

outliers_death_age = in_force_dead %>%
  filter(age_at_death < (Q1 - 1.5*iqr) | age_at_death > (Q3 + 1.5*iqr)) # 254 outliers rows. 0.64% of rows in in_force_dead are outliers

table(outliers_death_age$Policy.type) # ALL outliers are T20, none is SPWL!

in_force_dead = in_force_dead %>%
  filter(age_at_death >= (Q1 - 1.5*iqr) & age_at_death <= (Q3 + 1.5*iqr))
detach(in_force_dead)


#Overall summary
in_force_data %>%
  summarise(avg_issue_age = mean(Issue.age), avg_face_amount = mean(Face.amount))

# Grouped by underwriting class
in_force_data %>%
  group_by(Underwriting.Class) %>%
  summarise(avg_issue_age = mean(Issue.age), avg_face_amount = mean(Face.amount))


# Grouped by smoking status 
in_force_data %>%
  group_by(Smoker.Status) %>%
  summarise(avg_issue_age = mean(Issue.age), avg_face_amount = mean(Face.amount))

# Grouped by sex
in_force_data %>%
  group_by(Sex) %>%
  summarise(avg_issue_age = mean(Issue.age), avg_face_amount = mean(Face.amount))

# Grouped by cause of death (16 possible ones), given they died
in_force_dead %>%
  group_by(Cause.of.Death) %>%
  summarise(avg_issue_age = mean(Issue.age), avg_face_amount = mean(Face.amount), avg_death_age = mean(age_at_death))


# Find the number of policyholders that died from cause C00-D48 and I00-I99
table(in_force_dead$Cause.of.Death)
sum(prop.table(table(in_force_dead$Cause.of.Death)))

# Box plots below. Mean is denoted by black star.
ggplot(in_force_dead, aes(x = Cause.of.Death, y = Face.amount, fill = Cause.of.Death)) + 
  geom_boxplot() +
  stat_summary(fun = "mean", geom = "point", shape = 8, size = 2, color = "black") +
  labs(x = "Cause of Death", y = "Face Amount", title = "Box plot of face amount with Death Causes")

ggplot(in_force_dead, aes(x = Cause.of.Death, y = age_at_death, fill = Cause.of.Death)) + 
  geom_boxplot() +
  stat_summary(fun = "mean", geom = "point", shape = 8, size = 2, color = "black") +
  labs(x = "Cause of Death", y = "Age at Death", title = "Box plot of Age of Death with Causes")


# Histogram plots below:
ggplot(in_force_data) +
  geom_histogram(aes(Issue.age), bins = 10, color = "lightblue", fill = "blue") +
  labs(x = "Issue age of life policy", title = "Histogram of issue ages from 2001 – 2023")

ggplot(in_force_data) +
  geom_histogram(aes(Face.amount), color = "gold", fill = "black", bins = 8) +
  labs(x = "face amount of death benefit (Č)", title = "Histogram of face amounts from 2001 – 2023")


# Bar plots below
ggplot(in_force_data) +
  geom_bar(aes(x = Sex, color = Sex, fill = Sex)) +
  labs(y = "Count", title ="Bar plot of Sex")
  
  
ggplot(in_force_data) +
  geom_bar(aes(x = Urban.vs.Rural, color = Urban.vs.Rural, fill = Urban.vs.Rural)) +
  labs(y = "Count", title ="Bar plot of Area located")

ggplot(in_force_data) +
  geom_bar(aes(x = Smoker.Status, color = Smoker.Status, fill = Smoker.Status)) +
  labs(y = "Count", title ="Bar plot of Smoker Status")


ggplot(in_force_data) +
  geom_bar(aes(x = Underwriting.Class, color = Underwriting.Class, fill = Underwriting.Class)) +
  labs(y = "Count", title ="Bar plot of Underwriting Class")

ggplot(in_force_data) +
  geom_bar(aes(x = Distribution.Channel, color = Distribution.Channel, fill = Distribution.Channel)) +
  labs(y = "Count", title ="Bar plot of Distribution Channel")

ggplot(in_force_data) +
  geom_bar(aes(x = Region, color = Region, fill = Region)) +
  labs(y = "Number of people living there", title ="Bar plot of Different Regions")

ggplot(in_force_dead) +
  geom_bar(aes(x = Cause.of.Death, color = Cause.of.Death, fill = Cause.of.Death)) +
  labs(y = "Count", title ="Bar plot of Different Causes of Death") # given death occurred



# count the number of policies issued in each year
num_policies = in_force_data %>%
  group_by(Issue.year) %>%
  summarise(num = n())

# Since year of issue is given in integer's only
# Assuming that policies can be sometimes issued between years
# A curve of best fit was drawn to interpolate
ggplot(num_policies, aes(x = Issue.year, y = num, group = 1)) + 
  geom_point() + 
  geom_smooth(se = TRUE) +
  labs(x = "Year of Policy Issue", y = "Number issued", title = "General increase in Uptake over Time")


# Next, ggplotting and cleaning the mortality_data
# Age is a count variable in this case, as we only given integer data
mortality_data = mortality_data[,c(1,2)]
colnames(mortality_data) = c("age", "mortality_rate")
mortality_data = mortality_data[-c(1:7), ]
mortality_data$age = as.numeric(mortality_data$age)
mortality_data$mortality_rate = as.numeric(mortality_data$mortality_rate)


ggplot(mortality_data, aes(x = age, y = mortality_rate)) + 
  geom_point() + 
  geom_smooth(se = TRUE) +
  labs(x = "Age", y = "Mortality rate", title = "Mortality rate Increase over Different Ages")

# Next, ggplotting and cleaning the economic_data below
economic_data = economic_data[-c(1:4),]
economic_data = economic_data[,-c(6,7)]
colnames(economic_data) = economic_data[1,]
economic_data = economic_data[-1,]

# Run code below
# Changing every element of economic_data to numeric type below
economic_data = apply(economic_data, c(1,2), function(x) as.numeric(x)) # as a matrix right now
economic_data = as.data.frame(economic_data)

# ggplotting time series with each type of rate below
ggplot(economic_data, aes(x = Year, y = Inflation)) + 
  geom_point() +
  geom_smooth(se = T) +
  labs(title = "Time series Inflation", y = "Inflation Rate")
  
ggplot(economic_data, aes(x = Year, y = `Government of Lumaria Overnight Rate`)) + 
  geom_point() +
  geom_smooth(se = T) +
  labs(title = "Time series Overnight Rate", y = "Government Overnight Rate")

ggplot(economic_data, aes(x = Year, y = `1-yr Risk Free Annual Spot Rate`)) + 
  geom_point() +
  geom_smooth(se = T) +
  labs(title = "Time series 1 Year Spot Rates")

ggplot(economic_data, aes(x = Year, y = `10-yr Risk Free Annual Spot Rate`)) + 
  geom_point() +
  geom_smooth(se = T) +
  labs(title = "Time series 10 Year Spot Rates")

# Combining all curves of best fit for each rate onto a single time series plot below
ggplot(economic_data, aes(x = Year)) +
  geom_smooth(se = F, aes(y = Inflation, color = "Inflation")) +
  geom_smooth(se = F, aes(y = `Government of Lumaria Overnight Rate`, color = "Overnight Rate")) +
  geom_smooth(se = F, aes(y = `1-yr Risk Free Annual Spot Rate`, color = "1-yr Risk Free Annual Spot Rate")) + 
  geom_smooth(se = F, aes(y = `10-yr Risk Free Annual Spot Rate`, color = "10-yr Risk Free Annual Spot Rate")) +
  scale_colour_brewer(type = "qual", palette="Set1") +
  labs(title = "Time Series Comparison of Different Rates", y = "Different Rates")

# Correlation matrix of each type of rate against one another below
economic_no_yr = economic_data %>%
  select(-Year)
cor(economic_no_yr)


# Next, ggplotting and cleaning the intervention data
intervention_data = intervention_data[-c(1:6),]
colnames(intervention_data) = intervention_data[1,]
intervention_data = intervention_data[-1,]
intervention_data = cbind(c(1:50), intervention_data)
colnames(intervention_data)[1] = "Program Number"

colnames(intervention_data)[4] = "Approximate Reduction in Mortality Rate %"
colnames(intervention_data)[5] = "Approximate Per Capita Cost in Č"

word_list = c(" reduction in overall mortality| reduction in mortality|%")
intervention_data[,4] = str_remove_all(intervention_data[,4], word_list)
intervention_data[,5] = str_remove_all(intervention_data[,5], "Č")

# Albert's part below until start of modelling
# Split data in T20 and WL
t20 <- subset(in_force_data, Policy.type == 'T20')
spwl <- subset(in_force_data, Policy.type == 'SPWL')

# Split into age groups
t20_2635 <- subset(t20, Issue.age <= 35)
t20_3645 <- subset(t20, Issue.age > 35 & Issue.age <= 45)
t20_4655 <- subset(t20, Issue.age > 45)

# Find sample lapse and death rates
lapse <- aggregate(t20$Lapse.Indicator, 
                   by=list(t20$Lapse.Indicator,t20$years_b4_lapse), 
                   FUN=length)
lapse

count1 <- aggregate(t20$Lapse.Indicator, 
                    by=list(t20$Lapse.Indicator), 
                    FUN=length)
count1

death <- aggregate(t20$Death.indicator, 
                   by=list(t20$Death.indicator,t20$years_b4_death), 
                   FUN=length)
death

count2 <- aggregate(t20$Death.indicator, 
                    by=list(t20$Death.indicator), 
                    FUN=length)
count2

(lapse26 <- aggregate(t20_2635$Lapse.Indicator, 
                      by=list(t20_2635$Lapse.Indicator,t20_2635$years_b4_lapse), 
                      FUN=length))
(lapse36 <- aggregate(t20_3645$Lapse.Indicator, 
                      by=list(t20_3645$Lapse.Indicator,t20_3645$years_b4_lapse), 
                      FUN=length))
(lapse46 <- aggregate(t20_4655$Lapse.Indicator, 
                      by=list(t20_4655$Lapse.Indicator,t20_4655$years_b4_lapse), 
                      FUN=length))

aggregate(t20_2635$Lapse.Indicator, 
          by=list(t20_2635$Lapse.Indicator), 
          FUN=length)
(death26 <- aggregate(t20_2635$Death.indicator, 
                      by=list(t20_2635$Death.indicator,t20_2635$years_b4_death), 
                      FUN=length))
(death36 <- aggregate(t20_3645$Death.indicator, 
                      by=list(t20_3645$Death.indicator,t20_3645$years_b4_death), 
                      FUN=length))
(death46 <- aggregate(t20_4655$Death.indicator, 
                      by=list(t20_4655$Death.indicator,t20_4655$years_b4_death), 
                      FUN=length))

aggregate(t20_4655$Death.indicator, 
          by=list(t20_4655$Death.indicator), 
          FUN=length)

# Calculate tpx (survival probability)
asdfg <- c()
for (i in 1:120) {
  asdfg <- c(asdfg, 1)
}

mortality_data$px <- asdfg - mortality_data$mortality_rate
x2 = c()
for (i in 1:121) {
  x2 <- c(x2,0)
}
x2 = c(mortality_data$px, x2)

tpx <- function(x,t) {
  if (t == 1) {
    x1 <- x2[x]
    return(x1)
  } else {
    x1 <- x2[x]
    for (i in 1:(t-1)) {
      x1 <- x1 * x2[x+i]
    }
    return(x1)
  }
}
p<-c()
for (i in 26:120) {
  for(j in 1:120) {
    p <- c(p, tpx(i, j))
  }
}
mtx <- matrix(p,nrow=120)
df <- as.data.frame(mtx)
write_xlsx(df, "~/Downloads/tpx12345667.xlsx")

# Fit inflation and risk free rate into normal distribution for VaR testings
fitdistr(economic_data$Inflation, "normal")
fitdistr(economic_data$`10-yr Risk Free Annual Spot Rate`, "normal")
qnorm(0.975, mean=0.067381046, sd=0.035581781)
qnorm(0.975, mean=0.042941380, sd=0.027724220)
qnorm(0.025, mean=0.067381046+0.04, sd=0.035581781)
pnorm(0.03, mean=0.067381046, sd=0.035581781)


################################################################################
################################# Program Design Modelling ###############################
################################################################################
# Remove policy number column as there is no way that it can be used to predict age at death (or death indicator)
in_force_dead = in_force_dead[,-1]

# The below columns only have 1 unique value, hence doesn't add any extra info to modelling
# hence can be removed
in_force_dead = in_force_dead %>%
  select(-c(Death.indicator, Lapse.Indicator, Year.of.Lapse, years_b4_lapse, age_at_lapse))

# Also, since age_at_death == year of death - birth year (explicit functional form)
# Then for inference, can delete any columns that makes inferential modelling pointless
in_force_dead = in_force_dead %>%
  select(-c(Year.of.Death, current_age, birth_year, Issue.year, years_b4_death))

# Use 50% of the data for training, 25% for validation, and the other 25% for testing
train_valid = sample(x = 1:nrow(in_force_dead), size = ceiling(nrow(in_force_dead)*0.75), replace = F) # training/validation row obs
test = -train_valid # NOT the row obs, but rather the index passed to get test row obs
valid_set = sample(x = train_valid, size = length(train_valid)*(1/3), replace = F) # validation set only row obs
train_rows = setdiff(train_valid, valid_set) # training row obs only

# model.matrix() adds an intercept, and removes age_at_death column.
# Also by indexing, minus first column intercept term, keep all rows
x = model.matrix(age_at_death ~., data = in_force_dead)[, -1] # dummy variable encoding
y = in_force_dead$age_at_death 
age_at_death_test = y[test] # Actual response vector for testing obs only
death_age_valid = y[valid_set]

# Logistic with LASSO penalties below: set alpha = 1 in glmnet() for lasso

# Now use 8 fold CV to find the best lambda that has smallest CV error using cv.glmnet()
# It also automatically does training/fitting first before that
cv_lasso_mse = cv.glmnet(x[train_valid, ], y[train_valid], alpha = 1, relax = F, 
type.measure = "mse", family = Gamma, trace.it = 1, nfolds = 8)

plot(cv_lasso_mse, main = "CV error over Different Lamdas")

# Pick largest lambda (simpler model) using 1 s.e. rule
(bestlam_lasso_mse = cv_lasso_mse$lambda.1se) 

# According to 1 s.e. rule, find mean CV error (CVM) in this case
# This should be the average of all MSE's computed over each fold (I think)
index = cv_lasso_mse$index[2,]
lasso_mse_cvm = cv_lasso_mse$cvm[index] 
sqrt(lasso_mse_cvm) # Average RMSE

(coef_exact_mse = coef(cv_lasso_mse, exact = T, s = bestlam_lasso_mse, x = x, y = y))

# Same thing below except change type.measure = "mae"
cv_lasso_mae = cv.glmnet(x[train_valid, ], y[train_valid], alpha = 1, relax = F, 
type.measure = "mae", family = Gamma, trace.it = 1, nfolds = 8)

plot(cv_lasso_mae, main = "CV error over Different Lamdas")

# Pick largest lambda (simpler model) using 1 s.e. rule
(bestlam_lasso_mae = cv_lasso_mae$lambda.1se) 

# According to 1 s.e. rule, find mean CV error (CVM) in this case
# This should be the average of all MAE's computed over each fold (I think)
index = cv_lasso_mae$index[2,]
(lasso_mae_cvm = cv_lasso_mae$cvm[index]) # Average MAE
(coef_exact_mae = coef(cv_lasso_mae, exact = T, s = bestlam_lasso_mae, x = x, y = y))


# KNN regression below
# There's a test formal argument below, but actually that's an error in design because test set only occurs at the END of model selection
# so will put validation set there instead
# n == # of valid_set obs. == number of predicted values
knn_pred = knn.reg(train = x[train_rows, ], test = x[valid_set, ], y = y[train_rows], k = 8)

# Below is the RMSE between the "true" age_at_death (from valid_set obs)
# and KNN predictions for age_at_death
sqrt(mean((y[valid_set] - knn_pred$pred)^2))

# and corresponding validation set MAE below
mean(abs(y[valid_set] - knn_pred$pred))

# Regression trees and their Extensions:
in_force_dead = as.data.frame(x = unclass(in_force_dead), stringsAsFactors = T) # convert strings/character columns to factors.


# Basic decision trees below:
# For regression trees, the deviance is simply the sum of squared errors for the tree.

tree_basic = tree(age_at_death ~., data = in_force_dead, subset = train_rows)


# CV pruning to find the optimal level of tree complexity
# cost complexity pruning is used in order to select a sequence of trees for consideration
# For the cv.tree() function, the default value for fuction argument FUN == deviance
cv_tree_basic = cv.tree(tree_basic, K = 8)

# dev corresponds to the number of CV errors
# Minimum dev = 262214.5 at size = 10. The unpruned full tree is actually the best then
plot(tree_basic)
text(tree_basic, pretty = 0)

death_age_hat = predict(tree_basic, newdata = in_force_dead[valid_set,])

sqrt(mean((death_age_hat - death_age_valid)^2)) # validation set RMSE for basic tree
mean(abs(y[valid_set] - death_age_hat)) # validation set MAE for basic tree


# Bagging (special case of a random forest) below: where m == p == total # of predictors == 10
# for argument mtry, note that the default values are different for classification (vs regression)
# Default mtry for regression is p/3
# Also note, the formal arguments xtest and ytest are flawed by design. Test sets are supposed to be unseen until model assessment
# Using OOB set error for both bagging and general RF below

(bag_death_age = ranger(age_at_death ~ ., data = in_force_dead[train_rows,], 
mtry = 10, importance = "impurity", scale.permutation.importance = T, 
classification = F, seed = 0, regularization.usedepth = T, keep.inbag = T))

vip(bag_death_age, num_features = 4, geom = "col", sort = T, scale = T, include_type = T) + # most important (top) to least important (bottom)
  labs(title = "Bagging Variable Importance Plot", x = "Predictors") + 
  aes(fill = 1:4)

# From pdp package below
bag_partial = partial(bag_death_age, train = in_force_dead[train_rows,], 
chull = T, pred.var = c("Issue.age", "Face.amount") , type = "regression", progress = T) 

autoplot(bag_partial, smooth = T, rug = T, 
main = "Bagging PDP", train = in_force_dead[train_rows,], xlab = "Issue Age", 
ylab = "Face Amount", legend.title = "Death Age")

sqrt(bag_death_age$prediction.error) # OOB prediction error (RMSE) for bagging
# note that sample size == bag_death_age$num.samples == number of OOB samples


# General random forest (RF) below
# RF below to tune for the optimal mtry parameter via grid search, so that OOB error is minimised
# **Optimal mtry == 3 
(rf_death_age = ranger(age_at_death ~ ., data = in_force_dead[train_rows,], 
mtry = 3, importance = "impurity", scale.permutation.importance = T, 
classification = F, seed = 0, regularization.usedepth = T, keep.inbag = T))

vip(rf_death_age, num_features = 4, geom = "col", sort = T, scale = T, include_type = T) + # most important (top) to least important (bottom)
  labs(title = "RF Variable Importance Plot", x = "Predictors") + 
  aes(fill = 1:4)

rf_partial = partial(rf_death_age, train = in_force_dead[train_rows,], 
chull = T, pred.var = c("Issue.age", "Policy.type") , type = "regression", progress = T) 

autoplot(rf_partial, smooth = T, rug = T, main = "Randomforest PDP", train = in_force_dead[train_rows,], 
xlab = "Issue Age", legend.title = "Death Age", ylab = "Predicted Death Age")

sqrt(rf_death_age$prediction.error) # OOB prediction error (RMSE) for general RF


# Boosting using xgboost below. Default booster is gbtree
# Pre sure my true underlying distribution isn't Gamma GLM
# data formal argument only includes predictors, not response

# In R, nrounds (formal argument) in functions xgboost() and xgb.train()
# means the number of boosted trees to fit in classification (not sure in regression)

# Very small/slow learning rate "eta" can require using a very large value of nrounds in order to achieve good performance (idk why)
dtrain = xgb.DMatrix(data = x[train_rows,], label = y[train_rows])
dvalid_set = xgb.DMatrix(data = x[valid_set,], label = y[valid_set])
watchlist = list(train = dtrain, valid_set = dvalid_set)

param = list(eta = 0.01, verbose = 1, objective = "reg:squarederror", eval_metric ="rmse", eval_metric = "mae", max_depth = 6)

# So far minimum valid_set_rmse == 5.289702 (not overfitting), with eta = 0.01 and nrounds == 614
# BUT with these same hyperparameters, valid_set_mae == 4.436510 (overfitting)

(xgb_valid = xgb.train(data = dtrain, params = param, watchlist = watchlist, booster = "gbtree", nrounds = 614))

# Important! xgb.importance() ONLY includes the features actually used in the fitted model
# Those that aren't fitted (not important) are left out in that function output
importance_xgb = xgb.importance(feature_names = colnames(x), model = xgb_valid)
head(importance_xgb)

# Remove Cover and frequency columns below
importance_xgb = importance_xgb %>%
  select(-c(Cover, Frequency))

xgb.ggplot.importance(importance_matrix = importance_xgb, measure = "Gain", n_clusters = c(3,3), top_n = 4) +
  ggtitle("Feature Importance of XGBoost on Validation Set")

xgb.ggplot.deepness(model = xgb_valid, which = "2x1")

xgb.ggplot.deepness(model = xgb_valid, which = "max.depth") +
  ggtitle("Maximum Leaf Depth vs Tree Number")  

xgb.ggplot.deepness(model = xgb_valid, which = "med.depth") +
  ggtitle("Median Leaf Depth vs Tree Number")  

xgb.ggplot.deepness(model = xgb_valid, which = "med.weight") +
  ggtitle("Median Leaf Weight vs Tree Number")

# Set up the test set below
dtest_set = xgb.DMatrix(data = x[test,], label = y[test])
watchlist = list(train = dtrain, test_set = dtest_set)

# So far test_set_rmse == 5.290736, with eta = 0.01 and nrounds == 614
# BUT with these same hyperparameters, test_set_mae == 4.450179
(xgb_test = xgb.train(data = dtrain, params = param, watchlist = watchlist, booster = "gbtree", nrounds = 614))

importance_xgb = xgb.importance(feature_names = colnames(x), model = xgb_test)

# Remove Cover and frequency columns below
importance_xgb = importance_xgb %>%
  select(-c(Cover, Frequency))

importance_xgb # only the top 30 out of 31 predictors were actually used in xgb.train()

xgb.ggplot.importance(importance_matrix = importance_xgb, measure = "Gain", top_n = 3) +
  labs(title = "Top 3 Features of XGBoost for Test Set", y = "Importance by Gain")


################################################################################
################################# Pricing ######################################
################################################################################
# At any year t >= 2024 (fractional years allowed), compute the expected death benefit payout/expense
# from SuperLife to ALL policyholders in that particular year

# xgboost (top predictive model) uses AFT for survival analysis (regression) to predict Y == years_b4_death since issue year(t = 0 start of study)

# For simplicity, assuming current policyholders ONLY and no new ones in the future (static model)
# Also assume, that death benefit face amount is paid at the EoY of death for both SPWL and T20

# Model selection done above, no need validation set
# Further, model assessment is done, no need test set
# Train on full dataset in_force_dead_full below
# Assume all yearly figures are at the beginning of the year

#Important! Outliers count towards DB payments so add them back
in_force_og = in_force_data # keep a copy of the original (after cleaning) b4 changing it below

in_force_dead_full = in_force_data %>% 
  filter(is.na(years_b4_death) == F) 

dead_t20_valid_2024 = in_force_dead_full %>%
  filter(Policy.type == "T20") %>%
  filter(years_b4_death <= 20) %>%
  filter(Year.of.Death == 2024)
  
  
dead_spwl_valid_2024 = in_force_dead_full %>%
  filter(Policy.type == "SPWL") %>%
  filter(Year.of.Death == 2024)


max_lifespan = 120
# max_years_b4_death is the theoretical max, since max_lifespan = 120
# remove policy number and y lower/upper bounds. And remove unncessary columns that add noise to data

in_force_data = in_force_data %>%
  mutate(max_years_b4_death = max_lifespan - Issue.year + birth_year, y_lower_bound = case_when(Death.indicator == "1" ~ min(years_b4_death, max_years_b4_death), 
    Lapse.Indicator == "1" ~ Year.of.Lapse - Issue.year, T ~ current_year - Issue.year), 
    y_upper_bound = case_when(Death.indicator == "1" ~ min(years_b4_death, max_years_b4_death), Lapse.Indicator == "1" ~ max_years_b4_death, T ~ max_years_b4_death))

in_force_y = in_force_data %>%
  select(years_b4_death, y_lower_bound, y_upper_bound, max_years_b4_death)

# Some data imputation
in_force_y$y_lower_bound[is.na(in_force_y$y_lower_bound) == T] = 0
in_force_y$y_upper_bound[is.na(in_force_y$y_upper_bound) == T] = in_force_y$max_years_b4_death
  
in_force_y = na.omit(in_force_y)

in_force_data = in_force_data %>%
  select(Policy.type, Issue.year, Sex, Face.amount, Smoker.Status, Underwriting.Class, Urban.vs.Rural, 
    Region, Distribution.Channel, Lapse.Indicator, Cause.of.Death, birth_year, Death.indicator, years_b4_death)

in_force_data = as.data.frame(x = unclass(in_force_data), stringsAsFactors = T) # convert strings/character columns to factors.
in_force_data = na.omit(in_force_data)
x = model.matrix(years_b4_death ~., data = in_force_data)[, -1]
in_force_y = in_force_y[1:nrow(x),]

param = list(eta = 0.001, objective = 'survival:aft', eval_metric = 'aft-nloglik', 
max_depth = 3, aft_loss_distribution='normal', aft_loss_distribution_scale=1.2, tree_method = 'hist')

dtrain = xgb.DMatrix(x)

setinfo(dtrain, 'label_lower_bound', in_force_y$y_lower_bound)
setinfo(dtrain, 'label_upper_bound', in_force_y$y_upper_bound)
watchlist = list(train = dtrain)

(xgb_full = xgb.train(data = dtrain, params = param, booster = "gbtree", nrounds = 1000, verbose = 0, watchlist = watchlist))
(xgb_in_force = predict(xgb_full, newdata = dtrain, iterationrange = c(1, 1)))

in_force_data = cbind(in_force_data, xgb_in_force)
names(in_force_data)[names(in_force_data) == "xgb_in_force"] = "years_b4_death_pred"

in_force_data$years_b4_death_pred[is.na(in_force_data$years_b4_death) == F] = in_force_data$years_b4_death # match predictions to actual values if they exist

in_force_data = in_force_data %>%
  mutate(Year_of_Death = floor(current_year -1 + years_b4_death_pred))

alive_2024 = in_force_data %>%
  filter(Lapse.Indicator == "0") %>% # don't give DB to pp who lapsed
  filter(Death.indicator == "0") # only give DB to pp who still alive 


