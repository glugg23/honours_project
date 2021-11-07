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
