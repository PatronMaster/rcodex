

#' Write R code
#'
#'
#' @importFrom rstudioapi getActiveDocumentContext insertText document_position
#' @importFrom openai create_completion
#' @return the code write in the file
#' @export
#'
#' @examples
#' #
writeRcode <- function() {
save_conf<-read_configuration()
  Sys.setenv(
     OPENAI_API_KEY = save_conf$rcodex_key
  )

  getContext<-rstudioapi::getActiveDocumentContext()
  getText<-getContext$selection[[]]$text

  Openai_pronpt<- paste("write in the",language," language the following:",getText)
  if (save_conf$rcodex_model %in% c("gpt-4","gpt-4-32k","gpt-3.5-turbo-0301","gpt-3.5-turbo")) {
    
    openai_answer<- openai::create_chat_completion(
      model = save_conf$rcodex_model,
      messages = list(list("role" = "user","content" = Openai_pronpt)),
      max_tokens = save_conf$rcodex_lenght
    )
    openai_message<-openai_answer$choices$message.content
  }else{
    openai_answer<- openai::create_completion(
        model = save_conf$rcodex_model,
        prompt = Openai_pronpt,
        max_tokens = save_conf$rcodex_lenght
     )
    openai_message<-openai_answer$choices$text
  }


  row<-as.numeric(getContext$selection[[]]$range$end[1]+1)
  column<-1
  rstudioapi::insertText(openai_message,id = getContext$id,location = document_position(row, column))

}

#' rcodexConf config
#'
#' @importFrom miniUI miniPage gadgetTitleBar miniContentPanel
#' @importFrom shiny passwordInput selectInput numericInput dialogViewer runGadget textOutput
#' @export
#'
#' @examples
rcodexConf  <- function() {
  save_conf<-read_configuration()

  ui <-  miniPage(
    gadgetTitleBar("Rcodex Conf"),
    miniContentPanel(
      passwordInput("key", "Insert a OPENAI KEY:", value = save_conf$rcodex_key),
      selectInput("model", "Choose the model:",selected = save_conf$rcodex_model, choices = c("text-davinci-003","gpt-4","gpt-4-32k","gpt-3.5-turbo-0301","gpt-3.5-turbo","code-davinci-002","code-cushman-001")),
      numericInput("lenght", "Insert max tokens:", save_conf$rcodex_lenght),
      selectInput("language", "Choose the Output language:",selected = save_conf$language, choices = c("R","Python","Shell Bash Script","SQL","Groovy","TypeScript","JavaScript","Go","Perl","PHP")),
    )
  )

  server <- function(input, output, session){

    #output$model_saved <- renderText({ "Bla" })

    observeEvent(input$key,{
      assign("rcodex_key", input$key, envir = .GlobalEnv)
    })
    observeEvent(input$model,{
      assign("rcodex_model", input$model, envir = .GlobalEnv)
    })
    observeEvent(input$lenght,{
      assign("rcodex_lenght", input$lenght, envir = .GlobalEnv)
    })
    observeEvent(input$language,{
      assign("language", input$language, envir = .GlobalEnv)
    })
    
    # Saving global variables
    observeEvent(input$done, {
      saveRDS(data.frame(rcodex_key=rcodex_key,rcodex_model=rcodex_model,rcodex_lenght=rcodex_lenght,language=language),file.path(Sys.getenv("HOME"), "Rprofile_codex.RDS"))
      save(rcodex_key, rcodex_model, rcodex_lenght,language, file = file.path(Sys.getenv("HOME"), ".RData"))

      invisible(stopApp())
    })


  }
  viewer <- dialogViewer("Subset", width = 100, height = 580)
  runGadget(ui, server, viewer = viewer)
}

#' Read Configuration
#'
#' @return
#'
#' @examples
read_configuration <- function() {
  if (file.exists(paste0(Sys.getenv("HOME"),"/Rprofile_codex.RDS"))) {
    save_conf<-readRDS(file = file.path(Sys.getenv("HOME"), "Rprofile_codex.RDS"))
  } else {
    save_conf<-data.frame(rcodex_key="",rcodex_model="text-davinci-003",rcodex_lenght="2000",language="R")
  }
}
