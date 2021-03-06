library(forecast)

df_train <- read.csv("solar_train.txt", header = FALSE)

OUTPUT_DIR = "Mean_Moving_window"
input_size = 24*1.25
max_forecast_horizon <- 24
seasonality_period_1 <- 24
seasonality_period_2 <- 168
seasonality_period_3 <- 8766

start_time <- Sys.time()

for (idr in 1 : nrow(df_train)) {
  print(idr)
  OUTPUT_PATH = paste(OUTPUT_DIR, "energy_mstl_test", sep = '/')
  OUTPUT_PATH = paste(OUTPUT_PATH, max_forecast_horizon, sep = '')
  OUTPUT_PATH = paste(OUTPUT_PATH, 'i', input_size, sep = '')
  OUTPUT_PATH = paste(OUTPUT_PATH, 'txt', sep = '.')
  
  time_series_data <- as.numeric(df_train[idr,])
  time_series_mean <- mean(time_series_data)
  
  time_series_data <- time_series_data/(time_series_mean)
  
  time_series_log <- log(time_series_data + 1)
  time_series_length = length(time_series_log)
  
  stl_result = tryCatch({
    sstl = mstl(msts(time_series_log, seasonal.periods = c(seasonality_period_1,seasonality_period_2, seasonality_period_3)), s.window = "period")
    seasonal_vect1 = as.numeric(sstl[, 3]) 
    seasonal_vect2 = as.numeric(sstl[, 4])
    seasonal_vect3 = as.numeric(sstl[, 5])
    levels_vect = as.numeric(sstl[, 2])
    values_vect = as.numeric(sstl[, 2] + sstl[, 6])
    cbind(seasonal_vect1, seasonal_vect2, seasonal_vect3, levels_vect, values_vect)
  },error = function(e) {
    seasonal_vect1 = rep(0, length(time_series_length))
    seasonal_vect2 = rep(0, length(time_series_length))
    seasonal_vect3 = rep(0, length(time_series_length))
    levels_vect = time_series_log
    values_vect = time_series_log
    cbind(seasonal_vect1, seasonal_vect2, seasonal_vect3, levels_vect, values_vect)
  })
  
  
  input_windows = embed(time_series_log[1 : (time_series_length)], input_size)[, input_size : 1]
  seasonality_windows_1 = embed(stl_result[1 : (time_series_length), 1], input_size)[, input_size : 1]
  seasonality_windows_2 = embed(stl_result[1 : (time_series_length), 2], input_size)[, input_size : 1]
  seasonality_windows_3 = embed(stl_result[1 : (time_series_length), 3], input_size)[, input_size : 1]
  
  seasonality1_windows =  seasonality_windows_1[, c(30)]
  seasonality2_windows =  seasonality_windows_2[, c(30)]
  seasonality3_windows =  seasonality_windows_3[, c(30)]
  
  meanvalues <- rowMeans(input_windows)
  input_windows <- input_windows - meanvalues
  
  sav_df = matrix(NA, ncol = (4 + input_size + 3), nrow = nrow(input_windows))
  sav_df = as.data.frame(sav_df)
  sav_df[, 1] = paste(idr - 1, '|i', sep = '')
  sav_df[, 2] = seasonality1_windows
  sav_df[, 3] = seasonality2_windows
  sav_df[, 4] = seasonality3_windows
  sav_df[, 5 : (input_size + 3 + 1)] = input_windows
  sav_df[, (input_size + 3 + 2)] = '|#'
  sav_df[, (input_size + 3 + 3)] = time_series_mean
  sav_df[, (input_size + 3 + 4)] = meanvalues
  
  write.table(sav_df, file = OUTPUT_PATH, row.names = F, col.names = F, sep = " ", quote = F, append = TRUE)
}

end_time <- Sys.time()
print(paste0("Total time", (end_time - start_time)))
