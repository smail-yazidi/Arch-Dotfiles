return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      local logo = [[










      

███████╗███╗   ███╗ █████╗ ██╗██╗     
██╔════╝████╗ ████║██╔══██╗██║██║     
███████╗██╔████╔██║███████║██║██║     
╚════██║██║╚██╔╝██║██╔══██║██║██║     
███████║██║ ╚═╝ ██║██║  ██║██║███████╗
╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝
      ]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"

      return {
        theme = "doom",
        config = {
          header = vim.split(logo, "\n"),
          -- Add a dummy center button to avoid nil line error
          center = {
            { action = "", desc = "", icon = "" },
          },
          footer = {}, -- no footer
        },
        hide = {
          statusline = false,
        },
      }
    end,
  },
}
