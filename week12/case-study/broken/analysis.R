library(readr)
library(dplyr)
library(ggplot2)

# Last run on my laptop. This should create the report inputs.
sales <- read_csv("data/orders.csv")

sales$date <- as.Date(sales$date, format = "%d/%m/%Y")

clean_sales <- sales |>
  filter(cancelled == "No") |>
  mutate(
    margin = revenue - cost,
    week = format(date, "%Y-%U")
  )

weekly_sales <- clean_sales |>
  group_by(week, campus) |>
  summarise(
    revenue = sum(revenue),
    margin = sum(margin),
    orders = n(),
    .groups = "drop"
  )

write_csv(weekly_sales, "output/weekly-summary.csv")

revenue_plot <- ggplot(weekly_sales, aes(x = week, y = revenue, colour = campus)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  labs(
    title = "Weekly revenue by campus",
    x = "Week",
    y = "Revenue",
    colour = "Campus"
  ) +
  theme_minimal()

ggsave("output/revenue-by-week.png", revenue_plot, width = 7, height = 4)

campus_summary <- clean_sales |>
  group_by(site) |>
  summarise(
    revenue = sum(revenue),
    margin = sum(margin),
    orders = n(),
    average_order = revenue / orders,
    .groups = "drop"
  )

write_csv(campus_summary, "output/campus-summary.csv")
