describe "I'm in a big house bro", ->
  el = $scope = null

  beforeEach module 'session-expiration'

  beforeEach inject ($rootScope, $compile) ->
    el = angular.element '<div>
                            <p>Hello World</p>
                              {{1 + 99}}
                            </p>
                          </div>'

    scope = $rootScope

    $compile(el)(scope)

    scope.$digest()

  it 'should be 14', ->
    expect(14).toEqual 14
