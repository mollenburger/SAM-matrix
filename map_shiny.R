library(sf)
library(tmap)
library(shiny)

regions_shape<-st_read('outdata/regions_shape.shp')


# Define the UI
ui = fluidPage(

  # App title
  titlePanel("Sustainable Agriculture Matrix Indicators"),

  # Sidebar layout with input and output definitions
  sidebarLayout(

    # Sidebar panel for inputs
    sidebarPanel(

      # First input: Scenario
      selectInput(inputId = "chosescen",
                  label = "Choose the future scenario to display:",
                  choices = list("Yield Gap Closure" = "PotYld",
                                 "Dietary Transition" = "DietaryTransition",
                                 "Reference"="Reference")),

      selectInput(inputId = "chosevar",
                  label = "Choose the indicator to display:",
                  choices = list("N surplus" = "Nsur",
                                 "P surplus" = "Psur",
                                 "Forest area change fraction"="forest_frac",
                                 "Emissions (gwp"="Emissions (gwp)",
                                 "Export percent"="Export percent",
                                 "Ag labor productivity"="Ag Labor Productivity",
                                 "Food affordability"="Food affordability")),

      sliderInput(inputId = "choseyear",
                  label = "Choose the year to display:",
                  min=2015, max=2050, step=10, value=2030)),

    # Main panel for displaying outputs
    mainPanel(

      # Output: interactive world map
      tmapOutput("my_tmap")

    )
  )
)

# Define the server
server = function(input, output, session) {


  # Create the world map
  tmap_mode("view")
  tm_style('white')
  output$my_tmap = renderTmap({
    tm_shape(regions_shape[regions_shape$scenari==input$chosescen &
                            regions_shape$year==input$choseyear &
                            regions_shape$variabl==input$chosevar,])+
      tm_polygons('value', title=paste0(input$chosevar))})
  }

# Finally, we can run our app by either clicking "Run App" in the top of our RStudio IDE, or by running
shinyApp(ui = ui, server = server)

