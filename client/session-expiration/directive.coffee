angular
.module 'session-expiration', ['timer', 'core.uri', 'core.time'], ($httpProvider) ->
  $httpProvider.interceptors.push ($rootScope, $log, uri) ->
    response: (res) ->
      responseUri = uri.parse res.config.url

      return res if uri.isRequestForFile responseUri.pathname

      event = 'sessionexpiration:window:migrate'

      # ignore requests for angular templates (*.html)
      # we're ignoring requests for ALL files actually for the time
      # being, since we don't have any async script loading going on (i.e. require).
      # but in the future, we could ignore files based on extension
      # and hostname if need be. server routes typically don't have
      # dots at the end of the path (unless you're github.com or some other
      # shop with exotic paths/REST endpoints).
      #
      # for now...YAGNI.
      $rootScope.$broadcast event

      res
.directive 'sessionExpiration', ->
  restrict: 'E'
  # no isolate scope since we want to receive events
  # emitted by the timer component. if we isolate, then
  # we want be in the ancestors chain and thus will not
  # any event notifications from child scopes. we are officially
  # a parent of the timer component.
  controller: ($scope, $modal, $timeout, $log, $window, $attrs, $http, time) ->
    ellapsedSeconds           = 0
    modalInstance             = null
    expirationPromptTimeoutId = null
    pageRefreshTimeoutId      = null
    expirationWindow          = parseInt $attrs.expirationWindow    * 1000
    expirationCountdown       = parseInt $attrs.expirationCountdown * 1000

    # manually propagate attr to scope since we're not isolating scope.
    # this would be automated if we isolated scope and specified bindings.
    $scope.expirationCountdown = $attrs.expirationCountdown

    queueSessionExpirationPrompt = ->
      cancelExpirationPromptTask()

      $log.debug '[%s] queuing session expiration prompt.', new Date()

      fn = ->
        secondsToMinutes = time.secondsToMinutes $attrs.expirationWindow

        $log.debug '[%s] no request issued in the last %s.', new Date(), secondsToMinutes
        $log.debug '[%s] opening session expiration prompt.', new Date()

        modalInstance = $modal.open
          templateUrl: 'templates/session-expiration/template.html'
          size: 'sm'

        registerModalHandlers()

      expirationPromptTimeoutId = $timeout fn, expirationWindow

    queuePageRefresh = (reason) ->
      fn = ->
        $log.debug '[%s] session expired, refreshing view.', new Date()

        $window.location.reload()

      message       = '[%s] page refreshing in %s, unless a server request is issued.'
      remainingTime = time.secondsToMinutes $attrs.expirationCountdown - ellapsedSeconds

      $log.debug message, new Date(), remainingTime
      $log.debug '[%s] queueing page refresh (%s).', new Date(), reason

      sessionDuration      = expirationCountdown - (ellapsedSeconds * 1000)
      pageRefreshTimeoutId = $timeout fn, sessionDuration


    cancelTask = (timeoutId, description) ->
      return if not timeoutId

      $log.debug '[%s] clearing pending task for %s.', new Date(), description

      $timeout.cancel timeoutId

    cancelExpirationPromptTask = ->
      cancelTask expirationPromptTimeoutId, 'session expiration prompt'

      expirationPromptTimeoutId = null

    cancelPageRefreshTask = ->
      cancelTask pageRefreshTimeoutId, 'page refresh'

      pageRefreshTimeoutId = null

    registerModalHandlers = ->
      closeFn = -> angular.noop

      dismissFn = (reason) ->
        pageRefreshReasons = ['backdrop click', 'keepalive:fail']

        queuePageRefresh reason if reason in pageRefreshReasons

        ellapsedSeconds = 0

      modalInstance.result.then closeFn, dismissFn

    dismisssSessionExpiationPrompt = (reason) ->
      return if not modalInstance

      message = '[%s] closing session expiration prompt and resetting ellapsedSeconds to 0.'

      $log.debug message, new Date()

      modalInstance.dismiss reason

      modalInstance = null

    slideExpirationWindow = ->
      message = '[%s] sliding expiration window forward by %s.'

      $log.debug message, new Date(), time.secondsToMinutes($attrs.expirationWindow)

      dismisssSessionExpiationPrompt 'sesssion:continued'
      queueSessionExpirationPrompt()
      cancelPageRefreshTask()

    $scope.continue = ->
      $log.debug '[%s] issuing keep-alive request.', new Date()

      $http
      .get('keep-alive')
      .success -> $log.debug '[%s] keep-alive request succeeded.', new Date()
      .error ->
        message       = '[%s] keep alive request failed. refreshing page in %s, unless a server request is issued.'
        remainingTime = time.secondsToMinutes $attrs.expirationCountdown - ellapsedSeconds

        $log.debug message, new Date(), remainingTime

        dismisssSessionExpiationPrompt 'keepalive:fail'

    $scope.$on 'sessionexpiration:window:migrate', ->
      slideExpirationWindow()

    $scope.$on 'timer-stopped', ->
      $log.debug 'timer stopped, refreshing view.'

      $window.location.reload()

    $scope.$on 'timer-tick', -> ++ellapsedSeconds

    $scope.$on 'destroy', ->
      $log.debug '[%s] scope destroyed.', new Date()

      cancelExpirationPromptTask()
      cancelPageRefreshTask()

    queueSessionExpirationPrompt()
.controller 'HttpCtl', ($http, $log, $timeout) ->
  callGithub = ->
    $http.get 'https://api.github.com/users/octocat/orgs'
    .success angular.noop

  callGithub()
  callGithub()
  callGithub()

  # should slide expirationg window an additional 5 seconds
  $timeout callGithub, 5000
