terraform { 
  cloud { 
    
    organization = "Swintech" 

    workspaces { 
      name = "CLI_Driven" 
    } 
  } 
}

resource "time_sleep" "w8_5_seconds" {
  create_duration = "5s"
}