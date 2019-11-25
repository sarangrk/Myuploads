required.library <- c(
    'lattice',
    'ggplot2',
    'tidyr',
    'tidyverse',
    'dplyr',
    'purrr',
    'lubridate',
    'stringr',
    'forcats',
    'readr',
    'ggraptR',
    'ggThemeAssist'
)

## install library
(function(required.library) {
    sapply(required.library,
           function(x) {
               if (!require( x , character.only = TRUE)) {
                   install.packages( x )
               }
           })
})(required.library)


                                        # library(plotflow,  quietly = TRUE, warn.conflicts = FALSE)
## overwrite
head <- function(x, ...) {
    if (is.list(x) && !is.data.frame(x)) {
        message("variable is LIST.")
        names(x)
    } else {
        utils::head(x, ...)
    }
}

## overwrite
str <- function(...) {
	tmp <- options()$max.print
	options(max.print=1e4)
	utils::str(...)
	options(max.print=tmp)
}

##
# + theme_bw(base_family = "HiraKakuProN-W3")

## for adhoc
options(max.print = 1e3, width = 140)
n <- names
l <- length
s <- str
d <- dim
h <- head


## Excel c&p
excel.mac <- function(...) {
   args <- c(...)
   temp <- matrix(scan(""), byrow=TRUE, ncol=length(args))
   data <- data.frame(temp)
   colnames(data) <- args
   return(data)
}
if (Sys.info()[1] == "Darwin" && FALSE) {
	par(family="HiraMaruProN-W4")
	par(family="HiraKakuProN-W3")
}

##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##' @title
##' @return
##' @author Kobayashi
main <- function () {

    ## load data
    if (readline("load file? <y/n>") == "y") {
        mat.doc2topic <- read.csv("./doc2topic_and_sim_replace2.csv")
        mat.doc2topic <<- mat.doc2topic
        mat.word2topic <- read.csv("./word2topic.csv")
        mat.word2topic <<- mat.word2topic
    }

    ##
    colname.topic.doc2topic <- colNameFinder(mat.doc2topic, "topic")
    colname.topic.doc2topic <<- colname.topic.doc2topic
    colname.topic.word2topic <- colNameFinder(mat.word2topic, "Topic")
    colname.topic.word2topic <<- colname.topic.word2topic

    ## remove null word
    mat.word2topic <- subset(mat.word2topic, word != "")

    if (readline("Rebuild estimation all topic?(it takes long time.) <y/n>") == "y") {
        res <- conv.doc2topic(as.character(mat.doc2topic[ , "doc"]))
        saveRDS(res, "estimated_topic_by_local_topic.RDS")
    }
    res <- readRDS("estimated_topic_by_local_topic.RDS")
    mat.doc2topic[, colname.topic.doc2topic] <- res
        

    do.main()

}

##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##' @title
##' @return
##' @author Kobayashi
do.main <- function() {
    while (TRUE) {
        str.target <- readline("* >")
        if (str.target %in% c("quit", "Q", "q"))
            break
        do.search (str.target)
    }

}


##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##' @title 
##' @param arg.str 
##' @param verbose 
##' @return 
##' @author G.KOBAYASHI
conv.doc2topic <- function(arg.str, verbose = FALSE) {

    ## 文章のtopic化
    len.str <- length(arg.str)
    my.res.apply <- sapply(as.character(mat.word2topic$word),
                           function (x) {
                               result <- rep(FALSE, len.str)
                               res.grep <- grep(x, arg.str)
                               result[res.grep] <- TRUE
                               ## ret
                               as.numeric(result)
                           })
    
    if (len.str == 1) {
        if ( verbose && any(my.res.apply != 0)) {
            ## キーワードリスト
            my.keyword.valid <- names(my.res.apply)[my.res.apply == 1]
            my.keyword.valid <- my.keyword.valid[my.keyword.valid != ""]
                                        # print( sort(my.keyword.valid) )

            my.res <- sapply(my.keyword.valid,
                             function (x) {
                                 tmp <- subset(mat.word2topic, word == x)
                                 round(as.numeric(tmp[, colNameFinder(tmp, "Topic")]), 3)
                             })
            my.keyword.weight <- apply(my.res, 2, sum)
            my.keyword.weight <- sort(my.keyword.weight, decreasing= TRUE)
            
            my.keyword.weight[0.05 < my.keyword.weight] # PARAMETER

            print( 
                paste0(paste0( names(my.keyword.weight),"(",
                              my.keyword.weight,
                              ")"), collapse = "|")
                )
        }
        
        my.res.apply <- t (my.res.apply)
    }

    if (FALSE) {
        ## 
        tmp <- subset(mat.word2topic, word == "エン")
        plot(as.numeric(tmp[, colNameFinder(tmp, "Topic")]), t="o")

        tmp <- subset(mat.word2topic, word == "エンジン")
        plot(as.numeric(tmp[, colNameFinder(tmp, "Topic")]), t="o")
    }
    
    
    
    my.res.apply <- as.matrix(my.res.apply)
    my.res.topic <- as.matrix(my.res.apply) %*% as.matrix(mat.word2topic[,2:31]) # HYPER PARAMETER


    my.res.topic <- apply(my.res.topic,
                          1,
                          function(x) {
                              if (0 < sum (x)) {
                                  return( x / sum (x) )
                              }
                              return (x)
                          })

    my.res.topic <- t(my.res.topic)

    ## ret
    my.res.topic
}


