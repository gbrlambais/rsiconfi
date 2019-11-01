get_rgf<- function(year, periodicity, period, report_tp, annex, entity, co_power ){

  #test if some variables have just one element

  if (length(report_tp)>1){
    stop("Must inform just one report type")
  }

  if (length(annex)>1){
    stop("Must inform just one annex")
  }

  if (length(periodicity)>1){
    stop("Must inform just one periodicity")
  }

  #test some business rules

  if(report_tp>2 ){
    stop("Wrong report type")
  }

  if(!(periodicity %in% c("Q","S"))){
    stop("Wrong periodicity")
  }


  if (periodicity == "S" && period >2){
    stop("Wrong period")
  }

  if (period >3){
    stop("Wrong period")
  }

  if (!(co_power %in% c("E","L","J","M","D") )){
    stop("Wrong power code")

  }

  df_esf_entidade = tibble(entidade = entity )

  df_esf_entidade<-df_esf_entidade%>%
    mutate(esfera= case_when(
      str_length(entity)== 1 ~"U",
      str_length(entity)== 2 ~"E",
      str_length(entity)== 7 ~"M"
    ) )



  annex_txt<-paste0("RGF-Anexo ",annex)

  test<- df_esf_entidade %>%
    anti_join(df_reports%>%
                filter(anexo==annex_txt))

  if (NROW(test)>0){
    stop("One or more entities not suitable for the annex informed")
  }


  map_df(year, function(ref_year){

    map_df(period, function(ref_per){

      map_df(entity, function(ref_entity){

        map_df(co_power, function(ref_power){

          base_address<- "http://apidatalake.tesouro.gov.br/ords/siconfi/tt/rgf"
          annex_conv<-paste0("RGF-Anexo%20",annex)

          exp<- paste0(base_address,
                       "?an_exercicio=", ref_year,
                       "&in_periodicidade=", periodicity,
                       "&nr_periodo=", ref_per,
                       "&co_poder=", ref_power,
                       "&co_tipo_demonstrativo=", c("RGF", "RGF+Simplificado")[report_tp],
                       "&no_anexo=", annex_conv,
                       "&id_ente=",ref_entity)

          #print(exp)

          ls_siconfi<-jsonlite::fromJSON(exp)


          #print(ls_siconfi$count)
          if (ls_siconfi$count==0){
            return (tibble())
          }
          df_siconfi<- ls_siconfi[["items"]]

          df_siconfi$valor <- as.numeric(df_siconfi$valor)

          df_siconfi


        })

      })

    })
  })

}