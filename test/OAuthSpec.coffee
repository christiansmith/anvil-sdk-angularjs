'use strict'


describe 'OAuthProvider', ->


  {OAuthProvider} = {}


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
    OAuth = $injector.get 'OAuth'


  describe 'configure', ->
  
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



