ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      * { box-sizing: border-box; }
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        background: #f0f2f5;
        margin: 0;
      }

      /* ── Header ── */
      .app-header {
        background: #1e3a5f;
        color: white;
        padding: 14px 24px;
        display: flex;
        align-items: baseline;
        gap: 12px;
        margin-bottom: 16px;
      }
      .app-header h2 { margin: 0; font-size: 1.1rem; font-weight: 600; }
      .app-header span { font-size: 0.78rem; opacity: 0.55; font-family: monospace; }

      /* ── Day strip ── */
      .day-strip {
        display: flex;
        gap: 0;
        margin: 0 24px 16px;
        border-radius: 9px;
        overflow: hidden;
        border: 1px solid #dde2ea;
        background: white;
      }
      .day-btn {
        flex: 1;
        border: none;
        border-right: 1px solid #dde2ea;
        background: white;
        padding: 10px 6px 9px;
        cursor: pointer;
        text-align: center;
        transition: background 0.12s;
        line-height: 1.3;
      }
      .day-btn:last-child { border-right: none; }
      .day-btn .lbl {
        display: block;
        font-size: 0.62rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.07em;
        color: #8a97a8;
      }
      .day-btn .dt {
        display: block;
        font-family: monospace;
        font-size: 0.9rem;
        font-weight: 600;
        color: #1e293b;
      }
      .day-btn .wd {
        display: block;
        font-size: 0.65rem;
        color: #b0bac6;
      }
      .day-btn.active { background: #1e3a5f; }
      .day-btn.active .lbl,
      .day-btn.active .dt,
      .day-btn.active .wd { color: white !important; opacity: 1; }
      .day-btn:not(.active):hover { background: #f4f6fa; }

      /* ── Content wrapper ── */
      .content { padding: 0 24px 28px; }

      /* ── Card ── */
      .card {
        background: white;
        border-radius: 10px;
        border: 1px solid #dde2ea;
        overflow: hidden;
      }
      .card-header {
        padding: 11px 16px 10px;
        border-bottom: 1px solid #edf0f5;
        display: flex;
        align-items: center;
        gap: 8px;
      }
      .card-header span {
        font-size: 0.72rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: #64748b;
      }
      .card-body { padding: 14px 16px; }

      /* ── Postal lookup ── */
      .postal-row { display: flex; gap: 8px; }
      .postal-row input[type=text] {
        flex: 1;
        font-family: monospace;
        font-size: 0.95rem;
        border: 1px solid #cdd4de;
        border-radius: 6px;
        padding: 7px 11px;
        outline: none;
        text-transform: uppercase;
        background: #f8fafc;
        color: #1e293b;
      }
      .postal-row input[type=text]:focus { border-color: #3b82c4; background: white; }
      .postal-row button {
        background: #1e3a5f;
        color: white;
        border: none;
        border-radius: 6px;
        padding: 7px 15px;
        font-size: 0.82rem;
        font-weight: 500;
        cursor: pointer;
        white-space: nowrap;
      }
      .postal-row button:hover { background: #16304f; }
      .lookup-result {
        margin-top: 10px;
        font-size: 0.84rem;
        min-height: 28px;
        color: #334155;
        padding: 7px 10px;
        background: #f8fafc;
        border-radius: 6px;
        border-left: 3px solid #3b82c4;
      }

      /* ── Forecast table ── */
      .ftable { width: 100%; border-collapse: collapse; font-size: 0.8rem; }
      .ftable th {
        background: #f8fafc;
        padding: 7px 10px;
        font-weight: 600;
        color: #64748b;
        border-bottom: 1.5px solid #e8edf3;
        text-align: center;
        font-family: monospace;
        font-size: 0.73rem;
        white-space: nowrap;
      }
      .ftable th.dcol { text-align: left; }
      .ftable td {
        padding: 6px 10px;
        border-bottom: 1px solid #f1f4f8;
        text-align: center;
        color: #334155;
      }
      .ftable td.dcol { text-align: left; font-weight: 500; color: #1e293b; }
      .ftable tr:last-child td { border-bottom: none; }
      .ftable tr:hover td { background: #f8fafc; }

      .risk-0 { background:#e6f4ec; color:#166534; border-radius:4px; padding:2px 8px; font-size:0.72rem; font-weight:600; display:inline-block; }
      .risk-1 { background:#fef9c3; color:#854d0e; border-radius:4px; padding:2px 8px; font-size:0.72rem; font-weight:600; display:inline-block; }
      .risk-2 { background:#fff0d9; color:#92400e; border-radius:4px; padding:2px 8px; font-size:0.72rem; font-weight:600; display:inline-block; }
      .risk-3 { background:#fee2e2; color:#991b1b; border-radius:4px; padding:2px 8px; font-size:0.72rem; font-weight:600; display:inline-block; }
      .risk-na { color:#b0bac6; font-size:0.72rem; }

      /* hide original dateInput */
      #selected_date { display: none !important; }
    "))
  ),

  # ── Header ──────────────────────────────────────────────────────────────────
  div(class = "app-header",
      h2("Heat Mortality Risk Forecast by District"),
      span("Switzerland")
  ),

  # ── Hidden dateInput (server still uses input$selected_date) ────────────────
  dateInput("selected_date", "", value = Sys.Date(),
            min = min(dummy_shiny_data$timestep),
            max = max(dummy_shiny_data$timestep)),

  # ── 5-day button strip ───────────────────────────────────────────────────────
  uiOutput("day_strip"),

  div(class = "content",

      # ── Map card ──────────────────────────────────────────────────────────────
      div(class = "card", style = "margin-bottom: 16px;",
          leafletOutput("risk_map", height = 580)
      ),

      # ── Below-map row ─────────────────────────────────────────────────────────
      fluidRow(
        column(4,
               div(class = "card",
                   div(class = "card-header",
                       tags$i(class = "ti ti-search", style = "font-size:15px; color:#64748b;", `aria-hidden` = "true"),
                       span("Address lookup")
                   ),
                   div(class = "card-body",
                       div(class = "postal-row",
                           tags$input(id = "addr_input", type = "text",
                                      placeholder = "e.g. Bundesplatz 3, Bern"),
                           tags$button(id = "addr_btn",
                                       onclick = "Shiny.setInputValue('addr_lookup', Math.random())",
                                       "Search")
                       ),
                       div(class = "lookup-result", uiOutput("addr_result"))
                   )
               )

      ),
        column(8,
               div(class = "card",
                   div(class = "card-header",
                       tags$i(class = "ti ti-calendar-stats", style = "font-size:15px; color:#64748b;", `aria-hidden` = "true"),
                       span("5-day risk forecast")
                   ),
                   div(class = "card-body", style = "padding: 0;",
                       div(style = "overflow-x: auto;",
                           uiOutput("forecast_table")
                       )
                   )
               )
        )
      )
  )
)
