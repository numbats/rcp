read_sales <- function(path) {
  readr::read_csv(path, show_col_types = FALSE)
}

clean_sales <- function(sales) {
  required_columns <- c(
    "date", "campus", "product", "category", "channel",
    "units", "revenue", "cost", "cancelled"
  )

  missing_columns <- setdiff(required_columns, names(sales))
  if (length(missing_columns) > 0) {
    stop(
      "Missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  sales |>
    dplyr::mutate(
      date = as.Date(date),
      margin = revenue - cost,
      week = format(date, "%Y-%U")
    ) |>
    dplyr::filter(cancelled == "No")
}

