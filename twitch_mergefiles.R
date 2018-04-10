

files <- list.files(path = "data", pattern="*.csv", full.names = TRUE)
require(purrr)

streams.df <- files %>% map_dfr(read.csv)
#save as csv
fwrite(streams.df, paste("data/all/twitch_streaming_data_all.csv", sep = ""))