#' Plot inversion of simultaneous confidence intervals (SCIs) into inner and outer confidence sets (CSs)
#'
#' Visualizes 1D or 2D inversion of simultaneous confidence sets using contour or band plots.
#' Supports plotting CSs at multiple levels and labeling contours.
#'
#' @param SCB A list returned by `SCB_dense()` or a custom list with two arrays: `scb_up` and `scb_low`, representing the upper and lower confidence bounds respectively.
#' @param levels A numeric vector of scalers specifying the levels to plot the cs.
#' @param type A character specifying the type of inverse sets to fit. Choices are `"upper"`, `"lower"` or `"interval"`. Default is `"upper"`.
#' @param x A vector of x-axis coordinates. For discrete coordinates, use a character vector.
#' @param y Optional vector of y-axis coordinates, required when the SCB array is 2D.
#' @param mu_hat A matrix or vector of estimated means. If `mu_true` is provided, this will be overwritten by the true mean.
#' @param mu_true Optional matrix or vector of true means, which overrides `mu_hat` if provided.
#' @param together Logical. If `TRUE`, plots all confidence levels on the same figure; otherwise, generates one plot per level.
#' @param xlab Character. Label for the x-axis.
#' @param ylab Character. Label for the y-axis.
#' @param level_label Logical. If `TRUE`, displays numeric level labels on contour lines for 2D confidence sets.
#' @param min.size Integer. Minimum number of points required for a contour to be labeled.
#' @param palette Character. Name of the HCL color palette to use when plotting multiple levels together (e.g., "Dynamic").
#' @param color_level_label Character. Color used for contour level labels (e.g., "black").
#'
#' @returns A \code{ggplot2} object representing the inversion of simultaneous confidence intervals.
#'
#' @import metR
#' @import ggpubr
#' @import ggplot2
#' @import patchwork
#' @import grDevices
#' @export
#'
#' @examples
#'
#' # example using ccds data
#' data(ccds)
#' ccds_fpca <- prepare_ccds_fpca(ccds)
#'
#' fosr_mod <- mgcv::bam(percent_change ~ s(seconds, k=30, bs="cr") +
#'   s(seconds, by = use, k=30, bs = "cr") +
#'   s(subject, by = Phi1, bs="re") +
#'   s(subject, by = Phi2, bs="re")+
#'   s(subject, by = Phi3, bs="re") +
#'   s(subject, by = Phi4, bs="re"),
#'   method = "fREML", data = ccds_fpca, discrete = TRUE)
#'
#' ccds_cma <- SCB_functional_outcome(data = ccds_fpca, object = fosr_mod, method = "cma",
#'                                    est_mean = TRUE, outcome = "percent_change",
#'                                    time = "seconds", group_name = "use",
#'                                    group_value = 1, subject = "subject")
#' ccds_cma <- tibble::as_tibble(ccds_cma)
#'
#' plot_cs(ccds_cma,levels = c(-7, -8, -9, -10), x = ccds_cma$time,
#'         mu_hat = ccds_cma$yhat, xlab = "", ylab = "",
#'         level_label = T, min.size = 40, palette = "Spectral",
#'         color_level_label = "black")
plot_cs = function(SCB, levels, type = "upper", x, y, mu_hat, mu_true = NULL, together = T, xlab = "X1", ylab = "X2", level_label = T,
                   min.size = 5,palette = "gray",color_level_label = "black"){
  dim = length(dim(SCB$scb_up))
  if(dim == 0){# 1 dimension case
    if(is.character(x)){# if we have discrete coordinates
      if(is.null(mu_true)){
        df_plot = data.frame(x = x, low = SCB$scb_low, up = SCB$scb_up,est_mean = mu_hat) %>%
          mutate(x = fct_reorder(x, desc(low)))
        p = df_plot %>% ggplot(aes(x = x))+ geom_errorbar(aes(ymin = low, ymax = up)) +
          geom_hline(yintercept = levels, linetype="dashed")
        p = p + geom_point(data = df_plot,aes(x = x, y = mu_hat),color = "black")
        if(type == "interval"){ i <- 1 }
        for(l in levels){
          if(type == "upper"){
            df_plot_l = df_plot %>%
              mutate(l_in = ifelse(low >= l, l, NA),
                     l_est = ifelse(est_mean >= l & is.na(l_in), l, NA),
                     l_out = ifelse(up >= l & is.na(l_est) & is.na(l_in), l, NA)
              )
          }else if(type == "lower"){
            df_plot_l = df_plot %>%
              mutate(l_in = ifelse(up <= l, l, NA),
                     l_est = ifelse(est_mean <= l & is.na(l_in), l, NA),
                     l_out = ifelse(low <= l & is.na(l_est) & is.na(l_in), l, NA)
              )
          }else if(type == "interval"){
            # l_dim = dim(levels)
            l = levels[i,]
            df_plot_l = df_plot %>%
              mutate(l_in = ifelse(low >= l$low & up <= l$up, l, NA),
                     l_est = ifelse((est_mean >= l$low & est_mean <= l$up) & is.na(l_in), l$low, NA),
                     l_out = ifelse((up >= l$low & low <= up) & is.na(l_est) & is.na(l_in), l$low, NA)
              )
            i = i + 1
          }else if(type == "two-sided"){
            stop("'two-sided' is not avaliable for plotting, please choose between 'upper', 'lower' or 'interval'.")
          }else{
            stop("Type must be chosen between 'upper', 'lower' or 'interval'.")
          }
          if(!all(is.na(df_plot_l$l_out))){
            p = p+ geom_point(aes(x, l_out), data = df_plot_l, color = "blue")
          }
          if(!all(is.na(df_plot_l$l_est))){
            p = p+ geom_point(aes(x, l_est), data = df_plot_l, color = "orange")
          }
          if(!all(is.na(df_plot_l$l_in))){
            p = p+ geom_point(aes(x, l_in), data = df_plot_l, color = "red")
          }
        }
      }else{
        df_plot = data.frame(x = x, low = SCB$scb_low, true_mean = mu_true, up = SCB$scb_up, est_mean = mu_hat)%>%
          mutate(x = fct_reorder(x, desc(low)))
        p = df_plot %>% ggplot(aes(x = x, y = true_mean))+ geom_point(color = "black")+ geom_errorbar(aes(ymin = low, ymax = up)) +
          geom_hline(yintercept = levels, linetype="dashed") +
          geom_text(data = data.frame(x = rep(levels(df_plot$x)[1], length(levels)), y = levels, labels = levels),
                    aes(x = x, y = y, label = labels,vjust = -0.5, hjust = -0.05))
        #scale_y_continuous(breaks =levels)
        #p = p + geom_point(data = df_plot,aes(x = x, y = mu_hat),color = "black")
        if(type == "interval"){ i <- 1}
        for(l in levels){
          if(type == "upper"){
            df_plot_l = df_plot %>%
              mutate(l_in = ifelse(low >= l, l, NA),
                     l_est = ifelse(true_mean >= l & is.na(l_in), l, NA),
                     l_out = ifelse(up >= l & is.na(l_est) & is.na(l_in), l, NA)
              )
          }else if(type == "lower"){
            df_plot_l = df_plot %>%
              mutate(l_in = ifelse(up <= l, l, NA),
                     l_est = ifelse(true_mean <= l & is.na(l_in), l, NA),
                     l_out = ifelse(low <= l & is.na(l_est) & is.na(l_in), l, NA)
              )
          }else if(type == "interval"){
            # l_dim = dim(levels)
            l = levels[i,]
            df_plot_l = df_plot %>%
              mutate(l_in = ifelse(low >= l$low & up <= l$up, l$low, NA),
                     l_est = ifelse((true_mean >= l$low & true_mean <= l$up) & is.na(l_in), l$low, NA),
                     l_out = ifelse((up >= l$low & low <= up) & is.na(l_est) & is.na(l_in), l$low, NA)
              )
            i = i + 1
          }else if(type == "two-sided"){
            stop("'two-sided' is not avaliable for plotting, please choose between 'upper', 'lower' or 'interval'.")
          }else{
            stop("Type must be chosen between 'upper', 'lower' or 'interval'.")
          }
          if(!all(is.na(df_plot_l$l_out))){
            p = p+ geom_point(aes(x, l_out), data = df_plot_l, color = "blue")
          }
          if(!all(is.na(df_plot_l$l_true))){
            p = p+ geom_point(aes(x, l_true), data = df_plot_l, color = "green")
          }
          if(!all(is.na(df_plot_l$l_in))){
            p = p+ geom_point(aes(x, l_in), data = df_plot_l, color = "red")
          }
        }
      }
      p = p + ggtitle("Confidence sets") + theme_light() +
        theme(plot.title = element_text(face = "bold", hjust = 0.5,), plot.margin = unit(c(0.2,0.2,0.2,0.2), "mm"),
              axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
        labs(x = "Coefficients", y = "Magnitude")
      return(p)
    }else{# Plotting for continuous x coordinate
      if(is.null(mu_true)){
        df_plot = data.frame(x = x, low = SCB$scb_low, up = SCB$scb_up, est_mean = mu_hat)
        p = df_plot %>% ggplot(aes(x = x, y = est_mean)) +
          geom_ribbon(aes(ymin = low, ymax = up),alpha = 0.5) +
          geom_hline(yintercept = levels, linetype="dashed") +
          geom_text(data = data.frame(x = rep(min(x), length(levels)), y = levels, labels = levels),
                    aes(x = x, y = y, label = labels,vjust = -0.5))
        p = p + geom_line(data = df_plot,aes(x = x, y = mu_hat),color = "black")
        if(type == "interval"){ i <- 1}
        for(l in levels){
          if(type == "upper"){
            df_plot_l = df_plot %>% mutate(l_in = ifelse(low >= l, l, NA),
                                           l_est = ifelse(est_mean >= l, l, NA),
                                           l_out = ifelse(up >= l , l, NA))
          }else if(type == "lower"){
            df_plot_l = df_plot %>% mutate(l_in = ifelse(up <= l, l, NA),
                                           l_est = ifelse(est_mean <= l, l, NA),
                                           l_out = ifelse(low <= l , l, NA))
          }else if(type == "interval"){
            # l_dim = dim(levels)
            l = levels[i,]
            df_plot_l = df_plot %>% mutate(l_in = ifelse(low >= l$low & up <= l$up, l$low, NA),
                                           l_est = ifelse(est_mean >= l$low & est_mean <= l$up, l$low, NA),
                                           l_out = ifelse(up >= l$low & low <= l$lup , l$low, NA))
            i = i + 1
          }else if(type == "two-sided"){
            stop("'two-sided' is not avaliable for plotting, please choose between 'upper', 'lower' or 'interval'.")
          }else{
            stop("Type must be chosen between 'upper', 'lower' or 'interval'.")
          }
          if(!all(is.na(df_plot_l$l_out))){
            p = p + geom_line(data = df_plot_l,aes(x = x, y = l_out),color = "blue",lwd=1.5)
          }
          if(!all(is.na(df_plot_l$l_est))){
            p = p + geom_line(data = df_plot_l,aes(x = x, y = l_est),color = "orange",lwd=1.5)
          }
          if(!all(is.na(df_plot_l$l_in))){
            p = p + geom_line(data = df_plot_l,aes(x = x, y = l_in),color = "red",lwd=1.5)
          }
        }
      }else{
        df_plot = data.frame(x = x, low = SCB$scb_low, true_mean = mu_true, up = SCB$scb_up,
                             est_mean = mu_hat)
        p = df_plot %>% ggplot(aes(x = x, y = true_mean))+ geom_line(color = "black")+
          geom_ribbon(aes(ymin = low, ymax = up),alpha = 0.3) +
          geom_hline(yintercept = levels, linetype="dashed")+
          geom_text(data = data.frame(x = rep(min(x), length(levels)), y = levels, labels = levels),
                    aes(x = x, y = y, label = labels, vjust = -0.5))
        #p = p + geom_line(data = df_plot,aes(x = x, y = mu_hat),color = "black")
        if(type == "interval"){ i <- 1}
        for(l in levels){
          if(type == "upper"){
            df_plot_l = df_plot %>% mutate(l_in = ifelse(low >= l, l, NA),
                                           l_est = ifelse(true_mean >= l, l, NA),
                                           l_out = ifelse(up >= l , l, NA))
          }else if(type == "lower"){
            df_plot_l = df_plot %>% mutate(l_in = ifelse(up <= l, l, NA),
                                           l_est = ifelse(true_mean <= l, l, NA),
                                           l_out = ifelse(low <= l , l, NA))
          }else if(type == "interval"){
            # l_dim = dim(levels)
            l = levels[i,]
            df_plot_l = df_plot %>% mutate(l_in = ifelse(low >= l$low & up <= l$up, l$low, NA),
                                           l_est = ifelse(true_mean >= l$low & true_mean <= l$up, l$low, NA),
                                           l_out = ifelse(up >= l$low & low <= l$up , l$low, NA))
            i = i + 1
          }else if(type == "two-sided"){
            stop("'two-sided' is not avaliable for plotting, please choose between 'upper', 'lower' or 'interval'.")
          }else{
            stop("Type must be chosen between 'upper', 'lower' or 'interval'.")
          }
          if(!all(is.na(df_plot_l$l_out))){
            p = p + geom_line(data = df_plot_l,aes(x = x, y = l_out),color = "blue",lwd=1.5)
          }
          if(!all(is.na(df_plot_l$l_true))){
            p = p + geom_line(data = df_plot_l,aes(x = x, y = l_true),color = "green",lwd=1.5)
          }
          if(!all(is.na(df_plot_l$l_in))){
            p = p + geom_line(data = df_plot_l,aes(x = x, y = l_in),color = "red",lwd=1.5)
          }


          # p = p + geom_line(data = df_plot_l,aes(x = x, y = l_out),
          #                   arrow=arrow(ends = 'both',type = "closed", length = unit(1, "mm")), color = "blue") +
          #   geom_line(data = df_plot_l,aes(x = x, y = l_in),
          #             arrow=arrow(ends = 'both', type = "closed", length = unit(1, "mm")), color = "red")
        }
      }
      p = p + ggtitle("Confidence sets") + theme_light() +
        theme(plot.title = element_text(face = "bold", hjust = 0.5,), plot.margin = unit(c(1,0.2,0.2,0.2), "mm"))+
        labs(x = xlab, y = "")
      return(p)
    }

  }else if(dim == 2){# 2 dimension case
    # remember to explain why 2D don't need to specify the type of set fitted
    # normalized quantity dataframe
    if(is.null(x)){
      x = seq(0,1,dim(SCB$scb_up)[1])
      y = seq(0,1,dim(SCB$scb_up)[2])
    }
    rownames(SCB$scb_up) = x
    colnames(SCB$scb_up) = y
    rownames(SCB$scb_low) = x
    colnames(SCB$scb_low) = y
    rownames(mu_hat) = x
    colnames(mu_hat) = y
    SCB$scb_up = suppressWarnings(melt(SCB$scb_up))
    SCB$scb_low = suppressWarnings(melt(SCB$scb_low))
    mu_hat = suppressWarnings(melt(mu_hat))
    colnames(SCB$scb_up)=c("X1","X2", "scb_up")
    colnames(SCB$scb_low)=c("X1","X2", "scb_low")
    colnames(mu_hat)=c("X1","X2", "est")
    # Mean frame for plotting
    # TO GET RID OF THE WARNING REFER TO THIS LINK
    # https://stackoverflow.com/questions/50359647/plotting-2-dimensional-function-in-ggplot
    if(!is.null(mu_true)){
      mu = mu_true
      rownames(mu) = x
      colnames(mu) = y
      mu = suppressWarnings(melt(mu))
      colnames(mu)=c("X1","X2", "true_mean")
    }else if(!is.null(mu_hat)){
      mu = mu_hat
      #rownames(mu) = x
      #colnames(mu) = y
      #mu = suppressWarnings(melt(mu))
      colnames(mu)=c("X1","X2", "estimated_mean")
    }else{
      stop("Must provide 'mu_true' or 'mu_hat'.")
    }
    #Plotting]

    if(together == T){
      colors = hcl.colors(length(levels),palette = palette, rev =T)
      if(!is.null(mu_true)){
        #browser()
        max_mu = round(max(mu$true_mean, na.rm = T)+0.2, digits = 1)
        min_mu = round(min(mu$true_mean, na.rm = T)-0.2, digits = 1)
        p_u <- ggplot()+
          geom_raster(aes(x=X1, y = X2, fill = true_mean), data = mu)+
          ggtitle("Outer confidence sets")+
          scale_fill_distiller(palette = "Spectral", direction = -1, limits = c(min_mu,max_mu), na.value = "transparent")+
          labs(fill="True mean", x = xlab, y = ylab)
        #scale_fill_gradientn(colours =
        #                       c("blue","green", "yellow", "orange", "red"))
        p_l <- ggplot()+
          geom_raster(aes(x=X1, y = X2, fill = true_mean),
                      data = mu,show.legend = F)+
          ggtitle("Inner confidence sets")+
          scale_fill_distiller(palette = "Spectral", direction = -1, na.value = "transparent")+
          labs(fill="True mean", x = xlab, y = ylab)
        p_est <- ggplot()+
          geom_raster(aes(x=X1, y = X2, fill = true_mean),
                      data = mu,show.legend = F)+
          ggtitle("Estimated sets")+
          scale_fill_distiller(palette = "Spectral", direction = -1, na.value = "transparent")+
          labs(fill="True mean", x = xlab, y = ylab)
      }else{
        max_mu = round(max(mu$estimated_mean, na.rm = T)+0.2, digits = 1)
        min_mu = round(min(mu$estimated_mean, na.rm = T)-0.2, digits = 1)
        #browser()
        p_u <- ggplot()+
          geom_raster(aes(x=X1, y = X2, fill = estimated_mean), data = mu)+
          ggtitle("Outer confidence sets")+
          scale_fill_distiller(palette = "Spectral", direction = -1, limits = c(min_mu,max_mu), na.value = "transparent")+
          labs(fill="Estimated \n mean", x = xlab, y = ylab)
        p_l <- ggplot()+
          geom_raster(aes(x=X1, y = X2, fill = estimated_mean),
                      data = mu,show.legend = F)+
          ggtitle("Inner confidence sets")+
          scale_fill_distiller(palette = "Spectral", direction = -1, na.value = "transparent")+
          labs(fill="Estimated \n mean", x = xlab, y = ylab)
        p_est <- ggplot()+
          geom_raster(aes(x=X1, y = X2, fill = estimated_mean),
                      data = mu,show.legend = F)+
          ggtitle("Estimated sets")+
          scale_fill_distiller(palette = "Spectral", direction = -1, na.value = "transparent")+
          labs(fill="Estimated \n mean", x = xlab, y = ylab)
      }
      for(i in 1:length(levels)){
        p_u <- p_u +
          stat_contour(aes(X1, X2, z= scb_up),data = SCB$scb_up,
                       breaks=levels[i],colour = colors[i],lwd=0.9)
        if(level_label){
          p_u <- p_u + geom_text_contour(aes(X1, X2, z= scb_up),label = levels[i],
                                         data = SCB$scb_up,
                                         breaks = levels[i],inherit.aes	= T, colour = color_level_label,
                                         position = position_jitter(), min.size = min.size)
        }
      }
      p_u = p_u +
        theme_light() +
        scale_x_continuous(expand = c(0.01,0.01)) + scale_y_continuous(expand = c(0.01,0.01))+
        theme(plot.title = element_text(face = "bold", hjust = 0.5,),
              plot.margin = unit(c(0.2,10,0.2,0.2), "mm"),
              aspect.ratio=1)

      for(i in 1:length(levels)){
        p_l <- p_l +
          stat_contour(aes(X1, X2, z= scb_low),data = SCB$scb_low,
                       breaks=levels[i],colour = colors[i],lwd=0.9)
        if(level_label){
          p_l <- p_l + geom_text_contour(aes(X1, X2, z= scb_low),label = levels[i],
                                         data = SCB$scb_low,
                                         breaks = levels[i], inherit.aes = T, colour = color_level_label,
                                         position = position_jitter(), min.size = min.size)
        }

        #theme(panel.background = element_blank(), plot.title = element_text(face = "bold"))
      }
      p_l = p_l +
        theme_light() +
        scale_x_continuous(expand = c(0.01,0.01)) + scale_y_continuous(expand = c(0.01,0.01))+
        theme(plot.title = element_text(face = "bold", hjust = 0.5,),
              plot.margin = unit(c(0.2,0.2,0.2,0.2), "mm"),
              aspect.ratio=1)

      for(i in 1:length(levels)){
        p_est <- p_est +
          stat_contour(aes(X1, X2, z= est),data = mu_hat,
                       breaks=levels[i],colour = colors[i],lwd=0.9)
        if(level_label){
          p_est <- p_est +geom_text_contour(aes(X1, X2, z= est),label = levels[i],
                                            data = mu_hat,
                                            breaks = levels[i], inherit.aes = T, colour = color_level_label,
                                            position = position_jitter(), min.size = min.size)
        }

        #theme(panel.background = element_blank(), plot.title = element_text(face = "bold"))
      }
      p_est = p_est +
        theme_light() +
        scale_x_continuous(expand = c(0.01,0.01)) + scale_y_continuous(expand = c(0.01,0.01))+
        theme(plot.title = element_text(face = "bold", hjust = 0.5,),
              plot.margin = unit(c(0.2,10,0.2,0.2), "mm"),
              aspect.ratio=1)
      #p = ggarrange(p_u,p_l, nrow = 1, common.legend = T, legend = "bottom")
      p = p_u + p_est  + p_l
      p[[1]] = p[[1]] + theme(
        axis.ticks.x = element_blank(),
        axis.title.x = element_blank() )
      p[[2]] = p[[2]] + theme(
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank() )

      # Remove title from third subplot
      p[[3]] = p[[3]] + theme(
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),

        axis.ticks.x = element_blank(),
        axis.title.x = element_blank() )

      p = p + plot_layout(guides = "collect")
      return(p)
    }else{
      # Plotting the level one by one
      p <- lapply(1:length(levels), function(i){
        if(!is.null(mu_true)){
          max_mu = round(max(mu$true_mean, na.rm = T)+0.2, digits = 1)
          min_mu = round(min(mu$true_mean, na.rm = T)-0.2, digits = 1)
          temp = ggplot()+
            geom_raster(aes(x=X1, y = X2, fill = true_mean), data = mu)+
            labs(fill="True mean", x = xlab, y = ylab)+ theme_light()
        }else{
          max_mu = round(max(mu$estimated_mean, na.rm = T))
          min_mu = round(min(mu$estimated_mean, na.rm = T))
          temp = ggplot()+
            geom_raster(aes(x=X1, y = X2, fill = estimated_mean), data = mu)+
            labs(fill="Estimated \n mean", x = xlab, y = ylab)+ theme_light()
        }
        if(i == 1){
          temp = temp + theme(axis.ticks.x = element_blank(),
                              axis.title.x = element_blank(),
                              plot.title = element_text(face = "bold", hjust = 0.5,),
                              plot.margin = unit(c(0.2,10,0.2,0.2), "mm"),
                              aspect.ratio=1)
        }
        if(i == 2){
          temp = temp + theme(axis.ticks.y = element_blank(),
                              axis.title.y = element_blank(),
                              plot.title = element_text(face = "bold", hjust = 0.5,),
                              plot.margin = unit(c(0.2,10,0.2,0.2), "mm"),
                              aspect.ratio=1)
        }
        if(i == 3){
          temp = temp + theme(axis.ticks.x = element_blank(),
                              axis.title.x = element_blank(),
                              axis.ticks.y = element_blank(),
                              axis.title.y = element_blank(),
                              plot.title = element_text(face = "bold", hjust = 0.5,),
                              plot.margin = unit(c(0.2,0.2,0.2,0.2), "mm"),
                              aspect.ratio=1)
        }
        temp +
          scale_fill_distiller(palette = "Spectral", direction = -1, limits = c(min_mu,max_mu), na.value = "transparent") +
          stat_contour(aes(X1, X2, z= scb_up),data = SCB$scb_up,
                       breaks=levels[i],colour =  "blue",lwd=0.9)+
          stat_contour(aes(X1, X2, z= scb_low),data = SCB$scb_low,
                       breaks=levels[i],colour = "red",lwd=0.9)+
          stat_contour(aes(X1, X2, z= est),data = mu_hat,
                       breaks=levels[i],colour = "green",lwd=0.9)+
          ggtitle(paste("level =",  levels[i]))+
          scale_x_continuous(expand = c(0.01,0.01)) + scale_y_continuous(expand = c(0.01,0.01))
      })
      return(wrap_plots(p)+ plot_layout(guides = "collect"))
    }
  }
}
# library(forcats)
# library(dplyr)
