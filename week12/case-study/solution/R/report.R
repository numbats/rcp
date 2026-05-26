render_report <- function(input, dependencies, output = "report.html") {
  force(dependencies)

  status <- system2(
    "quarto",
    args = c("render", input, "--to", "html"),
    stdout = "",
    stderr = ""
  )

  if (!identical(status, 0L)) {
    stop("Quarto render failed.", call. = FALSE)
  }

  if (!file.exists(output)) {
    stop("Expected output file was not created: ", output, call. = FALSE)
  }

  output
}

