# Function to find the vector position (in env Dates) with the closest date
find_date = function(obs_date, env_date) {
  which(abs(env_date-obs_date) == min(abs(env_date-obs_date)))[1]
}