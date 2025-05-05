library(dplyr)
library(leaflet)
library(sf)
library(htmltools)


  leaflet() %>%
    addProviderTiles(providers$Esri.WorldTopoMap) %>%
    #     addTiles() %>%

    # Add guage points for SFJ and SRY/
    addCircleMarkers(group = "cdec-gages",
                     lng = -123.0150,
                     lat = 41.64069,
                     radius = 10,
                     color = "blue",
                     fillOpacity = 1,
                     label = HTML("<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9263&end=&geom=small&interval=2' target='_blank'>SFJ</a>"),
                     labelOptions = labelOptions(noHide = TRUE,
                                                 interactive = TRUE,
                                                 direction = "bottom",
                                                 textsize = "15px")
    ) %>%
    addCircleMarkers(group = "cdec-gages",
                     lng = -122.5956,
                     lat = 41.82292,
                     radius = 10,
                     color = "blue",
                     fillOpacity = 1,
                     label = HTML("<a href='https://cdec.water.ca.gov/cdecplotter/JspPlotServlet?sensor_no=9254&end=&geom=small&interval=2' target='_blank'>SRY</a>"),
                     labelOptions = labelOptions(noHide = TRUE,
                                                 interactive = TRUE,
                                                 direction = "bottom",
                                                 textsize = "15px")) %>%

    # # Add pod_curtailment_status points.
    # addCircleMarkers(
    #   group = "pods",
    #   data = pods,
    #   lng = ~lon,
    #   lat = ~lat,
    #   popup = ~paste("WR ID:", wr_id, "<br>Owner:", owner, "<br>Status:", curtail_status),
    #   radius = 6,
    #   color = ~pal(curtail_status),  # Now correctly mapped
    #   stroke = TRUE,
    #   weight = 1.0,
    #   fillOpacity = 0.5
    # ) %>%
    #
    # # Add legend for curtailment status.
    # addLegend(
    #   group = "pods",
    #   data = pods,
    #   position = "bottomright",
    #   pal = pal,
    #   values = ~curtail_status,
    #   title = "Curtailment Status",
    #   opacity = 1
    # )

# Add scott-shasta watershed boundaries by reading in layer file
addPolygons(
  data = sf::st_read("./data/scott-shasta-huc8s/scott-shasta-huc8s.shp"),
  group = "watersheds",
  color = "black",
  weight = 1.5,
  opacity = 1.0,
  fillOpacity = 0.0
)# %>%

  # # Add legend for watersheds.
  # addLegend(
  #   group = "watersheds",
  #   data = sf::st_read("./data/scott-shasta-huc8s/scott-shasta-huc8s.shp"),
  #   position = "bottomright",
  #   pal = pal,
  #   values = ~NAME,
  #   title = "Watershed",
  #   opacity = 1
  # )
