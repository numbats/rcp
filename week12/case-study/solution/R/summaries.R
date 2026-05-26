summarise_by_campus <- function(sales) {
  sales |>
    dplyr::group_by(campus) |>
    dplyr::summarise(
      revenue = sum(revenue),
      margin = sum(margin),
      orders = dplyr::n(),
      units = sum(units),
      average_order = revenue / orders,
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(revenue))
}

summarise_by_week <- function(sales) {
  sales |>
    dplyr::group_by(week, campus) |>
    dplyr::summarise(
      revenue = sum(revenue),
      margin = sum(margin),
      orders = dplyr::n(),
      units = sum(units),
      .groups = "drop"
    ) |>
    dplyr::arrange(week, campus)
}

write_output_csv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, path)
  path
}

