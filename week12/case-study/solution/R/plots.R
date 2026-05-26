plot_weekly_revenue <- function(weekly_sales, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  plot <- ggplot2::ggplot(
    weekly_sales,
    ggplot2::aes(x = week, y = revenue, colour = campus, group = campus)
  ) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::geom_point(size = 2.4) +
    ggplot2::scale_y_continuous(labels = scales::label_dollar()) +
    ggplot2::labs(
      title = "Weekly revenue by campus",
      x = "Week",
      y = "Revenue",
      colour = "Campus"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )

  ggplot2::ggsave(path, plot, width = 7, height = 4, dpi = 160)
  path
}

