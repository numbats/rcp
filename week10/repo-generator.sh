#!/bin/bash

# Create a new Git repository
mkdir git-bisect-demo
cd git-bisect-demo
git init

# Create an initial script file with two functions
cat <<EOF > script.R
square <- function(x) {
  return(x * x)
}

cube <- function(x) {
  result <- x * x * x
  return(result)
}
EOF

git add script.R
git commit -m "Initial commit with square and cube functions"

# Define author names
authors=("Michael <michael.lydeamore@monash.edu>" "Di <dicook@monash.edu>" "Rob <rob.hyndman@monash.edu>")

# 10 harmless commits before the bug, modifying only cube()
for i in {1..23}; do
  varname="result${i}"

  cat <<EOF > script.R
square <- function(x) {
  return(x * x)
}

cube <- function(x) {
  $varname <- x * x * x
  return($varname)
}
EOF

  git add script.R
  author=${authors[$((i % 3))]}
  GIT_AUTHOR_NAME="${author%% <*}" GIT_AUTHOR_EMAIL="${author##*<}" git commit -m "Refactor cube function"
done

# Introduce a bug in the square function in commit 11
cat <<EOF > script.R
square <- function(x) {
  return(x + x)
}

cube <- function(x) {
  result11 <- x * x * x
  return(result11)
}
EOF

git add script.R
GIT_AUTHOR_NAME="Michael" GIT_AUTHOR_EMAIL="michael.lydeamore@monash.edu" git commit -m "Refactor functions"

# 10 more harmless commits modifying only cube()
for i in {12..82}; do
  varname="res${i}"

  cat <<EOF > script.R
square <- function(x) {
  $varname <- x + x
  return($varname) 
}

cube <- function(x) {
  $varname <- x * x * x
  return($varname)
}
EOF

  git add script.R
  author=${authors[$((i % 3))]}
  GIT_AUTHOR_NAME="${author%% <*}" GIT_AUTHOR_EMAIL="${author##*<}" git commit -m "Further refactor"
done

# Now you can run `git bisect` to find the commit introducing the bug
