library(targets)

tar_source()

tar_option_set(
  packages = c("dplyr", "readr", "ggplot2", "scales", "knitr")
)

list(
  tar_target(raw_sales_file, "data/raw/cafe_sales.csv", format = "file"),
  tar_target(raw_sales, read_sales(raw_sales_file)),
  tar_target(clean_sales_data, clean_sales(raw_sales)),
  tar_target(campus_summary, summarise_by_campus(clean_sales_data)),
  tar_target(weekly_summary, summarise_by_week(clean_sales_data)),
  tar_target(
    campus_summary_file,
    write_output_csv(campus_summary, "outputs/campus_summary.csv"),
    format = "file"
  ),
  tar_target(
    weekly_summary_file,
    write_output_csv(weekly_summary, "outputs/weekly_summary.csv"),
    format = "file"
  ),
  tar_target(
    weekly_revenue_plot,
    plot_weekly_revenue(weekly_summary, "outputs/revenue_by_week.png"),
    format = "file"
  ),
  tar_target(
    report,
    render_report(
      input = "report.qmd",
      dependencies = c(campus_summary_file, weekly_summary_file, weekly_revenue_plot)
    ),
    format = "file"
  )
)
