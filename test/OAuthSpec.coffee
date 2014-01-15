'use strict'


describe 'OAuth', ->


  {OAuthProvider,OAuth,$httpBackend} = {}

  url = 'https://authorizationserver.tld'

  params =
    client_id:     'CLIENT_ID'
    response_type: 'token'
    redirect_uri:  'https://app.tld/callback'
    scope:         'https://authorizationserver.tld https://whatever.tld/resource'




  beforeEach module 'anvil'

  beforeEach module ($injector) ->
    OAuthProvider = $injector.get 'OAuthProvider'
    OAuthProvider.configure url, params

  beforeEach inject ($injector) ->
    OAuth        = $injector.get 'OAuth'
    $httpBackend = $injector.get '$httpBackend'




  describe 'provider configuration', ->

    it 'should set the provider url', ->
      expect(OAuthProvider.provider).toBe url

    it 'should set the authorization params', ->
      expect(OAuthProvider.params).toBe params

    it 'should set the authorization url', ->
      expect(OAuthProvider.urls.authorize).toContain url
      expect(OAuthProvider.urls.authorize).toContain '?'
      expect(OAuthProvider.urls.authorize).toContain "client_id=#{params.client_id}"
      expect(OAuthProvider.urls.authorize).toContain "response_type=#{params.response_type}"
      expect(OAuthProvider.urls.authorize).toContain "redirect_uri=#{params.redirect_uri}"
      expect(OAuthProvider.urls.authorize).toContain "scope=#{params.scope}"

    it 'should set the account url', ->
      expect(OAuthProvider.urls.account).toContain '/v1/account'




  describe 'authorization', ->

    beforeEach inject ($injector) ->
      spyOn OAuth, 'redirect'

    it 'should initiate authorization', ->
      OAuth.authorize()
      expect(OAuth.redirect).toHaveBeenCalledWith OAuthProvider.urls.authorize




  describe 'authorization failure', ->

    beforeEach inject ($injector) ->
      spyOn OAuth, 'clearCredentials'

    it 'should handle failed authorization' , ->
      OAuth.authorize('error=access_denied')
      expect(OAuth.clearCredentials).toHaveBeenCalled()




  describe 'authorization success', ->

    #beforeEach inject ($injector) ->
      #spyOn OAuth, 'setCredentials'

    it 'should handle successful authorization' , ->
      OAuth.authorize('access_token=RANDOM')
      expect(OAuth.credentials.access_token).toBe 'RANDOM'
      #expect(OAuth.setCredentials).toHaveBeenCalledWith access_token: 'RANDOM'



  describe 'request', ->


    {url,headers} = {}


    beforeEach ->
      url = 'https://protected.api.tld/resource'
      headers =
        'Authorization': 'Bearer RANDOM'
        'Accept': 'application/json, text/plain, */*'
      OAuth.setCredentials access_token: 'RANDOM'
      $httpBackend.expectGET(url, headers).respond(200, { foo: 'bar' })

    it 'should set a bearer token', ->
      OAuth({ method: 'GET', url: url })
      $httpBackend.flush()

    it 'should resolve response data', ->
      OAuth({ method: 'GET', url: url }).then (response) ->
        expect(response.foo).toBe 'bar'
      $httpBackend.flush()


