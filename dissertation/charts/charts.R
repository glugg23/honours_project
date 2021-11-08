library(ggplot2)

elixir1 <- read.csv("elixir/experiment1.csv")
elixir2 <- read.csv("elixir/experiment2.csv")
elixir3 <- read.csv("elixir/experiment3.csv")
elixir4 <- read.csv("elixir/experiment4.csv")
elixir5 <- read.csv("elixir/experiment5.csv")

jade1 <- read.csv("jade/experiment1.csv")
jade2 <- read.csv("jade/experiment2.csv")
jade3 <- read.csv("jade/experiment3.csv")
jade4 <- read.csv("jade/experiment4.csv")
jade5 <- read.csv("jade/experiment5.csv")

system <- rep(c("Elixir", "JADE"), each = 5)

experiment <-
    rep(c(
        "Experiment 1",
        "Experiment 2",
        "Experiment 3",
        "Experiment 4",
        "Experiment 5"
    ),
    2)

mean_cpu <-
    c(
        mean(elixir1$cpu_usage[-(1:1)]),
        mean(elixir2$cpu_usage[-(1:1)]),
        mean(elixir3$cpu_usage[-(1:1)]),
        mean(elixir4$cpu_usage[-(1:1)]),
        mean(elixir5$cpu_usage[-(1:1)]),
        mean(jade1$cpu_usage[-(1:1)]),
        mean(jade2$cpu_usage[-(1:1)]),
        mean(jade3$cpu_usage[-(1:1)]),
        mean(jade4$cpu_usage[-(1:1)]),
        mean(jade5$cpu_usage[-(1:1)])
    )

cpu_df <- data.frame(system, experiment, mean_cpu)

ggplot(cpu_df, aes(x = experiment, y = mean_cpu, fill = system)) +
    geom_col(position = "dodge") +
    theme_bw() +
    labs(x = "Experiment", y = "Mean CPU utilisation (%)", fill = "System")

mean_memory <-
    c(
        mean(elixir1$memory[-(1:1)]) / 1024 / 1024,
        mean(elixir2$memory[-(1:1)]) / 1024 / 1024,
        mean(elixir3$memory[-(1:1)]) / 1024 / 1024,
        mean(elixir4$memory[-(1:1)]) / 1024 / 1024,
        mean(elixir5$memory[-(1:1)]) / 1024 / 1024,
        mean(jade1$memory[-(1:1)]) / 1024 / 1024,
        mean(jade2$memory[-(1:1)]) / 1024 / 1024,
        mean(jade3$memory[-(1:1)]) / 1024 / 1024,
        mean(jade4$memory[-(1:1)]) / 1024 / 1024,
        mean(jade5$memory[-(1:1)]) / 1024 / 1024
    )

memory_df <- data.frame(system, experiment, mean_memory)

ggplot(memory_df, aes(x = experiment, y = mean_memory, fill = system)) +
    geom_col(position = "dodge") +
    theme_bw() +
    labs(x = "Experiment", y = "Mean memory usage (MiB)", fill = "System")

elixir1_time_diff <- c()
elixir2_time_diff <- c()
elixir3_time_diff <- c()
elixir4_time_diff <- c()
elixir5_time_diff <- c()
jade1_time_diff <- c()
jade2_time_diff <- c()
jade3_time_diff <- c()
jade4_time_diff <- c()
jade5_time_diff <- c()

for (i in 1:10) {
    elixir1_time_diff <-
        c(elixir1_time_diff, as.double(difftime(
            strptime(elixir1$time[elixir1$run == i][221], "%H:%M:%OS"),
            strptime(elixir1$time[elixir1$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    elixir2_time_diff <-
        c(elixir2_time_diff, as.double(difftime(
            strptime(elixir2$time[elixir2$run == i][221], "%H:%M:%OS"),
            strptime(elixir2$time[elixir2$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    elixir3_time_diff <-
        c(elixir3_time_diff, as.double(difftime(
            strptime(elixir3$time[elixir3$run == i][221], "%H:%M:%OS"),
            strptime(elixir3$time[elixir3$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    elixir4_time_diff <-
        c(elixir4_time_diff, as.double(difftime(
            strptime(elixir4$time[elixir4$run == i][221], "%H:%M:%OS"),
            strptime(elixir4$time[elixir4$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    elixir5_time_diff <-
        c(elixir5_time_diff, as.double(difftime(
            strptime(elixir5$time[elixir5$run == i][221], "%H:%M:%OS"),
            strptime(elixir5$time[elixir5$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    jade1_time_diff <-
        c(jade1_time_diff, as.double(difftime(
            strptime(jade1$time[jade1$run == i][221], "%H:%M:%OS"),
            strptime(jade1$time[jade1$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    jade2_time_diff <-
        c(jade2_time_diff, as.double(difftime(
            strptime(jade2$time[jade2$run == i][221], "%H:%M:%OS"),
            strptime(jade2$time[jade2$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    jade3_time_diff <-
        c(jade3_time_diff, as.double(difftime(
            strptime(jade3$time[jade3$run == i][221], "%H:%M:%OS"),
            strptime(jade3$time[jade3$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    jade4_time_diff <-
        c(jade4_time_diff, as.double(difftime(
            strptime(jade4$time[jade4$run == i][221], "%H:%M:%OS"),
            strptime(jade4$time[jade4$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
    
    jade5_time_diff <-
        c(jade5_time_diff, as.double(difftime(
            strptime(jade5$time[jade5$run == i][221], "%H:%M:%OS"),
            strptime(jade5$time[jade5$run == i][1], "%H:%M:%OS"),
            units = "secs"
        )))
}

mean_time_diff <-
    c(
        mean(elixir1_time_diff),
        mean(elixir2_time_diff),
        mean(elixir3_time_diff),
        mean(elixir4_time_diff),
        mean(elixir5_time_diff),
        mean(jade1_time_diff),
        mean(jade2_time_diff),
        mean(jade3_time_diff),
        mean(jade4_time_diff),
        mean(jade5_time_diff)
    )

time_diff_df <- data.frame(system, experiment, mean_time_diff)

ggplot(time_diff_df,
       aes(x = experiment, y = mean_time_diff, fill = system)) +
    geom_col(position = "dodge") +
    theme_bw() +
    labs(x = "Experiment", y = "Mean total time taken (secs)", fill = "System")

elixir5_1 <- elixir5[elixir5$run == 1,]
elixir5_1 <- elixir5_1[-(1:1),] # Remove round 0 row
elixir5_1$system <- rep(c("Elixir"), 220)

jade5_1 <- jade5[jade5$run == 1,]
jade5_1 <- jade5_1[-(1:1),] # Remove round 0 row
jade5_1$system <- rep(c("JADE"), 220)

both5_1 <- rbind(elixir5_1, jade5_1)

ggplot(both5_1, aes(
    x = round,
    y = memory / 1024 / 1024,
    colour = system
)) +
    geom_line() +
    theme_bw() +
    labs(x = "Rounds", y = "Memory usage (MiB)", colour = "System")
