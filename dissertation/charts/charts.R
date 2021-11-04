library(ggplot2)

elixir1 <- read.csv("elixir/experiment1.csv")
elixir2 <- read.csv("elixir/experiment2.csv")
elixir3 <- read.csv("elixir/experiment3.csv")
elixir4 <- read.csv("elixir/experiment4.csv")
elixir5 <- read.csv("elixir/experiment5.csv")

system <- rep(c("Elixir"), 5)

experiment <-
    c("Experiment 1",
      "Experiment 2",
      "Experiment 3",
      "Experiment 4",
      "Experiment 5")

mean_cpu <-
    c(
        mean(elixir1$cpu_usage[-(1:1)]),
        mean(elixir2$cpu_usage[-(1:1)]),
        mean(elixir3$cpu_usage[-(1:1)]),
        mean(elixir4$cpu_usage[-(1:1)]),
        mean(elixir5$cpu_usage[-(1:1)])
    )

cpu_df <- data.frame(system, experiment, mean_cpu)

ggplot(cpu_df, aes(x = experiment, y = mean_cpu, fill = system)) +
    geom_col() +
    theme_bw() +
    labs(x = "Experiment", y = "Mean CPU utilisation (%)", fill = "System")