##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##' @title
##' @param str.target
##' @return
##' @author Kobayashi
do.search <- function(str.target, arg.num.search = 8, flag.graph = TRUE) {

    CONST.NUM.OUTPUT <- arg.num.search


    res.topic <- conv.doc2topic(str.target, verbose = TRUE)

    if (all(res.topic == 0)) {
        message("cannot estimate topic.")
        return (NULL)
    }
    
    ## topic行列
    mat.doc.topic <- as.matrix((mat.doc2topic[, colname.topic.doc2topic]))

    ## hellinger distance
    res.topic.sqrt <- sqrt(res.topic)
    mat.doc.topic.sqrt <- sqrt(mat.doc.topic)

    res.distance <- apply(mat.doc.topic.sqrt,
                          1,
                          function (x) {
                              sum( (x - res.topic.sqrt)^2 )
                          })


    ## Find similar data , of CONST.NUM.OUTPUT
    rowid.min <- numeric(CONST.NUM.OUTPUT)
    rowid.min <- order(res.distance, decreasing=FALSE)[ seq (CONST.NUM.OUTPUT)]

    if (FALSE) {
        res.distance.sort <- sort(res.distance)
        for (i in seq (CONST.NUM.OUTPUT)) {
            rowid.min[i] <- which(res.distance == res.distance.sort[i])[1]
        }
    }

    ## output

    message(rep ("=",80))
    print(
        paste(round(res.topic,2), collapse="| ")
    )
    for (i in seq(CONST.NUM.OUTPUT)) {
        message("---[",rowid.min[i],"]",rep("-",40))
        print(
            as.character(mat.doc2topic[rowid.min[i] ,"doc"])
        )
        print(
            paste0("  Dist = ", round( res.distance[rowid.min[i]], 3))
        )
        print(
            paste(round(mat.doc2topic[rowid.min[i] , colname.topic.doc2topic],2), collapse="| ")
        )
    }

    ## graph
    if (flag.graph) {
        par.ylim.range <- c(0, 
                            max(c(as.numeric(res.topic),as.numeric(unlist(mat.doc2topic[rowid.min, colNameFinder(mat.doc2topic, "topic")]))), na.rm = TRUE)
                            )
        
        i.counter <- 1
        for (i.rowid in rowid.min) {
            i.counter <- i.counter + 1

            plot(as.numeric(mat.doc2topic[i.rowid, colNameFinder(mat.doc2topic, "topic")]),t="o", xlab="",ylab="", ylim = par.ylim.range,lty=i.counter, col="red", axes = FALSE)

            par(new=T)

        }
        plot(as.numeric(res.topic), t="o", ylim=par.ylim.range, xlab="Topic",ylab="Probability")
    }
    
}



##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##' @title
##' @param dat
##' @param regex
##' @param diff
##' @param except
##' @return
##' @author
colNameFinder <- function(dat, regex, diff, except = FALSE) {

    res.regex <- c()
    res.diff <- c()

    ## col name list.
    my.colNames <- colnames(dat)

    if (!missing(regex)) {
        res.regex <- sapply(regex,
                            function(x) {
                                colid.grep <- grep(x, my.colNames)
                                my.colNames[colid.grep]
                            })
    }

    if (!missing(diff)) {
        res.diff <- sapply(diff,
                           function(x) {
                               colid.grep <- grep(x, my.colNames)
                               my.colNames[colid.grep]
                           })
    }

    ## conv
    res.regex <- as.character(unique(unlist(res.regex)))
    res.diff <- as.character(unique(unlist(res.diff)))

    ## ret
    if (except) {
        return( setdiff(names(dat),
                        setdiff(res.regex, res.diff))
               )

    } else {
        return( setdiff(res.regex, res.diff) )
    }
    return (NULL)                      # dummy
}

##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##' @title 
##' @return 
##' @author G.KOBAYASHI
adhoc.analysis.1 <- function() {

    ## 例
    tmp.rowid <- 808
    mat.doc2topic[tmp.rowid,]

    
    pdf("./fig_topic_rowid=808.pdf", width = 14)
    plot(as.numeric(mat.doc2topic[tmp.rowid,colNameFinder(mat.doc2topic, "topic")]),t="o", xlab="",ylab="")


    ## 
    rowid.sim.1 <- which(mat.doc2topic[, "doc"]%in%mat.doc2topic[tmp.rowid, "X1_similar_doc"])
    rowid.sim.2 <- which(mat.doc2topic[, "doc"]%in%mat.doc2topic[tmp.rowid, "X2_similar_doc"])
    rowid.sim.3 <- which(mat.doc2topic[, "doc"]%in%mat.doc2topic[tmp.rowid, "X3_similar_doc"])
    rowid.sim.4 <- which(mat.doc2topic[, "doc"]%in%mat.doc2topic[tmp.rowid, "X4_similar_doc"])
    rowid.sim.5 <- which(mat.doc2topic[, "doc"]%in%mat.doc2topic[tmp.rowid, "X5_similar_doc"])

    ##
    plot(as.numeric(mat.doc2topic[rowid.sim.1,colNameFinder(mat.doc2topic, "topic")]),t="o", xlab="",ylab="")
    plot(as.numeric(mat.doc2topic[rowid.sim.2,colNameFinder(mat.doc2topic, "topic")]),t="o", xlab="",ylab="")
    plot(as.numeric(mat.doc2topic[rowid.sim.3,colNameFinder(mat.doc2topic, "topic")]),t="o", xlab="",ylab="")
    plot(as.numeric(mat.doc2topic[rowid.sim.4,colNameFinder(mat.doc2topic, "topic")]),t="o", xlab="",ylab="")
    plot(as.numeric(mat.doc2topic[rowid.sim.5,colNameFinder(mat.doc2topic, "topic")]),t="o", xlab="",ylab="")
    dev.off()
    

    
    as.character(mat.doc2topic[tmp.rowid,"doc"])
    mat.doc2topic[tmp.rowid,colNameFinder(mat.doc2topic, "similar")]


    
}
