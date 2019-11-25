library(dplyr)
library(httr)
library(purrr)
library(rvest)
library(readr)
library(stringr)
library(tidyr)


options(error = function() traceback(2))


get_car_type <- function(maker_name){

  #' 車のメーカー名から、goo-net(https://www.goo-net.com/car/)に存在する車種名・販売期間一覧を作成する 。
  #' @param maker_name:メーカー名(半角英字)
  #' @return 車種・車種情報URL・販売期間を含むdataframe

  root_url <- sprintf("https://www.goo-net.com/car/%s/index.html", toupper(maker_name))

  http_status <- status_code(GET(root_url))
  if(http_status != 200) stop(sprintf("Http response from %s is %s.", root_url, http_status))

  car_list <- read_html(root_url) %>%
    html_node("div.carlist") %>%
    html_nodes("table") %>%
    html_nodes("span")

  # 車種名ごとに型式情報パス情報取得
  df_url_name <- data.frame(
    url = car_list %>% html_nodes("a") %>% html_attr("href"),
    name = car_list %>% html_nodes("a") %>% html_text(),
    stringsAsFactors = FALSE)

  # 車種の販売期間情報抽出
  df_name_term <- car_list %>%
    html_text() %>%
    as.data.frame() %>%
    rename(text = ".") %>%
    mutate(text = str_replace_all(text, "〜", "～")) %>%
    filter(str_detect(text, regex('[1-2][0-9]{3}年[0-9]{1,2}月～'))) %>%
    mutate(
      name = str_extract(text, regex("[^0-9]+")),
      name = str_sub(name, 2L, -1L),
      is_selling = str_detect(text, "販売中"),
      term = if_else(
        is_selling,
        str_extract(text, regex("[1-2][0-9]{3}年[0-9]{1,2}月～")),
        str_extract(text, regex("[1-2][0-9]{3}年[0-9]{1,2}月～[1-2][0-9]{3}年[0-9]{1,2}月"))),
      term_split = str_split(term,"～"),
      begin = term_split %>% map(~ .x[1]) %>% invoke(.f = 'rbind') %>% as.vector(),
      end = term_split %>% map(~ .x[2]) %>% invoke(.f = 'rbind') %>% as.vector()) %>%
    select(name, begin, end)

  # 上記二つのdataframe結合
  df_car_info <- df_url_name %>%
    left_join(df_name_term, by = "name") %>%
    mutate(url = str_c("https://www.goo-net.com",str_sub(url, 1L, -6L), "/type.html"),
           begin_yyyym = str_replace_all(begin, "年|月", ""),
           end_yyyym = str_replace_all(end, "年|月", ""),
           begin_term = str_c(str_sub(begin_yyyym, 1L, 4L),
                              "-",
                              str_sub(begin_yyyym, 5L, -1L) %>% as.integer() %>% formatC(width = 2L, flag = "0")
                              ),
           end_term = if_else(end == "",
                              "9999-12",
                              str_c(str_sub(end_yyyym, 1L, 4L),
                                    "-",
                                    str_sub(end_yyyym, 5L, -1L) %>% as.integer() %>% formatC(width = 2L, flag = "0")
                                    )
                              )
           ) %>%
    select(url, name, begin_term, end_term)

  return(df_car_info)

}


get_model <- function(df_car_info, maker_name, output_filename){

  #' 車種名から対応する型式一覧を取得する。
  #' @param df_car_info:メーカー名と車種の情報を持つdataframe
  #' @param maker_name:メーカー名(半角英字)
  #' @return car_model_info_{maker_name}.csv (実行ディレクトリに作成される)

  res <- NULL

  for(i in 1L:nrow(df_car_info)){

    target <- df_car_info %>% slice(i)
    Sys.sleep(2)

    # 型式情報取得
    sprintf("Progress: %d/%d\n URL: '%s'.\n", i, nrow(df_car_info), target$url) %>% cat()
    katashiki <- try(read_html(target$url), silent = TRUE)

    # クローリング失敗時の処理
    if("try-error" %in% class(katashiki)){

      sprintf("Failed to access to %s.", target$url) %>% warnings()
      next()

    }

    # Parse
    katashiki %<>%
      html_nodes("table") %>%
      html_nodes("a") %>%
      html_nodes("strong") %>%
      html_text()  %>%
      unique() %>%
      str_split("-") %>%
      map(~ .x[2]) %>%
      invoke(.f = 'rbind') %>%
      as.vector()

    res_i <- crossing(target %>% select(-url), katashiki)
    res <- rbind(res, res_i)

  }

  res %>%
    write_csv(output_filename)

}


main <- function(maker_name, output_filename){

  #' 実行
  #' @input maker_name:メーカー名(半角英字)

  df_car_info <- get_car_type(maker_name = maker_name)
  get_model(
    df_car_info = df_car_info,
    maker_name = maker_name,
    output_filename = output_filename
  )

}

commandArgs(trailingOnly = TRUE) %>%
  as.list()  %>%
  do.call(main, .)

