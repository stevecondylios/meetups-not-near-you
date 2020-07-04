
# Replace topic with the url segment for any topic on meetup.com
# For ideas, see: https://www.meetup.com/topics/

topic <- "r-project-for-statistical-computing"

topic_url <- paste0("https://www.meetup.com/topics/", topic, "/all/")


# Install libraries if you don't already have them:
# install.packages("tidyverse"); install.packages("rvest"); 
# install.packages("jsonlite"); install.packages(purrr)

library(tidyverse)
library(rvest)
library(jsonlite)
library(purrr)
library(lubridate)



index_html <- read_html(topic_url)

(meetup_links <- index_html %>% 
  html_nodes("li.gridList-item a") %>% 
  .[c(TRUE, FALSE)] %>% 
  html_attr("href"))


# Botswana, Manaus, Yaounde, Mexico, Skopje --- cool -- it works!!





# Define a function that grabs the upcoming events from a meetup group page

get_meetup_info <- function(meetup_url) {
  
  meetup_url %>% 
    read_html %>% 
    
    html_nodes("script") %>% 
    
    # Inspecting HTML in the browser shows the tenth <script> is the one we're after
    .[10] %>% 
    
    # Get it's content
    html_text %>% 
    
    # Trim the ends off
    str_split("window.APP_RUNTIME=") %>% 
    .[[1]] %>% 
    .[2] %>% 
    {substr(., 1, nchar(.) - 1)} %>% # (this removes the final semi-colon)
    
    # Parse it
    fromJSON %>% 
    
    # There is yet another JSON glob nested within the list
    # This one contains &quot; in place of ", so let's fix that
    .$escapedState %>% 
    gsub("&quot;", '"', .) %>%
    
    # Now parse!
    fromJSON
} 




# Define functions that extract the things we're after

get_group <- function(meetup_info) {
  meetup_info$api$groupEvents$value$group$name
}

get_location <- function(meetup_info) {
  meetup_info$api$groupEvents$value$group$localized_location
}

is_online <- function(meetup_info) {
  meetup_info$api$groupEvents$value$is_online_event
}

is_upcoming <- function(meetup_info) {
  meetup_info$api$groupEvents$value$status
}

is_free <- function(meetup_info) {
  meetup_info$api$groupEvents$value$member_pay_fee
}

get_link <- function(meetup_info) {
  meetup_info$api$groupEvents$value$link
}

get_name <- function(meetup_info) {
  meetup_info$api$groupEvents$value$name
}

get_description <- function(meetup_info) {
  meetup_info$api$groupEvents$value$description
}

find_us <- function(meetup_info) {
  meetup_info$api$groupEvents$value$how_to_find_us # https://www.meetup.com/atlantaruby/
}

get_local_date <- function(meetup_info) {
  meetup_info$api$groupEvents$value$local_date
}

get_local_time <- function(meetup_info) {
  meetup_info$api$groupEvents$value$local_time
}

get_utc_offset <- function(meetup_info) {
  meetup_info$api$groupEvents$value$utc_offset
}

get_duration <- function(meetup_info) {
  meetup_info$api$groupEvents$value$duration
}

  
  
# Set up some configs before the crawl

sleep_between_requests <- 10 # Seconds

make_df <- function() { 
  data.frame(group=character(),
  group_url=character(),
  location=character(),
  online=character(),
  upcoming=character(),
  free=character(),
  link=character(), 
  name=character(), 
  description=character(),
  find_us=character(),
  local_date=character(),
  local_time=character(),
  utc_offset=character(),
  duration=character(),
  stringsAsFactors = FALSE)
}

# Try setting depth to a smaller number to start with, e.g. 50
depth <- length(meetup_links) 

list_output <- list()








# Here goes... This will take a few minutes

