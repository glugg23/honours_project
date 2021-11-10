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

elixir1$memory <- elixir1$memory / 1024 / 1024
elixir2$memory <- elixir2$memory / 1024 / 1024
elixir3$memory <- elixir3$memory / 1024 / 1024
elixir4$memory <- elixir4$memory / 1024 / 1024
elixir5$memory <- elixir5$memory / 1024 / 1024

jade1$memory <- jade1$memory / 1024 / 1024
jade2$memory <- jade2$memory / 1024 / 1024
jade3$memory <- jade3$memory / 1024 / 1024
jade4$memory <- jade4$memory / 1024 / 1024
jade5$memory <- jade5$memory / 1024 / 1024

elixir1$time_converted <- strptime(elixir1$time, "%H:%M:%OS")
elixir2$time_converted <- strptime(elixir2$time, "%H:%M:%OS")
elixir3$time_converted <- strptime(elixir3$time, "%H:%M:%OS")
elixir4$time_converted <- strptime(elixir4$time, "%H:%M:%OS")
elixir5$time_converted <- strptime(elixir5$time, "%H:%M:%OS")

jade1$time_converted <- strptime(jade1$time, "%H:%M:%OS")
jade2$time_converted <- strptime(jade2$time, "%H:%M:%OS")
jade3$time_converted <- strptime(jade3$time, "%H:%M:%OS")
jade4$time_converted <- strptime(jade4$time, "%H:%M:%OS")
jade5$time_converted <- strptime(jade5$time, "%H:%M:%OS")

elixir1$time_diff <-
    ave(
        as.numeric(elixir1$time_converted),
        factor(elixir1$run),
        FUN = function(x)
            c(NA, diff(x))
    )
elixir2$time_diff <-
    ave(
        as.numeric(elixir2$time_converted),
        factor(elixir2$run),
        FUN = function(x)
            c(NA, diff(x))
    )
elixir3$time_diff <-
    ave(
        as.numeric(elixir3$time_converted),
        factor(elixir3$run),
        FUN = function(x)
            c(NA, diff(x))
    )
elixir4$time_diff <-
    ave(
        as.numeric(elixir4$time_converted),
        factor(elixir4$run),
        FUN = function(x)
            c(NA, diff(x))
    )
elixir5$time_diff <-
    ave(
        as.numeric(elixir5$time_converted),
        factor(elixir5$run),
        FUN = function(x)
            c(NA, diff(x))
    )

jade1$time_diff <-
    ave(
        as.numeric(jade1$time_converted),
        factor(jade1$run),
        FUN = function(x)
            c(NA, diff(x))
    )
jade2$time_diff <-
    ave(
        as.numeric(jade2$time_converted),
        factor(jade2$run),
        FUN = function(x)
            c(NA, diff(x))
    )
jade3$time_diff <-
    ave(
        as.numeric(jade3$time_converted),
        factor(jade3$run),
        FUN = function(x)
            c(NA, diff(x))
    )
jade4$time_diff <-
    ave(
        as.numeric(jade4$time_converted),
        factor(jade4$run),
        FUN = function(x)
            c(NA, diff(x))
    )
jade5$time_diff <-
    ave(
        as.numeric(jade5$time_converted),
        factor(jade5$run),
        FUN = function(x)
            c(NA, diff(x))
    )

elixir1$system <- "Elixir"
elixir2$system <- "Elixir"
elixir3$system <- "Elixir"
elixir4$system <- "Elixir"
elixir5$system <- "Elixir"

jade1$system <- "JADE"
jade2$system <- "JADE"
jade3$system <- "JADE"
jade4$system <- "JADE"
jade5$system <- "JADE"

elixir1$experiment <- "Experiment 1"
jade1$experiment <- "Experiment 1"
elixir2$experiment <- "Experiment 2"
jade2$experiment <- "Experiment 2"
elixir3$experiment <- "Experiment 3"
jade3$experiment <- "Experiment 3"
elixir4$experiment <- "Experiment 4"
jade4$experiment <- "Experiment 4"
elixir5$experiment <- "Experiment 5"
jade5$experiment <- "Experiment 5"

