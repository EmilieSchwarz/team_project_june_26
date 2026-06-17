library(tidygeocoder)
library(httr)
library(sf)

server <- function(input, output, session) {

  # ---- reactive data ----
  map_data <- reactive({
    daily_data <- dummy_shiny_data %>%
      filter(timestep == input$selected_date)
    shapefile_d %>%
      left_join(daily_data, by = c("BEZNAME" = "district"))
  })

  # ---- initial map (CH ONLY) ----
  output$risk_map <- renderLeaflet({
    leaflet(shapefile_d) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      fitBounds(
        lng1 = 5.96, lat1 = 45.82,
        lng2 = 10.49, lat2 = 47.81
      ) %>%
      addLegend(
        position = "bottomright",
        colors   = c("#FDB927", "#D95F41", "#8C2969", "#431A4D", "#d9d9d9"),
        labels   = c("None", "Low", "Medium", "High", "No data"),
        title    = "Risk level",
        opacity  = 0.9
      )
  })

  # ---- palette (NUMERIC RISK 0–3) ----
  pal <- colorFactor(
    palette = c(
      "#FDB927",
      "#D95F41",
      "#8C2969",
      "#431A4D"
    ),
    domain = c(0, 1, 2, 3),
    na.color = "#d9d9d9"
  )

  # ---- update polygons ----
  observe({
    data <- map_data()
    req(nrow(data) > 0)
    leafletProxy("risk_map", data = data) %>%
      clearShapes() %>%
      addPolygons(
        layerId = ~BEZNAME,
        fillColor = ~pal(risk),
        fillOpacity = 0.8,
        color = "white",
        weight = 1,
        popup = ~paste0("<b>", BEZNAME, "</b><br>Risk: ", risk)
      )
  })

  # ---- click interaction ----
  selected_district <- reactiveVal(NULL)

  observeEvent(input$risk_map_shape_click, {
    click <- input$risk_map_shape_click
    selected_district(click$id)
    district <- map_data() %>% filter(BEZNAME == click$id)
    req(nrow(district) > 0)
    bbox <- sf::st_bbox(district)
    leafletProxy("risk_map") %>%
      flyToBounds(
        lng1 = bbox["xmin"], lat1 = bbox["ymin"],
        lng2 = bbox["xmax"], lat2 = bbox["ymax"]
      )
  })

  # ---- info panel ----
  output$district_info <- renderPrint({
    req(selected_district())
    map_data() %>%
      filter(BEZNAME == selected_district()) %>%
      sf::st_drop_geometry() %>%
      select(BEZNAME, risk)
  })

  # ---- day strip ----
  output$day_strip <- renderUI({
    dates  <- Sys.Date() + 0:4
    labels <- c("Today", "Tomorrow", "", "", "")
    btns <- lapply(seq_along(dates), function(i) {
      d <- dates[i]
      is_active <- (d == input$selected_date)
      tags$button(
        class   = paste("day-btn", if (is_active) "active"),
        onclick = sprintf(
          "Shiny.setInputValue('selected_date', '%s', {priority:'event'})",
          format(d, "%Y-%m-%d")
        ),
        tags$span(class = "lbl", labels[i]),
        tags$span(class = "dt",  format(d, "%d %b")),
        tags$span(class = "wd",  format(d, "%A"))
      )
    })
    div(class = "day-strip", tagList(btns))
  })

  # ---- postal lookup ----
  output$postal_result <- renderUI({
    req(input$postal_lookup)
    code <- toupper(trimws(isolate(input$postal_input)))
    if (nchar(code) == 0)
      return(HTML("<span style='color:#94a3b8'>Enter a postal code above.</span>"))
    hit <- postal_to_district[postal_to_district$postal_code == code, ]
    if (nrow(hit) == 0)
      HTML(paste0("<span style='color:#dc2626'>No district found for <b>", code, "</b>.</span>"))
    else
      HTML(paste0("<b>", code, "</b> → <b>", hit$district[1], "</b>"))
  })

  # ---- 5-day forecast table ----
  output$forecast_table <- renderUI({
    dates     <- Sys.Date() + 0:4
    date_hdrs <- format(dates, "%a %d %b")
    districts <- sort(unique(dummy_shiny_data$district))
    risk_label <- c("None", "Low", "Medium", "High")

    header <- tags$tr(
      tags$th(class = "dcol", "District"),
      lapply(date_hdrs, tags$th)
    )

    rows <- lapply(districts, function(d) {
      cells <- lapply(dates, function(dt) {
        r <- dummy_shiny_data$risk[
          dummy_shiny_data$district == d & dummy_shiny_data$timestep == dt
        ]
        if (length(r) == 0 || is.na(r[1])) {
          tags$td(tags$span(class = "risk-na", "–"))
        } else {
          rv  <- r[1]
          cls <- paste0("risk-", rv)
          lbl <- if (rv >= 0 && rv <= 3) risk_label[rv + 1] else as.character(rv)
          tags$td(tags$span(class = cls, lbl))
        }
      })
      tags$tr(tags$td(class = "dcol", d), cells)
    })

    tags$table(class = "ftable", tags$thead(header), tags$tbody(rows))
  })


  observeEvent(input$addr_lookup, {
    query <- isolate(input$addr_input)

    if (nchar(query) == 0) {
      output$addr_result <- renderUI(
        HTML("<span style='color:#94a3b8'>Enter an address above.</span>")
      )
      return()
    }

    url <- paste0("https://photon.komoot.io/api/?q=", URLencode(query))

    raw <- tryCatch(
      httr::GET(url),
      error = function(e) NULL
    )

    if (is.null(raw) || httr::status_code(raw) != 200) {
      output$addr_result <- renderUI(
        HTML("<span style='color:#dc2626'>Address lookup failed (server error).</span>")
      )
      return()
    }

    txt <- httr::content(raw, as = "text", encoding = "UTF-8")

    if (!is.character(txt) || length(txt) == 0 || !jsonlite::validate(txt)) {
      output$addr_result <- renderUI(
        HTML("<span style='color:#dc2626'>Address lookup returned invalid data.</span>")
      )
      return()
    }

    res <- jsonlite::fromJSON(txt)

    geom <- res$features$geometry[[1]]

    if (is.null(geom$coordinates) || length(geom$coordinates) < 2) {
      output$addr_result <- renderUI(
        HTML("<span style='color:#dc2626'>No coordinates found for this address.</span>")
      )
      return()
    }

    lon <- geom$coordinates[1]
    lat <- geom$coordinates[2]

    pt <- sf::st_as_sf(
      data.frame(lon = lon, lat = lat),
      coords = c("lon", "lat"),
      crs = 4326
    )

    pt <- sf::st_transform(pt, sf::st_crs(shapefile_d))

    hit <- sf::st_join(pt, shapefile_d)

    if (nrow(hit) == 0 || is.na(hit$BEZNAME)) {
      output$addr_result <- renderUI(
        HTML("<span style='color:#dc2626'>No district found for this location.</span>")
      )
      return()
    }

    district <- hit$BEZNAME[1]

    output$addr_result <- renderUI(
      HTML(paste0("<b>", query, "</b> → <b>", district, "</b>"))
    )

    selected_district(district)

    bbox <- sf::st_bbox(shapefile_d[shapefile_d$BEZNAME == district, ])
    leafletProxy("risk_map") %>%
      flyToBounds(bbox["xmin"], bbox["ymin"], bbox["xmax"], bbox["ymax"])
  })

} # <-- single closing brace for the whole server function
