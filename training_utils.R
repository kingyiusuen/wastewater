library(caret)
library(tools)
library(purrr)


compute_rmse <- function(reverse_log_transform = FALSE) {
  # Compute the RMSE
  f <- function(data, lev = NULL, model = NULL, reverse_log_transform = FALSE) {
    if (reverse_log_transform) {
      data$pred <- 10^data$pred
      data$obs <- 10^data$obs
    }
    return(c("RMSE" = sqrt(mean((data$pred - data$obs)^2))))
  }

  return(partial(f, reverse_log_transform = reverse_log_transform))
}


train_one_model <- function(formula, data, model = "lm", cv_method = "none", num_splits = 5, num_repeats = 5, seed = 123, ...) {
  # For reproducibility
  set.seed(seed)
  if (cv_method == "cv") {
    index <- createFolds(1:nrow(data), k = num_splits)
  } else if (cv_method == "repeatedcv") {
    index <- createMultiFolds(1:nrow(data), k = num_splits, times = num_repeats)
  } else {
    index <- NULL
  }

  # Check if the response variable is log-transformed
  is_log_transformed <- grepl("log10", formula[2], fixed = TRUE)
  summary_function <- compute_rmse(reverse_log_transform = is_log_transformed)
  
  # Arguments used to control the computational nuances of the training process
  train_control <- trainControl(
    method = cv_method,
    number = num_splits,
    index = index,
    summaryFunction = summary_function
  )
  
  # Fit the model
  train_object <- train(
    formula,
    data = data,
    method = model,
    trControl = train_control,
    ...
  )
  
  if (cv_method == "none") {
    preds_and_obs <- data.frame(
      pred = train_object$finalModel$fitted.values,
      obs = train_object$finalModel$model$.outcome
    )
    train_object$results <- data.frame(t(summary_function(preds_and_obs)))
  }
  return(train_object)
}


train_models <- function(formulas, data, by_WWTP = TRUE,...) {
  # If by_WWTP is TRUE, train the models for each WWTP separately
  if (by_WWTP) {
    codes <- unique(data$Code)
    metrics <- data.frame(matrix(nrow = length(formulas), ncol = length(codes)))
    for (i in seq_along(formulas)) {
      for (j in seq_along(codes)) {
        train_object <- train_one_model(formula = as.formula(formulas[i]), data = data %>% filter(Code == codes[j]), ...)
        metrics[i, j] <- train_object$results$RMSE
      }
    }
    colnames(metrics) <- codes
    metrics <- cbind(formula = formulas, metrics)
  } else {
    metrics <- data.frame(matrix(nrow = length(formulas), ncol = 2))
    for (i in seq_along(formulas)) {
      train_object <- train_one_model(as.formula(formulas[i]), data, ...)
      metrics[i, 1] <- formulas[i]
      metrics[i, 2] <- train_object$results$RMSE
    }
    colnames(metrics) <- c("formula", "RMSE")
  }
  return(metrics)
}


get_coefs_by_WWTP <- function(formula, data, ...) {
  # Extract the coefficient of the first predictor
  codes <- unique(data$Code)
  coefs <- data.frame(matrix(nrow = length(codes), ncol = 3))
  for (i in seq_along(codes)) {
    train_object <- train_one_model(as.formula(formula), data = data %>% filter(Code == codes[i]), cv_method = "none", ...)
    summary_object <- summary(train_object$finalModel)
    coefs[i, 1] <- codes[i]
    coefs[i, 2] <- summary_object$coefficients[2, 1]
    coefs[i, 3] <- summary_object$coefficients[2, 4]
  }
  colnames(coefs) <- c("code", "est_coef", "p_value")
  return(coefs)
}


compute_var_estimator <- function(x, y){
  # Compute the variance estimator proposed by Rice (1984)
  # Reference: https://rstudio-pubs-static.s3.amazonaws.com/220965_c823353a5d654d239a00d3e210deb291.html
  data <- cbind(x, y)
  if (is.unsorted(x, na.rm = FALSE, strictly = FALSE)) {
    data <- data[order(x), ]
  }
  
  sum_sq <- 0
  for (i in 2:nrow(data)) {
    sum_sq <- sum_sq + (data[i, 2] - data[i - 1, 2])^2
  }
  var_estimator <- unname(1 / (2 * (nrow(data) - 1)) * sum_sq)
  return(var_estimator)
}


get_var_estimators_by_WWTP <- function(formula, data, ...) {
  codes <- unique(data$Code)
  var_estimators <- data.frame(matrix(nrow = length(codes), ncol = 2))
  for (i in seq_along(codes)) {
    train_object <- train_one_model(as.formula(formula), data = data %>% filter(Code == codes[i]), cv_method = "none", ...)
    x <- train_object$finalModel$model[, 1]
    y <- train_object$finalModel$model[, 2]
    var_estimators[i, 1] <- codes[i]
    var_estimators[i, 2] <- compute_var_estimator(x, y)
  }
  colnames(var_estimators) <- c("code", "var_est")
  return(var_estimators)
}