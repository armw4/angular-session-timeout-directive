angular
.module 'core.time', []
.service 'time', ->
  @secondsToMinutes = (seconds) ->
    if seconds < 60
      "#{seconds}s"
    else if seconds % 60 is 0
      "#{seconds / 60}m"
    else
      remainingSeconds  = seconds % 60
      normalizedSeconds = if remainingSeconds < 10 then '0' + remainingSeconds else remainingSeconds

      "#{Math.floor(seconds / 60)}m, and #{normalizedSeconds}s"

  @
