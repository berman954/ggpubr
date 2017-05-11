#' @include utilities.R
NULL
#'Add Summary Statistics or a Geom onto a ggplot
#'@description Add summary statistics or a geometry onto a ggplot.
#'@inheritParams add_summary
#'@param p a ggplot
#'@param add character vector specifying other plot elements to be added.
#'  Allowed values are one or the combination of: "none", "dotplot", "jitter",
#'  "boxplot", "point", "mean", "mean_se", "mean_sd", "mean_ci", "mean_range",
#'  "median", "median_iqr", "median_mad", "median_range".
#'@param color point or outline color.
#'@param fill fill color. Used only whne \code{error.plot = "crossbar"}.
#'@param width numeric value between 0 and 1 specifying bar or box width.
#'  Example width = 0.8. Used only when \code{error.plot} is one of
#'  c("crossbar", "errorbar").
#'@param shape point shape. Allowed values can be displayed using the function
#'  \code{\link{show_point_shapes}()}.
#'@param size numeric value in [0-1] specifying point and line size.
#'@param alpha numeric value specifying fill color transparency. Value should be
#'  in [0, 1], where 0 is full transparency and 1 is no transparency.
#'@param jitter a numeric value specifying the amount of jittering. Used only
#'  when \code{add} contains "jitter".
#'@param binwidth numeric value specifying bin width. use value between 0 and 1
#'  when you have a strong dense dotplot. For example binwidth = 0.2. Used only
#'  when \code{add} contains "dotplot".
#'@param dotsize as \code{size} but applied only to dotplot.
#'@param p_geom the geometry of the main plot. Ex: p_geom = "geom_line". If
#'  NULL, the geometry is extracted from p. Used only by \link{ggline}().
#' @examples
#'# Basic violin plot
#'data("ToothGrowth")
#'p <- ggviolin(ToothGrowth, x = "dose", y = "len", add = "none")
#'
#'# Add mean +/- SD and jitter points
#'p %>% ggadd(c("mean_sd", "jitter"), color = "dose")
#'
#'# Add box plot
#'p %>% ggadd(c("boxplot", "jitter"), color = "dose")
#'
#'@export
ggadd <- function(p, add = NULL, color = "black", fill = "white",
                  width = 1, shape = 19, size = NULL, alpha = 1, jitter = 0.2,
                  binwidth = NULL, dotsize = size,
                  error.plot = "pointrange",
                  data = NULL, position = position_dodge(0.8),
                  p_geom = ""
)
{

  . <- NULL
  # Checkpoints
  #:::::::::::::::::::::::::::::::::::::::::::
  if("none" %in% add) add <- "none"
  # Adding mean or median point
  center <- intersect(c("mean", "median"), add)
  if(length(center) == 2)
    stop("Use mean or mdedian, but not both at the same time.")
  # Adding error bars
  errors <- c("mean_se", "mean_sd", "mean_ci", "mean_range",
              "median_iqr", "median_mad", "median_range")
  errors <- intersect(errors, add)
  if(length(errors) > 1)
    stop("Choose only one of these: ", .collapse(errors, sep = ", "))

  if(is.null(dotsize)) dotsize =1


  # Data and mapping
  #:::::::::::::::::::::::::::::::::::::::::::
  if(is.null(data)) data <- p$data
  .map <- .mapping(p)
  x <- .map$x
  y <- .map$y
  if(missing(color) & !is.null(.map$colour))
    color <- .map$colour
  if(missing(fill) & !is.null(.map$fill))
    fill <- .map$fill
  ngrps <- intersect(names(data), c(.map$x, fill, color)) %>%
    length() # number of grouping variables

  # Amount of jittering when add = "jitter"
  #:::::::::::::::::::::::::::::::::::::::::::
  set.seed(123)
  .jitter <- jitter
  if(is.numeric(jitter)) jitter <- position_jitter(jitter)
  if(p_geom == "geom_line" & ngrps > 1){}
  else if(ngrps > 1) jitter <- position_jitterdodge(jitter.width = .jitter, dodge.width = 0.8)

  common.opts <- opts <- list(data = data, color = color, fill = fill,
                              size = size, position = position, alpha = alpha)

  if ("boxplot" %in% add) {
    if(.geom(p) == "violin" & missing(width)) width = 0.2
    else if(missing(width)) width = 0.7
    p <- common.opts %>%
      .add_item(geomfunc = geom_boxplot, width = width) %>%
      .update_plot(p)
  }
  if ("violin" %in% add) {
    if(missing(width)) width = 1
    p <- common.opts %>%
      .add_item(geomfunc = geom_violin, width = width, trim = FALSE) %>%
      .update_plot(p)
  }
  if ( "dotplot" %in% add ) {
    p <- common.opts %>%
      .add_item(geomfunc = geom_dotplot, binaxis = 'y', stackdir = 'center',
                dotsize = dotsize, stackratio = 1, binwidth = binwidth) %>%
      .update_plot(p)
  }
  if ( "jitter" %in% add ){
    p <- common.opts %>%
      .add_item(geomfunc = geom_jitter, position = jitter, shape = shape) %>%
      .update_plot(p)
  }

  if ( "point" %in% add ) {
    p <- common.opts %>% .remove_item("fill") %>%
      .add_item(geomfunc = geom_point) %>%
      .update_plot(p)
  }
  if ( "line" %in% add ) {
    p <- common.opts %>% .remove_item("fill") %>%
      .add_item(geomfunc = geom_line, group = 1) %>%
      .update_plot(p)
  }

  # Add mean or median
  #:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  if(!.is_empty(center))
    p <- p %>% add_summary(fun = center, color = color, shape = shape,
                  position = position, size = size)

  # Add erors
  #:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  if(!.is_empty(errors)){
    if(error.plot %in% c("errorbar", "lower_errorbar", "upper_errorbar"))
      width <- 0.1
    p <- p %>% add_summary(errors, error.plot = error.plot, color = color, shape = shape,
                  position = position, size = size, width = width)
  }

  p

}