for(i in 1:depth) {
  
  print(paste0("Grabbing link number ", i, " of ", depth))
  
  meetup_info <- get_meetup_info(meetup_links[i])
  
  len <- length(get_group(meetup_info))
  
  if(len != 0) tryCatch({ # tryCatch for error handling
  
    output <- make_df()
    
    output[1:len, "group"] <- get_group(meetup_info)
    output[1:len, "group_url"] <- meetup_links[i]
    output[1:len, "location"] <- get_location(meetup_info)
    
    tryCatch(output[1:len, "online"] <- is_online(meetup_info), 
             error = function(e) { output[1:len, "online"] <- NA})
    tryCatch(output[1:len, "upcoming"] <- is_upcoming(meetup_info), 
             error = function(e) { output[1:len, "upcoming"] <- NA})
    tryCatch(output[1:len, "free"] <- is_free(meetup_info), 
             error = function(e) { output[1:len, "free"] <- NA})
    
    output[1:len, "link"] <- get_link(meetup_info)
    output[1:len, "name"] <- get_name(meetup_info)
    
    tryCatch(output[1:len, "description"] <- get_description(meetup_info), 
             error = function(e) { output[1:len, "description"] <- NA})
    
    # This is very useful, but not all events provide it
    tryCatch(output[1:len, "find_us"] <- find_us(meetup_info), 
             error = function(e) { output[1:len, "find_us"] <- NA})
    
    tryCatch(output[1:len, "local_date"] <- get_local_date(meetup_info), 
             error = function(e) { output[1:len, "local_date"] <- NA})
    tryCatch(output[1:len, "local_time"] <- get_local_time(meetup_info), 
             error = function(e) { output[1:len, "local_time"] <- NA})
    tryCatch(output[1:len, "utc_offset"] <- get_utc_offset(meetup_info), 
             error = function(e) { output[1:len, "utc_offset"] <- NA})
    tryCatch(output[1:len, "duration"] <- get_duration(meetup_info), 
             error = function(e) { output[1:len, "duration"] <- NA})
    
    list_output[[i]] <- output
    
  }, error = function(e) { print("Skipping due to error")})
  
  if(sleep_between_requests > 0) {
    print(paste0("Waiting ", sleep_between_requests, " seconds between requests"))
    Sys.sleep(sleep_between_requests)
  }
  
}






# Collate all events into a single data.frame for easy inspection
meetups <- do.call(rbind, list_output) %>% as_tibble()


# Convert description field's character entities to HTML so it can be parsed
replace_character_entities <- function(char_entity) {
    xml2::xml_text(xml2::read_html(paste0("<x>", char_entity, "</x>")))
}
meetups$desc_clean <- sapply(meetups$description, replace_character_entities) %>% unname


# Extract any links we find in the cleaned description field 
find_all_links <- function(html) {
  tryCatch(html %>% read_html %>% html_nodes("a") %>% html_attr("href") %>% unname,
           error = function(e) { NA })
}
meetups$all_links <- meetups$desc_clean %>% sapply(find_all_links) %>% unname



# Scan for relevant links - we'll keep any that conotain the 
# terms 'zoom', 'meet.google', 'youtube', or 'facebook'
find_specific_links <- function(all_links, search_term) {
  all_links %>% 
  { grep(search_term, ., value = TRUE) }
}

meetups$zoom_links <- meetups$all_links %>% sapply(find_specific_links, search_term = "zoom")
meetups$meet_links <- meetups$all_links %>% sapply(find_specific_links, search_term = "meet\\.google")
meetups$youtube_links <- meetups$all_links %>% sapply(find_specific_links, search_term = "youtube")
meetups$facebook_links <- meetups$all_links %>% sapply(find_specific_links, search_term = "facebook")



# Find what time the events are on in *your* timezone
(your_local_timezone <- Sys.timezone())

meetups <- meetups %>% 
  
  # Combine date and time
  mutate(datetime = ifelse(!is.na(local_date) & !is.na(local_time),
                           paste(local_date, local_time), NA)) %>% 
  
  # Convert to datetime object, apply offset, and convert start time to your_local_timezone
  mutate(your_local_time = datetime %>% ymd_hm() %>% 
  {. - as.numeric(meetups$utc_offset)/1000} %>% 
  with_tz(your_local_timezone)) 
  





# Explore!

# Here we look at only results that contain a zoom, google meet, youtube, facebook or 
# other online stream link, arranged by date

meetups %>%
  filter(map_lgl(zoom_links, ~ .x %>% length %>% {. != 0}) |
           map_lgl(meet_links, ~ .x %>% length %>% {. != 0}) |
           map_lgl(youtube_links, ~ .x %>% length %>% {. != 0}) |
           map_lgl(facebook_links, ~ .x %>% length %>% {. != 0}) |
           (!is.na(find_us)) & online == TRUE) %>%
  mutate(available_links = mapply(c, find_us, zoom_links, meet_links, youtube_links, facebook_links)) %>% 
  select(group, name, desc_clean, available_links, your_local_time) %>% 
  arrange(your_local_time) %>% 
  View












