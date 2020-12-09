#Extract Data

{
  
  library(xml2)
  library(rvest)
  
  player_position <- c("PG", "SG", "SF", "PF", "C")
  stat_type <- c("Totals", "Misc_Stats", "Advanced_Stats")
  season <- as.character(1947:2020)
  
  
  data_list <- list()
  
  for (i in stat_type) {
    
    position_per_stat_type <- list()
    
    for (j in player_position) {
      
      season_per_position <- list()
      
      for (k in season) {
        
        my_url <- paste("https://basketball.realgm.com/nba/stats/", k, "/", i, "/All/player/", j, "/asc/1/Regular_Season?rookies=", sep = "")
        file <- read_html(my_url)
        tables <- html_nodes(file, "table")
        table1 <- html_table(tables[1], fill = TRUE)
        
        season_per_position <- c(season_per_position, table1)
        
      }
      
      position_per_stat_type <- c(position_per_stat_type, list(season_per_position))
      
    }
    
    data_list <- c(data_list, list(position_per_stat_type))
    
  }
  
}


save(AscRookie, AscQualified, file = "ASC.RData")


#remove first column
#add year
#add position category
#rbind within stat type

clean <- function(list){
  
  
  stat_type_result <- list()
  
  
  for (i in 1:3) {
    
    position_result <- list()
    
    for (j in 1:5) {
      
      year <- seq(to = 2020, by = 1, length.out = length( list[[i]][[j]] ))
      
      for (k in 1:length( list[[i]][[j]] ) ) {
        
        list[[i]][[j]][[k]] <- list[[i]][[j]][[k]][-1]
        
        list[[i]][[j]][[k]] <- cbind(list[[i]][[j]][[k]], YEAR = as.character(year[k]), POSITION = player_position[j])
        
      }
      
      pos_df <- do.call("rbind", list[[i]][[j]])
      
      position_result <- c(position_result, list(pos_df))
      
      
    }
    
    stat_type_df <- do.call("rbind", position_result)
    
    stat_type_result <- c(stat_type_result, list(stat_type_df))
    
  }
  
  stat_type_result
  
}


data_list <- clean(data_list)

total_data <- data_list[[1]]
misc_data <-data_list[[2]]
adv_data <- data_list[[3]]


library(dplyr)

two_season <- full_join(total_data, misc_data, by = c("Player", "Team", "YEAR", "POSITION", "ROOKIE"))

reg_season <- full_join(two_season, adv_data, by = c("Player", "Team", "YEAR", "POSITION", "ROOKIE"))

reg_season[8:21] <- lapply(reg_season[8:21], as.numeric)
reg_season[47:62] <- lapply(reg_season[47:62], as.numeric)





two_season_rookie <- full_join(total_data, misc_data, by = c("Player", "Team", "YEAR", "POSITION", "ROOKIE"))
reg_season_rookie <- full_join(two_season_rookie, adv_data, by = c("Player", "Team", "YEAR", "POSITION", "ROOKIE"))
reg_season_rookie[8:21] <- lapply(reg_season_rookie[8:21], as.numeric)
reg_season_rookie[47:62] <- lapply(reg_season_rookie[47:62], as.numeric)


final <- rbind(reg_season_rookie, reg_season)

final[36:37] <- lapply(final[36:47], as.numeric)


dup <- which(duplicated(final[-25]))

final <- final[-dup, ] #remove non rookie duplicates


final <- distinct(final, Player, YEAR, .keep_all = TRUE)


write.csv(final, "Reg_Season_2.csv", row.names = FALSE)































player_position <- c("PG", "SG", "SF", "PF", "C")
stat_type <- c("Totals", "Misc_Stats", "Advanced_Stats")
season <- as.character(1947:2020)


pages <- as.character((1:14))


salary <- list()

for (i in pages) {
  
  my_url2 <- paste("http://www.espn.com/nba/salaries/_/year/2020/page/", i, "/seasontype/4", sep = "")
  file <- read_html(my_url2)
  tables <- html_nodes(file, "table")
  table1 <- html_table(tables[1], fill = TRUE)
  
  salary <- c(salary, table1)
  
}


salary_df <- do.call("rbind", salary)


index <- which(salary_df$X1 == "RK")


salary_df <- salary_df[-index, ]


salary_df <- salary_df[, -1]


library(stringr)


Player <- str_remove(salary_df$X2, ", [A-Z]*")

player_salary <- str_remove_all(salary_df$X4, "[,$]")

salary_df <- cbind(Player = Player, salary = player_salary)

salary_df <- as.data.frame(salary_df)

salary_df$salary <- as.numeric(salary_df$salary)








index <- which(total_data$YEAR == 2019)

total_data <- total_data[index, ]



final2 <- inner_join(total_data, salary_df, by = "Player")


write.csv(final2, "2019_2020_Salary.csv")





