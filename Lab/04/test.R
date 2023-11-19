# using spotifyr to grab lyrics data
# install.packages("spotifyr")
# install_github('charlie86/spotifyr')
library(spotifyr)

# # using genius to lyrics, failed
# library(geniusr)
# library(dplyr)
# library(tidytext)
# 
# Sys.setenv(GENIUS_API_TOKEN = 'MopeXJwy6Z5B5Jye3YCvgEYurwGxqFjjhkSrLZk2564jxgXTWjNtXxD94GllMwEc')
# 
# # Lyrics
# thingCalledLoveLyrics <- get_lyrics_id(song_id = 81524)

# switching to spotifyr library
# STEP 1: setting token
# get spotify access token:
Sys.setenv(SPOTIFY_CLIENT_ID = '5a8451083ff143ada759c6395dd343e1')
Sys.setenv(SPOTIFY_CLIENT_SECRET = 'aaaf9164b35d4fc1ada87f7e3a5f3b08')

access_token <- get_spotify_access_token()

# get album data
# Here I select "Halloqveen" by Qveen Herby
# Halloqveen_data = get_album(album_id = '0ETFjACtuP2ADo6LFhL6HN', authorization = access_token)
# get album 
Album_Songs = get_album_tracks("3g3P8dofBdBkEioDroTO2H", authorization = access_token)

# spotifyr did not provide a function for fetching lyrics, so to get lyrics, I have to use a external api provided by a Github author:
library(httr)
library(jsonlite)

# get the lyrics data
lyrics_df = data.frame(track = character(), name = character(), timeTag = character(), words = character(), stringsAsFactors = F)
# for loop
Album_Songs$id[1]
for (i in 1:nrow(Album_Songs)) {
  print(i)
  # construct request header
  response = GET("https://spotify-lyric-api-984e7b4face0.herokuapp.com", query = list(trackid = Album_Songs$id[i], format = "lrc"))
  
  # parse the result
  response = content(response, "parsed")
  
  # convert to data frame
  for (line in response$lines) {
    new_row = data.frame(track = i, name = Album_Songs$name[i], timeTag = line$timeTag, words = line$words, stringsAsFactors = FALSE)
    lyrics_df = rbind(lyrics_df, new_row)
  }
}
