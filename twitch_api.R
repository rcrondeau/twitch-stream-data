
#get url, customer key and customer secret
url <- "https://api.twitch.tv/helix/streams?first=100"
#enter your key and secret
c.key <- "yourkey"
c.secret <- "yoursecret"

#get token
req.token <- POST(url = paste("https://id.twitch.tv/oauth2/token?client_id=", c.key, "&client_secret=", c.secret, "&grant_type=client_credentials", sep = ""))
token <- paste("Bearer", httr::content(req.token)$access_token)

#get top 100 streams
req <- httr::GET(url, httr::add_headers(Authorization = token))
json <- httr::content(req, as = "text")
data <- fromJSON(json)
df.stream <- data$data

dt.streams <- data.table()
dt.streams <- rbind(dt.streams, df.stream)

#get next n streams 
dt.stream2 <- data.table("test")
while (length(dt.stream2) > 0) {
  if (nrow(dt.streams) == 10000*(as.numeric(substr(nrow(dt.streams),1,1)))) {
    Sys.sleep(60)
  }
  dt.stream2 <- data.table()
  cursor <- httr::content(req)$pagination$cursor
  url2 <- paste("https://api.twitch.tv/helix/streams?first=100&after=",cursor, sep = "")
  req <- httr::GET(url2, httr::add_headers(Authorization = token))
  json <- httr::content(req, as = "text")
  data <- fromJSON(json)
  df.stream2 <- data$data
  dt.stream2 <- data.table(df.stream2)
  dt.streams <- rbind(dt.streams, dt.stream2)
}

#remove streams with no games
dt.streams.temp <- subset(dt.streams, game_id != "")
dt.streams.temp <- subset(dt.streams.temp, game_id != 0)

#get unique games only
dist.games <- subset(dt.streams.temp, !duplicated(game_id))
dist.games <- dist.games[!(dist.games$game_id %in% dist.games.final$game_id), ]
dist.games.final <- rbind(dist.games.final, dist.games)
#dist.games.final <- dist.games.final.t
#dist.streams <- distinct(dt.streams)



#get game info

dt.games <- data.table()
for (i in 1:nrow(dist.games)) {
  if (as.numeric(i) == 100*(as.numeric(substr(i,1,1)))) {
    Sys.sleep(120)
  }
  gameid <- dist.games$game_id[i]
  g.url <- paste("https://api.twitch.tv/helix/games", "?id=",gameid, sep = "")
  #g.url <- paste("https://api.twitch.tv/helix/games?id=493057", sep = "")
  req <- httr::GET(g.url, httr::add_headers(Authorization = token))
  if (req$status_code == 429) {
    Sys.sleep(60)
    req <- httr::GET(g.url, httr::add_headers(Authorization = token))
  }
  json <- httr::content(req, as = "text")
  data <- fromJSON(json)
  df.game <- data$data
  dt.games <- rbind(dt.games, df.game)
  print(paste(c("Record ", i, " of ", nrow(dist.games)), collapse = ""))
}

names(dt.games) <- c("game_id", "game_name", "box_art_url")
#games.list <- data.table()
games.list <- rbind(games.list, dt.games)

#Combine Game with Stream
dt.streams.final <- merge(x = dt.streams.temp, y = games.list, by = "game_id")
dt.streams.final$date <- Sys.time()

date <- Sys.time()
date <- date %>% str_replace_all(":", "")
date <- date %>% str_replace_all(" ", "_")

#save as csv
fwrite(dt.streams.final, paste("data/twitch_streaming_data_", date, ".csv", sep = ""))