mean_cpu <-
    rbind(
        data.frame(
            system = elixir1$system[1],
            experiment = elixir1$experiment[1],
            mean = mean(elixir1$cpu_usage[-(1:1)]),
            sd = sd(elixir1$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = elixir2$system[1],
            experiment = elixir2$experiment[1],
            mean = mean(elixir2$cpu_usage[-(1:1)]),
            sd = sd(elixir2$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = elixir3$system[1],
            experiment = elixir3$experiment[1],
            mean = mean(elixir3$cpu_usage[-(1:1)]),
            sd = sd(elixir3$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = elixir4$system[1],
            experiment = elixir4$experiment[1],
            mean = mean(elixir4$cpu_usage[-(1:1)]),
            sd = sd(elixir4$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = elixir5$system[1],
            experiment = elixir5$experiment[1],
            mean = mean(elixir5$cpu_usage[-(1:1)]),
            sd = sd(elixir5$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = jade1$system[1],
            experiment = jade1$experiment[1],
            mean = mean(jade1$cpu_usage[-(1:1)]),
            sd = sd(jade1$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = jade2$system[1],
            experiment = jade2$experiment[1],
            mean = mean(jade2$cpu_usage[-(1:1)]),
            sd = sd(jade2$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = jade3$system[1],
            experiment = jade3$experiment[1],
            mean = mean(jade3$cpu_usage[-(1:1)]),
            sd = sd(jade3$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = jade4$system[1],
            experiment = jade4$experiment[1],
            mean = mean(jade4$cpu_usage[-(1:1)]),
            sd = sd(jade4$cpu_usage[-(1:1)])
        ),
        data.frame(
            system = jade5$system[1],
            experiment = jade5$experiment[1],
            mean = mean(jade5$cpu_usage[-(1:1)]),
            sd = sd(jade5$cpu_usage[-(1:1)])
        )
    )

ggplot(mean_cpu, aes(x = experiment, y = mean, fill = system)) +
    geom_col(position = "dodge") +
    geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd),
                  width = 0.2,
                  position = position_dodge(.9)) +
    theme_bw() +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 110)) +
    labs(x = "Experiment", y = "Mean CPU utilisation (%)", fill = "System")

ggsave("../img/mean_cpu.png")

mean_memory <-
    rbind(
        data.frame(
            system = elixir1$system[1],
            experiment = elixir1$experiment[1],
            mean = mean(elixir1$memory[-(1:1)]),
            sd = sd(elixir1$memory[-(1:1)])
        ),
        data.frame(
            system = elixir2$system[1],
            experiment = elixir2$experiment[1],
            mean = mean(elixir2$memory[-(1:1)]),
            sd = sd(elixir2$memory[-(1:1)])
        ),
        data.frame(
            system = elixir3$system[1],
            experiment = elixir3$experiment[1],
            mean = mean(elixir3$memory[-(1:1)]),
            sd = sd(elixir3$memory[-(1:1)])
        ),
        data.frame(
            system = elixir4$system[1],
            experiment = elixir4$experiment[1],
            mean = mean(elixir4$memory[-(1:1)]),
            sd = sd(elixir4$memory[-(1:1)])
        ),
        data.frame(
            system = elixir5$system[1],
            experiment = elixir5$experiment[1],
            mean = mean(elixir5$memory[-(1:1)]),
            sd = sd(elixir5$memory[-(1:1)])
        ),
        data.frame(
            system = jade1$system[1],
            experiment = jade1$experiment[1],
            mean = mean(jade1$memory[-(1:1)]),
            sd = sd(jade1$memory[-(1:1)])
        ),
        data.frame(
            system = jade2$system[1],
            experiment = jade2$experiment[1],
            mean = mean(jade2$memory[-(1:1)]),
            sd = sd(jade2$memory[-(1:1)])
        ),
        data.frame(
            system = jade3$system[1],
            experiment = jade3$experiment[1],
            mean = mean(jade3$memory[-(1:1)]),
            sd = sd(jade3$memory[-(1:1)])
        ),
        data.frame(
            system = jade4$system[1],
            experiment = jade4$experiment[1],
            mean = mean(jade4$memory[-(1:1)]),
            sd = sd(jade4$memory[-(1:1)])
        ),
        data.frame(
            system = jade5$system[1],
            experiment = jade5$experiment[1],
            mean = mean(jade5$memory[-(1:1)]),
            sd = sd(jade5$memory[-(1:1)])
        )
    )

ggplot(mean_memory, aes(x = experiment, y = mean, fill = system)) +
    geom_col(position = "dodge") +
    geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd),
                  width = 0.2,
                  position = position_dodge(.9)) +
    theme_bw() +
    scale_y_continuous(expand = c(0, 0), limit = c(0, 425)) +
    labs(x = "Experiment", y = "Mean memory usage (MiB)", fill = "System")

ggsave("../img/mean_memory.png")

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
        c(elixir1_time_diff, as.double(
            difftime(
                elixir1$time_converted[elixir1$run == i][221],
                elixir1$time_converted[elixir1$run == i][1],
                units = "secs"
            )
        ))
    
    elixir2_time_diff <-
        c(elixir2_time_diff, as.double(
            difftime(
                elixir2$time_converted[elixir2$run == i][221],
                elixir2$time_converted[elixir2$run == i][1],
                units = "secs"
            )
        ))
    
    elixir3_time_diff <-
        c(elixir3_time_diff, as.double(
            difftime(
                elixir3$time_converted[elixir3$run == i][221],
                elixir3$time_converted[elixir3$run == i][1],
                units = "secs"
            )
        ))
    
    elixir4_time_diff <-
        c(elixir4_time_diff, as.double(
            difftime(
                elixir4$time_converted[elixir4$run == i][221],
                elixir4$time_converted[elixir4$run == i][1],
                units = "secs"
            )
        ))
    
    elixir5_time_diff <-
        c(elixir5_time_diff, as.double(
            difftime(
                elixir5$time_converted[elixir5$run == i][221],
                elixir5$time_converted[elixir5$run == i][1],
                units = "secs"
            )
        ))
    
    jade1_time_diff <-
        c(jade1_time_diff, as.double(
            difftime(jade1$time_converted[jade1$run == i][221],
                     jade1$time_converted[jade1$run == i][1],
                     units = "secs")
        ))
    
    jade2_time_diff <-
        c(jade2_time_diff, as.double(
            difftime(jade2$time_converted[jade2$run == i][221],
                     jade2$time_converted[jade2$run == i][1],
                     units = "secs")
        ))
    
    jade3_time_diff <-
        c(jade3_time_diff, as.double(
            difftime(jade3$time_converted[jade3$run == i][221],
                     jade3$time_converted[jade3$run == i][1],
                     units = "secs")
        ))
    
    jade4_time_diff <-
        c(jade4_time_diff, as.double(
            difftime(jade4$time_converted[jade4$run == i][221],
                     jade4$time_converted[jade4$run == i][1],
                     units = "secs")
        ))
    
    jade5_time_diff <-
        c(jade5_time_diff, as.double(
            difftime(jade5$time_converted[jade5$run == i][221],
                     jade5$time_converted[jade5$run == i][1],
                     units = "secs")
        ))
}

mean_time_diff <-
    rbind(
        data.frame(
            system = "Elixir",
            experiment = "Experiment 1",
            mean = mean(elixir1_time_diff),
            sd = sd(elixir1_time_diff)
        ),
        data.frame(
            system = "Elixir",
            experiment = "Experiment 2",
            mean = mean(elixir2_time_diff),
            sd = sd(elixir2_time_diff)
        ),
        data.frame(
            system = "Elixir",
            experiment = "Experiment 3",
            mean = mean(elixir3_time_diff),
            sd = sd(elixir3_time_diff)
        ),
        data.frame(
            system = "Elixir",
            experiment = "Experiment 4",
            mean = mean(elixir4_time_diff),
            sd = sd(elixir4_time_diff)
        ),
        data.frame(
            system = "Elixir",
            experiment = "Experiment 5",
            mean = mean(elixir5_time_diff),
            sd = sd(elixir5_time_diff)
        ),
        data.frame(
            system = "JADE",
            experiment = "Experiment 1",
            mean = mean(jade1_time_diff),
            sd = sd(jade1_time_diff)
        ),
        data.frame(
            system = "JADE",
            experiment = "Experiment 2",
            mean = mean(jade2_time_diff),
            sd = sd(jade2_time_diff)
        ),
        data.frame(
            system = "JADE",
            experiment = "Experiment 3",
            mean = mean(jade3_time_diff),
            sd = sd(jade3_time_diff)
        ),
        data.frame(
            system = "JADE",
            experiment = "Experiment 4",
            mean = mean(jade4_time_diff),
            sd = sd(jade4_time_diff)
        ),
        data.frame(
            system = "JADE",
            experiment = "Experiment 5",
            mean = mean(jade5_time_diff),
            sd = sd(jade5_time_diff)
        )
    )

ggplot(mean_time_diff,
       aes(x = experiment, y = mean, fill = system)) +
    geom_col(position = "dodge") +
    geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd),
                  width = 0.2,
                  position = position_dodge(.9)) +
    theme_bw() +
    scale_y_continuous(expand = c(0, 0), limit = c(0, 12.5)) +
    labs(x = "Experiment", y = "Mean total time taken (secs)", fill = "System")

