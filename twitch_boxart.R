#get image

for (i in 1:nrow(dt.games)) {
  tryCatch({
    game <- dt.games$game_name[i]
    image.url <- dt.games$box_art_url[i]
    image.url <- gsub("\\{|\\}", "", image.url)
    image.url <- gsub("-widthxheight", "", image.url)
    game <- gsub("[.]","",game)
    download.file(image.url, paste("images/", game,".jpg", sep = ""), mode = 'wb')
  }, error=function(e){})
  print(paste(c("Record ", i, " of ", nrow(dt.games)), collapse = ""))
}
