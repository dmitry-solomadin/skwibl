$ ->
  app = {
    initRemote: ->
      $("form[data-remote]").on "submit", ->
        data = {}
        $(this).find("input").each(-> data[$(@).attr("name")] = $(@).val())

        onsuccess = $(this).data("process-submit") or -> $("#main-content").html(content)

        $.ajax
          url:$(this).attr("action")
          data:data
          type:"POST"
          success:onsuccess

        return false

      $("a[data-remote]").on "click", ->
        $.ajax
          url:$(this).attr("href")
          type:"GET"
          success: (content) -> $("#main-content").html(content)
        return false
  }

  app.initRemote()

  App = app
