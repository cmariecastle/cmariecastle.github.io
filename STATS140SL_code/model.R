library(caret)
library(ggplot2)
library(leaps)
library(tidyverse)

# Reading in data set ----------------------------------------------------------

dat <- read.csv("2019_2020_Salary.csv", stringsAsFactors = FALSE)
# Separate player names
players <- dat$Player
names(players) <- dat$X
# Remove Player and YEAR columns, keep row names as ID
dat <- dat %>%
  rename(ID = X) %>%
  select(-Player, -YEAR) %>%
  mutate(
    Team = factor(Team),
    POSITION = factor(
      POSITION, levels = unique(as.character(POSITION)), ordered = TRUE
    )
  )

# Variable Selection -----------------------------------------------------------

# Create matrix w/numeric predictors
predmat1 <- dat %>%
  select_if(is.numeric) %>%
  select(-ID, -salary) %>%
  as.matrix()
# Do we have linear combinations in the predictors?
findLinearCombos(predmat1)
# Remove linear combinations
predmat2 <- predmat1[, -findLinearCombos(predmat1)$remove]
# Do we have highly correlated predictors?
findCorrelation(cor(predmat2))
# Remove highly correlated predictors
predmat <- predmat2[, -findCorrelation(cor(predmat2))]
# Data frame w/remaining numeric predictors plus ID, Team, POSITION, salary
dat_new <- data.frame(
  ID = dat$ID, Team = dat$Team, POSITION = dat$POSITION, predmat,
  salary = dat$salary
)

# Best subset selection (numeric predictors only)
subsel <- regsubsets(
  dat_new$salary ~ ., data = data.frame(predmat),
  nvmax = ncol(predmat), method = "exhaustive"
)
summ_subsel <- summary(subsel)
summ_subsel

# Plots of Cp and BIC vs. # of predictors
par(mfrow = c(1, 2))
plot(
  seq_along(summ_subsel$cp), summ_subsel$cp, type = "b",
  xlab = "Subset size", ylab = "Cp", las = 1
)
abline(v = which.min(summ_subsel$cp), col = 2)
plot(
  seq_along(summ_subsel$bic), summ_subsel$bic, type = "b",
  xlab = "Subset size", ylab = "BIC", las = 1
)
abline(v = which.min(summ_subsel$bic), col = 2)
par(mfrow = c(1, 1))

which.min(summ_subsel$cp)
which.min(summ_subsel$bic)
# Mean subset size btwn Cp and BIC is 8

# Analysis ---------------------------------------------------------------------

set.seed(2020)
# Indices for training observations (70% of players)
training <- sample(nrow(dat), floor(0.7 * nrow(dat)))
# Data frame of best subset of size 8 plus ID, Team, POSITION, salary
dat8 <- data.frame(
  ID = dat_new$ID, Team = dat_new$Team, POSITION = dat_new$POSITION,
  predmat[, summ_subsel$which[8, -1]], salary = dat_new$salary
)
# Linear regression model
model8 <- lm(salary ~ . - ID, data = dat8, subset = training)
summary(model8)
# Predictions from this model
pred8 <- predict(model8, newdata = dat8[-training,])
# MSE
mean((dat8[-training, "salary"] - pred8)^2)
# RMSE
sqrt(mean((dat8[-training, "salary"] - pred8)^2))

# Model Performance ------------------------------------------------------------

# Diagnostic plots from plot.lm()
par(mfrow = c(2, 2))
plot(model8)
par(mfrow = c(1, 1))

# Actual and predicted total salary by team in millions
datsum_team <- dat8[-training,] %>%
  cbind(predicted_salary = pred8) %>%
  group_by(Team) %>%
  summarize(
    actual = sum(salary) / 10^6,
    prediction = sum(predicted_salary) / 10^6
  ) %>%
  select(-Team) %>%
  as.matrix() %>%
  t()
colnames(datsum_team) <- levels(dat8$Team)
datsum_team
# Side-by-side bar plot comparing actual and predicted total salary by team
barplot(
  datsum_team, beside = TRUE, las = 2,
  main = "Total Salaries by Team", ylab = "Salary (in millions of US dollars)",
  legend.text = rownames(datsum_team), args.legend = list(bty = "n")
)

# Actual and predicted total salary by positions in millions
datsum_pos <- dat8[-training,] %>%
  cbind(predicted_salary = pred8) %>%
  group_by(POSITION) %>%
  summarize(
    actual = sum(salary) / 10^6,
    prediction = sum(predicted_salary) / 10^6
  ) %>%
  select(-POSITION) %>%
  as.matrix() %>%
  t()
colnames(datsum_pos) <- levels(dat8$POSITION)
datsum_pos
# Side-by-side bar plot comparing actual and predicted total salary by position
barplot(
  datsum_pos, beside = TRUE, las = 1,
  main = "Total Salaries by Position",
  ylab = "Salary (in millions of US dollars)",
  legend.text = rownames(datsum_pos),
  args.legend = list(x = "topleft", bty = "n")
)

plot(
  pred8 / 10^6, dat8[-training, "salary"] / 10^6, asp = 1, las = 1, pch = 19,
  main = "Actual versus Predicted Player Salaries",
  xlab = "Predicted salary (in millions of USD)",
  ylab = "Acutal Salary (in millions of USD)"
)
abline(a = 0, b = 1, col = "gray")