ggsave("../img/mean_time_diff.png")

elixir5_1 <- elixir5[elixir5$run == 1,]
elixir5_1 <- elixir5_1[-(1:1),] # Remove round 0 row
elixir5_1$system <- rep(c("Elixir"), 220)

jade5_1 <- jade5[jade5$run == 1,]
jade5_1 <- jade5_1[-(1:1),] # Remove round 0 row
jade5_1$system <- rep(c("JADE"), 220)

both5_1 <- rbind(elixir5_1, jade5_1)

ggplot(both5_1, aes(x = round,
                    y = memory,
                    colour = system)) +
    geom_line() +
    theme_bw() +
    scale_x_continuous(expand = c(0, 0), limits = c(0, 220)) +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 700)) +
    labs(x = "Rounds", y = "Memory usage (MiB)", colour = "System")

ggsave("../img/memory_per_round.png")

ggplot(both5_1, aes(x = round, y = cpu_usage, colour = system)) +
    geom_line() +
    theme_bw() +
    scale_x_continuous(expand = c(0, 0), limits = c(0, 220)) +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 101)) +
    labs(x = "Rounds", y = "CPU utilisation (%)", colour = "System")

ggsave("../img/cpu_per_round.png")

ggplot(both5_1, aes(x = round, y = time_diff * 1000, colour = system)) +
    geom_line() +
    geom_smooth() +
    theme_bw() +
    scale_x_continuous(expand = c(0, 0), limits = c(0, 220)) +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 200)) +
    labs(x = "Rounds", y = "Time between rounds (ms)", colour = "System")

ggsave("../img/time_per_round.png")
