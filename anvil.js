'use strict';

angular.module('anvil', [])


  .provider('OAuth', function OAuthProvider () {

    /**
     * Private state
     */

    var provider, params, urls = {};


    /**
     * Provider configuration
     */

    this.configure = function (url, options) {
      this.provider  = provider = url;
      this.params    = params   = options;
      this.urls      = urls;
      urls.authorize = provider + '/authorize?' + toFormUrlEncoded(params);
      urls.account   = provider + '/v1/account'
    };



    /**
     * Form Urlencode an object
     */

    function toFormUrlEncoded (obj) {
      var pairs = [];

      Object.keys(obj).forEach(function (key) {
        pairs.push(key + '=' + obj[key]);
      });

      return pairs.join('&');
    }


    /**
     * Parse Form Urlencoded data
     */

    function parseFormUrlEncoded (str) {
      var obj = {};

      str.split('&').forEach(function (property) {
        var pair = property.split('=')
          , key  = pair[0]
          , val  = pair[1]
          ;

        obj[key] = val;
      });

      return obj;
    }


    this.$get = ['$q', '$http', '$window', function ($q, $http, $window) {

      /**
       * OAuth Request
       */

      function OAuth (config) {
        var deferred = $q.defer();

        if (!config.headers) { config.headers = {} }
        config.headers['Authorization'] = 'Bearer '
                                        + OAuth.credentials.access_token
                                        ;

        function success (response) {
          deferred.resolve(response.data);
        }

        function failure (fault) {
          deferred.reject(fault);
        }

        $http(config).then(success, failure);
        return deferred.promise;
      }


      /**
       * Authorize
       */

      OAuth.authorize = function (authorization) {

        // in this case, we're handling the authorization response
        if (authorization) {
          var deferred    = $q.defer()
            , credentials = parseFormUrlEncoded(authorization)
            ;

          // handle authorization error
          if (credentials.error) {
            deferred.reject(credentials);
            OAuth.clearCredentials();
          }

          // handle successful authorization
          else {
            deferred.resolve(credentials);
            OAuth.setCredentials(credentials);
          }

          return deferred.promise;
        }

        // in this case, we're initiating the flow
        else {
          OAuth.redirect(urls.authorize);
        }

      };


      /**
       * Redirect
       */

      OAuth.redirect = function (url) {
        $window.location = url;
      }


      /**
       * Popup
       */


      /**
       * Account info
       */

      OAuth.accountInfo = function () {
        return OAuth({
          url: urls.account,
          method: 'GET'
        });
      }


      /**
       * Authorized
       */

      OAuth.authorized = function () {
        return Boolean(this.credentials && this.credentials.access_token);
      };


      /**
       * Check authorization
       */

      OAuth.checkAuthorization = function () {
        var json = localStorage['credentials'];
        if (typeof json === 'string') {
          OAuth.credentials = JSON.parse(json);
        }
      }


      /**
       * Clear credentials
       */

      OAuth.clearCredentials = function () {
        delete OAuth.credentials;
        delete localStorage['credentials'];
      };


      /**
       * Set credentials
       */

      OAuth.setCredentials = function (credentials) {
        OAuth.credentials = credentials;
        localStorage['credentials'] = JSON.stringify(credentials);
      };



      /**
       *
       */

      OAuth.checkAuthorization();


      /**
       *
       */

      return OAuth;

    }];


  })


  .factory('User', function ($q, OAuth) {


    /**
     * CurrentUser Class
     */

    function CurrentUser () {
      if (this.isAuthenticated()) {
        var account = localStorage['account'];
        if (typeof account === 'string') {
          account = JSON.parse(account);
          var key;
          for (key in account) { this[key] = account[key] }
        }
      }
    }


    /**
     * Prototype
     */

    CurrentUser.prototype = {

      isAuthenticated: function () {
        return OAuth.authorized();
      },

      cacheAccountInfo: function () {
        var user = this;
        return OAuth.accountInfo().then(function (response) {
          var deferred = $q.defer();

          var key, data = response.data;
          for (key in data) { user[key] = data[key]; }
          localStorage['account'] = JSON.stringify(user);
          deferred.resolve();

          return deferred.promise;
        });
      },

      reset: function () {
        var key;
        for (key in this) { delete this[key]; }
        OAuth.clearCredentials();
        localStorage.removeItem('account');
      }

    };

    return new CurrentUser();

  })

