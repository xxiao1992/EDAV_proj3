library(shiny)
library(leaflet)
library(RColorBrewer)
library(dplyr)
library(ggplot2)


shinyServer(function(input, output, session) {
        
        
        
        ## complain Map ###########################################
        
        # Create the map
        output$map <- renderLeaflet({
                leaflet() %>%
                        addTiles(
                                urlTemplate = "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiZnJhcG9sZW9uIiwiYSI6ImNpa3Q0cXB5bTAwMXh2Zm0zczY1YTNkd2IifQ.rjnjTyXhXymaeYG6r2pclQ",
                                attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
                        ) %>%
                setView(lng = -73.97, lat = 40.75, zoom = 13)
        })
        
        output$mapc <- renderLeaflet({
                leaflet() %>%
                        addTiles(
                                urlTemplate = "https://api.mapbox.com/v4/mapbox.dark/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiZnJhcG9sZW9uIiwiYSI6ImNpa3Q0cXB5bTAwMXh2Zm0zczY1YTNkd2IifQ.rjnjTyXhXymaeYG6r2pclQ",
                                attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
                        ) %>%
                        setView(lng = -73.97, lat = 40.75, zoom = 13)
        })
        
        # Filter complain data
        cdata <- reactive({
                draw <- data_2015_top5
                if (input$complain != '') {
                        t <- filter(draw, Complaint_Type == input$complain)
                        draw <- t
                }
                return(draw)
        })
        
        crimedata <- reactive({
                draw <- crime
                if (input$crime != '') {
                        t <- filter(draw, Offense == input$crime)
                        draw <- t
                }
                return(draw)
        })
                
        observe({  
                pal1 <- colorFactor(palette()[2:6], levels(data_2015_top5$Complaint_Type))
                Radius1 <- 2
                if (length(as.matrix(cdata())) != 0){
                        leafletProxy("map") %>%
                                clearMarkers() %>%
                                # addPolylines(lng=c(a$lon,a$lon1),lat=c(a$lat,a$lat1),color="red") %>%
                                #addMarkers(data = ttype(), ~Long, ~Lat, icon = restroomIcon(), options = markerOptions(opacity = 0.9), popup = ~Name) %>%
                                addCircleMarkers(data = cdata(), ~Long, ~Lat, radius = Radius1, stroke = FALSE, fillOpacity = 0.7, fillColor = pal1(cdata()[["Complaint_Type"]])) %>%
                                addLegend("bottomleft", pal=pal1, values=cdata()[["Complaint_Type"]], title="complain",
                                          layerId="colorLegend")
                }
                else {
                        #       print("hello")
                        #       print(a$lat)
                        #       print(a$lon)
                        leafletProxy("map") %>%
                                clearMarkers() 
                }
        })
        
               
        observe({  
                pal2 <- colorFactor(palette()[-1], levels(crime$Offense))
                Radius1 <- 2
                if (nrow(crimedata())!=0){
                        leafletProxy("mapc") %>%
                                clearMarkers() %>%
                                # addPolylines(lng=c(a$lon,a$lon1),lat=c(a$lat,a$lat1),color="red") %>%
                                #addMarkers(data = ttype(), ~Long, ~Lat, icon = restroomIcon(), options = markerOptions(opacity = 0.9), popup = ~Name) %>%
                                addCircleMarkers(data = crimedata(), ~Long, ~Lat, radius = Radius1, stroke = FALSE, fillOpacity = 0.7, fillColor = pal2(crimedata()[["Offense"]])) %>%
                                addLegend("bottomleft", pal=pal2, values=crimedata()[["Offense"]], title="crime",
                                          layerId="colorLegend")
                }
                else {
                        leafletProxy("mapc") %>%
                                clearMarkers() 
                }
        })
        
        output$heat_text = renderText({
                paste("Heat Graph of All Complaints")
        })
        
        output$baseMap  <- renderMap({
                baseMap <- Leaflet$new()
                baseMap$setView(c(40.7577,-73.9857), 10)
                baseMap$tileLayer(provider = "Stamen.TonerLite")
                baseMap
                
                #leaflet() %>% addTiles() %>% addProviderTiles("Stamen.TonerLite") %>%setView(lat=40.7577,lng=-73.9857, zoom=10)
                
        })
        
        
        output$heatMap <- renderUI({
                if (input$complaintype == ''){
                        hdata <- data_2015_top5
                        
                }
                else{
                        hdata <- data_2015_top5[which(data_2015_top5$Complaint_Type==input$complaintype), ]
                        
                }
                
                
                complainmap1 <- as.data.table(hdata)
                complainmap2 <- complainmap1[(Lat != ""), .(count = .N), by=.(Lat, Long)]
                j <- paste0("[",complainmap2[,Lat], ",", complainmap2[,Long], ",", complainmap2[,count], "]", collapse=",")
                j <- paste0("[",j,"]")
                tags$body(tags$script(HTML(sprintf("
                                var addressPoints = %s
if (typeof heat === typeof undefined) {
            heat = L.heatLayer(addressPoints)
            heat.addTo(map)
          } else {
            heat.setOptions()
            heat.setLatLngs(addressPoints)
          }
                                         </script>"
                                                   , j))))
                
                
                
        })
        
        
        
        
        output$trellis <- renderPlotly({
                
                gg <- ggplot(trellis_data, aes(Room, Price)) +
                        geom_point(aes(color = Type ))+
                        facet_wrap(~RegionName, ncol=3)+coord_flip()+
                        ggtitle("Comparison of Home Value and Lease")
                # Convert the ggplot to a plotly
                p <- ggplotly(gg)
                p
        })
        
        # output$zipmaps <- renderImage({
        #         safe <- filter(plot_data, security == input$safety)
        #         #trans <- filter(plot_data, metro_convenience == input$transportation)
        #         safe_plot <- zip.map[zip.map@data$ZCTA5CE10 %in% safe$zip_code, ]
        #         safe_data <- fortify(safe_plot)
        #         
        #         outfile <- tempfile(fileext='.png')
        #         
        #         # Generate the PNG
        #         png(outfile, width=400, height=300)
        #         qmap(center, zoom = 12, maptype = 'roadmap') +
        #                 geom_polygon(aes(x = long, y = lat, group = group), data = safe_data,
        #                              colour = 'white', fill = 'black', alpha = .4, size = .3)
        #         
        #         dev.off()
        #         
        #         # Return a list containing the filename
        #         list(src = outfile,
        #              contentType = 'image/png',
        #              width = 400,
        #              height = 300,
        #              alt = "This is alternate text")
        # }, deleteFile = TRUE)
        
        
        output$transportation <- renderPlotly({
                #safe <- filter(plot_data, security == input$safety)
                #trans <- filter(plot_data, metro_convenience == input$transportation)
                #trans_plot <- zip.map[zip.map@data$ZCTA5CE10 %in% trans$zip_code, ]
                #trans_data <- fortify(trans_plot)
                
                
                trans_data <- plot_data[ , c(1,6)]
                colnames(trans_data) <- c("region", "value")
                trans_data$region <- as.character(trans_data$region)
                transmap <- zip_choropleth(trans_data,
                                         zip_zoom = trans_data$region,
                                         title="New York City Transportation",
                                         legend="Transportation")
                transmap
                
                
        })
        
        output$crime_rate <- renderPlotly({
                cr_data <- plot_data[ , c(1,8)]
                colnames(cr_data) <- c("region", "value")
                cr_data$region <- as.character(cr_data$region)
                crmap <- zip_choropleth(cr_data,
                                           zip_zoom = cr_data$region,
                                           title="New York City Crime Rate",
                                           legend="Crime Rate")
                crmap
                
        })
        
        output$housing_price <- renderPlotly({
                hp_data <- plot_data[ , c(1,4)]
                colnames(hp_data) <- c("region", "value")
                hp_data$region <- as.character(hp_data$region)
                hpmap <- zip_choropleth(hp_data,
                                           zip_zoom = hp_data$region,
                                           title="New York City Housing Price",
                                           legend="Housing Price")
                hpmap
                
        })
        
        output$income <- renderPlotly({
                income_data <- plot_data[ , c(1,3)]
                colnames(income_data) <- c("region", "value")
                income_data$region <- as.character(income_data$region)
                incomemap <- zip_choropleth(income_data,
                                           zip_zoom = income_data$region,
                                           title="New York City Income",
                                           legend="Income")
                incomemap
                
        })
        
        output$population <- renderPlotly({
                pop_data <- plot_data[ , c(1,2)]
                colnames(pop_data) <- c("region", "value")
                pop_data$region <- as.character(pop_data$region)
                popmap <- zip_choropleth(pop_data,
                                           zip_zoom = pop_data$region,
                                           title="New York City Population",
                                           legend="Population")
                popmap
                
        })
        
        
        
        
        
})
